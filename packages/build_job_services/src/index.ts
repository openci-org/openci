export {
  appendBuildLogForWorker,
  BuildJobStatus,
  claimQueuedBuildJob,
  completeBuildJobForWorker,
  createBuildRunForWorker,
  getBuildJob,
  listWorkerEnvironmentVariables,
  listWorkerSecrets,
  updateBuildJobStatus,
  updateBuildRunStatusForWorker,
  updateEnvironmentVariableValueForWorker,
} from "./firestoreData";

import {
  BuildJobStatus,
  getBuildJob,
  getTeamById,
  listLatestBuildLogs,
  listTeamNotificationUsers,
  listWaitingBuildJobs,
  updateBuildJobFailureSummary,
  updateBuildJobStatus,
  updateUserFcmTokens,
} from "./firestoreData";
import { getMessaging } from "firebase-admin/messaging";

type BuildJobStatusValue = (typeof BuildJobStatus)[keyof typeof BuildJobStatus];
type TerminalBuildJobStatus =
  | typeof BuildJobStatus.SUCCESS
  | typeof BuildJobStatus.FAILURE
  | typeof BuildJobStatus.CANCELLED
  | typeof BuildJobStatus.SKIPPED
  | typeof BuildJobStatus.TIMED_OUT;

export interface BuildJob {
  id: string;
  status: BuildJobStatusValue;
  owner: string;
  repo: string;
  teamId?: string | null;
  workflowFileName?: string | null;
  workflowName?: string | null;
  jobKey?: string | null;
  workflowRunId?: string | null;
  needs?: string[] | null;
  resolvedNeeds?: unknown | null;
  installationToken?: string | null;
  checkRunId?: string | number | null;
  commitSha?: string | null;
  pullRequestNumber?: number | null;
  tagName?: string | null;
  branch?: string | null;
  runsOn?: string | null;
  githubApiBaseUrl?: string | null;
  githubBaseUrl?: string | null;
  latestRunId?: string | null;
  createdAt?: string | null;
  updatedAt?: string | null;
  completedAt?: string | null;
}

export const defaultGitHubApiBaseUrl = "https://api.github.com";
const dashboardBaseUrl = "https://dashboard.openci.org";

function asBuildJob(value: unknown): BuildJob | undefined {
  if (!value || typeof value !== "object") return undefined;
  return value as BuildJob;
}

export function normalizeGitHubApiBaseUrl(apiBaseUrl?: string | null): string {
  if (!apiBaseUrl) return defaultGitHubApiBaseUrl;
  const normalized = apiBaseUrl.replace(/\/+$/u, "");
  if (normalized === `${defaultGitHubApiBaseUrl}/graphql`) return defaultGitHubApiBaseUrl;
  if (normalized.endsWith("/api/graphql")) return `${new URL(normalized).origin}/api/v3`;
  if (normalized.endsWith("/graphql")) return normalized.slice(0, -"/graphql".length);
  return normalized;
}

export function buildDashboardRunUrl(buildJobId: string): string {
  return `${dashboardBaseUrl}/runs/${encodeURIComponent(buildJobId)}`;
}

function formatDuration(createdAt?: string | null, completedAt?: string | null): string {
  if (!createdAt || !completedAt) return "";
  const durationMs = new Date(completedAt).getTime() - new Date(createdAt).getTime();
  if (!Number.isFinite(durationMs) || durationMs <= 0) return "";
  const totalSeconds = Math.floor(durationMs / 1000);
  const minutes = Math.floor(totalSeconds / 60);
  const seconds = totalSeconds % 60;
  return minutes > 0 ? `${minutes}m ${seconds}s` : `${seconds}s`;
}

export async function getBuildJobOrThrow(buildJobId: string): Promise<BuildJob> {
  const result = await getBuildJob({ id: buildJobId });
  const buildJob = asBuildJob(result.data.buildJob);
  if (!buildJob) throw new Error("Build job not found");
  return buildJob;
}

export async function updateCheckRun(
  buildJob: BuildJob,
  runStatus: "in_progress" | "completed",
  conclusion?: "success" | "failure",
): Promise<void> {
  if (buildJob.checkRunId === null || buildJob.checkRunId === undefined) return;
  if (!buildJob.installationToken) return;

  const response = await fetch(
    `${normalizeGitHubApiBaseUrl(buildJob.githubApiBaseUrl)}/repos/${buildJob.owner}/${buildJob.repo}/check-runs/${String(
      buildJob.checkRunId,
    )}`,
    {
      method: "PATCH",
      headers: {
        Authorization: `Bearer ${buildJob.installationToken}`,
        Accept: "application/vnd.github+json",
        "X-GitHub-Api-Version": "2022-11-28",
        "Content-Type": "application/json",
      },
      body: JSON.stringify({
        status: runStatus,
        ...(runStatus === "completed" && conclusion ? { conclusion } : {}),
        details_url: buildDashboardRunUrl(buildJob.id),
      }),
    },
  );

  if (!response.ok) {
    throw new Error(
      `Failed to update GitHub check run: ${response.status} ${await response.text()}`,
    );
  }
}

export async function updateCheckRunById(
  buildJobId: string,
  runStatus: "in_progress" | "completed",
  conclusion?: "success" | "failure",
): Promise<void> {
  await updateCheckRun(await getBuildJobOrThrow(buildJobId), runStatus, conclusion);
}

