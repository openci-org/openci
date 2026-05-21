import { HttpsError } from "firebase-functions/v2/https";

import { getBuildJob as getBuildJobOperation } from "../../firestoreData.js";

export interface RetryBuildJobRequest {
  buildJobId: string;
}

export interface RetryWorkflowRunRequest {
  workflowRunId: string;
  workflowFileName?: string;
}

export function requireNonEmptyString(value: unknown, field: string): string {
  if (typeof value !== "string" || value.length === 0) {
    throw new HttpsError("invalid-argument", `${field} is required`);
  }
  return value;
}

export async function getBuildJobData(buildJobId: string): Promise<Record<string, unknown>> {
  const result = await getBuildJobOperation({ id: buildJobId });
  if (!result.data.buildJob) {
    throw new HttpsError("not-found", "Build job not found");
  }
  return result.data.buildJob as unknown as Record<string, unknown>;
}

function firestoreSafeValue(value: unknown): unknown {
  if (value === undefined) return null;
  if (Array.isArray(value)) return value.map(firestoreSafeValue);
  if (value === null || typeof value !== "object") return value;
  const prototype = Object.getPrototypeOf(value);
  if (prototype !== Object.prototype && prototype !== null) return value;
  return Object.fromEntries(
    Object.entries(value as Record<string, unknown>).map(([key, entry]) => [
      key,
      firestoreSafeValue(entry),
    ]),
  );
}

function firestoreSafeDocument(data: Record<string, unknown>): Record<string, unknown> {
  return Object.fromEntries(
    Object.entries(data).map(([key, value]) => [key, firestoreSafeValue(value)]),
  );
}

export function copyRetryJobFields(
  originalJob: FirebaseFirestore.DocumentData,
  overrides: Record<string, unknown>,
): Record<string, unknown> {
  return firestoreSafeDocument({
    owner: originalJob.owner,
    repo: originalJob.repo,
    teamId: originalJob.teamId,
    workflowId: originalJob.workflowId,
    workflowFileName: originalJob.workflowFileName,
    workflowName: originalJob.workflowName,
    jobKey: originalJob.jobKey,
    workflowJobKey: originalJob.workflowJobKey,
    matrix: originalJob.matrix,
    matrixLabel: originalJob.matrixLabel,
    matrixIndex: originalJob.matrixIndex,
    matrixGroupKey: originalJob.matrixGroupKey,
    matrixFailFast: originalJob.matrixFailFast,
    installationId: originalJob.installationId,
    installationToken: originalJob.installationToken,
    tokenExpiresAt: originalJob.tokenExpiresAt,
    commitSha: originalJob.commitSha,
    pullRequestNumber: originalJob.pullRequestNumber,
    event: originalJob.event,
    action: originalJob.action,
    sender: originalJob.sender,
    repository: originalJob.repository,
    tagName: originalJob.tagName,
    branch: originalJob.branch,
    releaseName: originalJob.releaseName,
    runsOn: originalJob.runsOn,
    githubApiBaseUrl: originalJob.githubApiBaseUrl,
    githubBaseUrl: originalJob.githubBaseUrl,
    ...overrides,
  });
}

export function numberFromInt64Value(value: unknown): number | undefined {
  if (typeof value === "number") return value;
  if (typeof value === "string" && value.length > 0) {
    const parsed = Number(value);
    return Number.isFinite(parsed) ? parsed : undefined;
  }
  return undefined;
}

export function stringFromUnknown(value: unknown): string | undefined {
  return typeof value === "string" && value.length > 0 ? value : undefined;
}

export function checkRunNameForJob(job: FirebaseFirestore.DocumentData): string {
  const workflowName = requireNonEmptyString(job.workflowName, "workflowName");
  const workflowJobKey = stringFromUnknown(job.workflowJobKey);
  const jobKey = stringFromUnknown(job.jobKey);
  const matrixLabel = stringFromUnknown(job.matrixLabel);
  if (!workflowJobKey && !jobKey) return workflowName;
  const suffix = matrixLabel ? ` (${matrixLabel})` : "";
  return `${workflowName} / ${workflowJobKey ?? jobKey}${suffix}`;
}

export function isInstallationTokenValid(expiresAt: unknown): boolean {
  if (typeof expiresAt !== "string" || expiresAt.length === 0) return false;
  const expiresAtMs = Date.parse(expiresAt);
  if (!Number.isFinite(expiresAtMs)) return false;
  return expiresAtMs > Date.now() + 5 * 60 * 1000;
}
