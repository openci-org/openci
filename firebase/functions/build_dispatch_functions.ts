import { randomUUID } from "node:crypto";
import { getFunctions } from "firebase-admin/functions";
import { onMutationExecuted } from "firebase-functions/dataconnect";
import { error, info } from "firebase-functions/logger";
import { defineInt, defineSecret, defineString } from "firebase-functions/params";
import { onTaskDispatched } from "firebase-functions/v2/tasks";
import {
  createdBuildJobIds,
  dispatchBuildJob as executeDispatch,
  dispatchTaskId,
  dispatchCompletionTaskId,
  dispatchContinuationTaskId,
  dispatchFailureReason,
  DispatchRetry,
  validJobId,
} from "./build_dispatch.js";
import { DataConnectDispatchStore, getDispatchDataConnect } from "./dispatch_store.js";
import { OrchardCapacityClient } from "./orchard_capacity.js";
import { launchCloudRunJob } from "./cloud_run_job.js";
import { orchardNetworkOptions } from "./orchard_network.js";
import { dispatchServiceAccount } from "./function_identity.js";
import { dataConnectServiceId } from "./data_connect_config.js";
import { queuedChecks } from "./queued_checks.js";

const orchardUrl = defineString("ORCHARD_API_URL");
const orchardAccount = defineString("ORCHARD_SERVICE_ACCOUNT_NAME");
const orchardToken = defineSecret("ORCHARD_SERVICE_ACCOUNT_TOKEN");
const githubPrivateKey = defineSecret("GITHUB_APP_PRIVATE_KEY");
const orchardCa = defineString("ORCHARD_CA_CERT", { default: "" });
const vmCpu = defineInt("ORCHARD_VM_CPU", { default: 2 });
const vmMemory = defineInt("ORCHARD_VM_MEMORY_MIB", { default: 4096 });
const vmImage = defineString("BASE_VM_NAME", { default: "base-macos" });
const cloudRunJob = defineString("BUILD_EXECUTOR_JOB");

async function enqueue(
  notification: { jobId: string } | { dispatch: true },
  taskId: string,
  scheduleTime?: Date,
): Promise<void> {
  try {
    await getFunctions()
      .taskQueue("locations/asia-northeast1/functions/dispatchBuildJob")
      .enqueue(notification, { id: taskId, scheduleTime, dispatchDeadlineSeconds: 120 });
  } catch (failure) {
    if (
      failure &&
      typeof failure === "object" &&
      "code" in failure &&
      failure.code === "functions/task-already-exists"
    )
      return;
    throw new Error("Build dispatch could not be queued");
  }
}

export const queueBuildJobs = onMutationExecuted(
  {
    serviceAccount: dispatchServiceAccount,
    region: "asia-northeast1",
    service: dataConnectServiceId(),
    connector: "webhooks",
    operation: "CompleteWebhookTask",
    memory: "256MiB",
    cpu: 1,
    concurrency: 1,
    minInstances: 0,
    timeoutSeconds: 540,
    secrets: [githubPrivateKey],
    retry: true,
  },
  async (event) => {
    try {
      if (event.authType !== "admin") throw new Error("Unexpected mutation principal");
      for (const id of createdBuildJobIds(event.data.payload)) {
        await queuedChecks(getDispatchDataConnect()).sync(id);
        await enqueue({ jobId: id }, dispatchTaskId(id));
      }
      const { data, variables, errors } = event.data.payload;
      // Older deployed connectors have no cancellation result. Redelivery of a
      // successful cancellation pages the durable source again with stable IDs.
      if (!errors?.length && data && typeof data === "object" && "cancelled" in data) {
        if (!Number.isSafeInteger(data.cancelled) || Number(data.cancelled) < 0)
          throw new Error("Invalid cancellation count");
        if (Number(data.cancelled) > 0) {
          if (
            !variables ||
            typeof variables !== "object" ||
            !("id" in variables) ||
            !validJobId(variables.id)
          )
            throw new Error("Invalid cancellation source");
          const taskId = variables.id;
          const store = new DataConnectDispatchStore(getDispatchDataConnect());
          let afterId = "";
          for (;;) {
            const jobs = await store.superseded(taskId, afterId);
            for (const job of jobs)
              await enqueue({ jobId: job.id }, dispatchTaskId(job.id, `superseded-${taskId}`));
            if (jobs.length < 100) break;
            afterId = jobs.at(-1)!.id;
          }
        }
      }
    } catch {
      error("Build dispatch enqueue failed", { eventId: event.id });
      throw new Error("Build dispatch enqueue failed; retry required");
    }
  },
);

export const queueBuildDispatchOnCompletion = onMutationExecuted(
  {
    serviceAccount: dispatchServiceAccount,
    region: "asia-northeast1",
    service: dataConnectServiceId(),
    connector: "dispatch",
    operation: "CompleteBuildExecution",
    memory: "256MiB",
    cpu: 1,
    concurrency: 1,
    minInstances: 0,
    timeoutSeconds: 60,
    retry: true,
  },
  async (event) => {
    try {
      if (event.authType !== "admin") throw new Error("Unexpected mutation principal");
      const { data, variables, errors } = event.data.payload;
      if (errors?.length) return;
      if (
        !data ||
        typeof data !== "object" ||
        !("buildJobDispatch_updateMany" in data) ||
        data.buildJobDispatch_updateMany !== 1 ||
        !variables ||
        typeof variables !== "object" ||
        !("jobId" in variables) ||
        !validJobId(variables.jobId) ||
        !("id" in variables) ||
        !validJobId(variables.id)
      )
        throw new Error("Invalid completed build execution");
      // The original recovery task may still be scheduled at the startup
      // deadline. Completion needs its own task ID to wake the queue now.
      await enqueue(
        { jobId: variables.jobId },
        dispatchCompletionTaskId(variables.jobId, variables.id),
      );
    } catch {
      error("Build completion dispatch enqueue failed", { eventId: event.id });
      throw new Error("Build completion dispatch enqueue failed; retry required");
    }
  },
);

