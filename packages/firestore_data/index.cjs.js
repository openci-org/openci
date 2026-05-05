const { createRequire } = require("node:module");

function requireFirebaseAdminFirestore() {
  try {
    return require("firebase-admin/firestore");
  } catch (error) {
    const requireFromApp = createRequire(`${process.cwd()}/package.json`);
    return requireFromApp("firebase-admin/firestore");
  }
}

const { getFirestore, FieldValue, Timestamp } = requireFirebaseAdminFirestore();

const BuildJobStatus = {
  WAITING: "WAITING",
  QUEUED: "QUEUED",
  IN_PROGRESS: "IN_PROGRESS",
  SUCCESS: "SUCCESS",
  FAILURE: "FAILURE",
  CANCELLED: "CANCELLED",
  SKIPPED: "SKIPPED",
  TIMED_OUT: "TIMED_OUT",
};
exports.BuildJobStatus = BuildJobStatus;

const InvitationStatus = {
  PENDING: "PENDING",
  ACCEPTED: "ACCEPTED",
  EXPIRED: "EXPIRED",
};
exports.InvitationStatus = InvitationStatus;

const connectorConfig = {
  connector: "firestore",
  serviceId: "openci",
  location: "asia-northeast1",
};
exports.connectorConfig = connectorConfig;

