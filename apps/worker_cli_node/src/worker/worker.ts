import { readFileSync } from "node:fs";
import { randomUUID } from "node:crypto";
import { hostname } from "node:os";
import { setTimeout } from "node:timers/promises";

import { checkAndUpdate, exitForUpdate } from "../auto_updater.js";
import {
  BuildJobStatus,
  handleBuildJobStatusChange,
  updateCheckRun,
} from "../build_job_services.js";
import {
  claimNextJob,
  completeJob,
  createRun,
  updateRunStatus,
  updateWorkerHeartbeat,
} from "../firestore.js";
import { buildEnvVars, buildSecretVars } from "../env.js";
import { withInstallationToken, fetchWorkflowContent } from "../github.js";
import { flushLogs, logError, logInfo, logWarning } from "../logger.js";
import { runBuildJob } from "../runner.js";
import type { WorkerConfig, WorkerStatus } from "../types.js";
import { version } from "../version.js";
import { backoffMilliSeconds } from "./backoff.js";

const heartbeatIntervalMs = 30_000;

interface WorkerHeartbeatState {
  status: WorkerStatus;
  currentBuildJobId: string | null;
  currentRunId: string | null;
  consecutiveFailures: number;
  lastError: string | null;
}

interface JobLifecycleCallbacks {
  onJobStarted?: (job: { buildJobId: string; runId: string }) => Promise<void>;
  onJobSucceeded?: (job: { buildJobId: string; runId: string }) => Promise<void>;
  onJobFailed?: (job: { buildJobId: string; runId: string; error: unknown }) => Promise<void>;
}

function messageFromError(error: unknown): string {
  return error instanceof Error ? error.message : String(error);
}

async function safeHeartbeat(config: WorkerConfig, state: WorkerHeartbeatState): Promise<void> {
  try {
    await updateWorkerHeartbeat({
      workerId: config.workerId,
      version,
      platform: process.platform,
      hostname: hostname(),
      pid: process.pid,
      status: state.status,
      currentBuildJobId: state.currentBuildJobId,
      currentRunId: state.currentRunId,
      consecutiveFailures: state.consecutiveFailures,
      lastError: state.lastError,
    });
  } catch (error) {
    console.warn(`Failed to update worker heartbeat: ${String(error)}`);
  }
}

export async function processOneJob(
  config: WorkerConfig,
  callbacks: JobLifecycleCallbacks = {},
): Promise<boolean> {
  const claimedJob = await claimNextJob();
  if (!claimedJob) return false;

  const runId = randomUUID();
  let buildJob = claimedJob;
  await createRun(claimedJob.id, runId);
  await callbacks.onJobStarted?.({ buildJobId: claimedJob.id, runId });
  await logInfo(
    claimedJob.id,
    runId,
    `Processing job: ${claimedJob.id} for ${claimedJob.owner}/${claimedJob.repo} [node]`,
  );

  try {
    buildJob = await withInstallationToken(claimedJob, config.projectId);
    await updateCheckRun(buildJob, "in_progress");
    let workflowContent: string | null = null;
    if (buildJob.workflowFileName) {
      try {
        workflowContent = await fetchWorkflowContent(buildJob, config.projectId);
      } catch (error) {
        await logWarning(
          buildJob.id,
          runId,
          `Failed to pre-fetch workflow content: ${String(error)}`,
        );
      }
    }

    const envVars = await buildEnvVars({
      buildJob,
      projectId: config.projectId,
      buildJobId: buildJob.id,
      runId,
      workflowContent,
    });

    try {
      const serviceAccountJson = readFileSync(config.serviceAccountPath, "utf8");
      envVars["OPENCI_SERVICE_ACCOUNT"] = Buffer.from(serviceAccountJson).toString("base64");
    } catch (error) {
      await logWarning(
        buildJob.id,
        runId,
        `Failed to read and inject master service account: ${String(error)}`,
      );
    }

    const secretVars = await buildSecretVars({
      buildJob,
      projectId: config.projectId,
      serviceAccountPath: config.serviceAccountPath,
      buildJobId: buildJob.id,
      runId,
      workflowContent,
    });
    await logInfo(buildJob.id, runId, "Environment variables written");

    await runBuildJob({ buildJob, runId, envVars, secretVars, workerId: config.workerId });

    await logInfo(buildJob.id, runId, "Build completed successfully");
    await updateRunStatus({
      buildJobId: buildJob.id,
      runId,
      status: "completed",
      conclusion: "success",
    });
    await completeJob(buildJob.id, BuildJobStatus.SUCCESS);
    const completedJob = {
      ...buildJob,
      status: BuildJobStatus.SUCCESS,
      latestRunId: runId,
      completedAt: new Date().toISOString(),
    };
    await updateCheckRun(completedJob, "completed", "success");
    await handleBuildJobStatusChange(completedJob, BuildJobStatus.SUCCESS);
    await callbacks.onJobSucceeded?.({ buildJobId: buildJob.id, runId });
  } catch (error) {
    const message = messageFromError(error);
    const stack = error instanceof Error ? error.stack : undefined;
    await logError(buildJob.id, runId, `Job failed: ${message}`, stack);
    await flushLogs();
    await updateRunStatus({
      buildJobId: buildJob.id,
      runId,
      status: "completed",
      conclusion: "failure",
    });
    await completeJob(buildJob.id, BuildJobStatus.FAILURE);
    const completedJob = {
      ...buildJob,
      status: BuildJobStatus.FAILURE,
      latestRunId: runId,
      completedAt: new Date().toISOString(),
    };
    await updateCheckRun(completedJob, "completed", "failure");
    await handleBuildJobStatusChange(completedJob, BuildJobStatus.FAILURE);
    await callbacks.onJobFailed?.({ buildJobId: buildJob.id, runId, error });
    throw error;
  } finally {
    await flushLogs();
  }

  return true;
}

