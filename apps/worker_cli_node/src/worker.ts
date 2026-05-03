import { randomUUID } from "node:crypto";

import {
  generateFailureSummary,
  handleBuildJobStatusChange,
  updateCheckRun,
} from "@openci/build-job-services";
import { BuildJobStatus } from "@openci/dataconnect-admin";
import { claimNextJob, completeJob, createRun, updateRunStatus } from "./dataconnect.js";
import { checkAndUpdate, exitForUpdate } from "./auto_updater.js";
import { buildEnvVars, buildSecretVars } from "./env.js";
import { withInstallationToken } from "./github.js";
import { flushLogs, logError, logInfo } from "./logger.js";
import { runBuildJob } from "./runner.js";
import type { WorkerConfig } from "./types.js";
import { version } from "./version.js";

export async function processOneJob(config: WorkerConfig): Promise<boolean> {
  const claimedJob = await claimNextJob();
  if (!claimedJob) return false;

  const runId = randomUUID();
  let buildJob = claimedJob;
  await createRun(claimedJob.id, runId);
  await logInfo(
    claimedJob.id,
    runId,
    `Processing job: ${claimedJob.id} for ${claimedJob.owner}/${claimedJob.repo} [node]`,
  );

  try {
    buildJob = await withInstallationToken(claimedJob, config.projectId);
    await updateCheckRun(buildJob, "in_progress");
    const envVars = await buildEnvVars({
      buildJob,
      projectId: config.projectId,
      buildJobId: buildJob.id,
      runId,
    });
    const secretVars = await buildSecretVars({
      buildJob,
      serviceAccountPath: config.serviceAccountPath,
      buildJobId: buildJob.id,
      runId,
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
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    const stack = error instanceof Error ? error.stack : undefined;
    await logError(buildJob.id, runId, `Job failed: ${message}`, stack);
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
    await generateFailureSummary(completedJob, config.projectId);
    throw error;
  } finally {
    await flushLogs();
  }

  return true;
}

const maxBackoffMs = 5 * 60_000;

function backoffMs(base: number, consecutiveFailures: number): number {
  const delay = base * 2 ** Math.min(consecutiveFailures, 10);
  return Math.min(delay, maxBackoffMs);
}

export async function pollForJobs(config: WorkerConfig): Promise<void> {
  console.log(`Worker started. Worker ID: ${config.workerId}`);
  console.log(`Worker version: ${version}`);
  console.log(
    `Platform: ${process.platform} (${process.platform === "linux" ? "ubuntu jobs" : "macos jobs"})`,
  );

  let lastUpdateCheckAt = 0;
  let consecutiveFailures = 0;
  while (true) {
    try {
      if (!config.once && Date.now() - lastUpdateCheckAt > 60_000) {
        lastUpdateCheckAt = Date.now();
        const updateResult = await checkAndUpdate();
        if (updateResult === "updated") exitForUpdate();
        if (updateResult === "failed") {
          consecutiveFailures += 1;
          const delay = backoffMs(config.pollIntervalMs, consecutiveFailures);
          console.warn(`Backing off for ${(delay / 1000).toFixed(0)}s (${consecutiveFailures} consecutive failures)`);
          await new Promise((resolve) => setTimeout(resolve, delay));
          continue;
        }
      }

      const found = await processOneJob(config);
      consecutiveFailures = 0;
      if (config.once) return;
      if (!found) {
        await new Promise((resolve) => setTimeout(resolve, config.pollIntervalMs));
      }
    } catch (error) {
      consecutiveFailures += 1;
      const delay = backoffMs(config.pollIntervalMs, consecutiveFailures);
      console.error(`Error in poll loop (${consecutiveFailures} consecutive failures, next retry in ${(delay / 1000).toFixed(0)}s): ${String(error)}`);
      if (config.once) throw error;
      await new Promise((resolve) => setTimeout(resolve, delay));
    }
  }
}
