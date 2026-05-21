import { randomUUID } from "node:crypto";

import { logger } from "firebase-functions/v2";
import { HttpsError, onCall } from "firebase-functions/v2/https";

import { BuildJobStatus, createBuildJob } from "../../firestoreData.js";
import { createCheckRun, getInstallationToken } from "../../github/githubApp.js";
import { buildDashboardRunUrl } from "../../github/githubUrls.js";
import { verifyTeamMembership } from "../../team/teamAuth.js";
import {
  type RetryBuildJobRequest,
  checkRunNameForJob,
  copyRetryJobFields,
  getBuildJobData,
  isInstallationTokenValid,
  numberFromInt64Value,
  requireNonEmptyString,
  stringFromUnknown,
} from "./retryBuildJobHelpers.js";

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
