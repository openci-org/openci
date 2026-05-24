import { randomUUID } from "node:crypto";

import { logger } from "firebase-functions/v2";
import { HttpsError, onCall } from "firebase-functions/v2/https";

import { BuildJobStatus, createBuildJob, listBuildJobsByWorkflowRun } from "../../firestoreData.js";
import { createCheckRun, getInstallationToken } from "../../github/githubApp.js";
import { buildDashboardRunUrl } from "../../github/githubUrls.js";
import { verifyTeamMembership } from "../../team/teamAuth.js";
import {
  type RetryWorkflowRunRequest,
  checkRunNameForJob,
  copyRetryJobFields,
  isInstallationTokenValid,
  numberFromInt64Value,
  requireNonEmptyString,
  stringFromUnknown,
} from "../retryBuildJob/retryBuildJobHelpers.js";

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

  const teamId =
    typeof originalJobs[0]?.teamId === "string" && originalJobs[0].teamId.length > 0
      ? originalJobs[0].teamId
      : undefined;
  if (!teamId) {
    throw new HttpsError("failed-precondition", "Workflow run is not associated with a team");
  }
  await verifyTeamMembership(auth, teamId);

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
