import { randomUUID } from "node:crypto";

import { logger } from "firebase-functions/v2";
import { HttpsError, onCall } from "firebase-functions/v2/https";

import { createCheckRun, getInstallationToken } from "../github/githubApp.js";
import { buildDashboardRunUrl } from "../github/githubUrls.js";
import {
  BuildJobStatus,
  createBuildJob,
  getBuildJob as getBuildJobOperation,
  listBuildJobsByWorkflowRun,
} from "../firestoreData.js";
import { verifyTeamMembership } from "../team/teamAuth.js";

interface RetryBuildJobRequest {
  buildJobId: string;
}

interface RetryWorkflowRunRequest {
  workflowRunId: string;
  workflowFileName?: string;
}

function requireNonEmptyString(value: unknown, field: string): string {
  if (typeof value !== "string" || value.length === 0) {
    throw new HttpsError("invalid-argument", `${field} is required`);
  }
  return value;
}

async function getBuildJobData(buildJobId: string): Promise<Record<string, unknown>> {
  const result = await getBuildJobOperation({ id: buildJobId });
  if (!result.data.buildJob) {
    throw new HttpsError("not-found", "Build job not found");
  }
  return result.data.buildJob as unknown as Record<string, unknown>;
}

function copyRetryJobFields(
  originalJob: FirebaseFirestore.DocumentData,
  overrides: Record<string, unknown>,
): Record<string, unknown> {
  return {
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
  };
}

function numberFromInt64Value(value: unknown): number | undefined {
  if (typeof value === "number") return value;
  if (typeof value === "string" && value.length > 0) {
    const parsed = Number(value);
    return Number.isFinite(parsed) ? parsed : undefined;
  }
  return undefined;
}

function stringFromUnknown(value: unknown): string | undefined {
  return typeof value === "string" && value.length > 0 ? value : undefined;
}

function checkRunNameForJob(job: FirebaseFirestore.DocumentData): string {
  const workflowName = requireNonEmptyString(job.workflowName, "workflowName");
  const workflowJobKey = stringFromUnknown(job.workflowJobKey);
  const jobKey = stringFromUnknown(job.jobKey);
  const matrixLabel = stringFromUnknown(job.matrixLabel);
  if (!workflowJobKey && !jobKey) return workflowName;
  const suffix = matrixLabel ? ` (${matrixLabel})` : "";
  return `${workflowName} / ${workflowJobKey ?? jobKey}${suffix}`;
}

function isInstallationTokenValid(expiresAt: unknown): boolean {
  if (typeof expiresAt !== "string" || expiresAt.length === 0) return false;
  const expiresAtMs = Date.parse(expiresAt);
  if (!Number.isFinite(expiresAtMs)) return false;
  return expiresAtMs > Date.now() + 5 * 60 * 1000;
}

export const retryBuildJob = onCall<
  RetryBuildJobRequest,
  Promise<{ success: true; newBuildJobId: string }>
>(async (request) => {
  const auth = request.auth;
  if (!auth) {
    throw new HttpsError("unauthenticated", "Unauthenticated");
  }

  const buildJobId = requireNonEmptyString(request.data?.buildJobId, "buildJobId");
  const originalJob = await getBuildJobData(buildJobId);
  const teamId = typeof originalJob.teamId === "string" ? originalJob.teamId : undefined;
  if (teamId) {
    await verifyTeamMembership(auth, teamId);
  }

  const newDocumentId = randomUUID();
  const installationId = numberFromInt64Value(originalJob.installationId);
  const apiBaseUrl = stringFromUnknown(originalJob.githubApiBaseUrl);
  let installationToken = stringFromUnknown(originalJob.installationToken);
  let tokenExpiresAt = stringFromUnknown(originalJob.tokenExpiresAt);
  let checkRunId = numberFromInt64Value(originalJob.checkRunId);

  if (
    installationId !== undefined &&
    (!installationToken || !isInstallationTokenValid(tokenExpiresAt))
  ) {
    try {
      const tokenData = await getInstallationToken(installationId, { apiBaseUrl });
      installationToken = tokenData.token;
      tokenExpiresAt = tokenData.expiresAt;
    } catch (error) {
      logger.error("Failed to authenticate with GitHub for retry", { buildJobId, error });
      throw new HttpsError("internal", "Failed to authenticate with GitHub");
    }
  }
  if (installationToken && typeof originalJob.commitSha === "string") {
    checkRunId =
      (await createCheckRun({
        token: installationToken,
        owner: requireNonEmptyString(originalJob.owner, "owner"),
        repo: requireNonEmptyString(originalJob.repo, "repo"),
        name: checkRunNameForJob(originalJob),
        headSha: originalJob.commitSha,
        status: "in_progress",
        detailsUrl: buildDashboardRunUrl(newDocumentId),
        apiBaseUrl,
      })) ?? undefined;
  }

  await createBuildJob(
    copyRetryJobFields(originalJob, {
      id: newDocumentId,
      status: BuildJobStatus.QUEUED,
      workflowRunId: null,
      needs: null,
      resolvedNeeds: null,
      installationToken,
      tokenExpiresAt,
      checkRunId,
      runCount: 0,
      latestRunId: null,
      retriedFromBuildJobId: buildJobId,
    }) as never,
  );

  logger.info("Build job retried", { buildJobId, newDocumentId, callerUid: auth.uid, teamId });
  return { success: true, newBuildJobId: newDocumentId };
});

