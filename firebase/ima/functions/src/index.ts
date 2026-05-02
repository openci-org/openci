import { createHmac, timingSafeEqual } from "node:crypto";

import { getApps, initializeApp } from "firebase-admin/app";
import { FieldValue, Timestamp, getFirestore } from "firebase-admin/firestore";
import { defineSecret } from "firebase-functions/params";
import { logger, setGlobalOptions } from "firebase-functions/v2";
import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { HttpsError, onCall, onRequest, type CallableRequest, type Request } from "firebase-functions/v2/https";

import {
  issueWeightInput,
  issueWeightInputHash,
  issueWeightPromptVersion,
  parseWeightEstimateResponse,
  truncateText,
} from "./issueWeightHelpers";
import { extractIssueKey, issueKey, normalizeIssueKeyPrefix, upsertLinkedIssueBlock } from "./issueLinkingHelpers";

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

interface CreateGitHubIssueRequest extends WorkspaceRequest {
  title: string;
  body?: string;
  repo: string;
  assignee?: string;
  labels?: string[];
  statusId: string;
  priority: string;
  rank: number;
  dueDate?: string;
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

interface BackfillIssueKeysResponse {
  updated: number;
}

interface CreateGitHubIssueResponse {
  issueId: string;
  number: number;
  url: string;
}

interface EstimateIssueWeightRequest extends WorkspaceRequest {
  issueId: string;
  force?: boolean;
}

interface IssueWeightEstimateResponse {
  value: number;
  confidence: number;
  reason: string;
  model: string;
  promptVersion: string;
  inputHash: string;
  source: "llm";
  status: "done";
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

interface GitHubPullRequestWebhookPayload {
  action?: unknown;
  repository?: {
    full_name?: unknown;
  };
  pull_request?: {
    number?: unknown;
    title?: unknown;
    body?: unknown;
    html_url?: unknown;
    state?: unknown;
    merged?: unknown;
    head?: {
      ref?: unknown;
    };
  };
}

const db = getFirestore();
const anthropicApiKey = defineSecret("ANTHROPIC_API_KEY");
const githubWebhookSecret = defineSecret("GITHUB_WEBHOOK_SECRET");
const closedStatusId = "done";
const inProgressStatusIds = new Set(["doing", "review"]);
const issueWeightModel = "claude-opus-4-6";

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
  method?: "GET" | "PATCH" | "POST";
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

function pullRequestLinkId(owner: string, repo: string, number: number): string {
  return `${owner}_${repo}_${number}`.replace(/[^a-zA-Z0-9_-]/gu, "_");
}

function asString(value: unknown, fallback = ""): string {
  return typeof value === "string" && value.length > 0 ? value : fallback;
}

function asNumber(value: unknown, fallback = 0): number {
  return typeof value === "number" ? value : fallback;
}

function asBoolean(value: unknown, fallback = false): boolean {
  return typeof value === "boolean" ? value : fallback;
}

function issueKeyFieldsFromData(data: Record<string, unknown>): Record<string, unknown> | null {
  const existingIssueKey = asString(data.issueKey);
  if (existingIssueKey.length === 0) {
    return null;
  }

  const existingNumber = asNumber(data.issueNumber);
  const prefix = normalizeIssueKeyPrefix(asString(data.issueKeyPrefix, existingIssueKey.split("-")[0] ?? "IMA"));
  return {
    issueKeyPrefix: prefix,
    issueNumber: existingNumber > 0 ? existingNumber : null,
    issueKey: existingIssueKey.toUpperCase(),
  };
}

async function nextIssueKeyFields(workspaceId: string): Promise<Record<string, unknown>> {
  const workspaceRef = db.doc(`workspaces/${workspaceId}`);
  const counterRef = workspaceRef.collection("counters").doc("issues");

  return db.runTransaction(async (transaction) => {
    const [workspace, counter] = await Promise.all([
      transaction.get(workspaceRef),
      transaction.get(counterRef),
    ]);
    const prefix = normalizeIssueKeyPrefix(asString(workspace.get("issueKeyPrefix"), "IMA"));
    const nextNumber = asNumber(counter.get("lastIssueNumber")) + 1;
    transaction.set(
      counterRef,
      {
        issueKeyPrefix: prefix,
        lastIssueNumber: nextNumber,
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    return {
      issueKeyPrefix: prefix,
      issueNumber: nextNumber,
      issueKey: issueKey(prefix, nextNumber),
    };
  });
}

async function issueKeyFields(
  workspaceId: string,
  data: Record<string, unknown>,
): Promise<Record<string, unknown>> {
  return issueKeyFieldsFromData(data) ?? nextIssueKeyFields(workspaceId);
}

function asStringList(value: unknown): string[] {
  if (!Array.isArray(value)) {
    return [];
  }
  return value.filter((item): item is string => typeof item === "string" && item.length > 0);
}

function asTimestamp(value: unknown): Timestamp | null {
  if (typeof value !== "string") {
    return null;
  }
  const date = new Date(value);
  return Number.isNaN(date.valueOf()) ? null : Timestamp.fromDate(date);
}

function timestampFromValue(value: unknown): Timestamp | null {
  if (value instanceof Timestamp) {
    return value;
  }
  if (value instanceof Date) {
    return Timestamp.fromDate(value);
  }
  return asTimestamp(value);
}

function roundedHours(milliseconds: number | null): number | null {
  if (milliseconds === null) {
    return null;
  }
  return Math.round((milliseconds / 3_600_000) * 10) / 10;
}

function median(values: number[]): number | null {
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

function issueWeightEstimateMap(issue: Record<string, unknown>): Record<string, unknown> {
  const estimate = issue.weightEstimate;
  return typeof estimate === "object" && estimate !== null ? (estimate as Record<string, unknown>) : {};
}

function normalizeIssueWeightEstimate(
  estimate: Record<string, unknown>,
): IssueWeightEstimateResponse | null {
  const value = asNumber(estimate.value);
  const confidence = asNumber(estimate.confidence);
  const reason = asString(estimate.reason);
  const model = asString(estimate.model);
  const inputHash = asString(estimate.inputHash);
  if (
    value < 1 ||
    value > 8 ||
    confidence < 0 ||
    confidence > 1 ||
    reason.length === 0 ||
    model.length === 0 ||
    inputHash.length === 0
  ) {
    return null;
  }
  return {
    value,
    confidence,
    reason,
    model,
    promptVersion: asString(estimate.promptVersion, issueWeightPromptVersion),
    inputHash,
    source: "llm",
    status: "done",
  };
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

function issueEventDocId(eventId: string | undefined, issueId: string, type: string): string {
  const source = eventId && eventId.length > 0 ? eventId : `${issueId}_${type}_${Date.now()}`;
  return `${source}_${type}`.replace(/[^a-zA-Z0-9_-]/gu, "_");
}

async function writeIssueEvent({
  workspaceId,
  issueId,
  type,
  eventId,
  data,
}: {
  workspaceId: string;
  issueId: string;
  type: string;
  eventId?: string;
  data: Record<string, unknown>;
}): Promise<void> {
  await db
    .doc(`workspaces/${workspaceId}/issueEvents/${issueEventDocId(eventId, issueId, type)}`)
    .set(
      {
        issueId,
        type,
        ...data,
        createdAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
}

interface ClosedIssueStatsEvent {
  title: string;
  repo: string;
  labels: string[];
  weightValue: number | null;
  leadTimeMs: number | null;
  cycleTimeMs: number | null;
  closedAt: Timestamp | null;
}

interface ResolutionStats {
  recentWindowDays: number;
  resolvedCount: number;
  medianLeadTimeHours: number | null;
  medianCycleTimeHours: number | null;
  byWeight: Record<string, { count: number; medianLeadTimeHours: number | null }>;
  byLabel: Record<string, { count: number; medianLeadTimeHours: number | null }>;
  recentExamples: Array<{
    title: string;
    repo: string;
    labels: string[];
    weight: number | null;
    leadTimeHours: number | null;
    cycleTimeHours: number | null;
  }>;
}

function closedIssueStatsEvent(data: Record<string, unknown>): ClosedIssueStatsEvent | null {
  if (asString(data.type) !== "closed") {
    return null;
  }
  return {
    title: asString(data.title),
    repo: asString(data.repo),
    labels: asStringList(data.labels),
    weightValue: typeof data.weightValue === "number" ? data.weightValue : null,
    leadTimeMs: typeof data.leadTimeMs === "number" ? data.leadTimeMs : null,
    cycleTimeMs: typeof data.cycleTimeMs === "number" ? data.cycleTimeMs : null,
    closedAt: timestampFromValue(data.closedAt),
  };
}

function bucketMedian(
  events: ClosedIssueStatsEvent[],
  keyForEvent: (event: ClosedIssueStatsEvent) => string[],
): Record<string, { count: number; medianLeadTimeHours: number | null }> {
  const buckets = new Map<string, number[]>();
  for (const event of events) {
    if (event.leadTimeMs === null) {
      continue;
    }
    for (const key of keyForEvent(event)) {
      const existing = buckets.get(key) ?? [];
      existing.push(event.leadTimeMs);
      buckets.set(key, existing);
    }
  }
  return Object.fromEntries(
    [...buckets.entries()]
      .sort((left, right) => right[1].length - left[1].length)
      .slice(0, 20)
      .map(([key, values]) => [
        key,
        {
          count: values.length,
          medianLeadTimeHours: roundedHours(median(values)),
        },
      ]),
  );
}

async function collectResolutionStats(workspaceId: string): Promise<ResolutionStats> {
  const snapshot = await db
    .collection(`workspaces/${workspaceId}/issueEvents`)
    .orderBy("createdAt", "desc")
    .limit(200)
    .get();
  const closedEvents = snapshot.docs
    .map((doc) => closedIssueStatsEvent(doc.data()))
    .filter((event): event is ClosedIssueStatsEvent => event !== null);
  const now = Date.now();
  const withinDays = (days: number) =>
    closedEvents.filter((event) => {
      const closedAt = event.closedAt?.toMillis();
      return closedAt !== undefined && now - closedAt <= days * 24 * 60 * 60 * 1000;
    });
  const recent30 = withinDays(30);
  const selected = recent30.length >= 10 ? recent30 : withinDays(90);
  const recentWindowDays = recent30.length >= 10 ? 30 : 90;
  const leadTimes = selected
    .map((event) => event.leadTimeMs)
    .filter((value): value is number => value !== null);
  const cycleTimes = selected
    .map((event) => event.cycleTimeMs)
    .filter((value): value is number => value !== null);

  return {
    recentWindowDays,
    resolvedCount: selected.length,
    medianLeadTimeHours: roundedHours(median(leadTimes)),
    medianCycleTimeHours: roundedHours(median(cycleTimes)),
    byWeight: bucketMedian(selected, (event) =>
      event.weightValue === null ? [] : [String(event.weightValue)],
    ),
    byLabel: bucketMedian(selected, (event) => event.labels),
    recentExamples: selected.slice(0, 30).map((event) => ({
      title: truncateText(event.title, 120),
      repo: event.repo,
      labels: event.labels.slice(0, 8),
      weight: event.weightValue,
      leadTimeHours: roundedHours(event.leadTimeMs),
      cycleTimeHours: roundedHours(event.cycleTimeMs),
    })),
  };
}

async function createAnthropicMessage(system: string, content: string): Promise<string> {
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
  const data = (await response.json()) as {
    content?: Array<{ type?: string; text?: string }>;
    error?: { message?: string };
  };
  if (!response.ok) {
    throw new Error(data.error?.message ?? `Anthropic API error: ${response.status}`);
  }
  return (data.content ?? [])
    .filter((block) => block.type === "text" && typeof block.text === "string")
    .map((block) => block.text)
    .join("");
}

async function estimateIssueWeightWithLlm(
  workspaceId: string,
  issue: Record<string, unknown>,
): Promise<Pick<IssueWeightEstimateResponse, "value" | "confidence" | "reason">> {
  const resolutionStats = await collectResolutionStats(workspaceId);
  const system = [
    "You estimate issue weight for a software team's issue board.",
    "Return only JSON with keys: value, confidence, reason.",
    "value must be an integer from 1 to 8 where 1 is tiny and 8 is very large.",
    "confidence must be a number from 0 to 1.",
    "reason must be short Japanese text, within 80 characters.",
    "Use the team's recent resolution speed statistics when available.",
  ].join("\n");
  const content = JSON.stringify(
    {
      issue: issueWeightInput(issue),
      resolutionStats,
    },
    null,
    2,
  );
  return parseWeightEstimateResponse(await createAnthropicMessage(system, content));
}

async function estimateAndSaveIssueWeight({
  workspaceId,
  issueId,
  issue,
  force,
  requestedBy,
}: {
  workspaceId: string;
  issueId: string;
  issue: Record<string, unknown>;
  force: boolean;
  requestedBy?: string;
}): Promise<IssueWeightEstimateResponse> {
  const inputHash = issueWeightInputHash(issue);
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
  await issueRef.set(
    {
      weightEstimate: {
        status: "estimating",
        inputHash,
        promptVersion: issueWeightPromptVersion,
        model: issueWeightModel,
        updatedAt: FieldValue.serverTimestamp(),
      },
    },
    { merge: true },
  );

  const start = Date.now();
  try {
    const parsed = await estimateIssueWeightWithLlm(workspaceId, issue);
    const estimate: IssueWeightEstimateResponse = {
      ...parsed,
      model: issueWeightModel,
      promptVersion: issueWeightPromptVersion,
      inputHash,
      source: "llm",
      status: "done",
    };
    const durationMs = Date.now() - start;
    await issueRef.set(
      {
        weightEstimate: {
          ...estimate,
          durationMs,
          requestedBy: requestedBy ?? null,
          estimatedAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        },
      },
      { merge: true },
    );
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
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    await issueRef.set(
      {
        weightEstimate: {
          status: "failed",
          inputHash,
          promptVersion: issueWeightPromptVersion,
          model: issueWeightModel,
          error: truncateText(message, 500),
          failedAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        },
      },
      { merge: true },
    );
    await writeIssueEvent({
      workspaceId,
      issueId,
      type: "weight_estimation_failed",
      data: {
        title: asString(issue.title),
        repo: asString(issue.repo),
        labels: asStringList(issue.labels),
        model: issueWeightModel,
        promptVersion: issueWeightPromptVersion,
        inputHash,
        error: truncateText(message, 500),
        requestedBy: requestedBy ?? null,
      },
    });
    throw error;
  }
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
      const message = error instanceof Error ? error.message : String(error);
      logger.error("Failed to connect GitHub", { workspaceId, uid, message });
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
    const message = error instanceof Error ? error.message : String(error);
    logger.error("Failed to complete GitHub device flow", { workspaceId, uid, message });
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
    const message = error instanceof Error ? error.message : String(error);
    logger.error("Failed to list Ima GitHub repositories", { workspaceId, uid, message });
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
          const keyFields = await issueKeyFields(workspaceId, existingData);
          batch.set(
            docRef,
            {
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
    const message = error instanceof Error ? error.message : String(error);
    logger.error("Failed to import Ima GitHub issues", { workspaceId, uid, message });
    throw new HttpsError("internal", "Failed to import GitHub issues");
  }
});

export const createGitHubIssue = onCall<
  CreateGitHubIssueRequest,
  Promise<CreateGitHubIssueResponse>
>(async (request) => {
  const workspaceId = requireNonEmptyString(request.data?.workspaceId, "workspaceId");
  const uid = await verifyWorkspaceMember(request.auth, workspaceId);
  const token = await getGitHubToken(uid);
  const title = requireNonEmptyString(request.data?.title, "title");
  const repoFullName = requireNonEmptyString(request.data?.repo, "repo");
  const [owner, repo] = repoFullName.split("/");
  if (!owner || !repo) {
    throw new HttpsError("invalid-argument", "repo must be owner/repo");
  }

  const body = asString(request.data?.body);
  const assignee = asString(request.data?.assignee);
  const labels = Array.isArray(request.data?.labels)
    ? request.data.labels.filter((label): label is string => typeof label === "string" && label.length > 0)
    : [];
  const githubAssignee = assignee.startsWith("@") ? assignee.slice(1) : "";
  const assignees = githubAssignee.length > 0 ? [githubAssignee] : [];

  try {
    logger.info("Creating GitHub issue", { workspaceId, repoFullName, owner, repo, title });
    const issue = await githubRequest<GitHubIssueResponseItem>({
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
      throw new HttpsError("failed-precondition", "GitHub issue could not be created");
    }

    const issueId = issueDocId(owner, repo, number);
    const docRef = db.doc(`workspaces/${workspaceId}/issues/${issueId}`);
    const keyFields = await issueKeyFields(workspaceId, {});
    await docRef.set(
      {
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
        createdAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    return {
      issueId,
      number,
      url: asString(issue.html_url),
    };
  } catch (error) {
    if (error instanceof HttpsError) {
      throw error;
    }
    const message = error instanceof Error ? error.message : String(error);
    const stack = error instanceof Error ? error.stack : undefined;
    logger.error("Failed to create Ima GitHub issue", { workspaceId, uid, repoFullName, message, stack });
    throw new HttpsError("internal", `Failed to create GitHub issue: ${message}`);
  }
});

export const backfillIssueKeys = onCall<WorkspaceRequest, Promise<BackfillIssueKeysResponse>>(
  async (request) => {
    const workspaceId = requireNonEmptyString(request.data?.workspaceId, "workspaceId");
    await verifyWorkspaceMember(request.auth, workspaceId);

    const issues = await db
      .collection(`workspaces/${workspaceId}/issues`)
      .limit(500)
      .get();

    let updated = 0;
    for (const issue of issues.docs) {
      if (issueKeyFieldsFromData(issue.data()) !== null) {
        continue;
      }
      await issue.ref.set(
        {
          ...(await nextIssueKeyFields(workspaceId)),
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
      updated += 1;
    }

    return { updated };
  },
);

function verifyGitHubSignature(rawBody: Buffer, signatureHeader: string, secret: string): boolean {
  if (!signatureHeader.startsWith("sha256=") || secret.length === 0) {
    return false;
  }

  const expected = `sha256=${createHmac("sha256", secret).update(rawBody).digest("hex")}`;
  const actualBuffer = Buffer.from(signatureHeader, "utf8");
  const expectedBuffer = Buffer.from(expected, "utf8");
  return actualBuffer.length === expectedBuffer.length && timingSafeEqual(actualBuffer, expectedBuffer);
}

function requestRawBody(request: Request): Buffer {
  const rawBody = (request as typeof request & { rawBody?: Buffer }).rawBody;
  if (Buffer.isBuffer(rawBody)) {
    return rawBody;
  }
  return Buffer.from(JSON.stringify(request.body ?? {}), "utf8");
}

function parseWebhookPayload(rawBody: Buffer): GitHubPullRequestWebhookPayload {
  return JSON.parse(rawBody.toString("utf8")) as GitHubPullRequestWebhookPayload;
}

async function upsertPullRequestLink({
  workspaceId,
  issueId,
  pullRequest,
  repoFullName,
  branch,
}: {
  workspaceId: string;
  issueId: string;
  pullRequest: NonNullable<GitHubPullRequestWebhookPayload["pull_request"]>;
  repoFullName: string;
  branch: string;
}): Promise<void> {
  const [owner, repo] = repoFullName.split("/");
  const number = asNumber(pullRequest.number);
  if (!owner || !repo || number <= 0) {
    return;
  }

  const issueRef = db.doc(`workspaces/${workspaceId}/issues/${issueId}`);
  await db.runTransaction(async (transaction) => {
    const issue = await transaction.get(issueRef);
    const currentPullRequests = Array.isArray(issue.get("pullRequests"))
      ? (issue.get("pullRequests") as Array<Record<string, unknown>>)
      : [];
    const linkId = pullRequestLinkId(owner, repo, number);
    const now = Timestamp.now();
    const existingLink = currentPullRequests.find((item) => asString(item.id) === linkId);
    const nextPullRequests = currentPullRequests.filter((item) => asString(item.id) !== linkId);
    nextPullRequests.push({
      id: linkId,
      owner,
      repo,
      number,
      url: asString(pullRequest.html_url),
      title: asString(pullRequest.title),
      branch,
      state: asString(pullRequest.state, "open"),
      merged: asBoolean(pullRequest.merged),
      linkedAt: timestampFromValue(existingLink?.linkedAt) ?? now,
      updatedAt: now,
    });
    transaction.set(
      issueRef,
      {
        pullRequests: nextPullRequests,
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  });
}

async function linkPullRequestToImaIssues(payload: GitHubPullRequestWebhookPayload): Promise<number> {
  const action = asString(payload.action);
  if (!["opened", "edited", "synchronize", "reopened", "closed"].includes(action)) {
    return 0;
  }

  const pullRequest = payload.pull_request;
  const repoFullName = asString(payload.repository?.full_name);
  const branch = asString(pullRequest?.head?.ref);
  const parsedIssueKey = extractIssueKey(
    branch,
    asString(pullRequest?.title),
    asString(pullRequest?.body),
  );
  if (!pullRequest || repoFullName.length === 0 || parsedIssueKey === null) {
    return 0;
  }

  const repoDocs = await db
    .collectionGroup("githubRepos")
    .where("fullName", "==", repoFullName)
    .where("enabled", "==", true)
    .get();

  let linked = 0;
  for (const repoDoc of repoDocs.docs) {
    const workspaceRef = repoDoc.ref.parent.parent;
    const workspaceId = workspaceRef?.id;
    if (!workspaceRef || !workspaceId) {
      continue;
    }

    const issueDocs = await workspaceRef
      .collection("issues")
      .where("repo", "==", repoFullName)
      .where("issueKey", "==", parsedIssueKey)
      .limit(5)
      .get();

    for (const issueDoc of issueDocs.docs) {
      const issue = issueDoc.data();
      const githubIssue = issue.githubIssue as Record<string, unknown> | undefined;
      const githubIssueNumber = asNumber(githubIssue?.number);
      if (githubIssueNumber <= 0) {
        continue;
      }

      const workspace = await workspaceRef.get();
      const ownerUid = asString(workspace.get("ownerUid"));
      if (ownerUid.length > 0) {
        try {
          const token = await getGitHubToken(ownerUid);
          const nextBody = upsertLinkedIssueBlock(
            asString(pullRequest.body),
            githubIssueNumber,
            parsedIssueKey,
          );
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
        } catch (error) {
          const message = error instanceof Error ? error.message : String(error);
          logger.warn("githubPullRequestWebhook: failed to update PR body", {
            workspaceId,
            repoFullName,
            issueKey: parsedIssueKey,
            message,
          });
        }
      }

      await upsertPullRequestLink({
        workspaceId,
        issueId: issueDoc.id,
        pullRequest,
        repoFullName,
        branch,
      });
      linked += 1;
    }
  }

  return linked;
}

export const githubPullRequestWebhook = onRequest(
  { secrets: [githubWebhookSecret] },
  async (request, response) => {
    if (request.method !== "POST") {
      response.status(405).send("Method Not Allowed");
      return;
    }

    const event = asString(request.header("x-github-event"));
    if (event !== "pull_request") {
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
      const linked = await linkPullRequestToImaIssues(parseWebhookPayload(rawBody));
      response.status(200).json({ linked });
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.error("githubPullRequestWebhook: failed", { message });
      response.status(500).send("Webhook processing failed");
    }
  },
);

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

export const estimateIssueWeight = onCall<
  EstimateIssueWeightRequest,
  Promise<{ issueId: string; weightEstimate: IssueWeightEstimateResponse }>
>({ timeoutSeconds: 120, secrets: [anthropicApiKey] }, async (request) => {
  const workspaceId = requireNonEmptyString(request.data?.workspaceId, "workspaceId");
  const issueId = requireNonEmptyString(request.data?.issueId, "issueId");
  const uid = await verifyWorkspaceMember(request.auth, workspaceId);
  const issueDoc = await db.doc(`workspaces/${workspaceId}/issues/${issueId}`).get();
  const issue = issueDoc.data();
  if (!issue) {
    throw new HttpsError("not-found", "Issue was not found");
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
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    logger.error("Failed to estimate Ima issue weight", { workspaceId, issueId, uid, message });
    throw new HttpsError("internal", "Failed to estimate issue weight");
  }
});

export const issueLifecycleLogger = onDocumentWritten(
  "workspaces/{workspaceId}/issues/{issueId}",
  async (event) => {
    const after = event.data?.after?.data();
    const before = event.data?.before?.data();
    if (!after) {
      return;
    }

    const workspaceId = event.params.workspaceId;
    const issueId = event.params.issueId;
    const eventId = (event as { id?: string }).id;
    const beforeStatus = before ? asString(before.statusId, "triage") : null;
    const afterStatus = asString(after.statusId, "triage");
    const now = Timestamp.now();
    const updates: Record<string, unknown> = {};

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

    if (inProgressStatusIds.has(afterStatus) && timestampFromValue(after.firstInProgressAt) === null) {
      updates.firstInProgressAt = now;
    }

    if (beforeStatus !== afterStatus && afterStatus === closedStatusId) {
      const createdAt = timestampFromValue(after.githubCreatedAt) ?? timestampFromValue(after.createdAt);
      const firstInProgressAt = timestampFromValue(after.firstInProgressAt);
      const leadTimeMs = createdAt === null ? null : now.toMillis() - createdAt.toMillis();
      const cycleTimeMs = firstInProgressAt === null ? null : now.toMillis() - firstInProgressAt.toMillis();
      const weightEstimate = issueWeightEstimateMap(after);
      const weightValue = typeof weightEstimate.value === "number" ? weightEstimate.value : null;
      updates.closedAt = now;
      updates.resolution = {
        closedAt: now,
        leadTimeMs,
        cycleTimeMs,
        weightValue,
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
        },
      });
    }

    if (beforeStatus === closedStatusId && afterStatus !== closedStatusId) {
      updates.closedAt = FieldValue.delete();
      updates.resolution = FieldValue.delete();
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
  },
);

export const autoEstimateIssueWeight = onDocumentWritten(
  {
    document: "workspaces/{workspaceId}/issues/{issueId}",
    timeoutSeconds: 120,
    secrets: [anthropicApiKey],
  },
  async (event) => {
    const after = event.data?.after?.data();
    if (!after) {
      return;
    }

    const before = event.data?.before?.data();
    const afterInputHash = issueWeightInputHash(after);
    if (before && issueWeightInputHash(before) === afterInputHash) {
      return;
    }

    const existing = issueWeightEstimateMap(after);
    const existingStatus = asString(existing.status);
    if (
      asString(existing.inputHash) === afterInputHash &&
      (existingStatus === "done" || existingStatus === "estimating" || existingStatus === "failed")
    ) {
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
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.error("autoEstimateIssueWeight: failed", { workspaceId, issueId, message });
    }
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
