import { FieldValue } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";
import * as logger from "firebase-functions/logger";
import { onDocumentUpdated } from "firebase-functions/v2/firestore";

import { db } from "./firebase";
import {
  buildJobsCollectionPath,
  teamsCollectionPath,
  usersCollectionPath,
  workflowsCollectionPath,
} from "./firestore-collection-paths";
import { generateFailureSummary, getGeminiSecrets } from "./generate-failure-summary";

export const onBuildJobStatusChange = onDocumentUpdated(
  {
    document: `${buildJobsCollectionPath}/{buildJobId}`,
    region: "asia-northeast1",
    secrets: [...getGeminiSecrets()],
  },
  async (event) => {
    const beforeData = event.data?.before.data();
    const afterData = event.data?.after.data();

    if (!beforeData || !afterData) {
      logger.warn("Missing data in build job update event");
      return;
    }

    const previousStatus = beforeData.status as string;
    const currentStatus = afterData.status as string;

    // Only process when status actually changes
    if (previousStatus === currentStatus) return;

    // Resolve job dependencies for any terminal status
    const terminalStatuses = ["success", "failure", "cancelled", "timed_out", "skipped"];
    if (terminalStatuses.includes(currentStatus)) {
      await resolveDependencies(afterData, currentStatus);
    }

    // Generate AI failure summary (fire-and-forget, runs in parallel with notifications)
    if (currentStatus === "failure") {
      const latestRunId = afterData.latestRunId as string | undefined;
      if (latestRunId) {
        // Check if the team has AI features enabled
        const teamId = afterData.teamId as string | undefined;
        let aiEnabled = true;
        if (teamId) {
          const teamDoc = await db.collection(teamsCollectionPath).doc(teamId).get();
          if (teamDoc.exists) {
            aiEnabled = teamDoc.data()?.aiEnabled !== false;
          }
        }

        if (aiEnabled) {
          generateFailureSummary(event.data!.after.id, latestRunId).catch((err) =>
            logger.error("Background failure summary generation failed:", err),
          );
        } else {
          logger.info(`AI features disabled for team ${teamId}, skipping failure summary`);
        }
      }
    }

    // Only send notifications when status changes to success or failure
    if (currentStatus !== "success" && currentStatus !== "failure") return;

    const teamId = afterData.teamId as string | undefined;
    if (!teamId) {
      logger.warn("No teamId found in build job");
      return;
    }

    // Get team members
    const teamDoc = await db.collection(teamsCollectionPath).doc(teamId).get();
    if (!teamDoc.exists) {
      logger.warn(`Team ${teamId} not found`);
      return;
    }

    const teamData = teamDoc.data();
    const members = teamData?.members as string[] | undefined;
    if (!members || members.length === 0) {
      logger.info("No team members to notify");
      return;
    }

    const owner = afterData.owner as string;
    const repo = afterData.repo as string;
    const branch = afterData.branch as string | undefined;
    const workflowId = afterData.workflowId as string | undefined;

    // Get workflow name from the build job document first, fallback to workflows collection
    let workflowName = afterData.workflowName as string | undefined;
    if (!workflowName && workflowId) {
      const workflowDoc = await db.collection(workflowsCollectionPath).doc(workflowId).get();
      if (workflowDoc.exists) {
        workflowName = workflowDoc.data()?.name as string | undefined;
      }
    }

    // Calculate build duration
    // createdAt may be a Firestore Timestamp (from FieldValue.serverTimestamp())
    // or an ISO string. completedAt is always an ISO string from the worker.
    const createdAtRaw = afterData.createdAt;
    const completedAtRaw = afterData.completedAt;
    let durationText = "";
    if (createdAtRaw && completedAtRaw) {
      let startTime: number;
      if (typeof createdAtRaw === "string") {
        startTime = new Date(createdAtRaw).getTime();
      } else if (createdAtRaw._seconds !== undefined) {
        startTime = createdAtRaw._seconds * 1000;
      } else if (createdAtRaw.toDate) {
        startTime = createdAtRaw.toDate().getTime();
      } else {
        startTime = NaN;
      }

      let endTime: number;
      if (typeof completedAtRaw === "string") {
        endTime = new Date(completedAtRaw).getTime();
      } else if (completedAtRaw._seconds !== undefined) {
        endTime = completedAtRaw._seconds * 1000;
      } else if (completedAtRaw.toDate) {
        endTime = completedAtRaw.toDate().getTime();
      } else {
        endTime = NaN;
      }

      const durationMs = endTime - startTime;
      if (!isNaN(durationMs) && durationMs > 0) {
        const totalSeconds = Math.floor(durationMs / 1000);
        const minutes = Math.floor(totalSeconds / 60);
        const seconds = totalSeconds % 60;
        if (minutes > 0) {
          durationText = `${minutes}m ${seconds}s`;
        } else {
          durationText = `${seconds}s`;
        }
      }
    }

    const isSuccess = currentStatus === "success";
    const title = isSuccess ? "✅ Build Succeeded" : "❌ Build Failed";

    // Build body lines
    const bodyLines: string[] = [];

    // Line 1: workflow name (if available)
    if (workflowName) {
      bodyLines.push(workflowName);
    }

    // Line 2: repo and branch
    const repoInfo = `${repo}${branch ? ` (${branch})` : ""}`;
    bodyLines.push(repoInfo);

    // Line 3: duration (if available)
    if (durationText) {
      bodyLines.push(`⏱ ${durationText}`);
    }

    // For failures, add error message
    if (!isSuccess) {
      const latestRunId = afterData.latestRunId as string | undefined;
      if (latestRunId) {
        const logsSnapshot = await db
          .collection(buildJobsCollectionPath)
          .doc(event.data!.after.id)
          .collection("runs")
          .doc(latestRunId)
          .collection("logs")
          .orderBy("timestamp", "desc")
          .limit(2)
          .get();

        if (logsSnapshot.docs.length >= 2) {
          const failureLog = logsSnapshot.docs[1].data();
          bodyLines.push(failureLog.message ?? "Unknown error");
        } else {
          bodyLines.push("Unknown error");
        }
      }
    }

    const body = bodyLines.join("\n");

    const tokensToNotify: string[] = [];

    for (const memberId of members) {
      const userDoc = await db.collection(usersCollectionPath).doc(memberId).get();
      if (!userDoc.exists) continue;

      const userData = userDoc.data();
      const preference = (userData?.notificationPreference as string) ?? "all";
      const fcmTokens = (userData?.fcmTokens as string[]) ?? [];

      if (fcmTokens.length === 0) continue;

      // Check notification preference
      if (preference === "none") continue;
      if (preference === "successOnly" && !isSuccess) continue;
      if (preference === "failureOnly" && isSuccess) continue;
      // "all" sends for both

      tokensToNotify.push(...fcmTokens);
    }

    if (tokensToNotify.length === 0) {
      logger.info("No tokens to send notifications to");
      return;
    }

    // Send notifications
    const messaging = getMessaging();

    try {
      const response = await messaging.sendEachForMulticast({
        tokens: tokensToNotify,
        notification: {
          title,
          body,
        },
        data: {
          buildJobId: event.data?.after.id ?? "",
          status: currentStatus,
          owner,
          repo,
          ...(branch ? { branch } : {}),
          ...(workflowName ? { workflowName } : {}),
          ...(durationText ? { duration: durationText } : {}),
        },
        apns: {
          payload: {
            aps: {
              sound: "default",
              badge: 1,
            },
          },
        },
      });

      logger.info(
        `Notifications sent: ${response.successCount} success, ${response.failureCount} failure`,
      );

      // Clean up invalid tokens
      const invalidTokens: string[] = [];
      response.responses.forEach((resp, idx) => {
        if (resp.error) {
          const errorCode = resp.error.code;
          if (
            errorCode === "messaging/invalid-registration-token" ||
            errorCode === "messaging/registration-token-not-registered"
          ) {
            invalidTokens.push(tokensToNotify[idx]);
          }
        }
      });

      if (invalidTokens.length > 0) {
        logger.info(`Removing ${invalidTokens.length} invalid FCM tokens`);
        for (const memberId of members) {
          const userDoc = await db.collection(usersCollectionPath).doc(memberId).get();
          if (!userDoc.exists) continue;

          const userData = userDoc.data();
          const userTokens = (userData?.fcmTokens as string[]) ?? [];
          const validTokens = userTokens.filter((t) => !invalidTokens.includes(t));

          if (validTokens.length !== userTokens.length) {
            await db
              .collection(usersCollectionPath)
              .doc(memberId)
              .update({ fcmTokens: validTokens });
          }
        }
      }
    } catch (error) {
      logger.error("Error sending notifications:", error);
    }
  },
);

