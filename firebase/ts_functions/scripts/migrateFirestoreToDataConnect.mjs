import { initializeApp } from "firebase-admin/app";
import { getAuth } from "firebase-admin/auth";
import { FieldPath, Timestamp, getFirestore } from "firebase-admin/firestore";
import {
  upsertBuildJobFromFirestore,
  upsertBuildLogFromFirestore,
  upsertBuildRunFromFirestore,
  upsertEnvironmentVariableFromFirestore,
  upsertInvitationFromFirestore,
  upsertSecretMetadataFromFirestore,
  upsertTeamFromFirestore,
  upsertTeamMemberFromFirestore,
  upsertUserFromFirestore,
  upsertWorkflowFile,
  upsertWorkflowFromFirestore,
} from "../src/generated/dataconnect/esm/index.esm.js";

const PROJECT_ID = process.env.GCLOUD_PROJECT || process.env.GOOGLE_CLOUD_PROJECT || "openci-b1b91";
const FIRESTORE_DATABASE_ID = process.env.FIRESTORE_DATABASE_ID || "(default)";
const DRY_RUN = process.argv.includes("--dry-run");
const VERBOSE = process.argv.includes("--verbose");
const SKIP_BUILD_LOGS = process.argv.includes("--skip-build-logs");
const ONLY_BUILD_LOGS = process.argv.includes("--only-build-logs");
const ONLY_BUILD_JOBS_AND_LOGS = process.argv.includes("--only-build-jobs-and-logs");
const ONLY_ENVIRONMENT_VARIABLES = process.argv.includes("--only-environment-variables");
const CONCURRENCY = Number.parseInt(process.env.MIGRATION_CONCURRENCY ?? "20", 10);
const PAGE_SIZE = Number.parseInt(process.env.MIGRATION_PAGE_SIZE ?? "500", 10);
const BUILD_JOBS_SINCE_HOURS = Number.parseInt(
  process.env.MIGRATION_BUILD_JOBS_SINCE_HOURS ?? "0",
  10,
);
const MAX_RETRIES = Number.parseInt(process.env.MIGRATION_MAX_RETRIES ?? "8", 10);
const SKIP_BUILD_LOGS_BEFORE = Number.parseInt(
  process.env.MIGRATION_SKIP_BUILD_LOGS_BEFORE ?? "0",
  10,
);
const LOG_PROGRESS_INTERVAL = Number.parseInt(
  process.env.MIGRATION_LOG_PROGRESS_INTERVAL ?? "1000",
  10,
);

initializeApp({ projectId: PROJECT_ID });
const db =
  FIRESTORE_DATABASE_ID === "(default)" ? getFirestore() : getFirestore(FIRESTORE_DATABASE_ID);
const auth = getAuth();

const stats = {
  teams: 0,
  users: 0,
  teamMembers: 0,
  invitations: 0,
  secrets: 0,
  environmentVariables: 0,
  workflows: 0,
  workflowFiles: 0,
  buildJobs: 0,
  buildRuns: 0,
  buildLogs: 0,
  skipped: 0,
  errors: 0,
};

const knownTeamIds = new Set();
let seenBuildLogs = 0;

async function loadKnownTeamIds() {
  if (knownTeamIds.size > 0) return;
  for await (const doc of streamCollection(db.collection("teams_v0"))) {
    knownTeamIds.add(doc.id);
  }
}

function timestamp(value) {
  if (!value) return null;
  if (typeof value === "string") {
    if (/[zZ]$|[+-]\d\d:\d\d$/.test(value)) return value;
    return new Date(`${value}Z`).toISOString();
  }
  if (value instanceof Date) return value.toISOString();
  if (typeof value.toDate === "function") return value.toDate().toISOString();
  return null;
}

function stringArray(value) {
  return Array.isArray(value) ? value.filter((item) => typeof item === "string") : null;
}

function intArray(value) {
  return Array.isArray(value) ? value.filter((item) => Number.isInteger(item)) : null;
}

function enumInvitationStatus(status) {
  const normalized = String(status ?? "pending").toUpperCase();
  return ["PENDING", "ACCEPTED", "EXPIRED"].includes(normalized) ? normalized : "PENDING";
}

async function maybe(operationName, vars, fn) {
  if (DRY_RUN) {
    if (VERBOSE) {
      console.log(`[dry-run] ${operationName}`, vars.id ?? vars.teamId ?? vars.buildJobId ?? "");
    }
    return;
  }
  await withRetry(operationName, () => fn(vars));
}

