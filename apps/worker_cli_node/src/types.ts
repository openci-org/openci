import type { BuildJobStatus } from "./build_job_services.js";

export interface BuildJob {
  id: string;
  status: BuildJobStatus;
  owner: string;
  repo: string;
  teamId?: string | null;
  workflowFileName?: string | null;
  workflowName?: string | null;
  jobKey?: string | null;
  workflowJobKey?: string | null;
  matrix?: Record<string, string | number | boolean> | null;
  matrixLabel?: string | null;
  matrixIndex?: number | null;
  matrixGroupKey?: string | null;
  matrixFailFast?: boolean | null;
  workflowRunId?: string | null;
  needs?: string[] | null;
  resolvedNeeds?: unknown | null;
  installationId?: string | number | null;
  installationToken?: string | null;
  tokenExpiresAt?: string | null;
  checkRunId?: string | number | null;
  commitSha?: string | null;
  pullRequestNumber?: number | null;
  tagName?: string | null;
  branch?: string | null;
  runsOn?: string | null;
  githubApiBaseUrl?: string | null;
  githubBaseUrl?: string | null;
  runCount?: number | null;
  latestRunId?: string | null;
  createdAt?: string | null;
  updatedAt?: string | null;
  completedAt?: string | null;
}

export interface WorkerConfig {
  serviceAccountPath: string;
  workerId: string;
  projectId: string;
  pollIntervalMs: number;
  once: boolean;
  runsOnPattern?: string;
  projectNumber?: string;
}

export type WorkerStatus = "starting" | "idle" | "busy" | "error" | "stopping";

export interface WorkerHeartbeatInput {
  workerId: string;
  version: string;
  platform: NodeJS.Platform;
  hostname: string;
  pid: number;
  status: WorkerStatus;
  currentBuildJobId?: string | null;
  currentRunId?: string | null;
  consecutiveFailures?: number;
  lastError?: string | null;
}
