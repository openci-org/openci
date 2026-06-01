import { readFileSync } from "node:fs";
import { JWT } from "google-auth-library";
import { BuildJobStatus } from "./build_job_services.js";
import type { BuildJob, WorkerHeartbeatInput } from "./types.js";

let apiBaseUrl = "";
let jwtClient: JWT | null = null;
let isEmulator = false;
let configProjectNumber: string | null = null;

// プロジェクトIDに対応するデフォルトのプロジェクト番号マッピング
const defaultProjectNumbers: Record<string, string> = {
  "openci-b1b91": "372767414789",
};

export function initFirebase(serviceAccountPath: string, projectNumber?: string): void {
  isEmulator =
    process.env.FUNCTIONS_EMULATOR === "true" || process.env.FIRESTORE_EMULATOR_HOST !== undefined;

  const serviceAccount = JSON.parse(readFileSync(serviceAccountPath, "utf8")) as {
    project_id?: string;
    client_email?: string;
    private_key?: string;
  };
  const projectId = serviceAccount.project_id ?? "openci-b1b91";

  if (isEmulator) {
    const emulatorHost = process.env.FIREBASE_FUNCTIONS_EMULATOR_HOST || "127.0.0.1:5001";
    apiBaseUrl = `http://${emulatorHost}/${projectId}/asia-northeast1`;
  } else {
    configProjectNumber = projectNumber ?? defaultProjectNumbers[projectId] ?? null;
    if (!serviceAccount.client_email || !serviceAccount.private_key) {
      throw new Error("client_email or private_key not found in service account file");
    }
    jwtClient = new JWT({
      email: serviceAccount.client_email,
      key: serviceAccount.private_key,
    });
  }
  console.log(
    `Worker API Client Initialized. Emulator: ${isEmulator}, Project ID: ${projectId}, Project Number: ${configProjectNumber}`,
  );
}

async function callApi(functionName: string, payload: unknown): Promise<any> {
  let url: string;
  if (isEmulator) {
    url = `${apiBaseUrl}/${functionName}`;
  } else {
    if (!configProjectNumber) {
      throw new Error(
        "FUNCTIONS_PROJECT_NUMBER is required for production mode but was not provided or resolved automatically.",
      );
    }
    url = `https://${functionName}-${configProjectNumber}.asia-northeast1.run.app`;
  }

  const headers: Record<string, string> = {
    "Content-Type": "application/json",
  };

  if (!isEmulator && jwtClient) {
    try {
      const idToken = await jwtClient.fetchIdToken(url);
      headers["Authorization"] = `Bearer ${idToken}`;
    } catch (err) {
      console.warn(`[API] Failed to retrieve Auth ID Token: ${String(err)}`);
    }
  } else if (isEmulator) {
    headers.Authorization = "Bearer emulator-token";
  }

  const response = await fetch(url, {
    method: "POST",
    headers,
    body: JSON.stringify(payload),
  });

  if (!response.ok) {
    throw new Error(`API ${functionName} failed: ${response.status} ${await response.text()}`);
  }

  return response.json();
}

export async function claimNextJob(customPattern?: string): Promise<BuildJob | null> {
  const runsOnPattern = customPattern ?? (process.platform === "linux" ? "%ubuntu%" : "%macos%");
  const response = await callApi("claim-next-job", { runsOnPattern });
  return response.job;
}

export async function createRun(buildJobId: string, runId: string): Promise<void> {
  await callApi("create-build-run", { buildJobId, id: runId });
}

export async function appendBuildLogs(input: {
  buildJobId: string;
  runId: string;
  logs: Array<{
    id: string;
    message: string;
    level: "info" | "warning" | "error";
    timestamp: string;
    stackTrace?: string;
  }>;
}): Promise<void> {
  await callApi("append-build-logs", input);
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
  await appendBuildLogs({
    buildJobId: input.buildJobId,
    runId: input.runId,
    logs: [
      {
        id: input.id,
        message: input.message,
        level: input.level,
        timestamp: input.timestamp,
        stackTrace: input.stackTrace,
      },
    ],
  });
}

export async function completeJob(id: string, status: BuildJobStatus): Promise<void> {
  await callApi("complete-build-job", { id, status });
}

export async function setJobStatus(id: string, status: BuildJobStatus): Promise<void> {
  await callApi("complete-build-job", { id, status });
}

export async function updateRunStatus(input: {
  buildJobId: string;
  runId: string;
  status: string;
  conclusion?: string | null;
}): Promise<void> {
  await callApi("update-build-run-status", input);
}

export async function updateWorkerHeartbeat(input: WorkerHeartbeatInput): Promise<void> {
  await callApi("update-worker-heartbeat", input);
}

export async function isJobCancelled(buildJobId: string): Promise<boolean> {
  const response = await callApi("is-job-cancelled", { buildJobId });
  return response.cancelled;
}

export async function getEnvironmentVariables(teamId: string): Promise<
  {
    id: string;
    key: string;
    value: string;
    autoIncrement?: boolean | null;
  }[]
> {
  const response = await callApi("get-environment-variables", { teamId });
  return response.environmentVariables;
}

export async function updateEnvironmentVariable(id: string, value: string): Promise<void> {
  await callApi("update-environment-variable", { id, value });
}

export async function getSecrets(teamId: string): Promise<
  {
    id: string;
    name: string;
    pathToSecret?: string | null;
  }[]
> {
  const response = await callApi("get-secrets", { teamId });
  return response.secrets;
}

export async function updateCheckRun(
  buildJob: BuildJob,
  runStatus: string,
  conclusion?: string | null,
): Promise<void> {
  await callApi("update-check-run", { buildJob, runStatus, conclusion });
}

export async function handleBuildJobStatusChange(
  buildJob: BuildJob,
  status: BuildJobStatus,
): Promise<void> {
  await callApi("handle-build-job-status-change", { buildJob, status });
}
