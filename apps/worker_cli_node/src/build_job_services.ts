// @ts-nocheck
import { FieldValue, Timestamp, getFirestore } from "firebase-admin/firestore";
import { getMessaging } from "firebase-admin/messaging";

export const BuildJobStatus = {
  WAITING: "WAITING",
  QUEUED: "QUEUED",
  IN_PROGRESS: "IN_PROGRESS",
  SUCCESS: "SUCCESS",
  FAILURE: "FAILURE",
  CANCELLED: "CANCELLED",
  SKIPPED: "SKIPPED",
  TIMED_OUT: "TIMED_OUT",
} as const;
export type BuildJobStatus = (typeof BuildJobStatus)[keyof typeof BuildJobStatus];

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

const collections = {
  teams: "teams_v0",
  users: "users_v0",
  secrets: "secrets_v0",
  env: "environment_variables_v0",
  buildJobs: "build_jobs_v0",
  workerInstances: "worker_instances_v0",
};

function db() {
  return getFirestore();
}

function varsFromArgs(first, second) {
  if (first && typeof first === "object" && typeof first.collection === "function") {
    return second ?? {};
  }
  if (first && typeof first === "object" && "impersonate" in first && second === undefined) {
    return {};
  }
  return first ?? {};
}

function now() {
  return FieldValue.serverTimestamp();
}

function timestamp(value) {
  if (value instanceof Timestamp) return value;
  if (value instanceof Date) return Timestamp.fromDate(value);
  if (typeof value === "string" || typeof value === "number") {
    const date = new Date(value);
    if (!Number.isNaN(date.getTime())) return Timestamp.fromDate(date);
  }
  return Timestamp.now();
}

function serializeValue(value) {
  if (value instanceof Timestamp) return value.toDate().toISOString();
  if (value instanceof Date) return value.toISOString();
  if (Array.isArray(value)) return value.map(serializeValue);
  if (value && typeof value === "object") {
    return Object.fromEntries(
      Object.entries(value).map(([key, entry]) => [key, serializeValue(entry)]),
    );
  }
  return value;
}

function docData(snapshot) {
  if (!snapshot.exists) return undefined;
  return { id: snapshot.id, ...serializeValue(snapshot.data() ?? {}) };
}

async function getDoc(collection, id) {
  return docData(await db().collection(collection).doc(id).get());
}

function withTimestamps(data, isCreate = false) {
  return {
    ...data,
    ...(isCreate ? { createdAt: now() } : {}),
    updatedAt: now(),
  };
}

async function queryAll(query) {
  const snap = await query.get();
  return snap.docs.map(docData).filter(Boolean);
}

function userRef(userId) {
  return db().collection(collections.users).doc(userId);
}

export async function getBuildJob(...args) {
  const vars = varsFromArgs(...args);
  return { data: { buildJob: (await getDoc(collections.buildJobs, vars.id)) ?? null } };
}

export async function updateBuildJobStatus(...args) {
  const vars = varsFromArgs(...args);
  await db().collection(collections.buildJobs).doc(vars.id).update({
    status: vars.status,
    updatedAt: now(),
  });
  return { data: { buildJob_update: { id: vars.id } } };
}

async function listWaitingBuildJobs(...args) {
  const vars = varsFromArgs(...args);
  const buildJobs = await queryAll(
    db()
      .collection(collections.buildJobs)
      .where("workflowRunId", "==", vars.workflowRunId)
      .where("status", "==", BuildJobStatus.WAITING),
  );
  return { data: { buildJobs } };
}

export async function claimQueuedBuildJob(...args) {
  const vars = varsFromArgs(...args);
  const platform = String(vars.runsOnPattern ?? "").includes("macos") ? "macos" : "ubuntu";
  const candidates = await db()
    .collection(collections.buildJobs)
    .where("status", "==", BuildJobStatus.QUEUED)
    .orderBy("createdAt")
    .limit(50)
    .get();
  const doc = candidates.docs.find((candidate) =>
    String(candidate.data().runsOn ?? "ubuntu-latest")
      .toLowerCase()
      .includes(platform),
  );
  if (!doc) return { data: { job: null } };
  const job = await db().runTransaction(async (tx) => {
    const fresh = await tx.get(doc.ref);
    if (!fresh.exists || fresh.data()?.status !== BuildJobStatus.QUEUED) return null;
    tx.update(doc.ref, { status: BuildJobStatus.IN_PROGRESS, updatedAt: now() });
    return {
      id: fresh.id,
      ...serializeValue(fresh.data() ?? {}),
      status: BuildJobStatus.IN_PROGRESS,
    };
  });
  return { data: { job } };
}