export async function pollForJobs(config: WorkerConfig): Promise<void> {
  console.log(`Worker started. Worker ID: ${config.workerId}`);
  console.log(`Worker version: ${version}`);
  console.log(
    `Platform: ${process.platform} (${process.platform === "linux" ? "ubuntu jobs" : "macos jobs"})`,
  );

  const heartbeatState: WorkerHeartbeatState = {
    status: "starting",
    currentBuildJobId: null,
    currentRunId: null,
    consecutiveFailures: 0,
    lastError: null,
  };
  const sendHeartbeat = async (patch: Partial<WorkerHeartbeatState> = {}) => {
    Object.assign(heartbeatState, patch);
    await safeHeartbeat(config, heartbeatState);
  };
  await sendHeartbeat();

  const heartbeatTimer = config.once
    ? undefined
    : globalThis.setInterval(() => {
        void safeHeartbeat(config, heartbeatState);
      }, heartbeatIntervalMs);

  let lastUpdateCheckAt = 0;
  let consecutiveFailures = 0;
  try {
    while (true) {
      try {
        if (!config.once && Date.now() - lastUpdateCheckAt > 60_000) {
          lastUpdateCheckAt = Date.now();
          const updateResult = await checkAndUpdate();
          if (updateResult === "updated") {
            await sendHeartbeat({ status: "stopping" });
            exitForUpdate();
          }
          if (updateResult === "failed") {
            const delay = backoffMilliSeconds(consecutiveFailures);
            consecutiveFailures += 1;
            console.warn(
              `Backing off for ${(delay / 1000).toFixed(0)}s (${consecutiveFailures} consecutive failures)`,
            );
            await sendHeartbeat({
              status: "error",
              consecutiveFailures,
              lastError: "Auto-update failed",
            });
            await setTimeout(delay);
            continue;
          }
        }

        const found = await processOneJob(config, {
          onJobStarted: (job) =>
            sendHeartbeat({
              status: "busy",
              currentBuildJobId: job.buildJobId,
              currentRunId: job.runId,
              consecutiveFailures,
              lastError: null,
            }),
          onJobSucceeded: () =>
            sendHeartbeat({
              status: "idle",
              currentBuildJobId: null,
              currentRunId: null,
              consecutiveFailures: 0,
              lastError: null,
            }),
          onJobFailed: (job) =>
            sendHeartbeat({
              status: "error",
              currentBuildJobId: job.buildJobId,
              currentRunId: job.runId,
              consecutiveFailures,
              lastError: messageFromError(job.error),
            }),
        });
        consecutiveFailures = 0;
        if (!found) {
          if (
            heartbeatState.status !== "idle" ||
            heartbeatState.currentBuildJobId ||
            heartbeatState.currentRunId ||
            heartbeatState.lastError
          ) {
            await sendHeartbeat({
              status: "idle",
              currentBuildJobId: null,
              currentRunId: null,
              consecutiveFailures,
              lastError: null,
            });
          }
        }
        if (config.once) return;
        if (!found) {
          await setTimeout(config.pollIntervalMs);
        }
      } catch (error) {
        const delay = backoffMilliSeconds(consecutiveFailures);
        consecutiveFailures += 1;
        await sendHeartbeat({
          status: "error",
          consecutiveFailures,
          lastError: messageFromError(error),
        });
        console.error(
          `Error in poll loop (${consecutiveFailures} consecutive failures, next retry in ${(delay / 1000).toFixed(0)}s): ${String(error)}`,
        );
        heartbeatState.currentBuildJobId = null;
        heartbeatState.currentRunId = null;
        if (config.once) throw error;
        await setTimeout(delay);
      }
    }
  } finally {
    if (heartbeatTimer) globalThis.clearInterval(heartbeatTimer);
    await sendHeartbeat({ status: "stopping" });
  }
}
