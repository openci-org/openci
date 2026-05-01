import { getApps, initializeApp } from "firebase-admin/app";
import { FieldValue, Timestamp, getFirestore } from "firebase-admin/firestore";
import { logger, setGlobalOptions } from "firebase-functions/v2";
import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { HttpsError, onCall, type CallableRequest } from "firebase-functions/v2/https";

if (getApps().length === 0) {
  initializeApp();
}

setGlobalOptions({
  region: "asia-northeast1",
  maxInstances: 10,
});

interface WorkspaceRequest {
  workspaceId: string;
}

interface ConnectGitHubRequest extends WorkspaceRequest {
  accessToken: string;
}

interface StartGitHubDeviceFlowRequest extends WorkspaceRequest {
  clientId: string;
}

interface StartGitHubDeviceFlowResponse {
  deviceCode: string;
  userCode: string;
  verificationUri: string;
  expiresIn: number;
  interval: number;
}

interface CompleteGitHubDeviceFlowRequest extends WorkspaceRequest {
  clientId: string;
  deviceCode: string;
}

interface GitHubRepository {
  fullName: string;
  name: string;
  owner: string;
  private: boolean;
  defaultBranch: string;
}

interface ListGitHubRepositoriesResponse {
  repositories: GitHubRepository[];
}

interface ImportGitHubIssuesResponse {
  imported: number;
  repositories: number;
}

interface SyncGitHubIssuesResponse {
  synced: number;
  failed: number;
}

interface GitHubUserResponse {
  login?: unknown;
  avatar_url?: unknown;
}

interface GitHubDeviceCodeResponse {
  device_code?: unknown;
  user_code?: unknown;
  verification_uri?: unknown;
  expires_in?: unknown;
  interval?: unknown;
  error?: unknown;
  error_description?: unknown;
}

interface GitHubDeviceTokenResponse {
  access_token?: unknown;
  token_type?: unknown;
  scope?: unknown;
  error?: unknown;
  error_description?: unknown;
}

interface GitHubRepositoriesResponseItem {
  full_name?: unknown;
  name?: unknown;
  owner?: { login?: unknown };
  private?: unknown;
  default_branch?: unknown;
}

interface GitHubIssueResponseItem {
  node_id?: unknown;
  number?: unknown;
  title?: unknown;
  body?: unknown;
  html_url?: unknown;
  state?: unknown;
  comments?: unknown;
  labels?: Array<string | { name?: unknown }>;
  assignee?: { login?: unknown } | null;
  assignees?: Array<{ login?: unknown }>;
  updated_at?: unknown;
  created_at?: unknown;
  pull_request?: unknown;
}

const db = getFirestore();

function requireNonEmptyString(value: unknown, field: string): string {
  if (typeof value !== "string" || value.trim().length === 0) {
    throw new HttpsError("invalid-argument", `${field} is required`);
  }
  return value.trim();
}

function requireUid(auth: CallableRequest["auth"]): string {
  if (!auth) {
    throw new HttpsError("unauthenticated", "Unauthenticated");
  }
  return auth.uid;
}

async function verifyWorkspaceMember(
  auth: CallableRequest["auth"],
  workspaceId: string,
): Promise<string> {
  const uid = requireUid(auth);
  const member = await db.doc(`workspaces/${workspaceId}/members/${uid}`).get();
  if (!member.exists) {
    throw new HttpsError("permission-denied", "Workspace membership is required");
  }
  return uid;
}

async function getGitHubToken(uid: string): Promise<string> {
  const tokenDoc = await db.doc(`users/${uid}/private/github`).get();
  const token = tokenDoc.get("accessToken");
  if (typeof token !== "string" || token.length === 0) {
    throw new HttpsError("failed-precondition", "GitHub is not connected");
  }
  return token;
}

async function githubRequest<T>({
  path,
  token,
  method = "GET",
  body,
  queryParameters,
}: {
  path: string;
  token: string;
  method?: "GET" | "PATCH";
  body?: unknown;
  queryParameters?: Record<string, string | number | boolean>;
}): Promise<T> {
  const url = new URL(path, "https://api.github.com");
  for (const [key, value] of Object.entries(queryParameters ?? {})) {
    url.searchParams.set(key, String(value));
  }

  const response = await fetch(url, {
    method,
    headers: {
      accept: "application/vnd.github+json",
      authorization: `Bearer ${token}`,
      "content-type": "application/json",
      "user-agent": "Ima-Functions",
      "x-github-api-version": "2022-11-28",
    },
    body: body === undefined ? undefined : JSON.stringify(body),
  });

  if (!response.ok) {
    const message = await response.text();
    throw new Error(`GitHub request failed: ${response.status} ${message}`);
  }

  return (await response.json()) as T;
}