function isRetryable(error) {
  const message = String(error?.message ?? error);
  return (
    message.includes("Too many connections") ||
    message.includes("ECONNRESET") ||
    message.includes("ETIMEDOUT") ||
    message.includes("DEADLINE_EXCEEDED") ||
    message.includes("INTERNAL") ||
    message.includes("UNAVAILABLE") ||
    message.includes("503") ||
    message.includes("504")
  );
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

async function withRetry(operationName, operation) {
  let attempt = 0;
  while (true) {
    try {
      return await operation();
    } catch (error) {
      attempt += 1;
      if (attempt > MAX_RETRIES || !isRetryable(error)) throw error;
      const delayMs = Math.min(30_000, 1_000 * 2 ** (attempt - 1));
      console.warn(
        `${operationName} failed with retryable error; retrying in ${delayMs}ms (attempt ${attempt}/${MAX_RETRIES})`,
        String(error?.message ?? error),
      );
      await sleep(delayMs);
    }
  }
}

async function runWithConcurrency(items, worker) {
  for (let i = 0; i < items.length; i += CONCURRENCY) {
    await Promise.all(items.slice(i, i + CONCURRENCY).map(worker));
  }
}

async function* streamCollection(collectionRef, pageSize = PAGE_SIZE) {
  let lastDoc = null;
  while (true) {
    let query = collectionRef.orderBy(FieldPath.documentId()).limit(pageSize);
    if (lastDoc) query = query.startAfter(lastDoc);
    const snap = await query.get();
    if (snap.empty) return;
    for (const doc of snap.docs) yield doc;
    lastDoc = snap.docs.at(-1);
  }
}

async function* streamBuildJobs() {
  const since =
    BUILD_JOBS_SINCE_HOURS > 0
      ? Timestamp.fromDate(new Date(Date.now() - BUILD_JOBS_SINCE_HOURS * 60 * 60 * 1000))
      : null;
  let lastDoc = null;
  while (true) {
    let query = since
      ? db
          .collection("build_jobs_v0")
          .where("createdAt", ">=", since)
          .orderBy("createdAt")
          .limit(PAGE_SIZE)
      : db.collection("build_jobs_v0").orderBy(FieldPath.documentId()).limit(PAGE_SIZE);
    if (lastDoc) query = query.startAfter(lastDoc);
    const snap = await query.get();
    if (snap.empty) return;
    for (const doc of snap.docs) yield doc;
    lastDoc = snap.docs.at(-1);
  }
}

function logProgress(label, count, interval = LOG_PROGRESS_INTERVAL) {
  if (count > 0 && count % interval === 0) {
    console.log(`${label}: ${count}`);
  }
}

async function authEmail(uid, fallback = null) {
  if (fallback) return fallback;
  try {
    return (await auth.getUser(uid)).email || `${uid}@unknown.invalid`;
  } catch {
    return `${uid}@unknown.invalid`;
  }
}

async function migrateTeams() {
  for await (const doc of streamCollection(db.collection("teams_v0"))) {
    const data = doc.data();
    await maybe("upsertTeamFromFirestore", { id: doc.id }, (vars) =>
      upsertTeamFromFirestore({
        ...vars,
        name: String(data.name ?? "Untitled Team"),
        aiEnabled: typeof data.aiEnabled === "boolean" ? data.aiEnabled : null,
        githubApiBaseUrl: typeof data.githubApiBaseUrl === "string" ? data.githubApiBaseUrl : null,
        githubBaseUrl: typeof data.githubBaseUrl === "string" ? data.githubBaseUrl : null,
        installationIds: intArray(data.installationIds),
        members: stringArray(data.members),
      }),
    );
    knownTeamIds.add(doc.id);
    stats.teams += 1;
    logProgress("teams", stats.teams, 100);
  }
}

async function migrateUsers() {
  const userIds = new Set();
  for await (const doc of streamCollection(db.collection("users_v0"))) userIds.add(doc.id);
  for await (const team of streamCollection(db.collection("teams_v0"))) {
    for (const uid of stringArray(team.data().members) ?? []) userIds.add(uid);
  }

  for (const uid of userIds) {
    const doc = await db.collection("users_v0").doc(uid).get();
    const data = doc.exists ? doc.data() : {};
    const email = await authEmail(uid, typeof data?.email === "string" ? data.email : null);
    await maybe("upsertUserFromFirestore", { id: uid }, (vars) =>
      upsertUserFromFirestore({
        ...vars,
        email,
        displayName: typeof data?.displayName === "string" ? data.displayName : null,
        photoUrl:
          typeof data?.photoURL === "string"
            ? data.photoURL
            : typeof data?.photoUrl === "string"
              ? data.photoUrl
              : null,
        notificationPreference:
          typeof data?.notificationPreference === "string" ? data.notificationPreference : null,
        fcmTokens: stringArray(data?.fcmTokens),
        selectedTeamId:
          typeof data?.selectedTeamId === "string" && knownTeamIds.has(data.selectedTeamId)
            ? data.selectedTeamId
            : null,
        selectedRepository:
          typeof data?.selectedRepository === "string" ? data.selectedRepository : null,
        selectedBranch: typeof data?.selectedBranch === "string" ? data.selectedBranch : null,
      }),
    );
    stats.users += 1;
    logProgress("users", stats.users, 100);
  }
}

async function migrateTeamMembers() {
  for await (const team of streamCollection(db.collection("teams_v0"))) {
    for (const uid of stringArray(team.data().members) ?? []) {
      await maybe("upsertTeamMemberFromFirestore", { teamId: team.id, userId: uid }, async (vars) =>
        upsertTeamMemberFromFirestore({
          ...vars,
          email: await authEmail(uid),
        }),
      );
      stats.teamMembers += 1;
      logProgress("teamMembers", stats.teamMembers, 100);
    }
  }
}

async function migrateInvitations() {
  for await (const doc of streamCollection(db.collection("invitations_v0"))) {
    const data = doc.data();
    if (
      !data.email ||
      !data.teamId ||
      !data.token ||
      !data.expiresAt ||
      !knownTeamIds.has(data.teamId)
    ) {
      stats.skipped += 1;
      continue;
    }
    await maybe("upsertInvitationFromFirestore", { id: doc.id }, (vars) =>
      upsertInvitationFromFirestore({
        ...vars,
        email: String(data.email),
        teamId: String(data.teamId),
        teamNameSnapshot: String(data.teamName ?? data.teamNameSnapshot ?? ""),
        token: String(data.token),
        status: enumInvitationStatus(data.status),
        expiresAt: timestamp(data.expiresAt),
        invitedById: typeof data.invitedBy === "string" ? data.invitedBy : null,
        acceptedById: typeof data.acceptedBy === "string" ? data.acceptedBy : null,
        acceptedAt: timestamp(data.acceptedAt),
      }),
    );
    stats.invitations += 1;
    logProgress("invitations", stats.invitations, 100);
  }
}

async function migrateSecrets() {
  await loadKnownTeamIds();
  for await (const doc of streamCollection(db.collection("secrets_v0"))) {
    const data = doc.data();
    if (!data.name || !data.teamId || !knownTeamIds.has(data.teamId)) {
      stats.skipped += 1;
      continue;
    }
    await maybe("upsertSecretMetadataFromFirestore", { id: doc.id }, (vars) =>
      upsertSecretMetadataFromFirestore({
        ...vars,
        name: String(data.name),
        teamId: String(data.teamId),
        pathToSecret: typeof data.pathToSecret === "string" ? data.pathToSecret : null,
      }),
    );
    stats.secrets += 1;
    logProgress("secrets", stats.secrets, 100);
  }
}

async function migrateEnvironmentVariables() {
  await loadKnownTeamIds();
  for await (const doc of streamCollection(db.collection("environment_variables_v0"))) {
    const data = doc.data();
    if (!data.key || !data.teamId || !knownTeamIds.has(data.teamId)) {
      stats.skipped += 1;
      continue;
    }
    await maybe("upsertEnvironmentVariableFromFirestore", { id: doc.id }, (vars) =>
      upsertEnvironmentVariableFromFirestore({
        ...vars,
        envKey: String(data.key),
        value: String(data.value ?? ""),
        teamId: String(data.teamId),
        autoIncrement: typeof data.autoIncrement === "boolean" ? data.autoIncrement : null,
      }),
    );
    stats.environmentVariables += 1;
    logProgress("environmentVariables", stats.environmentVariables, 100);
  }
}

async function migrateWorkflows() {
  await loadKnownTeamIds();
  for await (const doc of streamCollection(db.collection("workflows_v1"))) {
    const data = doc.data();
    if (!data.teamId || !knownTeamIds.has(data.teamId)) {
      stats.skipped += 1;
      continue;
    }
    await maybe("upsertWorkflowFromFirestore", { id: doc.id }, (vars) =>
      upsertWorkflowFromFirestore({
        ...vars,
        teamId: String(data.teamId),
        name: typeof data.name === "string" ? data.name : null,
        workflowConfig: data.workflowConfig ?? null,
        workflowSteps: data.workflowSteps ?? null,
        isEditing: typeof data.isEditing === "boolean" ? data.isEditing : null,
      }),
    );
    stats.workflows += 1;
    logProgress("workflows", stats.workflows, 100);
  }
}

async function migrateWorkflowFiles() {
  await loadKnownTeamIds();
  for await (const doc of streamCollection(db.collection("workflow_files_v0"))) {
    const data = doc.data();
    if (
      !data.teamId ||
      !knownTeamIds.has(data.teamId) ||
      !data.repository ||
      !data.branch ||
      !data.fileName ||
      !data.content
    ) {
      stats.skipped += 1;
      continue;
    }
    await maybe("upsertWorkflowFile", { id: doc.id }, (vars) =>
      upsertWorkflowFile({
        ...vars,
        teamId: String(data.teamId),
        repository: String(data.repository),
        branch: String(data.branch),
        fileName: String(data.fileName),
        filePath: String(data.filePath ?? `.openci/${data.fileName}`),
        content: String(data.content),
        enabled: typeof data.enabled === "boolean" ? data.enabled : null,
      }),
    );
    stats.workflowFiles += 1;
    logProgress("workflowFiles", stats.workflowFiles, 100);
  }
}

function buildJobVars(doc) {
  const data = doc.data();
  return {
    id: doc.id,
    status: String(data.status ?? "queued"),
    owner: String(data.owner ?? ""),
    repo: String(data.repo ?? ""),
    teamId: typeof data.teamId === "string" && knownTeamIds.has(data.teamId) ? data.teamId : null,
    workflowId: typeof data.workflowId === "string" ? data.workflowId : null,
    workflowFileName: typeof data.workflowFileName === "string" ? data.workflowFileName : null,
    workflowName: typeof data.workflowName === "string" ? data.workflowName : null,
    jobKey: typeof data.jobKey === "string" ? data.jobKey : null,
    workflowRunId: typeof data.workflowRunId === "string" ? data.workflowRunId : null,
    needs: stringArray(data.needs),
    resolvedNeeds: data.resolvedNeeds ?? null,
    installationId: Number.isInteger(data.installationId) ? String(data.installationId) : null,
    installationToken: typeof data.installationToken === "string" ? data.installationToken : null,
    tokenExpiresAt: timestamp(data.tokenExpiresAt),
    checkRunId: Number.isInteger(data.checkRunId) ? String(data.checkRunId) : null,
    commitSha: typeof data.commitSha === "string" ? data.commitSha : null,
    pullRequestNumber: Number.isInteger(data.pullRequestNumber) ? data.pullRequestNumber : null,
    event: typeof data.event === "string" ? data.event : null,
    action: typeof data.action === "string" ? data.action : null,
    sender: typeof data.sender === "string" ? data.sender : null,
    repository: typeof data.repository === "string" ? data.repository : null,
    tagName: typeof data.tagName === "string" ? data.tagName : null,
    branch: typeof data.branch === "string" ? data.branch : null,
    releaseName: typeof data.releaseName === "string" ? data.releaseName : null,
    runsOn: typeof data.runsOn === "string" ? data.runsOn : null,
    runCount: Number.isInteger(data.runCount) ? data.runCount : null,
    latestRunId: typeof data.latestRunId === "string" ? data.latestRunId : null,
    retriedFromBuildJobId:
      typeof data.retriedFromBuildJobId === "string" ? data.retriedFromBuildJobId : null,
    retriedFromWorkflowRunId:
      typeof data.retriedFromWorkflowRunId === "string" ? data.retriedFromWorkflowRunId : null,
    githubApiBaseUrl: typeof data.githubApiBaseUrl === "string" ? data.githubApiBaseUrl : null,
    githubBaseUrl: typeof data.githubBaseUrl === "string" ? data.githubBaseUrl : null,
    failureSummaryStatus:
      typeof data.failureSummaryStatus === "string" ? data.failureSummaryStatus : null,
    failureSummary: typeof data.failureSummary === "string" ? data.failureSummary : null,
    failureSummaryModel:
      typeof data.failureSummaryModel === "string" ? data.failureSummaryModel : null,
    failureSummaryDurationMs: Number.isInteger(data.failureSummaryDurationMs)
      ? data.failureSummaryDurationMs
      : null,
    completedAt: timestamp(data.completedAt),
  };
}

async function migrateBuildJobsAndLogs() {
  await loadKnownTeamIds();
  for await (const doc of streamBuildJobs()) {
    const vars = buildJobVars(doc);
    if (!vars.owner || !vars.repo) {
      stats.skipped += 1;
      continue;
    }
    if (!ONLY_BUILD_LOGS) {
      await maybe("upsertBuildJobFromFirestore", vars, upsertBuildJobFromFirestore);
    }
    stats.buildJobs += 1;
    logProgress("buildJobs", stats.buildJobs, 100);

    for await (const runDoc of streamCollection(doc.ref.collection("runs"))) {
      if (!ONLY_BUILD_LOGS) {
        await maybe(
          "upsertBuildRunFromFirestore",
          { buildJobId: doc.id, id: runDoc.id },
          upsertBuildRunFromFirestore,
        );
      }
      stats.buildRuns += 1;
      logProgress("buildRuns", stats.buildRuns, 100);

      if (!SKIP_BUILD_LOGS) {
        const logPage = [];
        for await (const logDoc of streamCollection(runDoc.ref.collection("logs"))) {
          logPage.push(logDoc);
          if (logPage.length < PAGE_SIZE) continue;
          await runWithConcurrency(
            logPage.splice(0),
            migrateBuildLog.bind(null, doc.id, runDoc.id),
          );
        }
        if (logPage.length > 0) {
          await runWithConcurrency(logPage, migrateBuildLog.bind(null, doc.id, runDoc.id));
        }
      }
    }
  }
}

async function migrateBuildLog(buildJobId, runId, logDoc) {
  const log = logDoc.data();
  if (!log.message || !log.timestamp) {
    stats.skipped += 1;
    return;
  }
  seenBuildLogs += 1;
  if (seenBuildLogs <= SKIP_BUILD_LOGS_BEFORE) {
    logProgress("buildLogsSkippedBeforeResume", seenBuildLogs);
    return;
  }
  await maybe(
    "upsertBuildLogFromFirestore",
    {
      buildJobId,
      runId,
      id: logDoc.id,
      message: String(log.message),
      timestamp: timestamp(log.timestamp),
    },
    upsertBuildLogFromFirestore,
  );
  stats.buildLogs += 1;
  logProgress("buildLogs", stats.buildLogs);
}

async function main() {
  console.log(`Migrating Firestore(${FIRESTORE_DATABASE_ID}) -> Data Connect (${PROJECT_ID})`);
  if (DRY_RUN) console.log("DRY RUN: no writes will be performed");
  if (SKIP_BUILD_LOGS) console.log("Skipping build logs");
  if (ONLY_BUILD_LOGS) console.log(`Migrating only build logs with concurrency ${CONCURRENCY}`);
  if (ONLY_BUILD_JOBS_AND_LOGS)
    console.log(`Migrating only build jobs/runs/logs with concurrency ${CONCURRENCY}`);
  if (ONLY_ENVIRONMENT_VARIABLES) console.log("Migrating only environment variables");
  if (BUILD_JOBS_SINCE_HOURS > 0) {
    console.log(`Migrating build jobs created in the last ${BUILD_JOBS_SINCE_HOURS} hours`);
  }
  if (SKIP_BUILD_LOGS_BEFORE > 0) {
    console.log(`Skipping first ${SKIP_BUILD_LOGS_BEFORE} valid build logs before writing`);
  }

  const steps = ONLY_ENVIRONMENT_VARIABLES
    ? [migrateEnvironmentVariables]
    : ONLY_BUILD_JOBS_AND_LOGS
      ? [migrateBuildJobsAndLogs]
      : ONLY_BUILD_LOGS
        ? [migrateBuildJobsAndLogs]
        : [
            migrateTeams,
            migrateUsers,
            migrateTeamMembers,
            migrateInvitations,
            migrateSecrets,
            migrateEnvironmentVariables,
            migrateWorkflows,
            migrateWorkflowFiles,
            migrateBuildJobsAndLogs,
          ];

  for (const step of steps) {
    try {
      console.log(`Starting ${step.name}`);
      await step();
      console.log(`Finished ${step.name}`);
    } catch (error) {
      stats.errors += 1;
      console.error(`Failed ${step.name}`, error);
      throw error;
    }
  }

  console.log("Migration complete");
  console.log(JSON.stringify(stats, null, 2));
}

await main();
