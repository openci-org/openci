import { randomUUID } from "node:crypto";

import {
  generateFailureSummary,
  handleBuildJobStatusChange,
  updateCheckRun,
} from "@openci/build-job-services";
import { claimNextJob, completeJob, createRun, updateRunStatus } from "./dataconnect.js";
import { checkAndUpdate, exitForUpdate } from "./auto_updater.js";
import { buildEnvVars, buildSecretVars } from "./env.js";
import { withInstallationToken } from "./github.js";
import { flushLogs, logError, logInfo } from "./logger.js";
import { runBuildJob } from "./runner.js";
import type { WorkerConfig } from "./types.js";

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
    await completeJob(buildJob.id, "success");
    const completedJob = {
      ...buildJob,
      status: "success",
      latestRunId: runId,
      completedAt: new Date().toISOString(),
    };
    await updateCheckRun(completedJob, "completed", "success");
    await handleBuildJobStatusChange(completedJob, "success");
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
    await completeJob(buildJob.id, "failure");
    const completedJob = {
      ...buildJob,
      status: "failure",
      latestRunId: runId,
      completedAt: new Date().toISOString(),
    };
    await updateCheckRun(completedJob, "completed", "failure");
    await handleBuildJobStatusChange(completedJob, "failure");
    await generateFailureSummary(completedJob, config.projectId);
    throw error;
  } finally {
    await flushLogs();
  }

  return true;
}

export async function pollForJobs(config: WorkerConfig): Promise<void> {
  console.log(`Worker started. Worker ID: ${config.workerId}`);
  console.log(
    `Platform: ${process.platform} (${process.platform === "linux" ? "ubuntu jobs" : "macos jobs"})`,
  );

  let lastUpdateCheckAt = 0;
  while (true) {
    try {
      if (!config.once && Date.now() - lastUpdateCheckAt > 60_000) {
        lastUpdateCheckAt = Date.now();
        const updateResult = await checkAndUpdate();
        if (updateResult === "updated") exitForUpdate();
        if (updateResult === "failed") {
          await new Promise((resolve) => setTimeout(resolve, config.pollIntervalMs));
          continue;
        }
      }

      const found = await processOneJob(config);
      if (config.once) return;
      if (!found) {
        await new Promise((resolve) => setTimeout(resolve, config.pollIntervalMs));
      }
    } catch (error) {
      console.error(`Error in poll loop: ${String(error)}`);
      if (config.once) throw error;
      await new Promise((resolve) => setTimeout(resolve, config.pollIntervalMs));
    }
  }
}
