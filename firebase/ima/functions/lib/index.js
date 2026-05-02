"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.autoSyncIssueToGitHub = exports.syncGitHubIssues = exports.createGitHubIssue = exports.importGitHubIssues = exports.listGitHubRepositories = exports.completeGitHubDeviceFlow = exports.startGitHubDeviceFlow = exports.connectGitHub = void 0;
const app_1 = require("firebase-admin/app");
const firestore_1 = require("firebase-admin/firestore");
const v2_1 = require("firebase-functions/v2");
const firestore_2 = require("firebase-functions/v2/firestore");
const https_1 = require("firebase-functions/v2/https");
if ((0, app_1.getApps)().length === 0) {
    (0, app_1.initializeApp)();
}
(0, v2_1.setGlobalOptions)({
    region: "asia-northeast1",
    maxInstances: 10,
});
const db = (0, firestore_1.getFirestore)();
function requireNonEmptyString(value, field) {
    if (typeof value !== "string" || value.trim().length === 0) {
        throw new https_1.HttpsError("invalid-argument", `${field} is required`);
    }
    return value.trim();
}
function requireUid(auth) {
    if (!auth) {
        throw new https_1.HttpsError("unauthenticated", "Unauthenticated");
    }
    return auth.uid;
}
async function verifyWorkspaceMember(auth, workspaceId) {
    const uid = requireUid(auth);
    const member = await db.doc(`workspaces/${workspaceId}/members/${uid}`).get();
    if (!member.exists) {
        throw new https_1.HttpsError("permission-denied", "Workspace membership is required");
    }
    return uid;
}
async function getGitHubToken(uid) {
    const tokenDoc = await db.doc(`users/${uid}/private/github`).get();
    const token = tokenDoc.get("accessToken");
    if (typeof token !== "string" || token.length === 0) {
        throw new https_1.HttpsError("failed-precondition", "GitHub is not connected");
    }
    return token;
}
async function githubRequest({ path, token, method = "GET", body, queryParameters, }) {
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
    return (await response.json());
}
async function githubOAuthRequest(path, body) {
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
    return (await response.json());
}
function repoDocId(fullName) {
    return fullName.replace(/\//gu, "__");
}
function issueDocId(owner, repo, number) {
    return `gh_${owner}_${repo}_${number}`.replace(/[^a-zA-Z0-9_-]/gu, "_");
}
function asString(value, fallback = "") {
    return typeof value === "string" && value.length > 0 ? value : fallback;
}
function asNumber(value, fallback = 0) {
    return typeof value === "number" ? value : fallback;
}
function asTimestamp(value) {
    if (typeof value !== "string") {
        return null;
    }
    const date = new Date(value);
    return Number.isNaN(date.valueOf()) ? null : firestore_1.Timestamp.fromDate(date);
}
function issueLabels(issue) {
    return (issue.labels ?? [])
        .map((label) => {
        if (typeof label === "string") {
            return label;
        }
        return asString(label.name);
    })
        .filter((label) => label.length > 0);
}
function issueAssignee(issue) {
    const assignees = issue.assignees ?? [];
    const firstAssignee = assignees
        .map((assignee) => asString(assignee.login))
        .find((login) => login.length > 0);
    return firstAssignee ?? asString(issue.assignee?.login, "-");
}
async function selectedRepositories(workspaceId) {
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
exports.connectGitHub = (0, https_1.onCall)(async (request) => {
    const workspaceId = requireNonEmptyString(request.data?.workspaceId, "workspaceId");
    const accessToken = requireNonEmptyString(request.data?.accessToken, "accessToken");
    const uid = await verifyWorkspaceMember(request.auth, workspaceId);
    try {
        const user = await githubRequest({
            path: "/user",
            token: accessToken,
        });
        const login = asString(user.login);
        if (login.length === 0) {
            throw new https_1.HttpsError("failed-precondition", "GitHub user could not be resolved");
        }
        const now = firestore_1.FieldValue.serverTimestamp();
        await db.doc(`users/${uid}/private/github`).set({
            accessToken,
            login,
            avatarUrl: asString(user.avatar_url),
            updatedAt: now,
        }, { merge: true });
        await db.doc(`workspaces/${workspaceId}/githubConnections/default`).set({
            connected: true,
            login,
            updatedAt: now,
        }, { merge: true });
        return { login };
    }
    catch (error) {
        if (error instanceof https_1.HttpsError) {
            throw error;
        }
        const message = error instanceof Error ? error.message : String(error);
        v2_1.logger.error("Failed to connect GitHub", { workspaceId, uid, message });
        throw new https_1.HttpsError("internal", "Failed to connect GitHub");
    }
});
exports.startGitHubDeviceFlow = (0, https_1.onCall)(async (request) => {
    let workspaceId = "unknown";
    let step = "init";
    try {
        workspaceId = requireNonEmptyString(request.data?.workspaceId, "workspaceId");
        const clientId = requireNonEmptyString(request.data?.clientId, "clientId");
        step = "verifyMember";
        await verifyWorkspaceMember(request.auth, workspaceId);
        step = "githubRequest";
        v2_1.logger.info("Starting device flow request", { workspaceId, clientId: clientId.substring(0, 8) });
        const data = await githubOAuthRequest("/login/device/code", {
            client_id: clientId,
            scope: "read:user repo",
        });
        v2_1.logger.info("Device flow response received", { workspaceId, hasError: !!data.error, hasUserCode: !!data.user_code });
        const error = asString(data.error);
        if (error.length > 0) {
            throw new https_1.HttpsError("failed-precondition", asString(data.error_description, error));
        }
        return {
            deviceCode: requireNonEmptyString(data.device_code, "device_code"),
            userCode: requireNonEmptyString(data.user_code, "user_code"),
            verificationUri: requireNonEmptyString(data.verification_uri, "verification_uri"),
            expiresIn: asNumber(data.expires_in, 900),
            interval: asNumber(data.interval, 5),
        };
    }
    catch (error) {
        if (error instanceof https_1.HttpsError) {
            throw error;
        }
        const message = error instanceof Error ? `${error.name}: ${error.message}` : String(error);
        const stack = error instanceof Error ? error.stack : undefined;
        v2_1.logger.error(`startGitHubDeviceFlow failed at step=${step}`, { workspaceId, message, stack });
        throw new https_1.HttpsError("internal", `step=${step}: ${message}`);
    }
});
exports.completeGitHubDeviceFlow = (0, https_1.onCall)(async (request) => {
    const workspaceId = requireNonEmptyString(request.data?.workspaceId, "workspaceId");
    const clientId = requireNonEmptyString(request.data?.clientId, "clientId");
    const deviceCode = requireNonEmptyString(request.data?.deviceCode, "deviceCode");
    const uid = await verifyWorkspaceMember(request.auth, workspaceId);
    try {
        const data = await githubOAuthRequest("/login/oauth/access_token", {
            client_id: clientId,
            device_code: deviceCode,
            grant_type: "urn:ietf:params:oauth:grant-type:device_code",
        });
        const error = asString(data.error);
        if (error.length > 0) {
            if (error === "authorization_pending") {
                throw new https_1.HttpsError("failed-precondition", "authorization_pending");
            }
            if (error === "slow_down") {
                throw new https_1.HttpsError("resource-exhausted", "slow_down");
            }
            if (error === "expired_token") {
                throw new https_1.HttpsError("deadline-exceeded", "expired_token");
            }
            if (error === "access_denied") {
                throw new https_1.HttpsError("permission-denied", "access_denied");
            }
            throw new https_1.HttpsError("failed-precondition", asString(data.error_description, error));
        }
        const accessToken = requireNonEmptyString(data.access_token, "access_token");
        const user = await githubRequest({
            path: "/user",
            token: accessToken,
        });
        const login = asString(user.login);
        if (login.length === 0) {
            throw new https_1.HttpsError("failed-precondition", "GitHub user could not be resolved");
        }
        const now = firestore_1.FieldValue.serverTimestamp();
        await db.doc(`users/${uid}/private/github`).set({
            accessToken,
            login,
            avatarUrl: asString(user.avatar_url),
            updatedAt: now,
        }, { merge: true });
        await db.doc(`workspaces/${workspaceId}/githubConnections/default`).set({
            connected: true,
            login,
            updatedAt: now,
        }, { merge: true });
        return { login };
    }
    catch (error) {
        if (error instanceof https_1.HttpsError) {
            throw error;
        }
        const message = error instanceof Error ? error.message : String(error);
        v2_1.logger.error("Failed to complete GitHub device flow", { workspaceId, uid, message });
        throw new https_1.HttpsError("internal", "Failed to complete GitHub device flow");
    }
});
exports.listGitHubRepositories = (0, https_1.onCall)(async (request) => {
    const workspaceId = requireNonEmptyString(request.data?.workspaceId, "workspaceId");
    const uid = await verifyWorkspaceMember(request.auth, workspaceId);
    const token = await getGitHubToken(uid);
    try {
        const repositories = [];
        let page = 1;
        while (true) {
            const pageRepos = await githubRequest({
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
    }
    catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        v2_1.logger.error("Failed to list Ima GitHub repositories", { workspaceId, uid, message });
        throw new https_1.HttpsError("internal", "Failed to list GitHub repositories");
    }
});
exports.importGitHubIssues = (0, https_1.onCall)(async (request) => {
    const workspaceId = requireNonEmptyString(request.data?.workspaceId, "workspaceId");
    const uid = await verifyWorkspaceMember(request.auth, workspaceId);
    const token = await getGitHubToken(uid);
    const repositories = await selectedRepositories(workspaceId);
    if (repositories.length === 0) {
        throw new https_1.HttpsError("failed-precondition", "No repositories are selected");
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
                const pageIssues = await githubRequest({
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
                    batch.set(docRef, {
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
                        updatedAt: firestore_1.FieldValue.serverTimestamp(),
                        createdAt: existing.exists
                            ? existingData.createdAt ?? firestore_1.FieldValue.serverTimestamp()
                            : firestore_1.FieldValue.serverTimestamp(),
                    }, { merge: true });
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
            batch.set(db.doc(`workspaces/${workspaceId}/githubRepos/${repoDocId(repository.fullName)}`), {
                ...repository,
                enabled: true,
                lastImportedAt: firestore_1.FieldValue.serverTimestamp(),
                lastImportError: null,
                lastImportCount: repoImported,
            }, { merge: true });
            pendingWrites += 1;
            await commitIfNeeded();
        }
        await commitIfNeeded(true);
        return { imported, repositories: repositories.length };
    }
    catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        v2_1.logger.error("Failed to import Ima GitHub issues", { workspaceId, uid, message });
        throw new https_1.HttpsError("internal", "Failed to import GitHub issues");
    }
});
exports.createGitHubIssue = (0, https_1.onCall)(async (request) => {
    const workspaceId = requireNonEmptyString(request.data?.workspaceId, "workspaceId");
    const uid = await verifyWorkspaceMember(request.auth, workspaceId);
    const token = await getGitHubToken(uid);
    const title = requireNonEmptyString(request.data?.title, "title");
    const repoFullName = requireNonEmptyString(request.data?.repo, "repo");
    const [owner, repo] = repoFullName.split("/");
    if (!owner || !repo) {
        throw new https_1.HttpsError("invalid-argument", "repo must be owner/repo");
    }
    const body = asString(request.data?.body);
    const assignee = asString(request.data?.assignee);
    const labels = Array.isArray(request.data?.labels)
        ? request.data.labels.filter((label) => typeof label === "string" && label.length > 0)
        : [];
    const githubAssignee = assignee.startsWith("@") ? assignee.slice(1) : "";
    const assignees = githubAssignee.length > 0 ? [githubAssignee] : [];
    try {
        v2_1.logger.info("Creating GitHub issue", { workspaceId, repoFullName, owner, repo, title });
        const issue = await githubRequest({
            path: `/repos/${owner}/${repo}/issues`,
            token,
            method: "POST",
            body: {
                title,
                body,
                labels,
                assignees,
            },
        });
        const number = asNumber(issue.number);
        const nodeId = asString(issue.node_id);
        if (number <= 0 || nodeId.length === 0) {
            throw new https_1.HttpsError("failed-precondition", "GitHub issue could not be created");
        }
        const issueId = issueDocId(owner, repo, number);
        const docRef = db.doc(`workspaces/${workspaceId}/issues/${issueId}`);
        await docRef.set({
            title: asString(issue.title, title),
            body: asString(issue.body, body),
            repo: repoFullName,
            assignee: issueAssignee(issue),
            labels: issueLabels(issue),
            comments: asNumber(issue.comments),
            priority: asString(request.data?.priority, "medium"),
            statusId: asString(request.data?.statusId, "triage"),
            rank: asNumber(request.data?.rank, Date.now()),
            dueDate: asTimestamp(request.data?.dueDate),
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
            updatedAt: firestore_1.FieldValue.serverTimestamp(),
            createdAt: firestore_1.FieldValue.serverTimestamp(),
        }, { merge: true });
        return {
            issueId,
            number,
            url: asString(issue.html_url),
        };
    }
    catch (error) {
        if (error instanceof https_1.HttpsError) {
            throw error;
        }
        const message = error instanceof Error ? error.message : String(error);
        const stack = error instanceof Error ? error.stack : undefined;
        v2_1.logger.error("Failed to create Ima GitHub issue", { workspaceId, uid, repoFullName, message, stack });
        throw new https_1.HttpsError("internal", `Failed to create GitHub issue: ${message}`);
    }
});
exports.syncGitHubIssues = (0, https_1.onCall)(async (request) => {
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
            const githubIssue = issue?.githubIssue;
            if (!issue || !githubIssue) {
                await operation.ref.set({ status: "skipped", updatedAt: firestore_1.FieldValue.serverTimestamp() }, { merge: true });
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
            await operation.ref.set({
                status: "done",
                syncedAt: firestore_1.FieldValue.serverTimestamp(),
                updatedAt: firestore_1.FieldValue.serverTimestamp(),
            }, { merge: true });
            synced += 1;
        }
        catch (error) {
            v2_1.logger.warn("Failed to sync Ima GitHub issue", { workspaceId, issueId, error });
            await operation.ref.set({
                status: "failed",
                error: error instanceof Error ? error.message : String(error),
                updatedAt: firestore_1.FieldValue.serverTimestamp(),
            }, { merge: true });
            failed += 1;
        }
    }
    return { synced, failed };
});
exports.autoSyncIssueToGitHub = (0, firestore_2.onDocumentWritten)("workspaces/{workspaceId}/issues/{issueId}", async (event) => {
    const after = event.data?.after?.data();
    const before = event.data?.before?.data();
    if (!after) {
        return;
    }
    const githubIssue = after.githubIssue;
    if (!githubIssue) {
        return;
    }
    const owner = asString(githubIssue.owner);
    const repo = asString(githubIssue.repo);
    const number = asNumber(githubIssue.number);
    if (owner.length === 0 || repo.length === 0 || number <= 0) {
        return;
    }
    if (!before) {
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
        v2_1.logger.warn("autoSyncIssueToGitHub: no ownerUid", { workspaceId });
        return;
    }
    let token;
    try {
        token = await getGitHubToken(ownerUid);
    }
    catch {
        v2_1.logger.warn("autoSyncIssueToGitHub: no GitHub token for owner", { workspaceId, ownerUid });
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
        v2_1.logger.info("autoSyncIssueToGitHub: synced", { workspaceId, owner, repo, number });
    }
    catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        v2_1.logger.error("autoSyncIssueToGitHub: failed", { workspaceId, owner, repo, number, message });
    }
});
//# sourceMappingURL=index.js.map