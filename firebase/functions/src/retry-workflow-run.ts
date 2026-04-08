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
  workflowsCollectionPath,
} from "./firestore-collection-paths";
import { buildDashboardRunUrl } from "./github/check-run-link";

const GITHUB_APP_ID = defineSecret("GITHUB_APP_ID");
const GITHUB_PRIVATE_KEY = defineSecret("GITHUB_PRIVATE_KEY");
const GITHUB_WEBHOOK_SECRET = defineSecret("GITHUB_WEBHOOK_SECRET");

export const retryWorkflowRun = onCall(
  {
    region: "asia-northeast1",
    secrets: [GITHUB_APP_ID, GITHUB_PRIVATE_KEY, GITHUB_WEBHOOK_SECRET],
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Unauthenticated");
    }

    const callerUid = request.auth.uid;
    const { workflowRunId } = request.data as { workflowRunId: string };

    if (!workflowRunId) {
      throw new HttpsError("invalid-argument", "Missing workflowRunId");
    }

    // Fetch all jobs in this workflow run
    const jobsSnapshot = await db
      .collection(buildJobsCollectionPath)
      .where("workflowRunId", "==", workflowRunId)
      .get();

    if (jobsSnapshot.empty) {
      throw new HttpsError("not-found", "No jobs found for this workflow run");
    }

    const originalJobs = jobsSnapshot.docs.map((doc) => doc.data());

    // Verify team membership using the first job's teamId
    const teamId = originalJobs[0].teamId;
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

    // Fetch the workflow name for check runs
    const workflowId = originalJobs[0].workflowId;
    let workflowName = "OpenCI Build";

    if (workflowId) {
      const workflowDoc = await db.collection(workflowsCollectionPath).doc(workflowId).get();
      if (workflowDoc.exists) {
        workflowName = workflowDoc.data()!.name || workflowName;
      }
    }

    // Get fresh GitHub installation token
    const installationId = originalJobs[0].installationId;
    let installationToken: string | null = null;
    let tokenExpiresAt: string | null = null;
    let octokit: any = null;

    if (installationId) {
      try {
        const app = new App({
          appId: GITHUB_APP_ID.value(),
          privateKey: GITHUB_PRIVATE_KEY.value(),
          webhooks: {
            secret: GITHUB_WEBHOOK_SECRET.value(),
          },
        });

        octokit = await app.getInstallationOctokit(installationId);
        const {
          data: { token, expires_at },
        } = await octokit.request("POST /app/installations/{installation_id}/access_tokens", {
          installation_id: installationId,
        });
        installationToken = token;
        tokenExpiresAt = expires_at;
      } catch (error) {
        logger.error("Failed to authenticate with GitHub for workflow retry", error);
        throw new HttpsError("internal", "Failed to authenticate with GitHub");
      }
    }

    // Generate new workflowRunId for the retry group
    const newWorkflowRunId = uuidv4();

    // First pass: assign new document IDs for each job (keyed by original jobKey)
    const newJobDocIds: Record<string, string> = {};
    for (const job of originalJobs) {
      const jobKey = job.jobKey;
      if (jobKey) {
        newJobDocIds[jobKey] = uuidv4();
      }
    }

    const multipleJobs = originalJobs.length > 1;
    const createdJobIds: string[] = [];

    // Second pass: create new build_jobs
    for (const originalJob of originalJobs) {
      const jobKey = originalJob.jobKey;
      const newDocumentId = jobKey ? newJobDocIds[jobKey] : uuidv4();
      const originalNeeds = originalJob.needs as string[] | null;
      const hasNeeds = originalNeeds && originalNeeds.length > 0;

      // Build new resolvedNeeds mapping
      let resolvedNeeds: Record<string, string> | null = null;
      if (hasNeeds) {
        resolvedNeeds = {};
        for (const needKey of originalNeeds!) {
          if (newJobDocIds[needKey]) {
            resolvedNeeds[needKey] = newJobDocIds[needKey];
          } else {
            logger.warn(
              `Retry: Job "${jobKey}" needs "${needKey}" which doesn't exist in workflow`,
            );
          }
        }
      }

      // Create check run for each job
      let checkRunId: number | null = null;
      if (octokit && originalJob.commitSha) {
        try {
          const checkRunName = multipleJobs
            ? `${workflowName} / ${jobKey}`
            : workflowName;
          const checkRunDetailsUrl = buildDashboardRunUrl(newDocumentId);
          const { data: checkRun } = await octokit.request(
            "POST /repos/{owner}/{repo}/check-runs",
            {
              owner: originalJob.owner,
              repo: originalJob.repo,
              name: checkRunName,
              head_sha: originalJob.commitSha,
              status: hasNeeds ? "queued" : "in_progress",
              started_at: new Date().toISOString(),
              details_url: checkRunDetailsUrl,
            },
          );
          checkRunId = checkRun.id;
        } catch (error) {
          logger.error(`Failed to create check run for retry ${jobKey}`, error);
        }
      }

      const newJobData: Record<string, any> = {
        id: newDocumentId,
        status: hasNeeds ? "waiting" : "queued",
        owner: originalJob.owner,
        repo: originalJob.repo,
        teamId: originalJob.teamId ?? null,
        workflowId: originalJob.workflowId ?? null,
        workflowFileName: originalJob.workflowFileName ?? null,
        workflowName: originalJob.workflowName ?? null,
        jobKey: jobKey ?? null,
        workflowRunId: newWorkflowRunId,
        needs: originalNeeds ?? null,
        resolvedNeeds,
        installationId: originalJob.installationId ?? null,
        commitSha: originalJob.commitSha ?? null,
        pullRequestNumber: originalJob.pullRequestNumber ?? null,
        event: originalJob.event ?? null,
        action: originalJob.action ?? null,
        sender: originalJob.sender ?? null,
        repository: originalJob.repository ?? null,
        tagName: originalJob.tagName ?? null,
        branch: originalJob.branch ?? null,
        releaseName: originalJob.releaseName ?? null,
        installationToken,
        tokenExpiresAt,
        checkRunId,
        runCount: 0,
        latestRunId: null,
        retriedFromWorkflowRunId: workflowRunId,
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      };

      await db.collection(buildJobsCollectionPath).doc(newDocumentId).set(newJobData);
      createdJobIds.push(newDocumentId);
    }

    logger.info(
      `Workflow run retried: ${workflowRunId} -> ${newWorkflowRunId} (${createdJobIds.length} jobs)`,
      {
        callerUid,
        teamId,
        owner: originalJobs[0].owner,
        repo: originalJobs[0].repo,
      },
    );

    return {
      success: true,
      newWorkflowRunId,
      newBuildJobIds: createdJobIds,
    };
  },
);
