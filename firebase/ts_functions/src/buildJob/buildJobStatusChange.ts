import { getMessaging } from "firebase-admin/messaging";
import { logger } from "firebase-functions/v2";
import { HttpsError, onCall } from "firebase-functions/v2/https";

import {
  getBuildJob,
  listLatestBuildLogs,
  listTeamNotificationUsers,
  listWaitingBuildJobs,
  updateBuildJobStatus,
  updateUserFcmTokens,
} from "@openci/dataconnect-admin";

interface BuildJobStatusChangeRequest {
  buildJobId: string;
  status: string;
}

function requireNonEmptyString(value: unknown, field: string): string {
  if (typeof value !== "string" || value.length === 0) {
    throw new HttpsError("invalid-argument", `${field} is required`);
  }
  return value;
}

async function resolveDependencies(
  completedJobData: FirebaseFirestore.DocumentData,
  completedStatus: string,
): Promise<void> {
  const workflowRunId = completedJobData.workflowRunId;
  const jobKey = completedJobData.jobKey;
  if (typeof workflowRunId !== "string" || typeof jobKey !== "string") return;

  const waitingJobs = await listWaitingBuildJobs({ workflowRunId });

  const isSuccess = completedStatus === "success";

  for (const jobData of waitingJobs.data.buildJobs) {
    const needs = Array.isArray(jobData.needs)
      ? jobData.needs.filter((need): need is string => typeof need === "string")
      : [];
    if (!needs.includes(jobKey)) continue;

    if (!isSuccess) {
      await updateBuildJobStatus({ id: jobData.id, status: "skipped" });
      await resolveDependencies(jobData, "skipped");
      continue;
    }

    const resolvedNeeds =
      typeof jobData.resolvedNeeds === "object" && jobData.resolvedNeeds !== null
        ? (jobData.resolvedNeeds as Record<string, string>)
        : undefined;
    if (!resolvedNeeds) continue;

    let allSatisfied = true;
    for (const needBuildJobId of Object.values(resolvedNeeds)) {
      const needDoc = await getBuildJob({ id: needBuildJobId });
      if (!needDoc.data.buildJob || needDoc.data.buildJob.status !== "success") {
        allSatisfied = false;
        break;
      }
    }

    if (allSatisfied) {
      await updateBuildJobStatus({ id: jobData.id, status: "queued" });
    }
  }
}

function formatDuration(createdAt?: unknown, completedAt?: unknown): string {
  if (typeof createdAt !== "string" || typeof completedAt !== "string") return "";
  const durationMs = new Date(completedAt).getTime() - new Date(createdAt).getTime();
  if (!Number.isFinite(durationMs) || durationMs <= 0) return "";
  const totalSeconds = Math.floor(durationMs / 1000);
  const minutes = Math.floor(totalSeconds / 60);
  const seconds = totalSeconds % 60;
  return minutes > 0 ? `${minutes}m ${seconds}s` : `${seconds}s`;
}

async function failureLogLine(buildJobId: string, latestRunId: unknown): Promise<string | undefined> {
  if (typeof latestRunId !== "string") return undefined;
  const logs = await listLatestBuildLogs({ buildJobId, runId: latestRunId, limit: 2 });
  return typeof logs.data.buildLogs[1]?.message === "string"
    ? logs.data.buildLogs[1]!.message
    : "Unknown error";
}

async function sendBuildNotifications(
  buildJobId: string,
  jobData: FirebaseFirestore.DocumentData,
  currentStatus: string,
): Promise<void> {
  const teamId = typeof jobData.teamId === "string" ? jobData.teamId : undefined;
  if (!teamId) return;
  const users = await listTeamNotificationUsers({ teamId });
  if (users.data.teamMembers.length === 0) return;

  const isSuccess = currentStatus === "success";
  const title = isSuccess ? "✅ Build Succeeded" : "❌ Build Failed";
  const owner = typeof jobData.owner === "string" ? jobData.owner : "";
  const repo = typeof jobData.repo === "string" ? jobData.repo : "";
  const branch = typeof jobData.branch === "string" ? jobData.branch : undefined;
  const workflowName = typeof jobData.workflowName === "string" ? jobData.workflowName : undefined;
  const duration = formatDuration(jobData.createdAt, jobData.completedAt);
  const bodyLines: string[] = [];
  if (workflowName) bodyLines.push(workflowName);
  bodyLines.push(`${repo}${branch ? ` (${branch})` : ""}`);
  if (duration) bodyLines.push(`⏱ ${duration}`);
  if (!isSuccess) {
    bodyLines.push((await failureLogLine(buildJobId, jobData.latestRunId)) ?? "Unknown error");
  }

  const invalidTokens = new Set<string>();
  let sent = 0;
  for (const member of users.data.teamMembers) {
    const userData = member.user;
    const preference = typeof userData.notificationPreference === "string" ? userData.notificationPreference : "all";
    if (preference === "none" || (preference === "successOnly" && !isSuccess) || (preference === "failureOnly" && isSuccess)) {
      continue;
    }
    const tokens = Array.isArray(userData.fcmTokens)
      ? userData.fcmTokens.filter((token): token is string => typeof token === "string")
      : [];
    for (const token of tokens) {
      try {
        await getMessaging().send({
          token,
          notification: { title, body: bodyLines.join("\n") },
          data: {
            buildJobId,
            status: currentStatus,
            owner,
            repo,
            ...(branch ? { branch } : {}),
            ...(workflowName ? { workflowName } : {}),
            ...(duration ? { duration } : {}),
          },
          apns: { payload: { aps: { sound: "default", badge: 1 } } },
        });
        sent += 1;
      } catch (error) {
        const message = String(error);
        if (message.includes("registration-token-not-registered") || message.includes("invalid-argument")) {
          invalidTokens.add(token);
        }
      }
    }
  }
  logger.info("Notifications sent", { sent, invalidTokens: invalidTokens.size });
  if (invalidTokens.size > 0) {
    for (const member of users.data.teamMembers) {
      const tokens = member.user.fcmTokens ?? [];
      const validTokens = tokens.filter((token: unknown) => typeof token === "string" && !invalidTokens.has(token));
      if (validTokens.length !== tokens.length) {
        await updateUserFcmTokens({ id: member.user.id, fcmTokens: validTokens });
      }
    }
  }
}

export const buildJobStatusChange = onCall<
  BuildJobStatusChangeRequest,
  Promise<{ success: true }>
>(async (request) => {
  const buildJobId = requireNonEmptyString(request.data?.buildJobId, "buildJobId");
  const status = requireNonEmptyString(request.data?.status, "status");
  const buildJobDoc = await getBuildJob({ id: buildJobId });
  const jobData = buildJobDoc.data.buildJob;
  if (!jobData) {
    throw new HttpsError("not-found", "Build job not found");
  }
  if (["success", "failure", "cancelled", "timed_out", "skipped"].includes(status)) {
    await resolveDependencies(jobData, status);
  }
  if (status === "success" || status === "failure") {
    await sendBuildNotifications(buildJobId, jobData, status);
  }
  return { success: true };
});
