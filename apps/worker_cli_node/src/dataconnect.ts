import { readFileSync } from "node:fs";

import {
  appendBuildLogForWorker,
  claimQueuedBuildJob,
  completeBuildJobForWorker,
  connectorConfig,
  createBuildRunForWorker,
  getBuildJob,
  listWorkerEnvironmentVariables,
  listWorkerSecrets,
  updateBuildJobStatus,
  updateBuildRunStatusForWorker,
  updateEnvironmentVariableValueForWorker,
} from "@openci/dataconnect-admin";
import { configureDataConnect as configureBuildJobServicesDataConnect } from "@openci/build-job-services";
import { cert, getApps, initializeApp } from "firebase-admin/app";

import type { BuildJob } from "./types.js";

export function initFirebase(
  serviceAccountPath: string,
  options: { dataConnectServiceId?: string; dataConnectLocation?: string } = {},
): void {
  if (getApps().length > 0) return;
  const serviceAccount = JSON.parse(readFileSync(serviceAccountPath, "utf8")) as Parameters<
    typeof cert
  >[0] & { project_id?: string };
  const dataConnectServiceId =
    options.dataConnectServiceId ?? process.env.OPENCI_DATACONNECT_SERVICE_ID;
  if (dataConnectServiceId) connectorConfig.serviceId = dataConnectServiceId;
  connectorConfig.location =
    options.dataConnectLocation ?? process.env.OPENCI_DATACONNECT_LOCATION ?? connectorConfig.location;
  configureBuildJobServicesDataConnect({
    serviceId: connectorConfig.serviceId,
    location: connectorConfig.location,
  });

  initializeApp({
    credential: cert(serviceAccount),
  });
  console.log(
    `Data Connect: ${connectorConfig.serviceId}/${connectorConfig.connector} (${connectorConfig.location})`,
  );
}

function normalizeJob(job: unknown): BuildJob | null {
  if (!job || typeof job !== "object") return null;
  return job as BuildJob;
}

export async function claimNextJob(): Promise<BuildJob | null> {
  const runsOnPattern = process.platform === "linux" ? "%ubuntu%" : "%macos%";
  const response = await claimQueuedBuildJob({ runsOnPattern });
  const claimedJob = normalizeJob(response.data.job);
  if (!claimedJob) return null;

  // Native SQL mutation results can lose fields through generated SDK decoding.
  // Re-read through the typed query before executing the job.
  const details = await getBuildJob({ id: claimedJob.id });
  return normalizeJob(details.data.buildJob) ?? claimedJob;
}

export async function createRun(buildJobId: string, runId: string): Promise<void> {
  await createBuildRunForWorker({ buildJobId, id: runId });
}

export async function appendLog(input: {
  buildJobId: string;
  runId: string;
  id: string;
  message: string;
  level: "info" | "warning" | "error";
  timestamp: string;
  stackTrace?: string;
}): Promise<void> {
  await appendBuildLogForWorker(input);
}

export async function completeJob(id: string, status: "success" | "failure"): Promise<void> {
  await completeBuildJobForWorker({
    id,
    status,
    completedAt: new Date().toISOString(),
  });
}

export async function setJobStatus(id: string, status: string): Promise<void> {
  await updateBuildJobStatus({ id, status });
}

export async function updateRunStatus(input: {
  buildJobId: string;
  runId: string;
  status: string;
  conclusion?: string | null;
}): Promise<void> {
  await updateBuildRunStatusForWorker(input);
}

export async function isJobCancelled(buildJobId: string): Promise<boolean> {
  const response = await getBuildJob({ id: buildJobId });
  const status = response.data.buildJob?.status;
  return status === "cancelled";
}

export async function getEnvironmentVariables(teamId: string): Promise<
  {
    id: string;
    key: string;
    value: string;
    autoIncrement?: boolean | null;
  }[]
> {
  const response = await listWorkerEnvironmentVariables({ teamId });
  return response.data.environmentVariables;
}

export async function updateEnvironmentVariable(id: string, value: string): Promise<void> {
  await updateEnvironmentVariableValueForWorker({ id, value });
}

export async function getSecrets(teamId: string): Promise<
  {
    id: string;
    name: string;
    pathToSecret?: string | null;
  }[]
> {
  const response = await listWorkerSecrets({ teamId });
  return response.data.secrets;
}