async function resolveDependencies(
  completedJob: BuildJob,
  completedStatus: BuildJobStatusValue,
): Promise<void> {
  if (!completedJob.workflowRunId || !completedJob.jobKey) return;
  const waitingJobs = await listWaitingBuildJobs({ workflowRunId: completedJob.workflowRunId });
  const isSuccess = completedStatus === BuildJobStatus.SUCCESS;

  for (const job of waitingJobs.data.buildJobs) {
    const needs = Array.isArray(job.needs)
      ? job.needs.filter((need: unknown): need is string => typeof need === "string")
      : [];
    if (!needs.includes(completedJob.jobKey)) continue;

    if (!isSuccess) {
      await updateBuildJobStatus({ id: job.id, status: BuildJobStatus.SKIPPED });
      await resolveDependencies(job as BuildJob, BuildJobStatus.SKIPPED);
      continue;
    }

    const resolvedNeeds =
      typeof job.resolvedNeeds === "object" && job.resolvedNeeds !== null
        ? (job.resolvedNeeds as Record<string, string>)
        : undefined;
    if (!resolvedNeeds) continue;

    let allSatisfied = true;
    for (const needBuildJobId of Object.values(resolvedNeeds)) {
      const need = await getBuildJob({ id: needBuildJobId });
      if (!need.data.buildJob || need.data.buildJob.status !== BuildJobStatus.SUCCESS) {
        allSatisfied = false;
        break;
      }
    }
    if (allSatisfied) {
      await updateBuildJobStatus({ id: job.id, status: BuildJobStatus.QUEUED });
    }
  }
}

async function failureLogLine(buildJobId: string, latestRunId?: string | null): Promise<string> {
  if (!latestRunId) return "Unknown error";
  const logs = await listLatestBuildLogs({ buildJobId, runId: latestRunId, limit: 2 });
  return logs.data.buildLogs[1]?.message ?? "Unknown error";
}

async function sendBuildNotifications(
  buildJob: BuildJob,
  status: typeof BuildJobStatus.SUCCESS | typeof BuildJobStatus.FAILURE,
): Promise<void> {
  if (!buildJob.teamId) return;
  const users = await listTeamNotificationUsers({ teamId: buildJob.teamId });
  if (users.data.teamMembers.length === 0) return;

  const isSuccess = status === BuildJobStatus.SUCCESS;
  const title = isSuccess ? "✅ Build Succeeded" : "❌ Build Failed";
  const duration = formatDuration(buildJob.createdAt, buildJob.completedAt);
  const bodyLines = [
    ...(buildJob.workflowName ? [buildJob.workflowName] : []),
    `${buildJob.repo}${buildJob.branch ? ` (${buildJob.branch})` : ""}`,
    ...(duration ? [`⏱ ${duration}`] : []),
    ...(!isSuccess ? [await failureLogLine(buildJob.id, buildJob.latestRunId)] : []),
  ];

  const invalidTokens = new Set<string>();
  for (const member of users.data.teamMembers) {
    const preference = member.user.notificationPreference ?? "all";
    if (
      preference === "none" ||
      (preference === "successOnly" && !isSuccess) ||
      (preference === "failureOnly" && isSuccess)
    ) {
      continue;
    }
    for (const token of member.user.fcmTokens ?? []) {
      try {
        await getMessaging().send({
          token,
          notification: { title, body: bodyLines.join("\n") },
          data: {
            buildJobId: buildJob.id,
            status,
            owner: buildJob.owner,
            repo: buildJob.repo,
            ...(buildJob.branch ? { branch: buildJob.branch } : {}),
            ...(buildJob.workflowName ? { workflowName: buildJob.workflowName } : {}),
            ...(duration ? { duration } : {}),
          },
          apns: { payload: { aps: { sound: "default", badge: 1 } } },
        });
      } catch (error) {
        const message = String(error);
        if (
          message.includes("registration-token-not-registered") ||
          message.includes("invalid-argument")
        ) {
          invalidTokens.add(token);
        }
      }
    }
  }

  if (invalidTokens.size > 0) {
    for (const member of users.data.teamMembers) {
      const validTokens = (member.user.fcmTokens ?? []).filter(
        (token: string) => !invalidTokens.has(token),
      );
      if (validTokens.length !== (member.user.fcmTokens ?? []).length) {
        await updateUserFcmTokens({ id: member.user.id, fcmTokens: validTokens });
      }
    }
  }
}

export async function handleBuildJobStatusChange(
  buildJob: BuildJob,
  status: BuildJobStatusValue,
): Promise<void> {
  const terminalStatuses: TerminalBuildJobStatus[] = [
    BuildJobStatus.SUCCESS,
    BuildJobStatus.FAILURE,
    BuildJobStatus.CANCELLED,
    BuildJobStatus.TIMED_OUT,
    BuildJobStatus.SKIPPED,
  ];
  if (terminalStatuses.includes(status as TerminalBuildJobStatus)) {
    await resolveDependencies(buildJob, status);
  }
  if (status === BuildJobStatus.SUCCESS || status === BuildJobStatus.FAILURE) {
    await sendBuildNotifications(buildJob, status);
  }
}

export async function handleBuildJobStatusChangeById(
  buildJobId: string,
  status: BuildJobStatusValue,
): Promise<void> {
  await handleBuildJobStatusChange(await getBuildJobOrThrow(buildJobId), status);
}