async function githubOAuthRequest<T>(
  path: string,
  body: Record<string, string>,
): Promise<T> {
  const response = await fetch(new URL(path, "https://github.com"), {
    method: "POST",
    headers: {
      accept: "application/json",
      "content-type": "application/json",
      "user-agent": "Ima-Functions",
    },
    body: JSON.stringify(body),
  });

  if (!response.ok) {
    const message = await response.text();
    throw new Error(`GitHub OAuth request failed: ${response.status} ${message}`);
  }

  return (await response.json()) as T;
}

function repoDocId(fullName: string): string {
  return fullName.replace(/\//gu, "__");
}

function issueDocId(owner: string, repo: string, number: number): string {
  return `gh_${owner}_${repo}_${number}`.replace(/[^a-zA-Z0-9_-]/gu, "_");
}

function asString(value: unknown, fallback = ""): string {
  return typeof value === "string" && value.length > 0 ? value : fallback;
}

function asNumber(value: unknown, fallback = 0): number {
  return typeof value === "number" ? value : fallback;
}

function asTimestamp(value: unknown): Timestamp | null {
  if (typeof value !== "string") {
    return null;
  }
  const date = new Date(value);
  return Number.isNaN(date.valueOf()) ? null : Timestamp.fromDate(date);
}

function issueLabels(issue: GitHubIssueResponseItem): string[] {
  return (issue.labels ?? [])
    .map((label) => {
      if (typeof label === "string") {
        return label;
      }
      return asString(label.name);
    })
    .filter((label) => label.length > 0);
}

function issueAssignee(issue: GitHubIssueResponseItem): string {
  const assignees = issue.assignees ?? [];
  const firstAssignee = assignees
    .map((assignee) => asString(assignee.login))
    .find((login) => login.length > 0);
  return firstAssignee ?? asString(issue.assignee?.login, "-");
}

async function selectedRepositories(workspaceId: string): Promise<GitHubRepository[]> {
  const snapshot = await db.collection(`workspaces/${workspaceId}/githubRepos`).get();
  return snapshot.docs
    .map((doc) => doc.data())
    .filter((repo) => repo.enabled === true)
    .map((repo) => ({
      fullName: asString(repo.fullName),
      name: asString(repo.name),
      owner: asString(repo.owner),
      private: repo.private === true,
      defaultBranch: asString(repo.defaultBranch, "main"),
    }))
    .filter((repo) => repo.fullName.includes("/"));
}

export const connectGitHub = onCall<ConnectGitHubRequest, Promise<{ login: string }>>(
  async (request) => {
    const workspaceId = requireNonEmptyString(request.data?.workspaceId, "workspaceId");
    const accessToken = requireNonEmptyString(request.data?.accessToken, "accessToken");
    const uid = await verifyWorkspaceMember(request.auth, workspaceId);

    try {
      const user = await githubRequest<GitHubUserResponse>({
        path: "/user",
        token: accessToken,
      });
      const login = asString(user.login);
      if (login.length === 0) {
        throw new HttpsError("failed-precondition", "GitHub user could not be resolved");
      }

      const now = FieldValue.serverTimestamp();
      await db.doc(`users/${uid}/private/github`).set(
        {
          accessToken,
          login,
          avatarUrl: asString(user.avatar_url),
          updatedAt: now,
        },
        { merge: true },
      );
      await db.doc(`workspaces/${workspaceId}/githubConnections/default`).set(
        {
          connected: true,
          login,
          updatedAt: now,
        },
        { merge: true },
      );

      return { login };
    } catch (error) {
      if (error instanceof HttpsError) {
        throw error;
      }
      logger.error("Failed to connect GitHub", { workspaceId, uid, error });
      throw new HttpsError("internal", "Failed to connect GitHub");
    }
  },
);

export const startGitHubDeviceFlow = onCall<
  StartGitHubDeviceFlowRequest,
  Promise<StartGitHubDeviceFlowResponse>
>(async (request) => {
  let workspaceId = "unknown";
  let step = "init";
  try {
    workspaceId = requireNonEmptyString(request.data?.workspaceId, "workspaceId");
    const clientId = requireNonEmptyString(request.data?.clientId, "clientId");
    step = "verifyMember";
    await verifyWorkspaceMember(request.auth, workspaceId);

    step = "githubRequest";
    logger.info("Starting device flow request", { workspaceId, clientId: clientId.substring(0, 8) });
    const data = await githubOAuthRequest<GitHubDeviceCodeResponse>("/login/device/code", {
      client_id: clientId,
      scope: "read:user repo",
    });
    logger.info("Device flow response received", { workspaceId, hasError: !!data.error, hasUserCode: !!data.user_code });

    const error = asString(data.error);
    if (error.length > 0) {
      throw new HttpsError(
        "failed-precondition",
        asString(data.error_description, error),
      );
    }

    return {
      deviceCode: requireNonEmptyString(data.device_code, "device_code"),
      userCode: requireNonEmptyString(data.user_code, "user_code"),
      verificationUri: requireNonEmptyString(data.verification_uri, "verification_uri"),
      expiresIn: asNumber(data.expires_in, 900),
      interval: asNumber(data.interval, 5),
    };
  } catch (error) {
    if (error instanceof HttpsError) {
      throw error;
    }
    const message = error instanceof Error ? `${error.name}: ${error.message}` : String(error);
    const stack = error instanceof Error ? error.stack : undefined;
    logger.error(`startGitHubDeviceFlow failed at step=${step}`, { workspaceId, message, stack });
    throw new HttpsError("internal", `step=${step}: ${message}`);
  }
});

export const completeGitHubDeviceFlow = onCall<
  CompleteGitHubDeviceFlowRequest,
  Promise<{ login: string }>
>(async (request) => {
  const workspaceId = requireNonEmptyString(request.data?.workspaceId, "workspaceId");
  const clientId = requireNonEmptyString(request.data?.clientId, "clientId");
  const deviceCode = requireNonEmptyString(request.data?.deviceCode, "deviceCode");
  const uid = await verifyWorkspaceMember(request.auth, workspaceId);

  try {
    const data = await githubOAuthRequest<GitHubDeviceTokenResponse>("/login/oauth/access_token", {
      client_id: clientId,
      device_code: deviceCode,
      grant_type: "urn:ietf:params:oauth:grant-type:device_code",
    });

    const error = asString(data.error);
    if (error.length > 0) {
      if (error === "authorization_pending") {
        throw new HttpsError("failed-precondition", "authorization_pending");
      }
      if (error === "slow_down") {
        throw new HttpsError("resource-exhausted", "slow_down");
      }
      if (error === "expired_token") {
        throw new HttpsError("deadline-exceeded", "expired_token");
      }
      if (error === "access_denied") {
        throw new HttpsError("permission-denied", "access_denied");
      }
      throw new HttpsError("failed-precondition", asString(data.error_description, error));
    }

    const accessToken = requireNonEmptyString(data.access_token, "access_token");
    const user = await githubRequest<GitHubUserResponse>({
      path: "/user",
      token: accessToken,
    });
    const login = asString(user.login);
    if (login.length === 0) {
      throw new HttpsError("failed-precondition", "GitHub user could not be resolved");
    }

    const now = FieldValue.serverTimestamp();
    await db.doc(`users/${uid}/private/github`).set(
      {
        accessToken,
        login,
        avatarUrl: asString(user.avatar_url),
        updatedAt: now,
      },
      { merge: true },
    );
    await db.doc(`workspaces/${workspaceId}/githubConnections/default`).set(
      {
        connected: true,
        login,
        updatedAt: now,
      },
      { merge: true },
    );

    return { login };
  } catch (error) {
    if (error instanceof HttpsError) {
      throw error;
    }
    logger.error("Failed to complete GitHub device flow", { workspaceId, uid, error });
    throw new HttpsError("internal", "Failed to complete GitHub device flow");
  }
});

export const listGitHubRepositories = onCall<
  WorkspaceRequest,
  Promise<ListGitHubRepositoriesResponse>
>(async (request) => {
  const workspaceId = requireNonEmptyString(request.data?.workspaceId, "workspaceId");
  const uid = await verifyWorkspaceMember(request.auth, workspaceId);
  const token = await getGitHubToken(uid);

  try {
    const repositories: GitHubRepository[] = [];
    let page = 1;

    while (true) {
      const pageRepos = await githubRequest<GitHubRepositoriesResponseItem[]>({
        path: "/user/repos",
        token,
        queryParameters: {
          affiliation: "owner,collaborator,organization_member",
          sort: "updated",
          direction: "desc",
          per_page: 100,
          page,
        },
      });

      for (const repo of pageRepos) {
        const fullName = asString(repo.full_name);
        const [ownerFallback, nameFallback] = fullName.split("/");
        repositories.push({
          fullName,
          name: asString(repo.name, nameFallback ?? ""),
          owner: asString(repo.owner?.login, ownerFallback ?? ""),
          private: repo.private === true,
          defaultBranch: asString(repo.default_branch, "main"),
        });
      }

      if (pageRepos.length < 100 || page >= 10) {
        break;
      }
      page += 1;
    }

    return {
      repositories: repositories.filter((repo) => repo.fullName.includes("/")),
    };
  } catch (error) {
    logger.error("Failed to list Ima GitHub repositories", { workspaceId, uid, error });
    throw new HttpsError("internal", "Failed to list GitHub repositories");
  }
});

export const importGitHubIssues = onCall<
  WorkspaceRequest,
  Promise<ImportGitHubIssuesResponse>
>(async (request) => {
  const workspaceId = requireNonEmptyString(request.data?.workspaceId, "workspaceId");
  const uid = await verifyWorkspaceMember(request.auth, workspaceId);
  const token = await getGitHubToken(uid);
  const repositories = await selectedRepositories(workspaceId);
  if (repositories.length === 0) {
    throw new HttpsError("failed-precondition", "No repositories are selected");
  }

  let imported = 0;
  let batch = db.batch();
  let pendingWrites = 0;

  async function commitIfNeeded(force = false) {
    if (pendingWrites === 0 || (!force && pendingWrites < 400)) {
      return;
    }
    await batch.commit();
    batch = db.batch();
    pendingWrites = 0;
  }

  try {
    for (const repository of repositories) {
      const [owner, repo] = repository.fullName.split("/");
      if (!owner || !repo) {
        continue;
      }

      let page = 1;
      let repoImported = 0;
      while (true) {
        const pageIssues = await githubRequest<GitHubIssueResponseItem[]>({
          path: `/repos/${owner}/${repo}/issues`,
          token,
          queryParameters: { state: "open", per_page: 100, page },
        });

        for (const issue of pageIssues) {
          if (issue.pull_request !== undefined) {
            continue;
          }
          const number = asNumber(issue.number);
          const nodeId = asString(issue.node_id);
          if (number <= 0 || nodeId.length === 0) {
            continue;
          }

          const docRef = db
            .collection(`workspaces/${workspaceId}/issues`)
            .doc(issueDocId(owner, repo, number));
          const existing = await docRef.get();
          const existingData = existing.data() ?? {};
          batch.set(
            docRef,
            {
              title: asString(issue.title, `#${number}`),
              body: asString(issue.body),
              repo: repository.fullName,
              assignee: issueAssignee(issue),
              labels: issueLabels(issue),
              comments: asNumber(issue.comments),
              priority: asString(existingData.priority, "medium"),
              statusId: asString(existingData.statusId, "triage"),
              rank: asNumber(existingData.rank, Date.now() + imported),
              githubIssue: {
                nodeId,
                owner,
                repo,
                number,
                url: asString(issue.html_url),
                state: asString(issue.state, "open"),
              },
              githubUpdatedAt: asTimestamp(issue.updated_at),
              githubCreatedAt: asTimestamp(issue.created_at),
              updatedAt: FieldValue.serverTimestamp(),
              createdAt: existing.exists
                ? existingData.createdAt ?? FieldValue.serverTimestamp()
                : FieldValue.serverTimestamp(),
            },
            { merge: true },
          );
          pendingWrites += 1;
          imported += 1;
          repoImported += 1;
          await commitIfNeeded();
        }

        if (pageIssues.length < 100 || page >= 10) {
          break;
        }
        page += 1;
      }

      batch.set(
        db.doc(`workspaces/${workspaceId}/githubRepos/${repoDocId(repository.fullName)}`),
        {
          ...repository,
          enabled: true,
          lastImportedAt: FieldValue.serverTimestamp(),
          lastImportError: null,
          lastImportCount: repoImported,
        },
        { merge: true },
      );
      pendingWrites += 1;
      await commitIfNeeded();
    }

    await commitIfNeeded(true);
    return { imported, repositories: repositories.length };
  } catch (error) {
    logger.error("Failed to import Ima GitHub issues", { workspaceId, uid, error });
    throw new HttpsError("internal", "Failed to import GitHub issues");
  }
});

export const syncGitHubIssues = onCall<WorkspaceRequest, Promise<SyncGitHubIssuesResponse>>(
  async (request) => {
    const workspaceId = requireNonEmptyString(request.data?.workspaceId, "workspaceId");
    const uid = await verifyWorkspaceMember(request.auth, workspaceId);
    const token = await getGitHubToken(uid);
    const outbox = await db
      .collection(`workspaces/${workspaceId}/syncOutbox`)
      .where("status", "==", "pending")
      .orderBy("createdAt")
      .limit(50)
      .get();

    let synced = 0;
    let failed = 0;

    for (const operation of outbox.docs) {
      const issueId = asString(operation.get("issueId"));
      try {
        const issueDoc = await db.doc(`workspaces/${workspaceId}/issues/${issueId}`).get();
        const issue = issueDoc.data();
        const githubIssue = issue?.githubIssue as Record<string, unknown> | undefined;
        if (!issue || !githubIssue) {
          await operation.ref.set(
            { status: "skipped", updatedAt: FieldValue.serverTimestamp() },
            { merge: true },
          );
          continue;
        }

        const owner = requireNonEmptyString(githubIssue.owner, "githubIssue.owner");
        const repo = requireNonEmptyString(githubIssue.repo, "githubIssue.repo");
        const number = asNumber(githubIssue.number);
        const assignee = asString(issue.assignee);
        const assignees = assignee.length > 0 && assignee !== "-" ? [assignee] : [];

        await githubRequest({
          path: `/repos/${owner}/${repo}/issues/${number}`,
          token,
          method: "PATCH",
          body: {
            title: asString(issue.title),
            body: asString(issue.body),
            state: asString(issue.statusId) === "done" ? "closed" : "open",
            labels: Array.isArray(issue.labels) ? issue.labels : [],
            assignees,
          },
        });

        await operation.ref.set(
          {
            status: "done",
            syncedAt: FieldValue.serverTimestamp(),
            updatedAt: FieldValue.serverTimestamp(),
          },
          { merge: true },
        );
        synced += 1;
      } catch (error) {
        logger.warn("Failed to sync Ima GitHub issue", { workspaceId, issueId, error });
        await operation.ref.set(
          {
            status: "failed",
            error: error instanceof Error ? error.message : String(error),
            updatedAt: FieldValue.serverTimestamp(),
          },
          { merge: true },
        );
        failed += 1;
      }
    }

    return { synced, failed };
  },
);

export const autoSyncIssueToGitHub = onDocumentWritten(
  "workspaces/{workspaceId}/issues/{issueId}",
  async (event) => {
    const after = event.data?.after?.data();
    const before = event.data?.before?.data();
    if (!after) {
      return;
    }

    const githubIssue = after.githubIssue as Record<string, unknown> | undefined;
    if (!githubIssue) {
      return;
    }

    const owner = asString(githubIssue.owner);
    const repo = asString(githubIssue.repo);
    const number = asNumber(githubIssue.number);
    if (owner.length === 0 || repo.length === 0 || number <= 0) {
      return;
    }

    const titleChanged = after.title !== before?.title;
    const bodyChanged = after.body !== before?.body;
    const labelsChanged = JSON.stringify(after.labels) !== JSON.stringify(before?.labels);
    const assigneeChanged = after.assignee !== before?.assignee;
    const statusChanged = after.statusId !== before?.statusId;

    if (!titleChanged && !bodyChanged && !labelsChanged && !assigneeChanged && !statusChanged) {
      return;
    }

    const workspaceId = event.params.workspaceId;
    const workspaceRef = db.doc(`workspaces/${workspaceId}`);
    const workspace = await workspaceRef.get();
    const ownerUid = asString(workspace.data()?.ownerUid);
    if (ownerUid.length === 0) {
      logger.warn("autoSyncIssueToGitHub: no ownerUid", { workspaceId });
      return;
    }

    let token: string;
    try {
      token = await getGitHubToken(ownerUid);
    } catch {
      logger.warn("autoSyncIssueToGitHub: no GitHub token for owner", { workspaceId, ownerUid });
      return;
    }

    const assignee = asString(after.assignee);
    const assignees = assignee.length > 0 && assignee !== "-" ? [assignee] : [];

    try {
      await githubRequest({
        path: `/repos/${owner}/${repo}/issues/${number}`,
        token,
        method: "PATCH",
        body: {
          title: asString(after.title),
          body: asString(after.body),
          state: asString(after.statusId) === "done" ? "closed" : "open",
          labels: Array.isArray(after.labels) ? after.labels : [],
          assignees,
        },
      });
      logger.info("autoSyncIssueToGitHub: synced", { workspaceId, owner, repo, number });
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.error("autoSyncIssueToGitHub: failed", { workspaceId, owner, repo, number, message });
    }
  },
);
