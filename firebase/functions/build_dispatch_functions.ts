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
  dispatchRetryTaskId,
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
  jobId: string,
  taskId = dispatchTaskId(jobId),
  scheduleTime?: Date,
): Promise<void> {
  try {
    await getFunctions()
      .taskQueue("locations/asia-northeast1/functions/dispatchBuildJob")
      .enqueue({ jobId }, { id: taskId, scheduleTime, dispatchDeadlineSeconds: 120 });
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
        await enqueue(id);
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
      await enqueue(variables.jobId, dispatchCompletionTaskId(variables.jobId, variables.id));
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
    if (
      !input ||
      typeof input !== "object" ||
      Object.keys(input).length !== 1 ||
      !("jobId" in input) ||
      !validJobId(input.jobId)
    ) {
      error("Invalid build dispatch task");
      return;
    }
    const jobId = input.jobId;
    try {
      const store = new DataConnectDispatchStore(getDispatchDataConnect());
      if ((await store.read(jobId)).job?.status === "CANCELLED") await store.cancelUnstarted(jobId);
      // Also covers jobs queued before deployment and cancellation while waiting
      // for capacity. Never launch a new reservation before its check is durable.
      await queuedChecks(getDispatchDataConnect()).sync(jobId);
      const orchard = new OrchardCapacityClient({
        url: orchardUrl.value(),
        account: orchardAccount.value(),
        token: orchardToken.value(),
        ca: orchardCa.value(),
        allowLocalHttp:
          process.env.FUNCTIONS_EMULATOR === "true" &&
          (process.env.GCLOUD_PROJECT ?? "").startsWith("demo-"),
      });
      await executeDispatch(jobId, {
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
            dispatch.jobId,
            dispatchTaskId(dispatch.jobId, dispatch.id),
            new Date(Date.parse(dispatch.startDeadline) + 1000),
          ),
        launch: (dispatch) => launchCloudRunJob(dispatch),
      });
    } catch (failure) {
      // Never include SDK/HTTP exception objects: they can contain credentials.
      if (failure instanceof DispatchRetry) {
        try {
          // Acknowledge only after the successor exists. A lost enqueue response
          // retries this task with the same successor ID, without multiplying work.
          await enqueue(
            jobId,
            dispatchRetryTaskId(jobId, request.id),
            new Date(Date.now() + 60_000),
          );
        } catch {
          error("Build dispatch failed", { jobId, reason: "retry_enqueue_failed" });
          throw new Error("Build dispatch retry could not be queued; retry required");
        }
        info("Build dispatch deferred", { jobId, reason: failure.reason });
        return;
      }
      error("Build dispatch failed", { jobId, reason: dispatchFailureReason(failure) });
      throw new Error("Build dispatch failed; retry required");
    }
  },
);
