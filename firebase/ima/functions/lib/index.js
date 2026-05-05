"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.autoSyncIssueToGitHubOnIssueWrite = exports.autoEstimateIssueWeightOnIssueWrite = exports.recomputeResolutionWeights = exports.issueLifecycleEventLogger = exports.estimateIssueWeight = exports.syncGitHubIssues = exports.githubPullRequestWebhook = exports.backfillCursorAgentPullRequests = exports.backfillIssueKeys = exports.startIssueCursorAgent = exports.createGitHubSubIssue = exports.createGitHubIssue = exports.importGitHubIssues = exports.listGitHubRepositories = exports.completeGitHubDeviceFlow = exports.startGitHubDeviceFlow = exports.connectGitHub = void 0;
const node_crypto_1 = require("node:crypto");
const sdk_1 = require("@cursor/sdk");
const app_1 = require("firebase-admin/app");
const firestore_1 = require("firebase-admin/firestore");
const params_1 = require("firebase-functions/params");
const v2_1 = require("firebase-functions/v2");
const firestore_2 = require("firebase-functions/v2/firestore");
const https_1 = require("firebase-functions/v2/https");
const issueLinkingHelpers_1 = require("./issueLinkingHelpers");
const issueWeightHelpers_1 = require("./issueWeightHelpers");
if ((0, app_1.getApps)().length === 0) {
    (0, app_1.initializeApp)();
}
(0, v2_1.setGlobalOptions)({
    region: "asia-northeast1",
    maxInstances: 10,
});
const db = (0, firestore_1.getFirestore)();
const anthropicApiKey = (0, params_1.defineSecret)("ANTHROPIC_API_KEY");
const cursorApiKey = (0, params_1.defineSecret)("CURSOR_API_KEY");
const githubWebhookSecret = (0, params_1.defineSecret)("GITHUB_WEBHOOK_SECRET");
const closedStatusId = "done";
const reviewStatusId = "review";
const inProgressStatusIds = new Set(["doing", "review"]);
const issueWeightModel = "claude-opus-4-6";
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
async function githubRequest({ path, token, method = "GET", body, queryParameters, apiVersion = "2022-11-28", }) {
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
            "x-github-api-version": apiVersion,
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
async function resolveGitHubIssueDocument(input) {
    const issuesRef = db.collection(`workspaces/${input.workspaceId}/issues`);
    const canonicalRef = issuesRef.doc(issueDocId(input.owner, input.repo, input.number));
    const canonicalDoc = await canonicalRef.get();
    if (canonicalDoc.exists) {
        return { ref: canonicalRef, doc: canonicalDoc };
    }
    const nodeId = input.nodeId ?? "";
    if (nodeId.length > 0) {
        const existing = await issuesRef.where("githubIssue.nodeId", "==", nodeId).limit(1).get();
        if (!existing.empty) {
            const existingDoc = existing.docs[0];
            return { ref: existingDoc.ref, doc: existingDoc };
        }
    }
    const existingByNumber = await issuesRef
        .where("githubIssue.number", "==", input.number)
        .limit(20)
        .get();
    const matchingDoc = existingByNumber.docs.find((doc) => {
        const githubIssue = doc.get("githubIssue");
        return (asString(githubIssue?.owner) === input.owner &&
            asString(githubIssue?.repo) === input.repo &&
            asNumber(githubIssue?.number) === input.number);
    });
    if (matchingDoc !== undefined) {
        return { ref: matchingDoc.ref, doc: matchingDoc };
    }
    return { ref: canonicalRef, doc: canonicalDoc };
}
function pullRequestLinkId(owner, repo, number) {
    return `${owner}_${repo}_${number}`.replace(/[^a-zA-Z0-9_-]/gu, "_");
}
function asString(value, fallback = "") {
    return typeof value === "string" && value.length > 0 ? value : fallback;
}
function asNumber(value, fallback = 0) {
    return typeof value === "number" ? value : fallback;
}
function asBoolean(value, fallback = false) {
    return typeof value === "boolean" ? value : fallback;
}
function isActiveCursorAgentStatus(status) {
    return status === "starting" || status === "running";
}
async function resolveIssueCursorStartingRef(workspaceId, repoFullName) {
    const repoDoc = await db
        .doc(`workspaces/${workspaceId}/githubRepos/${repoDocId(repoFullName)}`)
        .get();
    return asString(repoDoc.get("defaultBranch"), "main");
}
function buildCursorAgentPrompt(input) {
    const labels = asStringList(input.issue.labels);
    const issueUrl = asString(input.githubIssue.url);
    const issueKeyValue = asString(input.issue.issueKey);
    const displayId = issueKeyValue.length > 0 ? issueKeyValue : `#${asNumber(input.githubIssue.number)}`;
    return [
        `Please work on this GitHub issue and open a pull request when finished.`,
        ``,
        `Repository: ${input.repoFullName}`,
        `Issue: ${displayId}`,
        issueUrl.length > 0 ? `Issue URL: ${issueUrl}` : undefined,
        labels.length > 0 ? `Labels: ${labels.join(", ")}` : undefined,
        ``,
        `Title:`,
        asString(input.issue.title, "Untitled issue"),
        ``,
        `Body:`,
        asString(input.issue.body, "(no body)"),
        ``,
        `Instructions:`,
        `- Understand the existing codebase before editing.`,
        `- Implement the issue with the smallest reasonable change.`,
        `- Add or update tests when the change is behaviorally meaningful.`,
        `- Run relevant checks if available.`,
        `- Open a pull request that links back to ${issueUrl.length > 0 ? issueUrl : input.issueId}. The pull request must NOT be a draft; create it as a regular open PR.`,
        issueKeyValue.length > 0
            ? `- Include "${issueKeyValue}" in the pull request title (e.g. "feat: description ${issueKeyValue}") for tracking.`
            : undefined,
    ]
        .filter((line) => typeof line === "string")
        .join("\n");
}
function cursorAgentStartComment(input) {
    return [
        `Cursor agent started from IMA.`,
        ``,
        `- Issue: ${input.issueKey}`,
        `- Agent ID: \`${input.agentId}\``,
        `- Run ID: \`${input.runId}\``,
        ``,
        `The agent will work on the issue and create a pull request if it completes successfully.`,
    ].join("\n");
}
function pullRequestSummary({ owner, repo, pullRequest, branch, }) {
    return {
        owner,
        repo,
        number: asNumber(pullRequest.number),
        url: asString(pullRequest.html_url),
        title: asString(pullRequest.title),
        branch,
        state: asString(pullRequest.state, "open"),
        merged: asBoolean(pullRequest.merged),
    };
}
function pullRequestMatchesIssue(pullRequest, issue) {
    const branch = asString(pullRequest.head?.ref);
    const title = asString(pullRequest.title);
    const body = asString(pullRequest.body);
    const issueKeyValue = asString(issue.issueKey).toUpperCase();
    if (issueKeyValue.length > 0 && (0, issueLinkingHelpers_1.extractIssueKey)(branch, title, body) === issueKeyValue) {
        return true;
    }
    const githubIssue = issue.githubIssue;
    const issueUrl = asString(githubIssue?.url);
    if (issueUrl.length > 0 && body.includes(issueUrl)) {
        return true;
    }
    const issueNumber = asNumber(githubIssue?.number);
    if (issueNumber <= 0) {
        return false;
    }
    const numberPattern = new RegExp(`(?:fix(?:e[sd])?|close[sd]?|resolve[sd]?)\\s+#${issueNumber}(?=$|\\D)`, "iu");
    return numberPattern.test(body);
}
function issueKeyFieldsFromData(data) {
    const existingIssueKey = asString(data.issueKey);
    if (existingIssueKey.length === 0) {
        return null;
    }
    const existingNumber = asNumber(data.issueNumber);
    const prefix = (0, issueLinkingHelpers_1.normalizeIssueKeyPrefix)(asString(data.issueKeyPrefix, existingIssueKey.split("-")[0] ?? "IMA"));
    return {
        issueKeyPrefix: prefix,
        issueNumber: existingNumber > 0 ? existingNumber : null,
        issueKey: existingIssueKey.toUpperCase(),
    };
}
async function nextIssueKeyFields(workspaceId) {
    const workspaceRef = db.doc(`workspaces/${workspaceId}`);
    const counterRef = workspaceRef.collection("counters").doc("issues");
    return db.runTransaction(async (transaction) => {
        const [workspace, counter] = await Promise.all([
            transaction.get(workspaceRef),
            transaction.get(counterRef),
        ]);
        const prefix = (0, issueLinkingHelpers_1.normalizeIssueKeyPrefix)(asString(workspace.get("issueKeyPrefix"), "IMA"));
        const nextNumber = asNumber(counter.get("lastIssueNumber")) + 1;
        transaction.set(counterRef, {
            issueKeyPrefix: prefix,
            lastIssueNumber: nextNumber,
            updatedAt: firestore_1.FieldValue.serverTimestamp(),
        }, { merge: true });
        return {
            issueKeyPrefix: prefix,
            issueNumber: nextNumber,
            issueKey: (0, issueLinkingHelpers_1.issueKey)(prefix, nextNumber),
        };
    });
}
async function issueKeyFields(workspaceId, data) {
    return issueKeyFieldsFromData(data) ?? nextIssueKeyFields(workspaceId);
}
function asStringList(value) {
    if (!Array.isArray(value)) {
        return [];
    }
    return value.filter((item) => typeof item === "string" && item.length > 0);
}
function asTimestamp(value) {
    if (typeof value !== "string") {
        return null;
    }
    const date = new Date(value);
    return Number.isNaN(date.valueOf()) ? null : firestore_1.Timestamp.fromDate(date);
}
function timestampFromValue(value) {
    if (value instanceof firestore_1.Timestamp) {
        return value;
    }
    if (value instanceof Date) {
        return firestore_1.Timestamp.fromDate(value);
    }
    return asTimestamp(value);
}
function roundedHours(milliseconds) {
    if (milliseconds === null) {
        return null;
    }
    return Math.round((milliseconds / 3_600_000) * 10) / 10;
}
function median(values) {
    if (values.length === 0) {
        return null;
    }
    const sorted = values.slice().sort((a, b) => a - b);
    const middle = Math.floor(sorted.length / 2);
    const middleValue = sorted[middle];
    if (middleValue === undefined) {
        return null;
    }
    if (sorted.length % 2 === 1) {
        return middleValue;
    }
    const previousValue = sorted[middle - 1];
    return previousValue === undefined ? middleValue : (previousValue + middleValue) / 2;
}
function issueWeightEstimateMap(issue) {
    const estimate = issue.weightEstimate;
    return typeof estimate === "object" && estimate !== null
        ? estimate
        : {};
}
function normalizeIssueWeightEstimate(estimate) {
    const value = asNumber(estimate.value);
    const confidence = asNumber(estimate.confidence);
    const reason = asString(estimate.reason);
    const model = asString(estimate.model);
    const inputHash = asString(estimate.inputHash);
    if (!(0, issueWeightHelpers_1.isValidWeight)(value) ||
        confidence < 0 ||
        confidence > 1 ||
        reason.length === 0 ||
        model.length === 0 ||
        inputHash.length === 0) {
        return null;
    }
    return {
        value,
        confidence,
        reason,
        model,
        promptVersion: asString(estimate.promptVersion, issueWeightHelpers_1.issueWeightPromptVersion),
        inputHash,
        source: "llm",
        status: "done",
    };
}
const defaultWeightThresholdsHours = [
    { weight: 1, maxHours: 1 },
    { weight: 2, maxHours: 4 },
    { weight: 4, maxHours: 12 },
    { weight: 8, maxHours: 32 },
    { weight: 16, maxHours: 80 },
    { weight: 32, maxHours: Infinity },
];
function deriveActualWeight(cycleTimeMs, byWeight) {
    const hours = cycleTimeMs / 3_600_000;
    const entries = Object.entries(byWeight)
        .map(([key, stats]) => ({ weight: Number(key), hours: stats.medianHours }))
        .filter((entry) => (0, issueWeightHelpers_1.isValidWeight)(entry.weight) && entry.hours !== null);
    const totalCount = Object.values(byWeight).reduce((sum, stats) => sum + stats.count, 0);
    if (entries.length >= 3 && totalCount >= 5) {
        let closest = entries[0];
        let closestDiff = Math.abs(closest.hours - hours);
        for (let i = 1; i < entries.length; i++) {
            const diff = Math.abs(entries[i].hours - hours);
            if (diff < closestDiff) {
                closest = entries[i];
                closestDiff = diff;
            }
        }
        return closest.weight;
    }
    for (const tier of defaultWeightThresholdsHours) {
        if (hours < tier.maxHours) {
            return tier.weight;
        }
    }
    return 32;
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
function issueSubIssuesSummary(issue) {
    const summary = issue.sub_issues_summary;
    const total = asNumber(summary?.total);
    if (total <= 0) {
        return null;
    }
    const completed = Math.min(Math.max(asNumber(summary?.completed), 0), total);
    const percentCompleted = Math.min(Math.max(asNumber(summary?.percent_completed, Math.round((completed / total) * 100)), 0), 100);
    return {
        total,
        completed,
        percentCompleted,
        parentIssueUrl: asString(issue.parent_issue_url) || null,
    };
}
function githubIssueFirestoreFields(owner, repo, issue) {
    const subIssuesSummary = issueSubIssuesSummary(issue);
    const fields = {
        nodeId: asString(issue.node_id),
        owner,
        repo,
        number: asNumber(issue.number),
        url: asString(issue.html_url),
        state: asString(issue.state, "open"),
    };
    if (subIssuesSummary !== null) {
        fields.subIssuesSummary = subIssuesSummary;
    }
    return fields;
}
function mergedSubIssueSummaries(existingValue, nextSummary) {
    const existing = Array.isArray(existingValue)
        ? existingValue.filter((value) => typeof value === "object" && value !== null && !Array.isArray(value))
        : [];
    const nextIssueId = asString(nextSummary.issueId);
    const nextNodeId = asString(nextSummary.nodeId);
    const nextNumber = asNumber(nextSummary.number);
    const merged = existing.filter((summary) => {
        const issueId = asString(summary.issueId);
        if (nextIssueId.length > 0 && issueId === nextIssueId) {
            return false;
        }
        const nodeId = asString(summary.nodeId);
        if (nextNodeId.length > 0 && nodeId === nextNodeId) {
            return false;
        }
        const number = asNumber(summary.number);
        return nextNumber <= 0 || number !== nextNumber;
    });
    merged.push(nextSummary);
    return merged;
}
async function closeDescendantSubIssues(input) {
    const issuesRef = db.collection(`workspaces/${input.workspaceId}/issues`);
    const visited = new Set([input.issueId]);
    const queue = [input.issueId];
    const descendants = [];
    while (queue.length > 0) {
        const parentIssueId = queue.shift();
        const children = await issuesRef
            .where("githubIssue.parentIssue.issueId", "==", parentIssueId)
            .get();
        for (const child of children.docs) {
            if (visited.has(child.id)) {
                continue;
            }
            visited.add(child.id);
            descendants.push(child);
            queue.push(child.id);
        }
    }
    const openDescendants = descendants.filter((descendant) => asString(descendant.get("statusId"), "triage") !== closedStatusId);
    if (openDescendants.length === 0) {
        return 0;
    }
    let batch = db.batch();
    let pendingWrites = 0;
    let closed = 0;
    const rankBase = input.rankBase ?? Date.now();
    async function commitIfNeeded(force = false) {
        if (pendingWrites === 0 || (!force && pendingWrites < 400)) {
            return;
        }
        await batch.commit();
        batch = db.batch();
        pendingWrites = 0;
    }
    for (const descendant of openDescendants) {
        batch.set(descendant.ref, {
            statusId: closedStatusId,
            rank: rankBase + closed + 1,
            "githubIssue.state": "closed",
            updatedAt: firestore_1.FieldValue.serverTimestamp(),
        }, { merge: true });
        pendingWrites += 1;
        closed += 1;
        await commitIfNeeded();
    }
    await commitIfNeeded(true);
    return closed;
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
function issueEventDocId(eventId, issueId, type) {
    const source = eventId && eventId.length > 0 ? eventId : `${issueId}_${type}_${Date.now()}`;
    return `${source}_${type}`.replace(/[^a-zA-Z0-9_-]/gu, "_");
}
async function writeIssueEvent({ workspaceId, issueId, type, eventId, data, }) {
    await db
        .doc(`workspaces/${workspaceId}/issueEvents/${issueEventDocId(eventId, issueId, type)}`)
        .set({
        issueId,
        type,
        ...data,
        createdAt: firestore_1.FieldValue.serverTimestamp(),
    }, { merge: true });
}
function closedIssueStatsEvent(data) {
    if (asString(data.type) !== "closed") {
        return null;
    }
    return {
        title: asString(data.title),
        repo: asString(data.repo),
        labels: asStringList(data.labels),
        weightValue: typeof data.weightValue === "number" ? data.weightValue : null,
        actualWeight: typeof data.actualWeight === "number" ? data.actualWeight : null,
        leadTimeMs: typeof data.leadTimeMs === "number" ? data.leadTimeMs : null,
        cycleTimeMs: typeof data.cycleTimeMs === "number" ? data.cycleTimeMs : null,
        closedAt: timestampFromValue(data.closedAt),
    };
}
function bucketMedian(events, keyForEvent, timeForEvent = (e) => e.leadTimeMs) {
    const buckets = new Map();
    for (const event of events) {
        const timeMs = timeForEvent(event);
        if (timeMs === null) {
            continue;
        }
        for (const key of keyForEvent(event)) {
            const existing = buckets.get(key) ?? [];
            existing.push(timeMs);
            buckets.set(key, existing);
        }
    }
    return Object.fromEntries([...buckets.entries()]
        .sort((left, right) => right[1].length - left[1].length)
        .slice(0, 20)
        .map(([key, values]) => [
        key,
        {
            count: values.length,
            medianHours: roundedHours(median(values)),
        },
    ]));
}
async function collectResolutionStats(workspaceId) {
    const snapshot = await db
        .collection(`workspaces/${workspaceId}/issueEvents`)
        .orderBy("createdAt", "desc")
        .limit(200)
        .get();
    const closedEvents = snapshot.docs
        .map((doc) => closedIssueStatsEvent(doc.data()))
        .filter((event) => event !== null);
    const now = Date.now();
    const withinDays = (days) => closedEvents.filter((event) => {
        const closedAt = event.closedAt?.toMillis();
        return closedAt !== undefined && now - closedAt <= days * 24 * 60 * 60 * 1000;
    });
    const recent30 = withinDays(30);
    const selected = recent30.length >= 10 ? recent30 : withinDays(90);
    const recentWindowDays = recent30.length >= 10 ? 30 : 90;
    const leadTimes = selected
        .map((event) => event.leadTimeMs)
        .filter((value) => value !== null);
    const cycleTimes = selected
        .map((event) => event.cycleTimeMs)
        .filter((value) => value !== null);
    const comparablePairs = selected.filter((event) => event.weightValue !== null && event.actualWeight !== null);
    let estimationAccuracy = null;
    if (comparablePairs.length > 0) {
        const exactMatches = comparablePairs.filter((e) => e.weightValue === e.actualWeight).length;
        const adjacentMatches = comparablePairs.filter((e) => (0, issueWeightHelpers_1.isAdjacentWeight)(e.weightValue, e.actualWeight)).length;
        const deltas = comparablePairs.map((e) => e.weightValue - e.actualWeight);
        const sumAbsError = deltas.reduce((sum, d) => sum + Math.abs(d), 0);
        const sumDelta = deltas.reduce((sum, d) => sum + d, 0);
        estimationAccuracy = {
            totalCompared: comparablePairs.length,
            exactMatchRate: Math.round((exactMatches / comparablePairs.length) * 100) / 100,
            within1Rate: Math.round((adjacentMatches / comparablePairs.length) * 100) / 100,
            meanAbsoluteError: Math.round((sumAbsError / comparablePairs.length) * 10) / 10,
            bias: Math.round((sumDelta / comparablePairs.length) * 10) / 10,
        };
    }
    return {
        recentWindowDays,
        resolvedCount: selected.length,
        medianLeadTimeHours: roundedHours(median(leadTimes)),
        medianCycleTimeHours: roundedHours(median(cycleTimes)),
        byWeight: bucketMedian(selected, (event) => event.weightValue === null ? [] : [String(event.weightValue)]),
        byLabel: bucketMedian(selected, (event) => event.labels),
        recentExamples: selected.slice(0, 30).map((event) => ({
            title: (0, issueWeightHelpers_1.truncateText)(event.title, 120),
            repo: event.repo,
            labels: event.labels.slice(0, 8),
            weight: event.weightValue,
            actualWeight: event.actualWeight,
            leadTimeHours: roundedHours(event.leadTimeMs),
            cycleTimeHours: roundedHours(event.cycleTimeMs),
        })),
        estimationAccuracy,
    };
}
async function createAnthropicMessage(system, content) {
    const apiKey = anthropicApiKey.value();
    if (apiKey.length === 0) {
        throw new Error("ANTHROPIC_API_KEY is not configured");
    }
    const response = await fetch("https://api.anthropic.com/v1/messages", {
        method: "POST",
        headers: {
            "x-api-key": apiKey,
            "anthropic-version": "2023-06-01",
            "Content-Type": "application/json",
        },
        body: JSON.stringify({
            model: issueWeightModel,
            max_tokens: 700,
            system,
            messages: [{ role: "user", content }],
        }),
    });
    const data = (await response.json());
    if (!response.ok) {
        throw new Error(data.error?.message ?? `Anthropic API error: ${response.status}`);
    }
    return (data.content ?? [])
        .filter((block) => block.type === "text" && typeof block.text === "string")
        .map((block) => block.text)
        .join("");
}
async function estimateIssueWeightWithLlm(workspaceId, issue) {
    const resolutionStats = await collectResolutionStats(workspaceId);
    const system = [
        "You estimate issue weight for a software team's issue board.",
        "Return only JSON with keys: value, confidence, reason.",
        "value must be one of: 1, 2, 4, 8, 16, 32 (powers of 2; 1=tiny, 32=very large).",
        "confidence must be a number from 0 to 1.",
        "reason must be short Japanese text, within 80 characters.",
        "Use the team's recent resolution speed statistics when available.",
    ].join("\n");
    const content = JSON.stringify({
        issue: (0, issueWeightHelpers_1.issueWeightInput)(issue),
        resolutionStats,
    }, null, 2);
    return (0, issueWeightHelpers_1.parseWeightEstimateResponse)(await createAnthropicMessage(system, content));
}
async function estimateAndSaveIssueWeight({ workspaceId, issueId, issue, force, requestedBy, }) {
    const inputHash = (0, issueWeightHelpers_1.issueWeightInputHash)(issue);
    const existing = issueWeightEstimateMap(issue);
    const existingStatus = asString(existing.status);
    const existingInputHash = asString(existing.inputHash);
    if (!force && existingInputHash === inputHash) {
        if (existingStatus === "done") {
            const normalized = normalizeIssueWeightEstimate(existing);
            if (normalized !== null) {
                return normalized;
            }
        }
        if (existingStatus === "estimating" || existingStatus === "failed") {
            throw new Error(`Issue weight estimate is already ${existingStatus}`);
        }
    }
    const issueRef = db.doc(`workspaces/${workspaceId}/issues/${issueId}`);
    await issueRef.set({
        weightEstimate: {
            status: "estimating",
            inputHash,
            promptVersion: issueWeightHelpers_1.issueWeightPromptVersion,
            model: issueWeightModel,
            manualOverride: false,
            updatedAt: firestore_1.FieldValue.serverTimestamp(),
        },
    }, { merge: true });
    const start = Date.now();
    try {
        const parsed = await estimateIssueWeightWithLlm(workspaceId, issue);
        const estimate = {
            ...parsed,
            model: issueWeightModel,
            promptVersion: issueWeightHelpers_1.issueWeightPromptVersion,
            inputHash,
            source: "llm",
            status: "done",
        };
        const durationMs = Date.now() - start;
        await issueRef.set({
            weightEstimate: {
                ...estimate,
                manualOverride: false,
                durationMs,
                requestedBy: requestedBy ?? null,
                estimatedAt: firestore_1.FieldValue.serverTimestamp(),
                updatedAt: firestore_1.FieldValue.serverTimestamp(),
            },
        }, { merge: true });
        await writeIssueEvent({
            workspaceId,
            issueId,
            type: "weight_estimated",
            data: {
                title: asString(issue.title),
                repo: asString(issue.repo),
                labels: asStringList(issue.labels),
                weightValue: estimate.value,
                confidence: estimate.confidence,
                model: estimate.model,
                promptVersion: estimate.promptVersion,
                inputHash,
                durationMs,
                requestedBy: requestedBy ?? null,
            },
        });
        return estimate;
    }
    catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        await issueRef.set({
            weightEstimate: {
                status: "failed",
                inputHash,
                promptVersion: issueWeightHelpers_1.issueWeightPromptVersion,
                model: issueWeightModel,
                manualOverride: false,
                error: (0, issueWeightHelpers_1.truncateText)(message, 500),
                failedAt: firestore_1.FieldValue.serverTimestamp(),
                updatedAt: firestore_1.FieldValue.serverTimestamp(),
            },
        }, { merge: true });
        await writeIssueEvent({
            workspaceId,
            issueId,
            type: "weight_estimation_failed",
            data: {
                title: asString(issue.title),
                repo: asString(issue.repo),
                labels: asStringList(issue.labels),
                model: issueWeightModel,
                promptVersion: issueWeightHelpers_1.issueWeightPromptVersion,
                inputHash,
                error: (0, issueWeightHelpers_1.truncateText)(message, 500),
                requestedBy: requestedBy ?? null,
            },
        });
        throw error;
    }
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
        v2_1.logger.info("Starting device flow request", {
            workspaceId,
            clientId: clientId.substring(0, 8),
        });
        const data = await githubOAuthRequest("/login/device/code", {
            client_id: clientId,
            scope: "read:user repo",
        });
        v2_1.logger.info("Device flow response received", {
            workspaceId,
            hasError: !!data.error,
            hasUserCode: !!data.user_code,
        });
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
                    apiVersion: "2026-03-10",
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
                    const { ref: docRef, doc: existing } = await resolveGitHubIssueDocument({
                        workspaceId,
                        owner,
                        repo,
                        number,
                        nodeId,
                    });
                    const existingData = existing.data() ?? {};
                    const keyFields = await issueKeyFields(workspaceId, existingData);
                    batch.set(docRef, {
                        ...keyFields,
                        title: asString(issue.title, `#${number}`),
                        body: asString(issue.body),
                        repo: repository.fullName,
                        assignee: issueAssignee(issue),
                        labels: issueLabels(issue),
                        comments: asNumber(issue.comments),
                        priority: asString(existingData.priority, "medium"),
                        statusId: asString(existingData.statusId, "triage"),
                        rank: asNumber(existingData.rank, Date.now() + imported),
                        githubIssue: githubIssueFirestoreFields(owner, repo, issue),
                        githubUpdatedAt: asTimestamp(issue.updated_at),
                        githubCreatedAt: asTimestamp(issue.created_at),
                        updatedAt: firestore_1.FieldValue.serverTimestamp(),
                        createdAt: existing.exists
                            ? (existingData.createdAt ?? firestore_1.FieldValue.serverTimestamp())
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
        const clientIssueId = asString(request.data?.issueId);
        const issueId = clientIssueId.length > 0 ? clientIssueId : issueDocId(owner, repo, number);
        const docRef = db.doc(`workspaces/${workspaceId}/issues/${issueId}`);
        const existingData = clientIssueId.length > 0 ? ((await docRef.get()).data() ?? {}) : {};
        const keyFields = await issueKeyFields(workspaceId, existingData);
        await docRef.set({
            ...keyFields,
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
            githubIssue: githubIssueFirestoreFields(owner, repo, issue),
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
        v2_1.logger.error("Failed to create Ima GitHub issue", {
            workspaceId,
            uid,
            repoFullName,
            message,
            stack,
        });
        throw new https_1.HttpsError("internal", `Failed to create GitHub issue: ${message}`);
    }
});
exports.createGitHubSubIssue = (0, https_1.onCall)(async (request) => {
    const workspaceId = requireNonEmptyString(request.data?.workspaceId, "workspaceId");
    const uid = await verifyWorkspaceMember(request.auth, workspaceId);
    const token = await getGitHubToken(uid);
    const parentIssueId = requireNonEmptyString(request.data?.parentIssueId, "parentIssueId");
    const title = requireNonEmptyString(request.data?.title, "title");
    const body = asString(request.data?.body);
    const parentRef = db.doc(`workspaces/${workspaceId}/issues/${parentIssueId}`);
    const parentDoc = await parentRef.get();
    const parentIssue = parentDoc.data();
    if (!parentIssue) {
        throw new https_1.HttpsError("not-found", "Parent issue was not found");
    }
    const parentGithubIssue = parentIssue.githubIssue;
    if (!parentGithubIssue) {
        throw new https_1.HttpsError("failed-precondition", "Parent issue must be linked to GitHub");
    }
    const owner = requireNonEmptyString(parentGithubIssue.owner, "githubIssue.owner");
    const repo = requireNonEmptyString(parentGithubIssue.repo, "githubIssue.repo");
    const parentNumber = asNumber(parentGithubIssue.number);
    if (parentNumber <= 0) {
        throw new https_1.HttpsError("failed-precondition", "Parent GitHub issue number is missing");
    }
    const assignee = asString(parentIssue.assignee);
    const githubAssignee = assignee.startsWith("@") ? assignee.slice(1) : "";
    const assignees = githubAssignee.length > 0 ? [githubAssignee] : [];
    const labels = asStringList(parentIssue.labels);
    try {
        v2_1.logger.info("Creating GitHub sub-issue", {
            workspaceId,
            parentIssueId,
            owner,
            repo,
            parentNumber,
            title,
        });
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
        const subIssueRestId = asNumber(issue.id);
        if (number <= 0 || nodeId.length === 0 || subIssueRestId <= 0) {
            throw new https_1.HttpsError("failed-precondition", "GitHub sub-issue could not be created");
        }
        const updatedParentIssue = await githubRequest({
            path: `/repos/${owner}/${repo}/issues/${parentNumber}/sub_issues`,
            token,
            method: "POST",
            apiVersion: "2026-03-10",
            body: {
                sub_issue_id: subIssueRestId,
            },
        });
        const clientIssueId = asString(request.data?.issueId);
        const issueId = clientIssueId.length > 0 ? clientIssueId : issueDocId(owner, repo, number);
        const subIssueRef = db.doc(`workspaces/${workspaceId}/issues/${issueId}`);
        const existingData = clientIssueId.length > 0 ? ((await subIssueRef.get()).data() ?? {}) : {};
        const keyFields = await issueKeyFields(workspaceId, existingData);
        const rank = Date.now();
        const statusId = asString(existingData.statusId, asString(parentIssue.statusId, "triage"));
        const subIssueSummary = {
            issueId,
            nodeId,
            number,
            title: asString(issue.title, title),
            url: asString(issue.html_url),
            state: asString(issue.state, "open"),
        };
        await subIssueRef.set({
            ...keyFields,
            title: asString(issue.title, title),
            body: asString(issue.body, body),
            repo: `${owner}/${repo}`,
            assignee: issueAssignee(issue),
            labels: issueLabels(issue),
            comments: asNumber(issue.comments),
            priority: asString(parentIssue.priority, "medium"),
            statusId,
            rank,
            githubIssue: {
                ...githubIssueFirestoreFields(owner, repo, issue),
                parentIssue: {
                    issueId: parentIssueId,
                    nodeId: asString(parentGithubIssue.nodeId),
                    number: parentNumber,
                    url: asString(parentGithubIssue.url),
                },
            },
            githubUpdatedAt: asTimestamp(issue.updated_at),
            githubCreatedAt: asTimestamp(issue.created_at),
            updatedAt: firestore_1.FieldValue.serverTimestamp(),
            createdAt: firestore_1.FieldValue.serverTimestamp(),
        }, { merge: true });
        await parentRef.set({
            githubIssue: {
                ...githubIssueFirestoreFields(owner, repo, updatedParentIssue),
                nodeId: asString(parentGithubIssue.nodeId),
                number: parentNumber,
                url: asString(parentGithubIssue.url),
                subIssues: mergedSubIssueSummaries(parentGithubIssue.subIssues, subIssueSummary),
            },
            updatedAt: firestore_1.FieldValue.serverTimestamp(),
        }, { merge: true });
        return {
            parentIssueId,
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
        v2_1.logger.error("Failed to create Ima GitHub sub-issue", {
            workspaceId,
            uid,
            parentIssueId,
            message,
            stack,
        });
        throw new https_1.HttpsError("internal", `Failed to create GitHub sub-issue: ${message}`);
    }
});
exports.startIssueCursorAgent = (0, https_1.onCall)({ timeoutSeconds: 120, secrets: [cursorApiKey] }, async (request) => {
    const workspaceId = requireNonEmptyString(request.data?.workspaceId, "workspaceId");
    const issueId = requireNonEmptyString(request.data?.issueId, "issueId");
    const uid = await verifyWorkspaceMember(request.auth, workspaceId);
    const githubToken = await getGitHubToken(uid);
    const apiKey = cursorApiKey.value();
    if (apiKey.length === 0) {
        throw new https_1.HttpsError("failed-precondition", "CURSOR_API_KEY is not configured");
    }
    const issueRef = db.doc(`workspaces/${workspaceId}/issues/${issueId}`);
    const issueDoc = await issueRef.get();
    const issue = issueDoc.data();
    if (!issue) {
        throw new https_1.HttpsError("not-found", "Issue was not found");
    }
    const cursorAgent = issue.cursorAgent;
    const existingStatus = asString(cursorAgent?.status);
    if (isActiveCursorAgentStatus(existingStatus)) {
        throw new https_1.HttpsError("failed-precondition", "Cursor agent is already running for this issue");
    }
    const repoFullName = requireNonEmptyString(issue.repo, "repo");
    const [owner, repo] = repoFullName.split("/");
    if (!owner || !repo) {
        throw new https_1.HttpsError("failed-precondition", "Issue repository must be owner/repo");
    }
    const githubIssue = issue.githubIssue;
    if (!githubIssue) {
        throw new https_1.HttpsError("failed-precondition", "Issue must be linked to GitHub");
    }
    const issueNumber = asNumber(githubIssue.number);
    if (issueNumber <= 0) {
        throw new https_1.HttpsError("failed-precondition", "GitHub issue number is missing");
    }
    const runRef = issueRef.collection("cursorAgentRuns").doc();
    const startingRef = await resolveIssueCursorStartingRef(workspaceId, repoFullName);
    const repositoryUrl = `https://github.com/${repoFullName}`;
    const prompt = buildCursorAgentPrompt({ issueId, issue, githubIssue, repoFullName });
    const now = firestore_1.FieldValue.serverTimestamp();
    const currentStatusId = asString(issue.statusId, "triage");
    const shouldMoveToDoing = currentStatusId !== closedStatusId && !inProgressStatusIds.has(currentStatusId);
    await issueRef.set({
        cursorAgent: {
            status: "starting",
            requestedBy: uid,
            startingRef,
            repositoryUrl,
            updatedAt: now,
            startedAt: now,
            errorMessage: firestore_1.FieldValue.delete(),
        },
        ...(shouldMoveToDoing ? { statusId: "doing" } : {}),
        updatedAt: now,
    }, { merge: true });
    await runRef.set({
        status: "starting",
        requestedBy: uid,
        startingRef,
        repositoryUrl,
        prompt,
        createdAt: firestore_1.FieldValue.serverTimestamp(),
        updatedAt: firestore_1.FieldValue.serverTimestamp(),
    });
    let agent;
    try {
        agent = await sdk_1.Agent.create({
            apiKey,
            cloud: {
                repos: [{ url: repositoryUrl, startingRef }],
                autoCreatePR: true,
            },
        });
        const run = await agent.send(prompt);
        const agentId = run.agentId;
        const runId = run.id;
        await Promise.all([
            issueRef.set({
                cursorAgent: {
                    status: "running",
                    agentId,
                    runId,
                    runDocumentId: runRef.id,
                    requestedBy: uid,
                    startingRef,
                    repositoryUrl,
                    updatedAt: firestore_1.FieldValue.serverTimestamp(),
                    startedAt: firestore_1.FieldValue.serverTimestamp(),
                    errorMessage: firestore_1.FieldValue.delete(),
                },
                updatedAt: firestore_1.FieldValue.serverTimestamp(),
            }, { merge: true }),
            runRef.set({
                status: "running",
                agentId,
                runId,
                updatedAt: firestore_1.FieldValue.serverTimestamp(),
            }, { merge: true }),
        ]);
        try {
            await githubRequest({
                path: `/repos/${owner}/${repo}/issues/${issueNumber}/comments`,
                token: githubToken,
                method: "POST",
                body: {
                    body: cursorAgentStartComment({
                        issueKey: asString(issue.issueKey, `#${issueNumber}`),
                        agentId,
                        runId,
                    }),
                },
            });
        }
        catch (error) {
            const message = error instanceof Error ? error.message : String(error);
            v2_1.logger.warn("Failed to post Cursor agent start comment", {
                workspaceId,
                issueId,
                repoFullName,
                issueNumber,
                message,
            });
        }
        return { issueId, agentId, runId, status: "running" };
    }
    catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        await Promise.all([
            issueRef.set({
                cursorAgent: {
                    status: "failed",
                    requestedBy: uid,
                    startingRef,
                    repositoryUrl,
                    errorMessage: message,
                    updatedAt: firestore_1.FieldValue.serverTimestamp(),
                },
                updatedAt: firestore_1.FieldValue.serverTimestamp(),
            }, { merge: true }),
            runRef.set({
                status: "failed",
                errorMessage: message,
                updatedAt: firestore_1.FieldValue.serverTimestamp(),
            }, { merge: true }),
        ]);
        v2_1.logger.error("Failed to start Cursor agent", { workspaceId, issueId, repoFullName, message });
        throw new https_1.HttpsError("internal", `Failed to start Cursor agent: ${message}`);
    }
    finally {
        await agent?.[Symbol.asyncDispose]?.();
    }
});
exports.backfillIssueKeys = (0, https_1.onCall)(async (request) => {
    const workspaceId = requireNonEmptyString(request.data?.workspaceId, "workspaceId");
    await verifyWorkspaceMember(request.auth, workspaceId);
    const issues = await db.collection(`workspaces/${workspaceId}/issues`).limit(500).get();
    let updated = 0;
    for (const issue of issues.docs) {
        if (issueKeyFieldsFromData(issue.data()) !== null) {
            continue;
        }
        await issue.ref.set({
            ...(await nextIssueKeyFields(workspaceId)),
            updatedAt: firestore_1.FieldValue.serverTimestamp(),
        }, { merge: true });
        updated += 1;
    }
    return { updated };
});
function recordList(value) {
    return Array.isArray(value)
        ? value.filter((item) => typeof item === "object" && item !== null)
        : [];
}
async function completeCursorAgentFromExistingPullRequest({ workspaceId, issueId, cursorAgent, pullRequest, }) {
    const issueRef = db.doc(`workspaces/${workspaceId}/issues/${issueId}`);
    const runDocumentId = asString(cursorAgent?.runDocumentId);
    const update = {
        status: "done",
        pullRequest,
        completedAt: firestore_1.FieldValue.serverTimestamp(),
        updatedAt: firestore_1.FieldValue.serverTimestamp(),
        errorMessage: firestore_1.FieldValue.delete(),
    };
    await Promise.all([
        issueRef.set({
            cursorAgent: update,
            updatedAt: firestore_1.FieldValue.serverTimestamp(),
        }, { merge: true }),
        ...(runDocumentId.length > 0
            ? [
                issueRef.collection("cursorAgentRuns").doc(runDocumentId).set({
                    status: "done",
                    pullRequest,
                    completedAt: firestore_1.FieldValue.serverTimestamp(),
                    updatedAt: firestore_1.FieldValue.serverTimestamp(),
                }, { merge: true }),
            ]
            : []),
    ]);
}
exports.backfillCursorAgentPullRequests = (0, https_1.onCall)(async (request) => {
    const workspaceId = requireNonEmptyString(request.data?.workspaceId, "workspaceId");
    const uid = await verifyWorkspaceMember(request.auth, workspaceId);
    const token = await getGitHubToken(uid);
    const issues = await db.collection(`workspaces/${workspaceId}/issues`).limit(500).get();
    const pullRequestsByRepo = new Map();
    let inspected = 0;
    let linked = 0;
    for (const issueDoc of issues.docs) {
        const issue = issueDoc.data();
        const cursorAgent = issue.cursorAgent;
        if (!isActiveCursorAgentStatus(asString(cursorAgent?.status))) {
            continue;
        }
        inspected += 1;
        const existingPullRequests = recordList(issue.pullRequests);
        const existingPullRequest = existingPullRequests[0];
        if (existingPullRequest !== undefined) {
            await completeCursorAgentFromExistingPullRequest({
                workspaceId,
                issueId: issueDoc.id,
                cursorAgent,
                pullRequest: existingPullRequest,
            });
            linked += 1;
            continue;
        }
        const repoFullName = asString(issue.repo);
        const [owner, repo] = repoFullName.split("/");
        if (!owner || !repo) {
            continue;
        }
        let pullRequests = pullRequestsByRepo.get(repoFullName);
        if (pullRequests === undefined) {
            pullRequests = await githubRequest({
                path: `/repos/${owner}/${repo}/pulls`,
                token,
                queryParameters: { state: "all", sort: "updated", direction: "desc", per_page: 100 },
            });
            pullRequestsByRepo.set(repoFullName, pullRequests);
        }
        const pullRequest = pullRequests.find((item) => pullRequestMatchesIssue(item, issue));
        if (pullRequest === undefined) {
            continue;
        }
        await upsertPullRequestLink({
            workspaceId,
            issueId: issueDoc.id,
            action: asString(pullRequest.state, "open") === "closed" ? "closed" : "opened",
            pullRequest,
            repoFullName,
            branch: asString(pullRequest.head?.ref),
        });
        linked += 1;
    }
    return { inspected, linked };
});
function verifyGitHubSignature(rawBody, signatureHeader, secret) {
    if (!signatureHeader.startsWith("sha256=") || secret.length === 0) {
        return false;
    }
    const expected = `sha256=${(0, node_crypto_1.createHmac)("sha256", secret).update(rawBody).digest("hex")}`;
    const actualBuffer = Buffer.from(signatureHeader, "utf8");
    const expectedBuffer = Buffer.from(expected, "utf8");
    return (actualBuffer.length === expectedBuffer.length && (0, node_crypto_1.timingSafeEqual)(actualBuffer, expectedBuffer));
}
function requestRawBody(request) {
    const rawBody = request.rawBody;
    if (Buffer.isBuffer(rawBody)) {
        return rawBody;
    }
    return Buffer.from(JSON.stringify(request.body ?? {}), "utf8");
}
function parseWebhookPayload(rawBody) {
    return JSON.parse(rawBody.toString("utf8"));
}
async function upsertPullRequestLink({ workspaceId, issueId, action, pullRequest, repoFullName, branch, }) {
    const [owner, repo] = repoFullName.split("/");
    const number = asNumber(pullRequest.number);
    if (!owner || !repo || number <= 0) {
        return;
    }
    const issueRef = db.doc(`workspaces/${workspaceId}/issues/${issueId}`);
    await db.runTransaction(async (transaction) => {
        const issue = await transaction.get(issueRef);
        const currentPullRequests = Array.isArray(issue.get("pullRequests"))
            ? issue.get("pullRequests")
            : [];
        const currentStatusId = asString(issue.get("statusId"), "triage");
        const nextStatusId = (0, issueLinkingHelpers_1.issueStatusForPullRequest)({
            action,
            merged: asBoolean(pullRequest.merged),
            currentStatusId,
            reviewStatusId,
            doneStatusId: closedStatusId,
        });
        const linkId = pullRequestLinkId(owner, repo, number);
        const now = firestore_1.Timestamp.now();
        const existingLink = currentPullRequests.find((item) => asString(item.id) === linkId);
        const linkedPullRequest = pullRequestSummary({ owner, repo, pullRequest, branch });
        const nextPullRequests = currentPullRequests.filter((item) => asString(item.id) !== linkId);
        nextPullRequests.push({
            id: linkId,
            ...linkedPullRequest,
            linkedAt: timestampFromValue(existingLink?.linkedAt) ?? now,
            updatedAt: now,
        });
        const cursorAgent = issue.get("cursorAgent");
        const shouldCompleteCursorAgent = isActiveCursorAgentStatus(asString(cursorAgent?.status));
        const runDocumentId = asString(cursorAgent?.runDocumentId);
        transaction.set(issueRef, {
            pullRequests: nextPullRequests,
            ...(nextStatusId === null ? {} : { statusId: nextStatusId }),
            ...(shouldCompleteCursorAgent
                ? {
                    cursorAgent: {
                        status: "done",
                        pullRequest: linkedPullRequest,
                        completedAt: firestore_1.FieldValue.serverTimestamp(),
                        updatedAt: firestore_1.FieldValue.serverTimestamp(),
                        errorMessage: firestore_1.FieldValue.delete(),
                    },
                }
                : {}),
            updatedAt: firestore_1.FieldValue.serverTimestamp(),
        }, { merge: true });
        if (shouldCompleteCursorAgent && runDocumentId.length > 0) {
            transaction.set(issueRef.collection("cursorAgentRuns").doc(runDocumentId), {
                status: "done",
                pullRequest: linkedPullRequest,
                completedAt: firestore_1.FieldValue.serverTimestamp(),
                updatedAt: firestore_1.FieldValue.serverTimestamp(),
            }, { merge: true });
        }
    });
}
async function syncGitHubIssueFromWebhook(payload) {
    const action = asString(payload.action);
    if (action !== "opened" && action !== "edited" && action !== "closed" && action !== "reopened") {
        return 0;
    }
    const ghIssue = payload.issue;
    const repoFullName = asString(payload.repository?.full_name);
    const number = asNumber(ghIssue?.number);
    if (!ghIssue || repoFullName.length === 0 || number <= 0) {
        return 0;
    }
    const [owner, repo] = repoFullName.split("/");
    if (!owner || !repo) {
        return 0;
    }
    if (ghIssue.pull_request !== undefined) {
        return 0;
    }
    const workspaces = await db.collection("workspaces").limit(100).get();
    let updated = 0;
    for (const workspace of workspaces.docs) {
        const workspaceRef = workspace.ref;
        const repoDoc = await workspaceRef.collection("githubRepos").doc(repoDocId(repoFullName)).get();
        if (!repoDoc.exists ||
            repoDoc.get("enabled") !== true ||
            asString(repoDoc.get("fullName")) !== repoFullName) {
            continue;
        }
        const { ref: issueRef, doc: issueDoc } = await resolveGitHubIssueDocument({
            workspaceId: workspace.id,
            owner,
            repo,
            number,
            nodeId: asString(ghIssue.node_id),
        });
        if (action === "opened" || action === "edited") {
            const existingData = issueDoc.data() ?? {};
            const title = asString(ghIssue.title, `#${number}`);
            const body = asString(ghIssue.body);
            const labels = (ghIssue.labels ?? [])
                .map((label) => (typeof label === "string" ? label : asString(label.name)))
                .filter((label) => label.length > 0);
            const assignees = (ghIssue.assignees ?? [])
                .map((assignee) => asString(assignee.login))
                .filter((login) => login.length > 0);
            const assignee = assignees[0] ?? asString(ghIssue.assignee?.login, "-");
            const keyFields = await issueKeyFields(workspaceRef.id, existingData);
            let rank = asNumber(existingData.rank);
            if (rank === 0 && !issueDoc.exists) {
                const topIssue = await workspaceRef.collection("issues").orderBy("rank").limit(1).get();
                const topDoc = topIssue.docs[0];
                const topRank = topDoc === undefined ? Date.now() : asNumber(topDoc.get("rank"));
                rank = topRank - 1000;
            }
            await issueRef.set({
                ...keyFields,
                title,
                body,
                repo: repoFullName,
                assignee,
                labels,
                comments: asNumber(ghIssue.comments),
                priority: asString(existingData.priority, "medium"),
                statusId: asString(existingData.statusId, "triage"),
                rank,
                githubIssue: githubIssueFirestoreFields(owner, repo, ghIssue),
                githubUpdatedAt: asTimestamp(ghIssue.updated_at),
                githubCreatedAt: asTimestamp(ghIssue.created_at),
                updatedAt: firestore_1.FieldValue.serverTimestamp(),
                createdAt: issueDoc.exists
                    ? (existingData.createdAt ?? firestore_1.FieldValue.serverTimestamp())
                    : firestore_1.FieldValue.serverTimestamp(),
            }, { merge: true });
            updated += 1;
        }
        else if (action === "closed" || action === "reopened") {
            if (!issueDoc.exists) {
                continue;
            }
            const issueData = issueDoc.data() ?? {};
            const currentStatusId = asString(issueData.statusId, "triage");
            if (action === "closed" && currentStatusId !== closedStatusId) {
                await issueRef.set({
                    statusId: closedStatusId,
                    "githubIssue.state": "closed",
                    updatedAt: firestore_1.FieldValue.serverTimestamp(),
                }, { merge: true });
                updated += 1;
            }
            else if (action === "reopened" && currentStatusId === closedStatusId) {
                await issueRef.set({
                    statusId: "triage",
                    "githubIssue.state": "open",
                    updatedAt: firestore_1.FieldValue.serverTimestamp(),
                }, { merge: true });
                updated += 1;
            }
        }
    }
    return updated;
}
async function linkPullRequestToImaIssues(payload) {
    const action = asString(payload.action);
    if (!["opened", "edited", "synchronize", "reopened", "closed"].includes(action)) {
        return 0;
    }
    const pullRequest = payload.pull_request;
    const repoFullName = asString(payload.repository?.full_name);
    const branch = asString(pullRequest?.head?.ref);
    const parsedIssueKey = (0, issueLinkingHelpers_1.extractIssueKey)(branch, asString(pullRequest?.title), asString(pullRequest?.body));
    if (!pullRequest || repoFullName.length === 0) {
        return 0;
    }
    const workspaces = await db.collection("workspaces").limit(100).get();
    let linked = 0;
    for (const workspace of workspaces.docs) {
        const workspaceRef = workspace.ref;
        const workspaceId = workspace.id;
        const repoDoc = await workspaceRef.collection("githubRepos").doc(repoDocId(repoFullName)).get();
        if (!repoDoc.exists ||
            repoDoc.get("enabled") !== true ||
            asString(repoDoc.get("fullName")) !== repoFullName) {
            continue;
        }
        const issueDocs = await workspaceRef.collection("issues").limit(500).get();
        for (const issueDoc of issueDocs.docs) {
            const issue = issueDoc.data();
            if (asString(issue.repo) !== repoFullName) {
                continue;
            }
            const issueKeyValue = asString(issue.issueKey).toUpperCase();
            const matchedByKey = parsedIssueKey !== null && issueKeyValue === parsedIssueKey;
            const matchesIssue = matchedByKey || pullRequestMatchesIssue(pullRequest, issue);
            if (!matchesIssue || issueKeyValue.length === 0) {
                continue;
            }
            const githubIssue = issue.githubIssue;
            const githubIssueNumber = asNumber(githubIssue?.number);
            if (githubIssueNumber <= 0) {
                continue;
            }
            const workspace = await workspaceRef.get();
            const ownerUid = asString(workspace.get("ownerUid"));
            if (ownerUid.length > 0) {
                try {
                    const token = await getGitHubToken(ownerUid);
                    const nextBody = (0, issueLinkingHelpers_1.upsertLinkedIssueBlock)(asString(pullRequest.body), githubIssueNumber, issueKeyValue);
                    if (nextBody !== asString(pullRequest.body)) {
                        const [owner, repo] = repoFullName.split("/");
                        const prNumber = asNumber(pullRequest.number);
                        if (owner && repo && prNumber > 0) {
                            await githubRequest({
                                path: `/repos/${owner}/${repo}/pulls/${prNumber}`,
                                token,
                                method: "PATCH",
                                body: { body: nextBody },
                            });
                        }
                    }
                }
                catch (error) {
                    const message = error instanceof Error ? error.message : String(error);
                    v2_1.logger.warn("githubPullRequestWebhook: failed to update PR body", {
                        workspaceId,
                        repoFullName,
                        issueKey: issueKeyValue,
                        message,
                    });
                }
            }
            await upsertPullRequestLink({
                workspaceId,
                issueId: issueDoc.id,
                action,
                pullRequest,
                repoFullName,
                branch,
            });
            linked += 1;
        }
    }
    return linked;
}
async function processBranchLogFromPush(payload) {
    const repoFullName = asString(payload.repository?.full_name);
    if (repoFullName.length === 0) {
        return 0;
    }
    const commits = payload.commits ?? [];
    const branchLogTouched = commits.some((commit) => {
        const files = [
            ...(commit.added ?? []),
            ...(commit.modified ?? []),
        ];
        return files.includes(".openci/branch-log.jsonl");
    });
    if (!branchLogTouched) {
        return 0;
    }
    const workspaces = await db.collection("workspaces").limit(100).get();
    let recorded = 0;
    for (const workspace of workspaces.docs) {
        const workspaceRef = workspace.ref;
        const workspaceId = workspace.id;
        const repoDoc = await workspaceRef.collection("githubRepos").doc(repoDocId(repoFullName)).get();
        if (!repoDoc.exists ||
            repoDoc.get("enabled") !== true ||
            asString(repoDoc.get("fullName")) !== repoFullName) {
            continue;
        }
        const ownerUid = asString(workspace.get("ownerUid"));
        if (ownerUid.length === 0) {
            continue;
        }
        let token;
        try {
            token = await getGitHubToken(ownerUid);
        }
        catch {
            v2_1.logger.warn("processBranchLog: no GitHub token for owner", { workspaceId, ownerUid });
            continue;
        }
        const [owner, repo] = repoFullName.split("/");
        if (!owner || !repo) {
            continue;
        }
        let branchLogContent;
        try {
            const ref = asString(payload.ref).replace(/^refs\/heads\//u, "");
            const fileResponse = await githubRequest({
                path: `/repos/${owner}/${repo}/contents/.openci/branch-log.jsonl`,
                token,
                queryParameters: ref.length > 0 ? { ref } : {},
            });
            if (asString(fileResponse.encoding) !== "base64") {
                continue;
            }
            branchLogContent = Buffer.from(asString(fileResponse.content), "base64").toString("utf8");
        }
        catch {
            v2_1.logger.warn("processBranchLog: failed to fetch branch-log.jsonl", {
                workspaceId,
                repoFullName,
            });
            continue;
        }
        const lines = branchLogContent.split("\n").filter((line) => line.trim().length > 0);
        for (const line of lines) {
            let entry;
            try {
                entry = JSON.parse(line);
            }
            catch {
                continue;
            }
            const branchName = asString(entry.branch);
            const createdAtStr = asString(entry.at);
            if (branchName.length === 0 || createdAtStr.length === 0) {
                continue;
            }
            const parsedIssueKey = (0, issueLinkingHelpers_1.extractIssueKey)(branchName);
            if (parsedIssueKey === null) {
                continue;
            }
            const branchCreatedAt = asTimestamp(createdAtStr);
            if (branchCreatedAt === null) {
                continue;
            }
            const issueDocs = await workspaceRef
                .collection("issues")
                .where("issueKey", "==", parsedIssueKey)
                .limit(1)
                .get();
            if (issueDocs.empty) {
                continue;
            }
            const issueDoc = issueDocs.docs[0];
            const existingBranchCreatedAt = timestampFromValue(issueDoc.get("branchCreatedAt"));
            if (existingBranchCreatedAt !== null) {
                continue;
            }
            const cursorAgent = issueDoc.get("cursorAgent");
            const cursorStartedAt = timestampFromValue(cursorAgent?.startedAt);
            const workStartedAt = cursorStartedAt ?? branchCreatedAt;
            await issueDoc.ref.set({
                branchCreatedAt,
                workStartedAt,
                updatedAt: firestore_1.FieldValue.serverTimestamp(),
            }, { merge: true });
            recorded += 1;
        }
    }
    return recorded;
}
exports.githubPullRequestWebhook = (0, https_1.onRequest)({ secrets: [githubWebhookSecret] }, async (request, response) => {
    if (request.method !== "POST") {
        response.status(405).send("Method Not Allowed");
        return;
    }
    const event = asString(request.header("x-github-event"));
    if (event !== "pull_request" && event !== "issues" && event !== "push") {
        response.status(204).send();
        return;
    }
    const rawBody = requestRawBody(request);
    const signature = asString(request.header("x-hub-signature-256"));
    if (!verifyGitHubSignature(rawBody, signature, githubWebhookSecret.value())) {
        response.status(401).send("Invalid signature");
        return;
    }
    try {
        if (event === "issues") {
            const payload = JSON.parse(rawBody.toString("utf8"));
            const updated = await syncGitHubIssueFromWebhook(payload);
            response.status(200).json({ updated });
            return;
        }
        if (event === "push") {
            const payload = JSON.parse(rawBody.toString("utf8"));
            const recorded = await processBranchLogFromPush(payload);
            response.status(200).json({ recorded });
            return;
        }
        const linked = await linkPullRequestToImaIssues(parseWebhookPayload(rawBody));
        response.status(200).json({ linked });
    }
    catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        const stack = error instanceof Error ? error.stack : undefined;
        v2_1.logger.error("githubPullRequestWebhook: failed", { event, message, stack });
        response.status(500).send("Webhook processing failed");
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
exports.estimateIssueWeight = (0, https_1.onCall)({ timeoutSeconds: 120, secrets: [anthropicApiKey] }, async (request) => {
    const workspaceId = requireNonEmptyString(request.data?.workspaceId, "workspaceId");
    const issueId = requireNonEmptyString(request.data?.issueId, "issueId");
    const uid = await verifyWorkspaceMember(request.auth, workspaceId);
    const issueDoc = await db.doc(`workspaces/${workspaceId}/issues/${issueId}`).get();
    const issue = issueDoc.data();
    if (!issue) {
        throw new https_1.HttpsError("not-found", "Issue was not found");
    }
    try {
        const weightEstimate = await estimateAndSaveIssueWeight({
            workspaceId,
            issueId,
            issue,
            force: asBoolean(request.data?.force),
            requestedBy: uid,
        });
        return { issueId, weightEstimate };
    }
    catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        v2_1.logger.error("Failed to estimate Ima issue weight", { workspaceId, issueId, uid, message });
        throw new https_1.HttpsError("internal", "Failed to estimate issue weight");
    }
});
exports.issueLifecycleEventLogger = (0, firestore_2.onDocumentWritten)("workspaces/{workspaceId}/issues/{issueId}", async (event) => {
    const after = event.data?.after?.data();
    const before = event.data?.before?.data();
    if (!after) {
        return;
    }
    const workspaceId = event.params.workspaceId;
    const issueId = event.params.issueId;
    const eventId = event.id;
    const beforeStatus = before ? asString(before.statusId, "triage") : null;
    const afterStatus = asString(after.statusId, "triage");
    const now = firestore_1.Timestamp.now();
    const updates = {};
    if (!before) {
        await writeIssueEvent({
            workspaceId,
            issueId,
            type: "created",
            eventId,
            data: {
                title: asString(after.title),
                repo: asString(after.repo),
                labels: asStringList(after.labels),
                statusId: afterStatus,
                githubCreatedAt: timestampFromValue(after.githubCreatedAt),
            },
        });
    }
    if (before && beforeStatus !== afterStatus) {
        await writeIssueEvent({
            workspaceId,
            issueId,
            type: "status_changed",
            eventId,
            data: {
                title: asString(after.title),
                repo: asString(after.repo),
                labels: asStringList(after.labels),
                fromStatusId: beforeStatus,
                toStatusId: afterStatus,
            },
        });
    }
    if (inProgressStatusIds.has(afterStatus) &&
        timestampFromValue(after.firstInProgressAt) === null) {
        updates.firstInProgressAt = now;
    }
    if (beforeStatus !== afterStatus && afterStatus === closedStatusId) {
        const createdAt = timestampFromValue(after.githubCreatedAt) ?? timestampFromValue(after.createdAt);
        const firstInProgressAt = timestampFromValue(after.firstInProgressAt);
        const cursorAgent = after.cursorAgent;
        const cursorStartedAt = timestampFromValue(cursorAgent?.startedAt);
        const branchCreatedAt = timestampFromValue(after.branchCreatedAt);
        const workStartedAt = cursorStartedAt ?? branchCreatedAt ?? firstInProgressAt;
        const workStartSource = cursorStartedAt !== null ? "cursorAgent" : branchCreatedAt !== null ? "branch" : "status";
        const leadTimeMs = createdAt === null ? null : now.toMillis() - createdAt.toMillis();
        const cycleTimeMs = workStartedAt === null ? null : now.toMillis() - workStartedAt.toMillis();
        const weightEstimate = issueWeightEstimateMap(after);
        const weightValue = typeof weightEstimate.value === "number" ? weightEstimate.value : null;
        let actualWeight = null;
        let weightDelta = null;
        const timeForWeight = cycleTimeMs ?? leadTimeMs;
        if (timeForWeight !== null) {
            const resolutionStats = await collectResolutionStats(workspaceId);
            actualWeight = deriveActualWeight(timeForWeight, resolutionStats.byWeight);
            if (weightValue !== null) {
                weightDelta = weightValue - actualWeight;
            }
        }
        updates.closedAt = now;
        updates.workStartedAt = workStartedAt ?? null;
        updates.resolution = {
            closedAt: now,
            leadTimeMs,
            cycleTimeMs,
            weightValue,
            actualWeight,
            weightDelta,
            workStartSource,
        };
        await writeIssueEvent({
            workspaceId,
            issueId,
            type: "closed",
            eventId,
            data: {
                title: asString(after.title),
                repo: asString(after.repo),
                labels: asStringList(after.labels),
                closedAt: now,
                leadTimeMs,
                cycleTimeMs,
                weightValue,
                actualWeight,
                weightDelta,
                workStartSource,
            },
        });
        const closedSubIssues = await closeDescendantSubIssues({
            workspaceId,
            issueId,
            rankBase: now.toMillis(),
        });
        if (closedSubIssues > 0) {
            v2_1.logger.info("Closed descendant sub-issues", {
                workspaceId,
                issueId,
                closedSubIssues,
            });
        }
    }
    if (beforeStatus === closedStatusId && afterStatus !== closedStatusId) {
        updates.closedAt = firestore_1.FieldValue.delete();
        updates.resolution = firestore_1.FieldValue.delete();
        updates.reopenedAt = now;
        await writeIssueEvent({
            workspaceId,
            issueId,
            type: "reopened",
            eventId,
            data: {
                title: asString(after.title),
                repo: asString(after.repo),
                labels: asStringList(after.labels),
                fromStatusId: beforeStatus,
                toStatusId: afterStatus,
                reopenedAt: now,
            },
        });
    }
    if (Object.keys(updates).length > 0) {
        await event.data?.after.ref.set(updates, { merge: true });
    }
});
exports.recomputeResolutionWeights = (0, https_1.onCall)({ timeoutSeconds: 300 }, async (request) => {
    const workspaceId = requireNonEmptyString(request.data?.workspaceId, "workspaceId");
    await verifyWorkspaceMember(request.auth, workspaceId);
    const resolutionStats = await collectResolutionStats(workspaceId);
    const snapshot = await db
        .collection(`workspaces/${workspaceId}/issues`)
        .where("statusId", "==", closedStatusId)
        .get();
    let updated = 0;
    let skipped = 0;
    const batch = db.batch();
    for (const doc of snapshot.docs) {
        const data = doc.data();
        const resolution = data.resolution;
        if (!resolution) {
            skipped++;
            continue;
        }
        if (resolution.actualWeightManualOverride === true) {
            skipped++;
            continue;
        }
        const cycleTimeMs = typeof resolution.cycleTimeMs === "number" ? resolution.cycleTimeMs : null;
        const leadTimeMs = typeof resolution.leadTimeMs === "number" ? resolution.leadTimeMs : null;
        const timeForWeight = cycleTimeMs ?? leadTimeMs;
        if (timeForWeight === null) {
            skipped++;
            continue;
        }
        const oldActual = typeof resolution.actualWeight === "number" ? resolution.actualWeight : null;
        const newActual = deriveActualWeight(timeForWeight, resolutionStats.byWeight);
        if (oldActual === newActual) {
            skipped++;
            continue;
        }
        const weightValue = typeof resolution.weightValue === "number" ? resolution.weightValue : null;
        const newDelta = weightValue !== null ? weightValue - newActual : null;
        batch.update(doc.ref, {
            "resolution.actualWeight": newActual,
            "resolution.weightDelta": newDelta,
        });
        updated++;
    }
    if (updated > 0) {
        await batch.commit();
    }
    v2_1.logger.info("recomputeResolutionWeights", { workspaceId, updated, skipped });
    return { updated, skipped };
});
exports.autoEstimateIssueWeightOnIssueWrite = (0, firestore_2.onDocumentWritten)({
    document: "workspaces/{workspaceId}/issues/{issueId}",
    timeoutSeconds: 120,
    secrets: [anthropicApiKey],
}, async (event) => {
    const after = event.data?.after?.data();
    if (!after) {
        return;
    }
    const before = event.data?.before?.data();
    const afterInputHash = (0, issueWeightHelpers_1.issueWeightInputHash)(after);
    if (before && (0, issueWeightHelpers_1.issueWeightInputHash)(before) === afterInputHash) {
        return;
    }
    const existing = issueWeightEstimateMap(after);
    if (existing.manualOverride === true) {
        return;
    }
    const existingStatus = asString(existing.status);
    if (asString(existing.inputHash) === afterInputHash &&
        (existingStatus === "done" || existingStatus === "estimating" || existingStatus === "failed")) {
        return;
    }
    const workspaceId = event.params.workspaceId;
    const issueId = event.params.issueId;
    try {
        await estimateAndSaveIssueWeight({
            workspaceId,
            issueId,
            issue: after,
            force: false,
        });
    }
    catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        v2_1.logger.error("autoEstimateIssueWeight: failed", { workspaceId, issueId, message });
    }
});
exports.autoSyncIssueToGitHubOnIssueWrite = (0, firestore_2.onDocumentWritten)("workspaces/{workspaceId}/issues/{issueId}", async (event) => {
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