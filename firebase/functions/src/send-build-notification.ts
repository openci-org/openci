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

export const onBuildJobStatusChange = onDocumentUpdated(
  {
    document: `${buildJobsCollectionPath}/{buildJobId}`,
    region: "asia-northeast1",
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

    // Only send notifications when status changes to success or failure
    if (previousStatus === currentStatus) return;
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
    const createdAt = afterData.createdAt as string | undefined;
    const completedAt = afterData.completedAt as string | undefined;
    let durationText = "";
    if (createdAt && completedAt) {
      const startTime = new Date(createdAt).getTime();
      const endTime = new Date(completedAt).getTime();
      const durationMs = endTime - startTime;
      if (durationMs > 0) {
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
    const repoInfo = `${owner}/${repo}${branch ? ` (${branch})` : ""}`;
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
