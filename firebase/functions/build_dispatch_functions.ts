import { getFunctions } from "firebase-admin/functions";
import { onMutationExecuted } from "firebase-functions/dataconnect";
import { error, info } from "firebase-functions/logger";
import { defineInt, defineSecret, defineString } from "firebase-functions/params";
import { onTaskDispatched } from "firebase-functions/v2/tasks";
import {
  createdBuildJobIds,
  dispatchBuildJob as executeDispatch,
  dispatchTaskId,
  DispatchRetry,
  validJobId,
} from "./build_dispatch.js";
import { DataConnectDispatchStore, getDispatchDataConnect } from "./dispatch_store.js";
import { OrchardCapacityClient } from "./orchard_capacity.js";
import { launchCloudRunJob } from "./cloud_run_job.js";

const orchardUrl = defineString("ORCHARD_API_URL");
const orchardAccount = defineString("ORCHARD_SERVICE_ACCOUNT_NAME");
const orchardToken = defineSecret("ORCHARD_SERVICE_ACCOUNT_TOKEN");
const orchardCa = defineString("ORCHARD_CA_CERT", { default: "" });
const vmCpu = defineInt("ORCHARD_VM_CPU", { default: 2 });
const vmMemory = defineInt("ORCHARD_VM_MEMORY_MIB", { default: 4096 });
const vmImage = defineString("BASE_VM_NAME", { default: "base-macos" });
const cloudRunJob = defineString("BUILD_EXECUTOR_JOB");

async function enqueue(jobId: string, dispatchId?: string, scheduleTime?: Date): Promise<void> {
  try {
    await getFunctions()
      .taskQueue("locations/asia-northeast1/functions/dispatchBuildJob")
      .enqueue(
        { jobId },
        { id: dispatchTaskId(jobId, dispatchId), scheduleTime, dispatchDeadlineSeconds: 120 },
      );
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
    region: "asia-northeast1",
    service: "openci-b1b91-service",
    connector: "webhooks",
    operation: "CompleteWebhookTask",
    memory: "128MiB",
    cpu: 1,
    concurrency: 1,
    minInstances: 0,
    timeoutSeconds: 60,
    retry: true,
  },
  async (event) => {
    try {
      if (event.authType !== "admin") throw new Error("Unexpected mutation principal");
      for (const id of createdBuildJobIds(event.data.payload)) await enqueue(id);
    } catch {
      error("Build dispatch enqueue failed", { eventId: event.id });
      throw new Error("Build dispatch enqueue failed; retry required");
    }
  },
);

export const dispatchBuildJob = onTaskDispatched<unknown>(
  {
    region: "asia-northeast1",
    invoker: "private",
    memory: "128MiB",
    cpu: 1,
    concurrency: 1,
    minInstances: 0,
    timeoutSeconds: 60,
    secrets: [orchardToken],
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
        store: new DataConnectDispatchStore(getDispatchDataConnect()),
        snapshot: () => orchard.snapshot(),
        configuration: {
          cpu: vmCpu.value(),
          memoryMiB: vmMemory.value(),
          image: vmImage.value(),
          cloudRunJob: cloudRunJob.value(),
        },
        enqueueRecovery: (dispatch) =>
          enqueue(jobId, dispatch.id, new Date(Date.parse(dispatch.startDeadline) + 1000)),
        launch: (dispatch) => launchCloudRunJob(dispatch),
      });
    } catch (failure) {
      // Never include SDK/HTTP exception objects: they can contain credentials.
      if (failure instanceof DispatchRetry)
        info("Build dispatch deferred", { jobId, reason: failure.reason });
      else error("Build dispatch failed", { jobId });
      throw new Error("Build dispatch deferred; retry required");
    }
  },
);