export const retryWorkflowRun = onCall<
  RetryWorkflowRunRequest,
  Promise<{ success: true; newWorkflowRunId: string; newBuildJobIds: string[] }>
>(async (request) => {
  const auth = request.auth;
  if (!auth) {
    throw new HttpsError("unauthenticated", "Unauthenticated");
  }

  const workflowRunId = requireNonEmptyString(request.data?.workflowRunId, "workflowRunId");
  const workflowFileName = stringFromUnknown(request.data?.workflowFileName);
  const jobsResult = await listBuildJobsByWorkflowRun({ workflowRunId });
  const workflowRunJobs = jobsResult.data.buildJobs as FirebaseFirestore.DocumentData[];
  const originalJobs = workflowFileName
    ? workflowRunJobs.filter((job) => job.workflowFileName === workflowFileName)
    : workflowRunJobs;

  if (originalJobs.length === 0) {
    throw new HttpsError("not-found", "No jobs found for this workflow run");
  }

  const teamId = typeof originalJobs[0]?.teamId === "string" ? originalJobs[0].teamId : undefined;
  if (teamId) {
    await verifyTeamMembership(auth, teamId);
  }

  const installationId = numberFromInt64Value(originalJobs[0]?.installationId);
  const apiBaseUrl = stringFromUnknown(originalJobs[0]?.githubApiBaseUrl);
  let installationToken = stringFromUnknown(originalJobs[0]?.installationToken);
  let tokenExpiresAt = stringFromUnknown(originalJobs[0]?.tokenExpiresAt);
  if (
    installationId !== undefined &&
    (!installationToken || !isInstallationTokenValid(tokenExpiresAt))
  ) {
    try {
      const tokenData = await getInstallationToken(installationId, { apiBaseUrl });
      installationToken = tokenData.token;
      tokenExpiresAt = tokenData.expiresAt;
    } catch (error) {
      logger.error("Failed to authenticate with GitHub for workflow retry", {
        workflowRunId,
        error,
      });
      throw new HttpsError("internal", "Failed to authenticate with GitHub");
    }
  }

  const newWorkflowRunId = randomUUID();
  const newJobDocIds = new Map<string, string>();
  for (const job of originalJobs) {
    if (typeof job.jobKey === "string") {
      newJobDocIds.set(job.jobKey, randomUUID());
    }
  }

  const createdJobIds: string[] = [];

  for (const originalJob of originalJobs) {
    const jobKey = typeof originalJob.jobKey === "string" ? originalJob.jobKey : undefined;
    const newDocumentId = jobKey ? newJobDocIds.get(jobKey)! : randomUUID();
    const originalNeeds = Array.isArray(originalJob.needs)
      ? originalJob.needs.filter((need: unknown): need is string => typeof need === "string")
      : undefined;
    const hasNeeds = Boolean(originalNeeds?.length);
    const resolvedNeeds: Record<string, string> | undefined = hasNeeds ? {} : undefined;
    for (const needKey of originalNeeds ?? []) {
      const newNeedId = newJobDocIds.get(needKey);
      if (newNeedId && resolvedNeeds) {
        resolvedNeeds[needKey] = newNeedId;
      }
    }

    let checkRunId: number | undefined;
    if (installationToken && typeof originalJob.commitSha === "string") {
      const workflowName =
        typeof originalJob.workflowName === "string" ? originalJob.workflowName : undefined;
      if (workflowName) {
        const checkRunName =
          originalJobs.length > 1 ? checkRunNameForJob(originalJob) : workflowName;
        checkRunId =
          (await createCheckRun({
            token: installationToken,
            owner: requireNonEmptyString(originalJob.owner, "owner"),
            repo: requireNonEmptyString(originalJob.repo, "repo"),
            name: checkRunName,
            headSha: originalJob.commitSha,
            status: hasNeeds ? "queued" : "in_progress",
            detailsUrl: buildDashboardRunUrl(newDocumentId),
            apiBaseUrl,
          })) ?? undefined;
      }
    }

    await createBuildJob(
      copyRetryJobFields(originalJob, {
        id: newDocumentId,
        status: hasNeeds ? BuildJobStatus.WAITING : BuildJobStatus.QUEUED,
        workflowRunId: newWorkflowRunId,
        needs: originalNeeds,
        resolvedNeeds,
        installationToken,
        tokenExpiresAt,
        checkRunId,
        runCount: 0,
        latestRunId: null,
        retriedFromWorkflowRunId: workflowRunId,
      }) as never,
    );
    createdJobIds.push(newDocumentId);
  }

  logger.info("Workflow run retried", {
    workflowRunId,
    workflowFileName,
    newWorkflowRunId,
    count: createdJobIds.length,
  });
  return { success: true, newWorkflowRunId, newBuildJobIds: createdJobIds };
});