async function resolveDependencies(completedJobData: any, completedStatus: string) {
  const workflowRunId = completedJobData.workflowRunId as string | undefined;
  const jobKey = completedJobData.jobKey as string | undefined;

  if (!workflowRunId || !jobKey) return;

  const waitingJobs = await db
    .collection(buildJobsCollectionPath)
    .where("workflowRunId", "==", workflowRunId)
    .where("status", "==", "waiting")
    .get();

  if (waitingJobs.empty) return;

  const isSuccess = completedStatus === "success";

  for (const doc of waitingJobs.docs) {
    const jobData = doc.data();
    const needs = jobData.needs as string[] | undefined;
    if (!needs || !needs.includes(jobKey)) continue;

    if (!isSuccess) {
      // Dependency failed/cancelled/timed_out/skipped → skip this job
      await doc.ref.update({
        status: "skipped",
        updatedAt: FieldValue.serverTimestamp(),
      });
      logger.info(`Skipped job ${jobData.jobKey} because dependency ${jobKey} ${completedStatus}`);
      continue;
    }

    // Dependency succeeded, check if ALL dependencies are now satisfied
    const resolvedNeeds = jobData.resolvedNeeds as Record<string, string> | undefined;
    if (!resolvedNeeds) continue;

    let allSatisfied = true;
    for (const [, needBuildJobId] of Object.entries(resolvedNeeds)) {
      const needDoc = await db.collection(buildJobsCollectionPath).doc(needBuildJobId).get();
      if (!needDoc.exists || needDoc.data()?.status !== "success") {
        allSatisfied = false;
        break;
      }
    }

    if (allSatisfied) {
      await doc.ref.update({
        status: "queued",
        updatedAt: FieldValue.serverTimestamp(),
      });
      logger.info(`Queued job ${jobData.jobKey} - all dependencies satisfied`);
    }
  }
}
