import { FieldValue } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/https";
import * as logger from "firebase-functions/logger";
import { defineSecret } from "firebase-functions/params";
import { App } from "octokit";
import { v4 as uuidv4 } from "uuid";

import { db } from "./firebase";
import {
  buildJobsCollectionPath,
  teamsCollectionPath,
} from "./firestore-collection-paths";
import { buildDashboardRunUrl } from "./github/check-run-link";

const GITHUB_APP_ID = defineSecret("GITHUB_APP_ID");
const GITHUB_PRIVATE_KEY = defineSecret("GITHUB_PRIVATE_KEY");
const GITHUB_WEBHOOK_SECRET = defineSecret("GITHUB_WEBHOOK_SECRET");

export const retryBuildJob = onCall(
  {
    region: "asia-northeast1",
    secrets: [GITHUB_APP_ID, GITHUB_PRIVATE_KEY, GITHUB_WEBHOOK_SECRET],
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Unauthenticated");
    }

    const callerUid = request.auth.uid;
    const { buildJobId } = request.data as { buildJobId: string };

    if (!buildJobId) {
      throw new HttpsError("invalid-argument", "Missing buildJobId");
    }

    // Fetch the original build job
    const originalJobRef = db.collection(buildJobsCollectionPath).doc(buildJobId);
    const originalJobDoc = await originalJobRef.get();

    if (!originalJobDoc.exists) {
      throw new HttpsError("not-found", "Build job not found");
    }

    const originalJob = originalJobDoc.data()!;

    // Verify team membership
    const teamId = originalJob.teamId;
    if (teamId) {
      const teamRef = db.collection(teamsCollectionPath).doc(teamId);
      const teamDoc = await teamRef.get();

      if (!teamDoc.exists) {
        throw new HttpsError("not-found", "Team not found");
      }

      const teamData = teamDoc.data()!;
      const members: string[] = teamData.members || [];

      if (!members.includes(callerUid)) {
        throw new HttpsError("permission-denied", "You are not a member of this team");
      }
    }



    // Prepare the retried build ID early so GitHub check-runs can point to it.
    const newDocumentId = uuidv4();
    const checkRunDetailsUrl = buildDashboardRunUrl(newDocumentId);

    // Get fresh GitHub installation token
    const installationId = originalJob.installationId;
    let installationToken: string | null = null;
    let tokenExpiresAt: string | null = null;
    let checkRunId: number | null = originalJob.checkRunId ?? null;

    if (installationId) {
      try {
        const app = new App({
          appId: GITHUB_APP_ID.value(),
          privateKey: GITHUB_PRIVATE_KEY.value(),
          webhooks: {
            secret: GITHUB_WEBHOOK_SECRET.value(),
          },
        });

        const octokit = await app.getInstallationOctokit(installationId);
        const {
          data: { token, expires_at },
        } = await octokit.request("POST /app/installations/{installation_id}/access_tokens", {
          installation_id: installationId,
        });
        installationToken = token;
        tokenExpiresAt = expires_at;

        if (originalJob.commitSha) {
          // GitHub API does not support reverting a completed check run back to
          // in_progress (PATCH returns 200 but silently ignores the status change).
          // We create a new check run with the same name so GitHub supersedes the
          // old one in merge-protection status.
          const checkRunName = originalJob.workflowName;
          if (!checkRunName) {
            throw new Error(`workflowName is missing on job ${buildJobId}`);
          }
          checkRunId = null;
          try {
            const { data: checkRun } = await octokit.request(
              "POST /repos/{owner}/{repo}/check-runs",
              {
                owner: originalJob.owner,
                repo: originalJob.repo,
                name: checkRunName,
                head_sha: originalJob.commitSha,
                status: "in_progress",
                started_at: new Date().toISOString(),
                details_url: checkRunDetailsUrl,
              },
            );
            checkRunId = checkRun.id;
            logger.info(`Created new check run ${checkRunId} for retry`);
          } catch (error) {
            logger.error("Failed to create check run for retry", error);
          }
        }
      } catch (error) {
        logger.error("Failed to authenticate with GitHub for retry", error);
        throw new HttpsError("internal", "Failed to authenticate with GitHub");
      }
    }

    const newJobData: Record<string, any> = {
      id: newDocumentId,
      status: "queued",
      owner: originalJob.owner,
      repo: originalJob.repo,
      teamId: originalJob.teamId ?? null,
      workflowId: originalJob.workflowId ?? null,
      workflowFileName: originalJob.workflowFileName ?? null,
      workflowName: originalJob.workflowName ?? null,
      jobKey: originalJob.jobKey ?? null,
      workflowRunId: null,
      needs: null,
      resolvedNeeds: null,
      installationId: originalJob.installationId ?? null,
      commitSha: originalJob.commitSha ?? null,
      pullRequestNumber: originalJob.pullRequestNumber ?? null,
      event: originalJob.event ?? null,
      action: originalJob.action ?? null,
      sender: originalJob.sender ?? null,
      repository: originalJob.repository ?? null,
      tagName: originalJob.tagName ?? null,
      installationToken,
      tokenExpiresAt,
      checkRunId,
      runCount: 0,
      latestRunId: null,
      retriedFromBuildJobId: buildJobId,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    };

    await db.collection(buildJobsCollectionPath).doc(newDocumentId).set(newJobData);


    logger.info(`Build job retried: ${buildJobId} -> ${newDocumentId}`, {
      callerUid,
      teamId,
      owner: originalJob.owner,
      repo: originalJob.repo,
    });

    return { success: true, newBuildJobId: newDocumentId };
  },
);
