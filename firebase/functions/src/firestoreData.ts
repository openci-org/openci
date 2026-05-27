// @ts-nocheck
import { FieldValue, Timestamp, getFirestore } from "firebase-admin/firestore";

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

export const InvitationStatus = {
  PENDING: "PENDING",
  ACCEPTED: "ACCEPTED",
  EXPIRED: "EXPIRED",
} as const;
export type InvitationStatus = (typeof InvitationStatus)[keyof typeof InvitationStatus];

export const firestoreCollectionPaths = {
  teams: "teams_v0",
  users: "users_v0",
  invitations: "invitations_v0",
  secrets: "secrets_v0",
  env: "environment_variables_v0",
  workflows: "workflows_v1",
  buildJobs: "build_jobs_v0",
  ciNotifications: "ci_notifications_v0",
  workspaces: "workspaces",
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

function teamRef(teamId) {
  return db().collection(firestoreCollectionPaths.teams).doc(teamId);
}

function userRef(userId) {
  return db().collection(firestoreCollectionPaths.users).doc(userId);
}

function workspaceRef(teamId) {
  return db().collection(firestoreCollectionPaths.workspaces).doc(teamId);
}

function workspaceMemberRef(teamId, userId) {
  return workspaceRef(teamId).collection("members").doc(userId);
}

function firstTeamMember(team) {
  const members = Array.isArray(team?.data()?.members) ? team.data().members : [];
  return typeof members[0] === "string" && members[0].length > 0 ? members[0] : undefined;
}

async function teamForMember(teamId, uid) {
  const team = await getDoc(firestoreCollectionPaths.teams, teamId);
  if (!team || !Array.isArray(team.members) || !team.members.includes(uid)) return undefined;
  return team;
}

async function getTeamById(...args) {
  const vars = varsFromArgs(...args);
  return { data: { team: (await getDoc(firestoreCollectionPaths.teams, vars.teamId)) ?? null } };
}

async function getTeamForMember(...args) {
  const vars = varsFromArgs(...args);
  const options = optionsFromArgs(...args);
  return { data: { team: (await teamForMember(vars.teamId, uidFromOptions(options))) ?? null } };
}

async function findTeamByInstallation(...args) {
  const vars = varsFromArgs(...args);
  const teams = await queryAll(
    db()
      .collection(firestoreCollectionPaths.teams)
      .where("installationIds", "array-contains", vars.installationId)
      .limit(1),
  );
  return { data: { teams } };
}

async function linkGitHubInstallation(...args) {
  const vars = varsFromArgs(...args);
  await teamRef(vars.teamId).update({
    installationIds: FieldValue.arrayUnion(vars.installationId),
    updatedAt: now(),
  });
  return { data: { team_update: { id: vars.teamId } } };
}

async function listTeamMembers(...args) {
  const vars = varsFromArgs(...args);
  const team = (await getDoc(firestoreCollectionPaths.teams, vars.teamId)) ?? {};
  const members = Array.isArray(team.members) ? team.members : [];

  let users = [];
  if (members.length > 0) {
    const userRefs = members.map((uid) => db().collection(firestoreCollectionPaths.users).doc(uid));
    const userSnaps = await db().getAll(...userRefs);
    users = userSnaps.map(docData);
  }

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

async function addTeamMember(...args) {
  const vars = varsFromArgs(...args);
  await db().runTransaction(async (tx) => {
    const teamDocument = teamRef(vars.teamId);
    const workspaceDocument = workspaceRef(vars.teamId);
    const team = await tx.get(teamDocument);
    const user = await tx.get(userRef(vars.userId));
    const workspace = await tx.get(workspaceDocument);
    const members = Array.isArray(team.data()?.members) ? team.data().members : [];
    if (members.includes(vars.userId)) throw new Error("already a member");
    tx.set(
      userRef(vars.userId),
      withTimestamps({ id: vars.userId, email: vars.email }, !user.exists),
      {
        merge: true,
      },
    );
    if (!workspace.exists) {
      tx.set(
        workspaceDocument,
        withTimestamps(
          {
            ownerUid: firstTeamMember(team) ?? vars.userId,
            name: team.get("name") ?? vars.teamId,
          },
          true,
        ),
      );
    }
    tx.set(workspaceMemberRef(vars.teamId, vars.userId), withTimestamps({ role: "member" }, true), {
      merge: true,
    });
    tx.update(teamDocument, {
      members: FieldValue.arrayUnion(vars.userId),
      updatedAt: now(),
    });
  });
  return {
    data: {
      user_upsert: { id: vars.userId },
      teamMember_upsert: { teamId: vars.teamId, userId: vars.userId },
    },
  };
}

async function createInvitation(...args) {
  const vars = varsFromArgs(...args);
  const options = optionsFromArgs(...args);
  await db()
    .collection(firestoreCollectionPaths.invitations)
    .doc(vars.id ?? db().collection(firestoreCollectionPaths.invitations).doc().id)
    .set(
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

async function reinviteInvitation(...args) {
  const vars = varsFromArgs(...args);
  const options = optionsFromArgs(...args);
  await db()
    .collection(firestoreCollectionPaths.invitations)
    .doc(vars.id)
    .update({
      token: vars.token,
      expiresAt: timestamp(vars.expiresAt),
      invitedById: uidFromOptions(options) ?? null,
      updatedAt: now(),
    });
  return { data: { invitation_update: { id: vars.id } } };
}

async function findExistingPendingInvitation(...args) {
  const vars = varsFromArgs(...args);
  const invitations = await queryAll(
    db()
      .collection(firestoreCollectionPaths.invitations)
      .where("email", "==", vars.email)
      .where("teamId", "==", vars.teamId)
      .where("status", "==", InvitationStatus.PENDING)
      .limit(1),
  );
  return { data: { invitations } };
}

async function invitationWithTeam(invitation) {
  const team = invitation?.teamId
    ? await getDoc(firestoreCollectionPaths.teams, invitation.teamId)
    : undefined;
  return invitation
    ? { ...invitation, team: team ?? { id: invitation.teamId, name: invitation.teamNameSnapshot } }
    : undefined;
}

async function getInvitationByToken(...args) {
  const vars = varsFromArgs(...args);
  const invitations = await queryAll(
    db().collection(firestoreCollectionPaths.invitations).where("token", "==", vars.token).limit(1),
  );
  return {
    data: { invitations: (await Promise.all(invitations.map(invitationWithTeam))).filter(Boolean) },
  };
}

async function listMyPendingInvitations(...args) {
  const options = optionsFromArgs(...args);
  const email = emailFromOptions(options);
  if (!email) return { data: { invitations: [] } };
  const invitations = await queryAll(
    db()
      .collection(firestoreCollectionPaths.invitations)
      .where("email", "==", email.trim().toLowerCase())
      .where("status", "==", InvitationStatus.PENDING)
      .orderBy("createdAt", "desc"),
  );
  return {
    data: { invitations: (await Promise.all(invitations.map(invitationWithTeam))).filter(Boolean) },
  };
}

async function expireInvitation(...args) {
  const vars = varsFromArgs(...args);
  await db()
    .collection(firestoreCollectionPaths.invitations)
    .doc(vars.id)
    .update({ status: InvitationStatus.EXPIRED, updatedAt: now() });
  return { data: { invitation_update: { id: vars.id } } };
}

async function acceptInvitationAndJoinTeam(...args) {
  const vars = varsFromArgs(...args);
  const options = optionsFromArgs(...args);
  const uid = uidFromOptions(options);
  const email = emailFromOptions(options);
  await db().runTransaction(async (tx) => {
    const teamDocument = teamRef(vars.teamId);
    const workspaceDocument = workspaceRef(vars.teamId);
    const team = await tx.get(teamDocument);
    const workspace = await tx.get(workspaceDocument);
    tx.set(userRef(uid), withTimestamps({ id: uid, email, selectedTeamId: vars.teamId }, true), {
      merge: true,
    });
    if (!workspace.exists) {
      tx.set(
        workspaceDocument,
        withTimestamps(
          {
            ownerUid: firstTeamMember(team) ?? uid,
            name: team.get("name") ?? vars.teamId,
          },
          true,
        ),
      );
    }
    tx.set(workspaceMemberRef(vars.teamId, uid), withTimestamps({ role: "member" }, true), {
      merge: true,
    });
    tx.update(db().collection(firestoreCollectionPaths.invitations).doc(vars.id), {
      status: InvitationStatus.ACCEPTED,
      acceptedById: uid,
      acceptedAt: now(),
      updatedAt: now(),
    });
    tx.update(teamDocument, { members: FieldValue.arrayUnion(uid), updatedAt: now() });
  });
  return {
    data: {
      user_upsert: { id: uid },
      invitation_update: { id: vars.id },
      teamMember_upsert: { teamId: vars.teamId, userId: uid },
    },
  };
}

async function createBuildJob(...args) {
  const vars = varsFromArgs(...args);
  await db()
    .collection(firestoreCollectionPaths.buildJobs)
    .doc(vars.id)
    .set(withTimestamps(vars, true));
  return { data: { buildJob_insert: { id: vars.id } } };
}

async function getBuildJob(...args) {
  const vars = varsFromArgs(...args);
  return {
    data: { buildJob: (await getDoc(firestoreCollectionPaths.buildJobs, vars.id)) ?? null },
  };
}

async function updateBuildJobStatus(...args) {
  const vars = varsFromArgs(...args);
  await db()
    .collection(firestoreCollectionPaths.buildJobs)
    .doc(vars.id)
    .update({ status: vars.status, updatedAt: now() });
  return { data: { buildJob_update: { id: vars.id } } };
}

async function listBuildJobsByWorkflowRun(...args) {
  const vars = varsFromArgs(...args);
  const buildJobs = await queryAll(
    db()
      .collection(firestoreCollectionPaths.buildJobs)
      .where("workflowRunId", "==", vars.workflowRunId)
      .orderBy("createdAt"),
  );
  return { data: { buildJobs } };
}

async function listWaitingBuildJobs(...args) {
  const vars = varsFromArgs(...args);
  const buildJobs = await queryAll(
    db()
      .collection(firestoreCollectionPaths.buildJobs)
      .where("workflowRunId", "==", vars.workflowRunId)
      .where("status", "==", BuildJobStatus.WAITING),
  );
  return { data: { buildJobs } };
}

async function cancelMatrixSiblingBuildJobs(...args) {
  const vars = varsFromArgs(...args);
  const workflowRunId = vars.workflowRunId;
  const matrixGroupKey = vars.matrixGroupKey;
  const excludingBuildJobId = vars.excludingBuildJobId;
  if (!workflowRunId || !matrixGroupKey) return { data: { cancelledBuildJobIds: [] } };

  const candidates = await db()
    .collection(firestoreCollectionPaths.buildJobs)
    .where("workflowRunId", "==", workflowRunId)
    .where("matrixGroupKey", "==", matrixGroupKey)
    .get();
  const cancellableStatuses = new Set([
    BuildJobStatus.WAITING,
    BuildJobStatus.QUEUED,
    BuildJobStatus.IN_PROGRESS,
  ]);
  const batch = db().batch();
  const cancelledBuildJobIds = [];
  for (const doc of candidates.docs) {
    if (doc.id === excludingBuildJobId) continue;
    const status = doc.data().status;
    if (!cancellableStatuses.has(status)) continue;
    batch.update(doc.ref, {
      status: BuildJobStatus.CANCELLED,
      completedAt: now(),
      updatedAt: now(),
    });
    cancelledBuildJobIds.push(doc.id);
  }
  if (cancelledBuildJobIds.length > 0) {
    await batch.commit();
  }
  return { data: { cancelledBuildJobIds } };
}

async function tryMarkCiNotificationSent(...args) {
  const vars = varsFromArgs(...args);
  const id = vars.id;
  if (typeof id !== "string" || id.length === 0) {
    return { data: { inserted: false } };
  }

  const ref = db().collection(firestoreCollectionPaths.ciNotifications).doc(id);
  const inserted = await db().runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (snap.exists) return false;
    tx.set(
      ref,
      withTimestamps(
        {
          id: ref.id,
          owner: vars.owner ?? null,
          repo: vars.repo ?? null,
          pullRequestNumber: vars.pullRequestNumber ?? null,
          headSha: vars.headSha ?? null,
          kind: vars.kind ?? "success",
        },
        true,
      ),
    );
    return true;
  });
  return { data: { inserted } };
}

async function claimQueuedBuildJob(...args) {
  const vars = varsFromArgs(...args);
  const platform = String(vars.runsOnPattern ?? "").includes("macos") ? "macos" : "ubuntu";
  const candidates = await db()
    .collection(firestoreCollectionPaths.buildJobs)
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

async function createBuildRunForWorker(...args) {
  const vars = varsFromArgs(...args);
  await db().runTransaction(async (tx) => {
    const job = db().collection(firestoreCollectionPaths.buildJobs).doc(vars.buildJobId);
    tx.set(
      job.collection("runs").doc(vars.id),
      withTimestamps({ id: vars.id, status: "in_progress" }, true),
      { merge: true },
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

async function appendBuildLogForWorker(...args) {
  const vars = varsFromArgs(...args);
  await db()
    .collection(firestoreCollectionPaths.buildJobs)
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
      buildLog_upsert: { buildRunBuildJobId: vars.buildJobId, buildRunId: vars.runId, id: vars.id },
    },
  };
}

async function updateBuildRunStatusForWorker(...args) {
  const vars = varsFromArgs(...args);
  await db()
    .collection(firestoreCollectionPaths.buildJobs)
    .doc(vars.buildJobId)
    .collection("runs")
    .doc(vars.runId)
    .set(withTimestamps({ status: vars.status, conclusion: vars.conclusion ?? null }, false), {
      merge: true,
    });
  return { data: { buildRun_update: { buildJobId: vars.buildJobId, id: vars.runId } } };
}

async function completeBuildJobForWorker(...args) {
  const vars = varsFromArgs(...args);
  await db()
    .collection(firestoreCollectionPaths.buildJobs)
    .doc(vars.id)
    .update({
      status: vars.status,
      completedAt: timestamp(vars.completedAt),
      updatedAt: now(),
    });
  return { data: { buildJob_update: { id: vars.id } } };
}

async function listLatestBuildLogs(...args) {
  const vars = varsFromArgs(...args);
  const buildLogs = await queryAll(
    db()
      .collection(firestoreCollectionPaths.buildJobs)
      .doc(vars.buildJobId)
      .collection("runs")
      .doc(vars.runId)
      .collection("logs")
      .orderBy("timestamp", "desc")
      .limit(vars.limit ?? 2),
  );
  return { data: { buildLogs } };
}

async function listTeamNotificationUsers(...args) {
  return listTeamMembers(...args);
}

async function updateUserFcmTokens(...args) {
  const vars = varsFromArgs(...args);
  await userRef(vars.id).set(withTimestamps({ fcmTokens: vars.fcmTokens ?? [] }), { merge: true });
  return { data: { user_update: { id: vars.id } } };
}

async function updateBuildJobFailureSummary(...args) {
  const vars = varsFromArgs(...args);
  await db()
    .collection(firestoreCollectionPaths.buildJobs)
    .doc(vars.id)
    .update({
      failureSummaryStatus: vars.failureSummaryStatus ?? null,
      failureSummary: vars.failureSummary ?? null,
      failureSummaryModel: vars.failureSummaryModel ?? null,
      failureSummaryDurationMs: vars.failureSummaryDurationMs ?? null,
      updatedAt: now(),
    });
  return { data: { buildJob_update: { id: vars.id } } };
}

async function findSecretByNameForTeam(...args) {
  const vars = varsFromArgs(...args);
  const secrets = await queryAll(
    db()
      .collection(firestoreCollectionPaths.secrets)
      .where("teamId", "==", vars.teamId)
      .where("name", "==", vars.name)
      .limit(1),
  );
  return { data: { secrets } };
}

async function getSecretsByNamesForTeam(...args) {
  const vars = varsFromArgs(...args);
  if (!Array.isArray(vars.names) || vars.names.length === 0) return { data: { secrets: [] } };
  const secrets = await queryAll(
    db()
      .collection(firestoreCollectionPaths.secrets)
      .where("teamId", "==", vars.teamId)
      .where("name", "in", vars.names.slice(0, 10)),
  );
  return { data: { secrets } };
}

async function listWorkerSecrets(...args) {
  const vars = varsFromArgs(...args);
  const secrets = await queryAll(
    db().collection(firestoreCollectionPaths.secrets).where("teamId", "==", vars.teamId),
  );
  return { data: { secrets } };
}

async function createSecretMetadata(...args) {
  const vars = varsFromArgs(...args);
  await db()
    .collection(firestoreCollectionPaths.secrets)
    .doc(vars.id)
    .set(
      withTimestamps(
        { id: vars.id, name: vars.name, teamId: vars.teamId, pathToSecret: vars.pathToSecret },
        true,
      ),
    );
  return { data: { secret_insert: { id: vars.id } } };
}

async function getSecretPathForTeam(...args) {
  const vars = varsFromArgs(...args);
  const secret = await getDoc(firestoreCollectionPaths.secrets, vars.id);
  return { data: { secret: secret && secret.teamId === vars.teamId ? secret : null } };
}

async function updateSecretMetadata(...args) {
  const vars = varsFromArgs(...args);
  await db()
    .collection(firestoreCollectionPaths.secrets)
    .doc(vars.id)
    .update({ name: vars.name, updatedAt: now() });
  return { data: { secret_update: { id: vars.id } } };
}

async function deleteSecretMetadata(...args) {
  const vars = varsFromArgs(...args);
  await db().collection(firestoreCollectionPaths.secrets).doc(vars.id).delete();
  return { data: { secret_delete: { id: vars.id } } };
}

async function listWorkflowsForTeam(...args) {
  const vars = varsFromArgs(...args);
  const workflows = await queryAll(
    db()
      .collection(firestoreCollectionPaths.workflows)
      .where("teamId", "==", vars.teamId)
      .orderBy("updatedAt", "desc"),
  );
  return { data: { workflows } };
}

async function updateWorkflowSecretKeys(...args) {
  const vars = varsFromArgs(...args);
  await db()
    .collection(firestoreCollectionPaths.workflows)
    .doc(vars.id)
    .update({ workflowSteps: vars.workflowSteps ?? [], updatedAt: now() });
  return { data: { workflow_update: { id: vars.id } } };
}

async function listWorkerEnvironmentVariables(...args) {
  const vars = varsFromArgs(...args);
  const environmentVariables = await queryAll(
    db().collection(firestoreCollectionPaths.env).where("teamId", "==", vars.teamId).orderBy("key"),
  );
  return { data: { environmentVariables } };
}

async function updateEnvironmentVariableValueForWorker(...args) {
  const vars = varsFromArgs(...args);
  await db()
    .collection(firestoreCollectionPaths.env)
    .doc(vars.id)
    .update({ value: vars.value, updatedAt: now() });
  return { data: { environmentVariable_update: { id: vars.id } } };
}
export {
  acceptInvitationAndJoinTeam,
  addTeamMember,
  appendBuildLogForWorker,
  cancelMatrixSiblingBuildJobs,
  claimQueuedBuildJob,
  completeBuildJobForWorker,
  createBuildJob,
  createBuildRunForWorker,
  createInvitation,
  createSecretMetadata,
  deleteSecretMetadata,
  expireInvitation,
  findExistingPendingInvitation,
  findSecretByNameForTeam,
  findTeamByInstallation,
  getBuildJob,
  getInvitationByToken,
  getSecretPathForTeam,
  getSecretsByNamesForTeam,
  getTeamById,
  getTeamForMember,
  linkGitHubInstallation,
  listBuildJobsByWorkflowRun,
  listLatestBuildLogs,
  listMyPendingInvitations,
  listTeamMembers,
  listTeamNotificationUsers,
  listWaitingBuildJobs,
  listWorkerEnvironmentVariables,
  listWorkerSecrets,
  listWorkflowsForTeam,
  reinviteInvitation,
  tryMarkCiNotificationSent,
  updateBuildJobFailureSummary,
  updateBuildJobStatus,
  updateBuildRunStatusForWorker,
  updateEnvironmentVariableValueForWorker,
  updateSecretMetadata,
  updateUserFcmTokens,
  updateWorkflowSecretKeys,
};
