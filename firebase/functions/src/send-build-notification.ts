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

    const owner = afterData.owner as string;
    const repo = afterData.repo as string;
    const branch = afterData.branch as string | undefined;
    const workflowId = afterData.workflowId as string | undefined;

    const teamRef = db.collection(teamsCollectionPath).doc(teamId);
    const workflowRef = workflowId ? db.collection(workflowsCollectionPath).doc(workflowId) : null;

    const [teamDoc, workflowDoc] = await Promise.all([
      teamRef.get(),
      workflowRef ? workflowRef.get() : Promise.resolve(null),
    ]);

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

    let workflowName: string | undefined;
    if (workflowDoc?.exists) {
      workflowName = workflowDoc.data()?.name as string | undefined;
    }

    const isSuccess = currentStatus === "success";
    const title = isSuccess ? "✅ Build Succeeded" : "❌ Build Failed";
    const displayName = workflowName ?? `${owner}/${repo}`;
    const bodyHeader = `${displayName}${branch ? ` (${branch})` : ""}`;

    let body = bodyHeader;
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
          body = `${bodyHeader}\n${failureLog.message ?? "Unknown error"}`;
        } else {
          body = `${bodyHeader}\nUnknown error`;
        }
      }
    }

    const memberRefs = members.map((memberId) => db.collection(usersCollectionPath).doc(memberId));
    const memberDocs = await db.getAll(...memberRefs);

    const tokensToNotify: string[] = [];

    for (const userDoc of memberDocs) {
      if (!userDoc.exists) continue;

      const userData = userDoc.data();
      const preference = (userData?.notificationPreference as string) ?? "all";
      const fcmTokens = (userData?.fcmTokens as string[]) ?? [];

      if (fcmTokens.length === 0) continue;

      if (preference === "none") continue;
      if (preference === "successOnly" && !isSuccess) continue;
      if (preference === "failureOnly" && isSuccess) continue;

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
        const refreshedMemberDocs = await db.getAll(...memberRefs);
        const batch = db.batch();
        let batchCount = 0;

        for (const userDoc of refreshedMemberDocs) {
          if (!userDoc.exists) continue;

          const userData = userDoc.data();
          const userTokens = (userData?.fcmTokens as string[]) ?? [];
          const validTokens = userTokens.filter((t) => !invalidTokens.includes(t));

          if (validTokens.length !== userTokens.length) {
            batch.update(userDoc.ref, { fcmTokens: validTokens });
            batchCount++;
          }
        }

        if (batchCount > 0) {
          await batch.commit();
        }
      }
    } catch (error) {
      logger.error("Error sending notifications:", error);
    }
  },
);