const collections = {
  teams: "teams_v0",
  users: "users_v0",
  invitations: "invitations_v0",
  secrets: "secrets_v0",
  env: "environment_variables_v0",
  workflows: "workflows_v1",
  workflowFiles: "workflow_files_v0",
  buildJobs: "build_jobs_v0",
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

function optionsFromArgs(first, second, third) {
  if (first && typeof first === "object" && typeof first.collection === "function") {
    return third ?? {};
  }
  if (first && typeof first === "object" && "impersonate" in first && second === undefined) {
    return first;
  }
  return second ?? {};
}

function uidFromOptions(options) {
  const claims = options?.impersonate?.authClaims ?? {};
  return claims.uid ?? claims.user_id ?? claims.sub;
}

function emailFromOptions(options) {
  const email = options?.impersonate?.authClaims?.email;
  return typeof email === "string" ? email : undefined;
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
    return Object.fromEntries(Object.entries(value).map(([key, entry]) => [key, serializeValue(entry)]));
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

function teamRef(teamId) {
  return db().collection(collections.teams).doc(teamId);
}

function userRef(userId) {
  return db().collection(collections.users).doc(userId);
}

async function teamForMember(teamId, uid) {
  const team = await getDoc(collections.teams, teamId);
  if (!team || !Array.isArray(team.members) || !team.members.includes(uid)) return undefined;
  return team;
}

async function getTeamById(...args) {
  const vars = varsFromArgs(...args);
  return { data: { team: (await getDoc(collections.teams, vars.teamId)) ?? null } };
}
exports.getTeamById = getTeamById;

async function getTeamForMember(...args) {
  const vars = varsFromArgs(...args);
  const options = optionsFromArgs(...args);
  return { data: { team: (await teamForMember(vars.teamId, uidFromOptions(options))) ?? null } };
}
exports.getTeamForMember = getTeamForMember;

async function findTeamByInstallation(...args) {
  const vars = varsFromArgs(...args);
  const teams = await queryAll(
    db().collection(collections.teams).where("installationIds", "array-contains", vars.installationId).limit(1),
  );
  return { data: { teams } };
}
exports.findTeamByInstallation = findTeamByInstallation;

async function linkGitHubInstallation(...args) {
  const vars = varsFromArgs(...args);
  await teamRef(vars.teamId).update({ installationIds: FieldValue.arrayUnion(vars.installationId), updatedAt: now() });
  return { data: { team_update: { id: vars.teamId } } };
}
exports.linkGitHubInstallation = linkGitHubInstallation;

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
exports.listTeamMembers = listTeamMembers;

async function addTeamMember(...args) {
  const vars = varsFromArgs(...args);
  await db().runTransaction(async (tx) => {
    const team = await tx.get(teamRef(vars.teamId));
    const members = Array.isArray(team.data()?.members) ? team.data().members : [];
    if (members.includes(vars.userId)) throw new Error("already a member");
    tx.set(userRef(vars.userId), withTimestamps({ email: vars.email }, !((await tx.get(userRef(vars.userId))).exists)), {
      merge: true,
    });
    tx.update(teamRef(vars.teamId), { members: FieldValue.arrayUnion(vars.userId), updatedAt: now() });
  });
  return { data: { user_upsert: { id: vars.userId }, teamMember_upsert: { teamId: vars.teamId, userId: vars.userId } } };
}
exports.addTeamMember = addTeamMember;

async function createInvitation(...args) {
  const vars = varsFromArgs(...args);
  const options = optionsFromArgs(...args);
  await db().collection(collections.invitations).doc(vars.id ?? db().collection(collections.invitations).doc().id).set(
    withTimestamps(
      {
        email: vars.email,
        teamId: vars.teamId,
        teamNameSnapshot: vars.teamNameSnapshot,
        token: vars.token,
        expiresAt: timestamp(vars.expiresAt),
        invitedById: uidFromOptions(options) ?? null,
        status: InvitationStatus.PENDING,
      },
      true,
    ),
  );
  return { data: { invitation_insert: { id: vars.id } } };
}
exports.createInvitation = createInvitation;

async function reinviteInvitation(...args) {
  const vars = varsFromArgs(...args);
  const options = optionsFromArgs(...args);
  await db().collection(collections.invitations).doc(vars.id).update({
    token: vars.token,
    expiresAt: timestamp(vars.expiresAt),
    invitedById: uidFromOptions(options) ?? null,
    updatedAt: now(),
  });
  return { data: { invitation_update: { id: vars.id } } };
}
exports.reinviteInvitation = reinviteInvitation;

async function findExistingPendingInvitation(...args) {
  const vars = varsFromArgs(...args);
  const invitations = await queryAll(
    db()
      .collection(collections.invitations)
      .where("email", "==", vars.email)
      .where("teamId", "==", vars.teamId)
      .where("status", "==", InvitationStatus.PENDING)
      .limit(1),
  );
  return { data: { invitations } };
}
exports.findExistingPendingInvitation = findExistingPendingInvitation;

async function invitationWithTeam(invitation) {
  const team = invitation?.teamId ? await getDoc(collections.teams, invitation.teamId) : undefined;
  return invitation ? { ...invitation, team: team ?? { id: invitation.teamId, name: invitation.teamNameSnapshot } } : undefined;
}

async function getInvitationByToken(...args) {
  const vars = varsFromArgs(...args);
  const invitations = await queryAll(db().collection(collections.invitations).where("token", "==", vars.token).limit(1));
  return { data: { invitations: (await Promise.all(invitations.map(invitationWithTeam))).filter(Boolean) } };
}
exports.getInvitationByToken = getInvitationByToken;

async function listMyPendingInvitations(...args) {
  const options = optionsFromArgs(...args);
  const email = emailFromOptions(options);
  if (!email) return { data: { invitations: [] } };
  const invitations = await queryAll(
    db()
      .collection(collections.invitations)
      .where("email", "==", email.trim().toLowerCase())
      .where("status", "==", InvitationStatus.PENDING)
      .orderBy("createdAt", "desc"),
  );
  return { data: { invitations: (await Promise.all(invitations.map(invitationWithTeam))).filter(Boolean) } };
}
exports.listMyPendingInvitations = listMyPendingInvitations;

async function expireInvitation(...args) {
  const vars = varsFromArgs(...args);
  await db().collection(collections.invitations).doc(vars.id).update({ status: InvitationStatus.EXPIRED, updatedAt: now() });
  return { data: { invitation_update: { id: vars.id } } };
}
exports.expireInvitation = expireInvitation;

async function acceptInvitationAndJoinTeam(...args) {
  const vars = varsFromArgs(...args);
  const options = optionsFromArgs(...args);
  const uid = uidFromOptions(options);
  const email = emailFromOptions(options);
  await db().runTransaction(async (tx) => {
    tx.set(userRef(uid), withTimestamps({ email, selectedTeamId: vars.teamId }, true), { merge: true });
    tx.update(db().collection(collections.invitations).doc(vars.id), {
      status: InvitationStatus.ACCEPTED,
      acceptedById: uid,
      acceptedAt: now(),
      updatedAt: now(),
    });
    tx.update(teamRef(vars.teamId), { members: FieldValue.arrayUnion(uid), updatedAt: now() });
  });
  return { data: { user_upsert: { id: uid }, invitation_update: { id: vars.id }, teamMember_upsert: { teamId: vars.teamId, userId: uid } } };
}
exports.acceptInvitationAndJoinTeam = acceptInvitationAndJoinTeam;

async function listWorkflowFilesForBranch(...args) {
  const vars = varsFromArgs(...args);
  let query = db().collection(collections.workflowFiles).where("teamId", "==", vars.teamId).where("repository", "==", vars.repository);
  if (vars.branch) query = query.where("branch", "==", vars.branch);
  const workflowFiles = await queryAll(query.orderBy("fileName"));
  return { data: { workflowFiles } };
}
exports.listWorkflowFilesForBranch = listWorkflowFilesForBranch;

async function getWorkflowFile(...args) {
  const vars = varsFromArgs(...args);
  return { data: { workflowFile: (await getDoc(collections.workflowFiles, vars.id)) ?? null } };
}
exports.getWorkflowFile = getWorkflowFile;

async function upsertWorkflowFile(...args) {
  const vars = varsFromArgs(...args);
  await db().collection(collections.workflowFiles).doc(vars.id).set(
    {
      id: vars.id,
      teamId: vars.teamId,
      repository: vars.repository,
      branch: vars.branch,
      fileName: vars.fileName,
      filePath: vars.filePath,
      content: vars.content,
      enabled: vars.enabled ?? true,
      syncedAt: now(),
      updatedAt: now(),
    },
    { merge: true },
  );
  return { data: { workflowFile_upsert: { id: vars.id } } };
}
exports.upsertWorkflowFile = upsertWorkflowFile;

async function deleteWorkflowFile(...args) {
  const vars = varsFromArgs(...args);
  await db().collection(collections.workflowFiles).doc(vars.id).delete();
  return { data: { workflowFile_delete: { id: vars.id } } };
}
exports.deleteWorkflowFile = deleteWorkflowFile;

async function createBuildJob(...args) {
  const vars = varsFromArgs(...args);
  await db().collection(collections.buildJobs).doc(vars.id).set(withTimestamps(vars, true));
  return { data: { buildJob_insert: { id: vars.id } } };
}
exports.createBuildJob = createBuildJob;

async function getBuildJob(...args) {
  const vars = varsFromArgs(...args);
  return { data: { buildJob: (await getDoc(collections.buildJobs, vars.id)) ?? null } };
}
exports.getBuildJob = getBuildJob;

async function updateBuildJobStatus(...args) {
  const vars = varsFromArgs(...args);
  await db().collection(collections.buildJobs).doc(vars.id).update({ status: vars.status, updatedAt: now() });
  return { data: { buildJob_update: { id: vars.id } } };
}
exports.updateBuildJobStatus = updateBuildJobStatus;

async function listBuildJobsByWorkflowRun(...args) {
  const vars = varsFromArgs(...args);
  const buildJobs = await queryAll(
    db().collection(collections.buildJobs).where("workflowRunId", "==", vars.workflowRunId).orderBy("createdAt"),
  );
  return { data: { buildJobs } };
}
exports.listBuildJobsByWorkflowRun = listBuildJobsByWorkflowRun;

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
exports.listWaitingBuildJobs = listWaitingBuildJobs;

async function claimQueuedBuildJob(...args) {
  const vars = varsFromArgs(...args);
  const platform = String(vars.runsOnPattern ?? "").includes("macos") ? "macos" : "ubuntu";
  const candidates = await db()
    .collection(collections.buildJobs)
    .where("status", "==", BuildJobStatus.QUEUED)
    .orderBy("createdAt")
    .limit(50)
    .get();
  const doc = candidates.docs.find((candidate) => String(candidate.data().runsOn ?? "ubuntu-latest").toLowerCase().includes(platform));
  if (!doc) return { data: { job: null } };
  const job = await db().runTransaction(async (tx) => {
    const fresh = await tx.get(doc.ref);
    if (!fresh.exists || fresh.data()?.status !== BuildJobStatus.QUEUED) return null;
    tx.update(doc.ref, { status: BuildJobStatus.IN_PROGRESS, updatedAt: now() });
    return { id: fresh.id, ...serializeValue(fresh.data() ?? {}), status: BuildJobStatus.IN_PROGRESS };
  });
  return { data: { job } };
}
exports.claimQueuedBuildJob = claimQueuedBuildJob;

async function createBuildRunForWorker(...args) {
  const vars = varsFromArgs(...args);
  await db().runTransaction(async (tx) => {
    const job = db().collection(collections.buildJobs).doc(vars.buildJobId);
    tx.set(job.collection("runs").doc(vars.id), withTimestamps({ id: vars.id, status: "in_progress" }, true), { merge: true });
    tx.update(job, { latestRunId: vars.id, runCount: FieldValue.increment(1), updatedAt: now() });
  });
  return { data: { buildRun_upsert: { buildJobId: vars.buildJobId, id: vars.id }, buildJob_update: { id: vars.buildJobId } } };
}
exports.createBuildRunForWorker = createBuildRunForWorker;

async function appendBuildLogForWorker(...args) {
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
  return { data: { buildLog_upsert: { buildRunBuildJobId: vars.buildJobId, buildRunId: vars.runId, id: vars.id } } };
}
exports.appendBuildLogForWorker = appendBuildLogForWorker;

async function updateBuildRunStatusForWorker(...args) {
  const vars = varsFromArgs(...args);
  await db().collection(collections.buildJobs).doc(vars.buildJobId).collection("runs").doc(vars.runId).set(
    withTimestamps({ status: vars.status, conclusion: vars.conclusion ?? null }, false),
    { merge: true },
  );
  return { data: { buildRun_update: { buildJobId: vars.buildJobId, id: vars.runId } } };
}
exports.updateBuildRunStatusForWorker = updateBuildRunStatusForWorker;

async function completeBuildJobForWorker(...args) {
  const vars = varsFromArgs(...args);
  await db().collection(collections.buildJobs).doc(vars.id).update({
    status: vars.status,
    completedAt: timestamp(vars.completedAt),
    updatedAt: now(),
  });
  return { data: { buildJob_update: { id: vars.id } } };
}
exports.completeBuildJobForWorker = completeBuildJobForWorker;

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
exports.listLatestBuildLogs = listLatestBuildLogs;

async function listTeamNotificationUsers(...args) {
  return listTeamMembers(...args);
}
exports.listTeamNotificationUsers = listTeamNotificationUsers;

async function updateUserFcmTokens(...args) {
  const vars = varsFromArgs(...args);
  await userRef(vars.id).set(withTimestamps({ fcmTokens: vars.fcmTokens ?? [] }), { merge: true });
  return { data: { user_update: { id: vars.id } } };
}
exports.updateUserFcmTokens = updateUserFcmTokens;

async function updateBuildJobFailureSummary(...args) {
  const vars = varsFromArgs(...args);
  await db().collection(collections.buildJobs).doc(vars.id).update({
    failureSummaryStatus: vars.failureSummaryStatus ?? null,
    failureSummary: vars.failureSummary ?? null,
    failureSummaryModel: vars.failureSummaryModel ?? null,
    failureSummaryDurationMs: vars.failureSummaryDurationMs ?? null,
    updatedAt: now(),
  });
  return { data: { buildJob_update: { id: vars.id } } };
}
exports.updateBuildJobFailureSummary = updateBuildJobFailureSummary;

async function findSecretByNameForTeam(...args) {
  const vars = varsFromArgs(...args);
  const secrets = await queryAll(
    db().collection(collections.secrets).where("teamId", "==", vars.teamId).where("name", "==", vars.name).limit(1),
  );
  return { data: { secrets } };
}
exports.findSecretByNameForTeam = findSecretByNameForTeam;

async function getSecretsByNamesForTeam(...args) {
  const vars = varsFromArgs(...args);
  if (!Array.isArray(vars.names) || vars.names.length === 0) return { data: { secrets: [] } };
  const secrets = await queryAll(db().collection(collections.secrets).where("teamId", "==", vars.teamId).where("name", "in", vars.names.slice(0, 10)));
  return { data: { secrets } };
}
exports.getSecretsByNamesForTeam = getSecretsByNamesForTeam;

async function listWorkerSecrets(...args) {
  const vars = varsFromArgs(...args);
  const secrets = await queryAll(db().collection(collections.secrets).where("teamId", "==", vars.teamId));
  return { data: { secrets } };
}
exports.listWorkerSecrets = listWorkerSecrets;

async function createSecretMetadata(...args) {
  const vars = varsFromArgs(...args);
  await db().collection(collections.secrets).doc(vars.id).set(
    withTimestamps({ id: vars.id, name: vars.name, teamId: vars.teamId, pathToSecret: vars.pathToSecret }, true),
  );
  return { data: { secret_insert: { id: vars.id } } };
}
exports.createSecretMetadata = createSecretMetadata;

async function getSecretPathForTeam(...args) {
  const vars = varsFromArgs(...args);
  const secret = await getDoc(collections.secrets, vars.id);
  return { data: { secret: secret && secret.teamId === vars.teamId ? secret : null } };
}
exports.getSecretPathForTeam = getSecretPathForTeam;

async function updateSecretMetadata(...args) {
  const vars = varsFromArgs(...args);
  await db().collection(collections.secrets).doc(vars.id).update({ name: vars.name, updatedAt: now() });
  return { data: { secret_update: { id: vars.id } } };
}
exports.updateSecretMetadata = updateSecretMetadata;

async function deleteSecretMetadata(...args) {
  const vars = varsFromArgs(...args);
  await db().collection(collections.secrets).doc(vars.id).delete();
  return { data: { secret_delete: { id: vars.id } } };
}
exports.deleteSecretMetadata = deleteSecretMetadata;

async function listWorkflowsForTeam(...args) {
  const vars = varsFromArgs(...args);
  const workflows = await queryAll(db().collection(collections.workflows).where("teamId", "==", vars.teamId).orderBy("updatedAt", "desc"));
  return { data: { workflows } };
}
exports.listWorkflowsForTeam = listWorkflowsForTeam;

async function updateWorkflowSecretKeys(...args) {
  const vars = varsFromArgs(...args);
  await db().collection(collections.workflows).doc(vars.id).update({ workflowSteps: vars.workflowSteps ?? [], updatedAt: now() });
  return { data: { workflow_update: { id: vars.id } } };
}
exports.updateWorkflowSecretKeys = updateWorkflowSecretKeys;

async function listWorkerEnvironmentVariables(...args) {
  const vars = varsFromArgs(...args);
  const environmentVariables = await queryAll(db().collection(collections.env).where("teamId", "==", vars.teamId).orderBy("key"));
  return { data: { environmentVariables } };
}
exports.listWorkerEnvironmentVariables = listWorkerEnvironmentVariables;

async function updateEnvironmentVariableValueForWorker(...args) {
  const vars = varsFromArgs(...args);
  await db().collection(collections.env).doc(vars.id).update({ value: vars.value, updatedAt: now() });
  return { data: { environmentVariable_update: { id: vars.id } } };
}
exports.updateEnvironmentVariableValueForWorker = updateEnvironmentVariableValueForWorker;