export async function createBuildRunForWorker(...args) {
  const vars = varsFromArgs(...args);
  await db().runTransaction(async (tx) => {
    const job = db().collection(collections.buildJobs).doc(vars.buildJobId);
    tx.set(
      job.collection("runs").doc(vars.id),
      withTimestamps({ id: vars.id, status: "in_progress" }, true),
      {
        merge: true,
      },
    );
    tx.update(job, { latestRunId: vars.id, runCount: FieldValue.increment(1), updatedAt: now() });
  });
  return {
    data: {
      buildRun_upsert: { buildJobId: vars.buildJobId, id: vars.id },
      buildJob_update: { id: vars.buildJobId },
    },
  };
}

export async function appendBuildLogForWorker(...args) {
  const vars = varsFromArgs(...args);
  await db()
    .collection(collections.buildJobs)
    .doc(vars.buildJobId)
    .collection("runs")
    .doc(vars.runId)
    .collection("logs")
    .doc(vars.id)
    .set({
      id: vars.id,
      message: vars.message,
      level: vars.level,
      timestamp: timestamp(vars.timestamp),
      ...(vars.stackTrace ? { stackTrace: vars.stackTrace } : {}),
    });
  return {
    data: {
      buildLog_upsert: {
        buildRunBuildJobId: vars.buildJobId,
        buildRunId: vars.runId,
        id: vars.id,
      },
    },
  };
}

export async function updateBuildRunStatusForWorker(...args) {
  const vars = varsFromArgs(...args);
  await db()
    .collection(collections.buildJobs)
    .doc(vars.buildJobId)
    .collection("runs")
    .doc(vars.runId)
    .set(withTimestamps({ status: vars.status, conclusion: vars.conclusion ?? null }, false), {
      merge: true,
    });
  return { data: { buildRun_update: { buildJobId: vars.buildJobId, id: vars.runId } } };
}

export async function completeBuildJobForWorker(...args) {
  const vars = varsFromArgs(...args);
  await db()
    .collection(collections.buildJobs)
    .doc(vars.id)
    .update({
      status: vars.status,
      completedAt: timestamp(vars.completedAt),
      updatedAt: now(),
    });
  return { data: { buildJob_update: { id: vars.id } } };
}

export async function upsertWorkerHeartbeat(...args) {
  const vars = varsFromArgs(...args);
  await db().runTransaction(async (tx) => {
    const ref = db().collection(collections.workerInstances).doc(vars.workerId);
    const snap = await tx.get(ref);
    tx.set(
      ref,
      withTimestamps(
        {
          workerId: vars.workerId,
          version: vars.version,
          platform: vars.platform,
          hostname: vars.hostname,
          pid: vars.pid,
          status: vars.status,
          lastSeenAt: now(),
          currentBuildJobId: vars.currentBuildJobId ?? null,
          currentRunId: vars.currentRunId ?? null,
          consecutiveFailures: vars.consecutiveFailures ?? 0,
          lastError: vars.lastError ?? null,
        },
        !snap.exists,
      ),
      { merge: true },
    );
  });
  return { data: { workerHeartbeat_upsert: { id: vars.workerId } } };
}

async function listLatestBuildLogs(...args) {
  const vars = varsFromArgs(...args);
  const buildLogs = await queryAll(
    db()
      .collection(collections.buildJobs)
      .doc(vars.buildJobId)
      .collection("runs")
      .doc(vars.runId)
      .collection("logs")
      .orderBy("timestamp", "desc")
      .limit(vars.limit ?? 2),
  );
  return { data: { buildLogs } };
}

async function listTeamMembers(...args) {
  const vars = varsFromArgs(...args);
  const team = (await getDoc(collections.teams, vars.teamId)) ?? {};
  const members = Array.isArray(team.members) ? team.members : [];
  const users = await Promise.all(members.map((uid) => getDoc(collections.users, uid)));
  return {
    data: {
      teamMembers: members.map((uid, index) => ({
        teamId: vars.teamId,
        userId: uid,
        user: users[index] ?? { id: uid, email: "" },
      })),
    },
  };
}

async function listTeamNotificationUsers(...args) {
  return listTeamMembers(...args);
}

async function updateUserFcmTokens(...args) {
  const vars = varsFromArgs(...args);
  await userRef(vars.id).set(withTimestamps({ fcmTokens: vars.fcmTokens ?? [] }), { merge: true });
  return { data: { user_update: { id: vars.id } } };
}

export async function listWorkerSecrets(...args) {
  const vars = varsFromArgs(...args);
  const secrets = await queryAll(
    db().collection(collections.secrets).where("teamId", "==", vars.teamId),
  );
  return { data: { secrets } };
}

export async function listWorkerEnvironmentVariables(...args) {
  const vars = varsFromArgs(...args);
  const environmentVariables = await queryAll(
    db().collection(collections.env).where("teamId", "==", vars.teamId).orderBy("key"),
  );
  return { data: { environmentVariables } };
}

export async function updateEnvironmentVariableValueForWorker(...args) {
  const vars = varsFromArgs(...args);
  await db()
    .collection(collections.env)
    .doc(vars.id)
    .update({ value: vars.value, updatedAt: now() });
  return { data: { environmentVariable_update: { id: vars.id } } };
}

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