export const dispatchBuildJob = onTaskDispatched<unknown>(
  {
    ...orchardNetworkOptions,
    serviceAccount: dispatchServiceAccount,
    region: "asia-northeast1",
    // Keep the scoped IAM bindings from deployment. Setting "private" here
    // makes Firebase CLI clear both Run invokers and Cloud Tasks enqueuers.
    memory: "256MiB",
    cpu: 1,
    concurrency: 1,
    minInstances: 0,
    timeoutSeconds: 60,
    secrets: [orchardToken, githubPrivateKey],
    retryConfig: {
      maxAttempts: -1,
      maxRetrySeconds: 0,
      minBackoffSeconds: 30,
      maxBackoffSeconds: 60,
      maxDoublings: 1,
    },
    rateLimits: { maxConcurrentDispatches: 5, maxDispatchesPerSecond: 5 },
  },
  async (request) => {
    const input = request.data;
    if (!input || typeof input !== "object" || Object.keys(input).length !== 1) {
      error("Invalid build dispatch task");
      return;
    }
    const jobId = "jobId" in input && validJobId(input.jobId) ? input.jobId : undefined;
    const sharedNotification = "dispatch" in input && input.dispatch === true;
    if (!jobId && !sharedNotification) {
      error("Invalid build dispatch task");
      return;
    }
    try {
      const continuationId = dispatchContinuationTaskId(request.id);
      const store = new DataConnectDispatchStore(getDispatchDataConnect());
      let awaitingJobId: string | undefined;
      if (jobId) {
        const { job } = await store.read(jobId);
        if (job?.status === "CANCELLED") await store.cancelUnstarted(jobId);
        if (job?.status === "QUEUED") awaitingJobId = jobId;
        // Also handles legacy per-job retries already queued before deployment.
        await queuedChecks(getDispatchDataConnect()).sync(jobId);
      } else {
        // Continue even if already consumed: this delivery may be recovering a
        // crash after clearing the reservation but before creating its successor.
        await store.consumeRetry(request.id);
      }
      const orchard = new OrchardCapacityClient({
        url: orchardUrl.value(),
        account: orchardAccount.value(),
        token: orchardToken.value(),
        ca: orchardCa.value(),
        allowLocalHttp:
          process.env.FUNCTIONS_EMULATOR === "true" &&
          (process.env.GCLOUD_PROJECT ?? "").startsWith("demo-"),
      });
      let launched = false;
      let deferred: DispatchRetry | undefined;
      try {
        launched = await executeDispatch({
          store,
          snapshot: () => orchard.snapshot(),
          configuration: {
            cpu: vmCpu.value(),
            memoryMiB: vmMemory.value(),
            image: vmImage.value(),
            cloudRunJob: cloudRunJob.value(),
          },
          syncQueuedCheck: (selectedJobId) =>
            queuedChecks(getDispatchDataConnect()).sync(selectedJobId),
          enqueueRecovery: (dispatch) =>
            enqueue(
              { jobId: dispatch.jobId },
              dispatchTaskId(dispatch.jobId, dispatch.id),
              new Date(Date.parse(dispatch.startDeadline) + 1000),
            ),
          launch: (dispatch) => launchCloudRunJob(dispatch),
        });
      } catch (failure) {
        if (!(failure instanceof DispatchRetry)) throw failure;
        deferred = failure;
      }

      const { queuedJob, changedJob } = await store.pendingWork();
      if (changedJob) {
        if (changedJob.status === "CANCELLED") {
          await enqueue(
            { jobId: changedJob.id },
            dispatchContinuationTaskId(request.id, changedJob.id),
          );
        }
        await store.completeRetryJob(changedJob.id);
      }
      if (launched || changedJob) {
        // Fill other free slots and drain status changes without waiting a minute.
        await enqueue({ dispatch: true }, continuationId);
      }
      if (deferred || queuedJob || awaitingJobId) {
        try {
          // Register a queued source even if it just left the queue. Cancellation
          // can race its check sync; the shared retry must inherit that notification.
          const retry = await store.reserveRetry(`capacity-${randomUUID()}`, awaitingJobId);
          await enqueue({ dispatch: true }, retry.taskId, retry.scheduleTime);
        } catch {
          throw new Error("Build dispatch retry could not be queued");
        }
      }
      if (deferred) info("Build dispatch deferred", { jobId, reason: deferred.reason });
    } catch (failure) {
      // Never include SDK/HTTP exception objects: they can contain credentials.
      error("Build dispatch failed", { jobId, reason: dispatchFailureReason(failure) });
      throw new Error("Build dispatch failed; retry required");
    }
  },
);
