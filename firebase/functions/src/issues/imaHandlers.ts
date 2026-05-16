import { getApps, initializeApp } from "firebase-admin/app";
import {
  FieldValue,
  Timestamp,
  getFirestore,
  type DocumentReference,
  type DocumentSnapshot,
} from "firebase-admin/firestore";
import { defineSecret } from "firebase-functions/params";
import { logger } from "firebase-functions/v2";
import { onDocumentWritten } from "firebase-functions/v2/firestore";
import { HttpsError, onCall, type CallableRequest } from "firebase-functions/v2/https";
import { firebaseRegion } from "../firebaseRegion.js";
import { firestoreCollectionPaths, getTeamById } from "../firestoreData.js";
import {
  getInstallationToken,
  githubAppId,
  githubGraphql,
  githubPrivateKey,
} from "../github/githubApp.js";

import {
  extractIssueKey,
  isOnlyLinkedIssueBlockChange,
  issueKey,
  issueStatusForPullRequest,
  normalizeIssueKeyPrefix,
  replaceLinkedIssueBlocks,
} from "./issueLinkingHelpers.js";
import {
  isAdjacentWeight,
  isValidWeight,
  issueWeightInput,
  issueWeightInputHash,
  issueWeightPromptVersion,
  parseWeightEstimateResponse,
  truncateText,
} from "./issueWeightHelpers.js";
import {
  asBoolean,
  asNumber,
  asString,
  asStringList,
  asTimestamp,
  branchLogPathPrefix,
  closedStatusId,
  errorMessage,
  errorStack,
  inProgressStatusIds,
  issueWeightModel,
  median,
  recordList,
  requireNonEmptyString,
  requireUid,
  reviewStatusId,
  roundedHours,
  timestampFromValue,
} from "./shared.js";
import type {
  BackfillCursorAgentPullRequestsResponse,
  BackfillIssueKeysResponse,
  BranchLogEntry,
  CompleteGitHubDeviceFlowRequest,
  CreateGitHubIssueRequest,
  CreateGitHubIssueResponse,
  CreateGitHubSubIssueRequest,
  CreateGitHubSubIssueResponse,
  EstimateIssueWeightRequest,
  GetIssuePullRequestDiffRequest,
  GetIssuePullRequestDiffResponse,
  GitHubContentFileResponse,
  GitHubDeviceCodeResponse,
  GitHubDeviceTokenResponse,
  GitHubInstallationRepositoriesResponse,
  GitHubIssueCommentResponseItem,
  GitHubIssueResponseItem,
  GitHubIssueWebhookPayload,
  GitHubMergePullRequestResponseItem,
  GitHubPullRequestFileResponseItem,
  GitHubPullRequestLinkedIssue,
  GitHubPullRequestLinkedIssuesGraphqlResponse,
  GitHubPullRequestResponseItem,
  GitHubPullRequestReviewCommentResponseItem,
  GitHubPullRequestWebhookPayload,
  GitHubPushWebhookPayload,
  GitHubRepositoriesResponseItem,
  GitHubRepository,
  GitHubUserResponse,
  ImportGitHubIssuesResponse,
  IssuePullRequestComment,
  IssueWeightEstimateResponse,
  ListGitHubRepositoriesResponse,
  MergeIssuePullRequestRequest,
  MergeIssuePullRequestResponse,
  PullRequestCiSummary,
  StartGitHubDeviceFlowRequest,
  StartGitHubDeviceFlowResponse,
  StartIssueCursorAgentRequest,
  StartIssueCursorAgentResponse,
  SyncGitHubIssuesResponse,
  WorkspaceRequest,
} from "./types.js";

if (getApps().length === 0) {
  initializeApp();
}

const db = getFirestore();
const anthropicApiKey = defineSecret("ANTHROPIC_API_KEY");
const cursorApiKey = defineSecret("CURSOR_API_KEY");
const githubAppSecrets = [githubAppId, githubPrivateKey];

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

async function getWorkspaceGitHubToken(workspaceId: string): Promise<{
  token: string;
  installationId: number;
  apiBaseUrl: string;
}> {
  const team = await getTeamById({ teamId: workspaceId });
  const installationIds = team.data.team?.installationIds ?? [];
  const installationId = installationIds.find(
    (id: unknown): id is number => typeof id === "number" && Number.isInteger(id) && id > 0,
  );
  if (installationId === undefined) {
    throw new HttpsError("failed-precondition", "OpenCI GitHub App is not installed");
  }

  const apiBaseUrl = asString(team.data.team?.githubApiBaseUrl, "https://api.github.com");
  const { token } = await getInstallationToken(installationId, { apiBaseUrl });
  return { token, installationId, apiBaseUrl };
}

async function githubRequest<T>({
  path,
  token,
  method = "GET",
  body,
  queryParameters,
  apiVersion = "2022-11-28",
}: {
  path: string;
  token: string;
  method?: "GET" | "PATCH" | "POST" | "PUT";
  body?: unknown;
  queryParameters?: Record<string, string | number | boolean>;
  apiVersion?: string;
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
      "x-github-api-version": apiVersion,
    },
    body: body === undefined ? undefined : JSON.stringify(body),
  });

  if (!response.ok) {
    const message = await response.text();
    throw new Error(`GitHub request failed: ${response.status} ${message}`);
  }

  return (await response.json()) as T;
}

async function githubOAuthRequest<T>(path: string, body: Record<string, string>): Promise<T> {
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

function issueDocId(owner: string, repo: string, number: number): string {
  return `gh_${owner}_${repo}_${number}`.replace(/[^a-zA-Z0-9_-]/gu, "_");
}

async function resolveGitHubIssueDocument(input: {
  workspaceId: string;
  owner: string;
  repo: string;
  number: number;
  nodeId?: string;
}): Promise<{
  ref: DocumentReference;
  doc: DocumentSnapshot;
}> {
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
      const existingDoc = existing.docs[0]!;
      return { ref: existingDoc.ref, doc: existingDoc };
    }
  }

  const existingByNumber = await issuesRef
    .where("githubIssue.number", "==", input.number)
    .limit(20)
    .get();
  const matchingDoc = existingByNumber.docs.find((doc) => {
    const githubIssue = doc.get("githubIssue") as Record<string, unknown> | undefined;
    return (
      asString(githubIssue?.owner) === input.owner &&
      asString(githubIssue?.repo) === input.repo &&
      asNumber(githubIssue?.number) === input.number
    );
  });
  if (matchingDoc !== undefined) {
    return { ref: matchingDoc.ref, doc: matchingDoc };
  }

  return { ref: canonicalRef, doc: canonicalDoc };
}

function pullRequestLinkId(owner: string, repo: string, number: number): string {
  return `${owner}_${repo}_${number}`.replace(/[^a-zA-Z0-9_-]/gu, "_");
}

function repositoryParts(repoFullName: string): {
  owner: string;
  repo: string;
} {
  const [owner, repo] = repoFullName.split("/");
  if (!owner || !repo) {
    throw new HttpsError("invalid-argument", "repository must be owner/repo");
  }
  return { owner, repo };
}

async function linkedIssuePullRequest(input: {
  workspaceId: string;
  issueId: string;
  repository: string;
  pullRequestNumber: number;
}): Promise<{
  issueRef: DocumentReference;
  owner: string;
  repo: string;
  linkId: string;
  pullRequest: Record<string, unknown>;
}> {
  const { owner, repo } = repositoryParts(input.repository);
  if (input.pullRequestNumber <= 0) {
    throw new HttpsError("invalid-argument", "pullRequestNumber must be positive");
  }

  const issueRef = db.doc(`workspaces/${input.workspaceId}/issues/${input.issueId}`);
  const issueDoc = await issueRef.get();
  if (!issueDoc.exists) {
    throw new HttpsError("not-found", "Issue was not found");
  }
  if (asString(issueDoc.get("repo")) !== input.repository) {
    throw new HttpsError("failed-precondition", "Pull request repository does not match issue");
  }

  const linkId = pullRequestLinkId(owner, repo, input.pullRequestNumber);
  const pullRequest = recordList(issueDoc.get("pullRequests")).find((item) => {
    if (asString(item.id) === linkId) {
      return true;
    }
    return (
      asString(item.owner) === owner &&
      asString(item.repo) === repo &&
      asNumber(item.number) === input.pullRequestNumber
    );
  });

  if (pullRequest === undefined) {
    throw new HttpsError("failed-precondition", "Pull request is not linked to this issue");
  }

  return {
    issueRef,
    owner,
    repo,
    linkId,
    pullRequest,
  };
}

function truncatePullRequestPatch(value: unknown): {
  patch: string;
  patchTruncated: boolean;
} {
  const patch = asString(value);
  const maxPatchLength = 12000;
  if (patch.length <= maxPatchLength) {
    return { patch, patchTruncated: false };
  }

  return {
    patch: patch.slice(0, maxPatchLength),
    patchTruncated: true,
  };
}

async function fetchPullRequestFiles(input: {
  owner: string;
  repo: string;
  number: number;
  token: string;
}): Promise<{
  files: GitHubPullRequestFileResponseItem[];
  filesTruncated: boolean;
}> {
  const files: GitHubPullRequestFileResponseItem[] = [];
  const maxPages = 3;

  for (let page = 1; page <= maxPages; page += 1) {
    const pageFiles = await githubRequest<GitHubPullRequestFileResponseItem[]>({
      path: `/repos/${input.owner}/${input.repo}/pulls/${input.number}/files`,
      token: input.token,
      queryParameters: { per_page: 100, page },
    });
    files.push(...pageFiles);
    if (pageFiles.length < 100) {
      return { files, filesTruncated: false };
    }
  }

  return { files, filesTruncated: true };
}

function pullRequestDiffFile(file: GitHubPullRequestFileResponseItem): {
  filename: string;
  status: string;
  additions: number;
  deletions: number;
  changes: number;
  patch: string;
  patchTruncated: boolean;
  blobUrl: string;
  rawUrl: string;
  previousFilename?: string;
} {
  const { patch, patchTruncated } = truncatePullRequestPatch(file.patch);
  const previousFilename = asString(file.previous_filename);
  return {
    filename: asString(file.filename, "unknown"),
    status: asString(file.status, "modified"),
    additions: asNumber(file.additions),
    deletions: asNumber(file.deletions),
    changes: asNumber(file.changes),
    patch,
    patchTruncated,
    blobUrl: asString(file.blob_url),
    rawUrl: asString(file.raw_url),
    ...(previousFilename.length > 0 ? { previousFilename } : {}),
  };
}

function pullRequestConversationComment(
  comment: GitHubIssueCommentResponseItem,
): IssuePullRequestComment {
  return {
    id: asString(comment.id),
    author: asString(comment.user?.login, "unknown"),
    authorAssociation: asString(comment.author_association),
    body: asString(comment.body),
    url: asString(comment.html_url),
    createdAt: asString(comment.created_at),
    updatedAt: asString(comment.updated_at),
    kind: "conversation",
  };
}

function pullRequestReviewComment(
  comment: GitHubPullRequestReviewCommentResponseItem,
): IssuePullRequestComment {
  const line = asNumber(comment.line, asNumber(comment.original_line));
  return {
    id: asString(comment.id),
    author: asString(comment.user?.login, "unknown"),
    authorAssociation: asString(comment.author_association),
    body: asString(comment.body),
    url: asString(comment.html_url),
    createdAt: asString(comment.created_at),
    updatedAt: asString(comment.updated_at),
    path: asString(comment.path),
    ...(line > 0 ? { line } : {}),
    side: asString(comment.side),
    inReplyToId: asString(comment.in_reply_to_id),
    kind: "review",
  };
}

async function fetchPullRequestComments({
  owner,
  repo,
  number,
  token,
}: {
  owner: string;
  repo: string;
  number: number;
  token: string;
}): Promise<{ comments: IssuePullRequestComment[]; commentsTruncated: boolean }> {
  const [conversationComments, reviewComments] = await Promise.all([
    githubRequest<GitHubIssueCommentResponseItem[]>({
      path: `/repos/${owner}/${repo}/issues/${number}/comments`,
      token,
      queryParameters: { per_page: 100 },
    }),
    githubRequest<GitHubPullRequestReviewCommentResponseItem[]>({
      path: `/repos/${owner}/${repo}/pulls/${number}/comments`,
      token,
      queryParameters: { per_page: 100 },
    }),
  ]);
  const comments = [
    ...conversationComments.map(pullRequestConversationComment),
    ...reviewComments.map(pullRequestReviewComment),
  ]
    .filter((comment) => comment.body.trim().length > 0)
    .sort((a, b) => a.createdAt.localeCompare(b.createdAt));

  return {
    comments,
    commentsTruncated: conversationComments.length >= 100 || reviewComments.length >= 100,
  };
}

interface PullRequestStatusCheckContext {
  __typename?: string;
  name?: string | null;
  context?: string | null;
  status?: string | null;
  conclusion?: string | null;
  state?: string | null;
}

interface PullRequestStatusCheckRollupResponse {
  repository?: {
    object?: {
      statusCheckRollup?: {
        contexts?: {
          nodes?: PullRequestStatusCheckContext[];
          pageInfo?: {
            hasNextPage?: boolean;
          };
        } | null;
      } | null;
    } | null;
  } | null;
}

const pullRequestStatusCheckRollupQuery = `
  query PullRequestStatusCheckRollup($owner: String!, $repo: String!, $headSha: GitObjectID!) {
    repository(owner: $owner, name: $repo) {
      object(oid: $headSha) {
        ... on Commit {
          statusCheckRollup {
            contexts(first: 100) {
              nodes {
                __typename
                ... on CheckRun {
                  name
                  status
                  conclusion
                }
                ... on StatusContext {
                  context
                  state
                }
              }
              pageInfo {
                hasNextPage
              }
            }
          }
        }
      }
    }
  }
`;

const emptyPullRequestCiSummary: PullRequestCiSummary = {
  status: "none",
  total: 0,
  passed: 0,
  failed: 0,
  pending: 0,
  skipped: 0,
  checksTruncated: false,
};

function pullRequestCheckBucket(
  context: PullRequestStatusCheckContext,
): "passed" | "failed" | "pending" | "skipped" {
  if (context.__typename === "StatusContext") {
    if (context.state === "SUCCESS") return "passed";
    if (context.state === "FAILURE" || context.state === "ERROR") return "failed";
    return "pending";
  }

  if (context.status !== "COMPLETED") {
    return "pending";
  }
  if (context.conclusion === "SUCCESS") return "passed";
  if (context.conclusion === "NEUTRAL" || context.conclusion === "SKIPPED") return "skipped";
  return "failed";
}

function pullRequestCiSummaryFromContexts({
  contexts,
  checksTruncated,
}: {
  contexts: PullRequestStatusCheckContext[];
  checksTruncated: boolean;
}): PullRequestCiSummary {
  const summary: PullRequestCiSummary = {
    ...emptyPullRequestCiSummary,
    checksTruncated,
  };
  for (const context of contexts) {
    const bucket = pullRequestCheckBucket(context);
    summary.total += 1;
    summary[bucket] += 1;
  }
  summary.status =
    summary.total === 0
      ? "none"
      : checksTruncated
        ? "unknown"
        : summary.failed > 0
          ? "failure"
          : summary.pending > 0
            ? "pending"
            : "success";
  return summary;
}

async function fetchPullRequestCiSummary({
  owner,
  repo,
  headSha,
  token,
  apiBaseUrl,
}: {
  owner: string;
  repo: string;
  headSha: string;
  token: string;
  apiBaseUrl: string;
}): Promise<PullRequestCiSummary> {
  if (headSha.length === 0) {
    return emptyPullRequestCiSummary;
  }
  const response = await githubGraphql<PullRequestStatusCheckRollupResponse>(
    pullRequestStatusCheckRollupQuery,
    token,
    {
      variables: { owner, repo, headSha },
      apiBaseUrl,
    },
  );
  const contexts = response.repository?.object?.statusCheckRollup?.contexts;
  return pullRequestCiSummaryFromContexts({
    contexts: contexts?.nodes ?? [],
    checksTruncated: contexts?.pageInfo?.hasNextPage === true,
  });
}

function isActiveCursorAgentStatus(status: string): boolean {
  return status === "starting" || status === "running";
}

async function resolveIssueCursorStartingRef(repoFullName: string, token: string): Promise<string> {
  const [owner, repo] = repoFullName.split("/");
  if (!owner || !repo) {
    return "main";
  }

  try {
    const repository = await githubRequest<GitHubRepositoriesResponseItem>({
      path: `/repos/${owner}/${repo}`,
      token,
    });
    return asString(repository.default_branch, "main");
  } catch (error) {
    logger.warn("resolveIssueCursorStartingRef: failed to fetch repository", {
      repoFullName,
      message: error instanceof Error ? error.message : String(error),
    });
    return "main";
  }
}

function buildCursorAgentPrompt(input: {
  issueId: string;
  issue: Record<string, unknown>;
  githubIssue: Record<string, unknown>;
  repoFullName: string;
}): string {
  const labels = asStringList(input.issue.labels);
  const issueUrl = asString(input.githubIssue.url);
  const issueKeyValue = asString(input.issue.issueKey);
  const displayId =
    issueKeyValue.length > 0 ? issueKeyValue : `#${asNumber(input.githubIssue.number)}`;

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
    .filter((line): line is string => typeof line === "string")
    .join("\n");
}

function cursorAgentStartComment(input: {
  issueKey: string;
  agentId: string;
  runId: string;
}): string {
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

function pullRequestSummary({
  owner,
  repo,
  pullRequest,
  branch,
  linkedIssues = [],
}: {
  owner: string;
  repo: string;
  pullRequest: NonNullable<GitHubPullRequestWebhookPayload["pull_request"]>;
  branch: string;
  linkedIssues?: GitHubPullRequestLinkedIssue[];
}): Record<string, unknown> {
  return {
    owner,
    repo,
    number: asNumber(pullRequest.number),
    url: asString(pullRequest.html_url),
    title: asString(pullRequest.title),
    branch,
    state: asString(pullRequest.state, "open"),
    merged: asBoolean(pullRequest.merged),
    createdAt: asTimestamp(pullRequest.created_at),
    linkedIssues,
  };
}

async function fetchPullRequestLinkedIssues({
  owner,
  repo,
  number,
  token,
}: {
  owner: string;
  repo: string;
  number: number;
  token: string;
}): Promise<GitHubPullRequestLinkedIssue[]> {
  const response = await githubGraphql<GitHubPullRequestLinkedIssuesGraphqlResponse>(
    `
      query OpenCIPullRequestLinkedIssues($owner: String!, $repo: String!, $number: Int!) {
        repository(owner: $owner, name: $repo) {
          pullRequest(number: $number) {
            closingIssuesReferences(first: 20) {
              nodes {
                number
                title
                url
                state
              }
            }
          }
        }
      }
    `,
    token,
    { variables: { owner, repo, number } },
  );

  const nodes = response.data?.repository?.pullRequest?.closingIssuesReferences?.nodes ?? [];
  return nodes
    .map((node) => {
      if (node === null) {
        return null;
      }
      const issueNumber = asNumber(node.number);
      if (issueNumber <= 0) {
        return null;
      }
      return {
        number: issueNumber,
        title: asString(node.title, `#${issueNumber}`),
        url: asString(node.url),
        state: asString(node.state, "OPEN").toLowerCase(),
      };
    })
    .filter((issue): issue is GitHubPullRequestLinkedIssue => issue !== null);
}

async function fetchPullRequestLinkedIssuesSafely({
  owner,
  repo,
  number,
  token,
  workspaceId,
}: {
  owner: string;
  repo: string;
  number: number;
  token: string;
  workspaceId: string;
}): Promise<GitHubPullRequestLinkedIssue[]> {
  try {
    return await fetchPullRequestLinkedIssues({ owner, repo, number, token });
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    logger.warn("failed to fetch pull request linked issues", {
      workspaceId,
      repository: `${owner}/${repo}`,
      pullRequestNumber: number,
      message,
    });
    return [];
  }
}

interface DashboardPullRequestLink {
  id: string;
  owner: string;
  repo: string;
  number: number;
}

interface PullRequestBodySyncOperation {
  action: "link" | "unlink";
  pullRequest: DashboardPullRequestLink;
}

function dashboardPullRequestLinkFromData(
  data: Record<string, unknown>,
): DashboardPullRequestLink | null {
  const owner = asString(data.owner);
  const repo = asString(data.repo);
  const number = asNumber(data.number);
  if (owner.length === 0 || repo.length === 0 || number <= 0) {
    return null;
  }

  return {
    id: asString(data.id, pullRequestLinkId(owner, repo, number)),
    owner,
    repo,
    number,
  };
}

function dashboardPullRequestLinks(value: unknown): Map<string, DashboardPullRequestLink> {
  const links = new Map<string, DashboardPullRequestLink>();
  for (const item of recordList(value)) {
    const link = dashboardPullRequestLinkFromData(item);
    if (link !== null) {
      links.set(link.id, link);
    }
  }
  return links;
}

function normalizedPullRequestLinks(value: unknown): Map<string, string> {
  const links = new Map<string, string>();
  for (const item of recordList(value)) {
    const link = dashboardPullRequestLinkFromData(item);
    if (link !== null) {
      links.set(link.id, JSON.stringify(item));
    }
  }
  return links;
}

function pullRequestBodySyncOperations({
  before,
  after,
}: {
  before: Record<string, unknown> | undefined;
  after: Record<string, unknown> | undefined;
}): PullRequestBodySyncOperation[] {
  const beforeLinks = dashboardPullRequestLinks(before?.pullRequests);
  const afterLinks = dashboardPullRequestLinks(after?.pullRequests);
  const beforeLinkSignatures = normalizedPullRequestLinks(before?.pullRequests);
  const afterLinkSignatures = normalizedPullRequestLinks(after?.pullRequests);
  const operations: PullRequestBodySyncOperation[] = [];

  for (const [id, pullRequest] of afterLinks.entries()) {
    if (!beforeLinks.has(id) || beforeLinkSignatures.get(id) !== afterLinkSignatures.get(id)) {
      operations.push({ action: "link", pullRequest });
    }
  }

  for (const [id, pullRequest] of beforeLinks.entries()) {
    if (!afterLinks.has(id)) {
      operations.push({ action: "unlink", pullRequest });
    }
  }

  return operations;
}

async function linkedIssueBlockEntriesForPullRequest({
  workspaceId,
  repoFullName,
  pullRequest,
}: {
  workspaceId: string;
  repoFullName: string;
  pullRequest: DashboardPullRequestLink;
}): Promise<Array<{ githubIssueNumber: number; imaIssueKey: string }>> {
  const linkId = pullRequest.id;
  const issues = await db
    .collection(`workspaces/${workspaceId}/issues`)
    .where("repo", "==", repoFullName)
    .get();

  const entries = new Map<number, string>();
  for (const issueDoc of issues.docs) {
    const issue = issueDoc.data();
    const pullRequests = recordList(issue.pullRequests);
    if (!pullRequests.some((item) => asString(item.id) === linkId)) {
      continue;
    }

    const githubIssue = issue.githubIssue as Record<string, unknown> | undefined;
    const githubIssueNumber = asNumber(githubIssue?.number);
    if (githubIssueNumber <= 0) {
      continue;
    }

    const issueKeyValue = asString(issue.issueKey, `IMA-${githubIssueNumber}`);
    entries.set(githubIssueNumber, issueKeyValue);
  }

  return [...entries.entries()]
    .sort(([left], [right]) => left - right)
    .map(([githubIssueNumber, imaIssueKey]) => ({
      githubIssueNumber,
      imaIssueKey,
    }));
}

async function syncPullRequestBodyToWorkspaceLinks({
  workspaceId,
  token,
  pullRequest,
  repoFullName,
}: {
  workspaceId: string;
  token: string;
  pullRequest: DashboardPullRequestLink;
  repoFullName: string;
}): Promise<boolean> {
  const path = `/repos/${pullRequest.owner}/${pullRequest.repo}/pulls/${pullRequest.number}`;
  const [currentPullRequest, linkedIssues] = await Promise.all([
    githubRequest<GitHubPullRequestResponseItem>({
      path,
      token,
    }),
    linkedIssueBlockEntriesForPullRequest({
      workspaceId,
      repoFullName,
      pullRequest,
    }),
  ]);
  const currentBody = asString(currentPullRequest.body);
  const nextBody = replaceLinkedIssueBlocks(currentBody, linkedIssues);

  if (nextBody === currentBody) {
    return false;
  }

  await githubRequest({
    path,
    token,
    method: "PATCH",
    body: { body: nextBody },
  });
  return true;
}

function pullRequestMatchesIssue(
  pullRequest: GitHubPullRequestResponseItem,
  issue: Record<string, unknown>,
): boolean {
  const branch = asString(pullRequest.head?.ref);
  const title = asString(pullRequest.title);
  const body = asString(pullRequest.body);
  const issueKeyValue = asString(issue.issueKey).toUpperCase();
  if (issueKeyValue.length > 0 && extractIssueKey(branch, title, body) === issueKeyValue) {
    return true;
  }

  const githubIssue = issue.githubIssue as Record<string, unknown> | undefined;
  const issueUrl = asString(githubIssue?.url);
  if (issueUrl.length > 0 && body.includes(issueUrl)) {
    return true;
  }

  const issueNumber = asNumber(githubIssue?.number);
  if (issueNumber <= 0) {
    return false;
  }
  const numberPattern = new RegExp(
    `(?:fix(?:e[sd])?|close[sd]?|resolve[sd]?)\\s+#${issueNumber}(?=$|\\D)`,
    "iu",
  );
  return numberPattern.test(body);
}

function issueKeyFieldsFromData(data: Record<string, unknown>): Record<string, unknown> | null {
  const existingIssueKey = asString(data.issueKey);
  if (existingIssueKey.length === 0) {
    return null;
  }

  const existingNumber = asNumber(data.issueNumber);
  const prefix = normalizeIssueKeyPrefix(
    asString(data.issueKeyPrefix, existingIssueKey.split("-")[0] ?? "IMA"),
  );
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

async function patchGitHubIssueCore(input: {
  owner: string;
  repo: string;
  number: number;
  token: string;
  title?: unknown;
  body?: unknown;
  statusId?: unknown;
}): Promise<void> {
  const update: Record<string, unknown> = {};
  if (input.title !== undefined) {
    update.title = asString(input.title);
  }
  if (input.body !== undefined) {
    update.body = asString(input.body);
  }
  if (input.statusId !== undefined) {
    update.state = asString(input.statusId) === closedStatusId ? "closed" : "open";
  }
  if (Object.keys(update).length === 0) {
    return;
  }

  await githubRequest({
    path: `/repos/${input.owner}/${input.repo}/issues/${input.number}`,
    token: input.token,
    method: "PATCH",
    body: update,
  });
}

async function patchGitHubIssueLabelsSafely(input: {
  workspaceId: string;
  owner: string;
  repo: string;
  number: number;
  token: string;
  labels: unknown;
}): Promise<void> {
  try {
    await githubRequest({
      path: `/repos/${input.owner}/${input.repo}/issues/${input.number}`,
      token: input.token,
      method: "PATCH",
      body: { labels: asStringList(input.labels) },
    });
  } catch (error) {
    logger.warn("autoSyncIssueToGitHub: failed to sync labels", {
      workspaceId: input.workspaceId,
      owner: input.owner,
      repo: input.repo,
      number: input.number,
      errorMessage: errorMessage(error),
      stack: errorStack(error),
    });
  }
}

function issueWeightEstimateMap(issue: Record<string, unknown>): Record<string, unknown> {
  const estimate = issue.weightEstimate;
  return typeof estimate === "object" && estimate !== null
    ? (estimate as Record<string, unknown>)
    : {};
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
    !isValidWeight(value) ||
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

const defaultWeightThresholdsHours: Array<{
  weight: number;
  maxHours: number;
}> = [
  { weight: 1, maxHours: 1 },
  { weight: 2, maxHours: 4 },
  { weight: 4, maxHours: 12 },
  { weight: 8, maxHours: 32 },
  { weight: 16, maxHours: 80 },
  { weight: 32, maxHours: Infinity },
];

function deriveActualWeight(
  cycleTimeMs: number,
  byWeight: Record<string, { count: number; medianHours: number | null }>,
): number {
  const hours = cycleTimeMs / 3_600_000;

  const entries = Object.entries(byWeight)
    .map(([key, stats]) => ({ weight: Number(key), hours: stats.medianHours }))
    .filter(
      (entry): entry is { weight: number; hours: number } =>
        isValidWeight(entry.weight) && entry.hours !== null,
    );

  const totalCount = Object.values(byWeight).reduce((sum, stats) => sum + stats.count, 0);
  if (entries.length >= 3 && totalCount >= 5) {
    let closest = entries[0]!;
    let closestDiff = Math.abs(closest.hours - hours);
    for (let i = 1; i < entries.length; i++) {
      const diff = Math.abs(entries[i]!.hours - hours);
      if (diff < closestDiff) {
        closest = entries[i]!;
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

function issueSubIssuesSummary(issue: GitHubIssueResponseItem): Record<string, unknown> | null {
  const summary = issue.sub_issues_summary;
  const total = asNumber(summary?.total);
  if (total <= 0) {
    return null;
  }
  const completed = Math.min(Math.max(asNumber(summary?.completed), 0), total);
  const percentCompleted = Math.min(
    Math.max(asNumber(summary?.percent_completed, Math.round((completed / total) * 100)), 0),
    100,
  );
  return {
    total,
    completed,
    percentCompleted,
    parentIssueUrl: asString(issue.parent_issue_url) || null,
  };
}

function githubIssueFirestoreFields(
  owner: string,
  repo: string,
  issue: GitHubIssueResponseItem,
): Record<string, unknown> {
  const subIssuesSummary = issueSubIssuesSummary(issue);
  const fields: Record<string, unknown> = {
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

function mergedSubIssueSummaries(
  existingValue: unknown,
  nextSummary: Record<string, unknown>,
): Record<string, unknown>[] {
  const existing = Array.isArray(existingValue)
    ? existingValue.filter(
        (value): value is Record<string, unknown> =>
          typeof value === "object" && value !== null && !Array.isArray(value),
      )
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

async function closeDescendantSubIssues(input: {
  workspaceId: string;
  issueId: string;
  rankBase?: number;
}): Promise<number> {
  const issuesRef = db.collection(`workspaces/${input.workspaceId}/issues`);
  const visited = new Set([input.issueId]);
  const queue = [input.issueId];
  const descendants: DocumentSnapshot[] = [];

  while (queue.length > 0) {
    const parentIssueId = queue.shift()!;
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

  const openDescendants = descendants.filter(
    (descendant) => asString(descendant.get("statusId"), "triage") !== closedStatusId,
  );
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
    batch.set(
      descendant.ref,
      {
        statusId: closedStatusId,
        rank: rankBase + closed + 1,
        "githubIssue.state": "closed",
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    pendingWrites += 1;
    closed += 1;
    await commitIfNeeded();
  }

  await commitIfNeeded(true);
  return closed;
}

async function selectedRepositories(workspaceId: string): Promise<GitHubRepository[]> {
  const workspace = await db.doc(`workspaces/${workspaceId}`).get();
  return asStringList(workspace.get("syncedGitHubRepoFullNames"))
    .map((fullName) => {
      const [owner, name] = fullName.split("/");
      return {
        fullName,
        name: name ?? "",
        owner: owner ?? "",
        private: false,
        defaultBranch: "main",
      };
    })
    .filter((repo) => repo.owner.length > 0 && repo.name.length > 0);
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
  actualWeight: number | null;
  leadTimeMs: number | null;
  cycleTimeMs: number | null;
  closedAt: Timestamp | null;
}

interface EstimationAccuracy {
  totalCompared: number;
  exactMatchRate: number;
  within1Rate: number;
  meanAbsoluteError: number;
  bias: number;
}

interface ResolutionStats {
  recentWindowDays: number;
  resolvedCount: number;
  medianLeadTimeHours: number | null;
  medianCycleTimeHours: number | null;
  byWeight: Record<string, { count: number; medianHours: number | null }>;
  byLabel: Record<string, { count: number; medianHours: number | null }>;
  recentExamples: Array<{
    title: string;
    repo: string;
    labels: string[];
    weight: number | null;
    actualWeight: number | null;
    leadTimeHours: number | null;
    cycleTimeHours: number | null;
  }>;
  estimationAccuracy: EstimationAccuracy | null;
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
    actualWeight: typeof data.actualWeight === "number" ? data.actualWeight : null,
    leadTimeMs: typeof data.leadTimeMs === "number" ? data.leadTimeMs : null,
    cycleTimeMs: typeof data.cycleTimeMs === "number" ? data.cycleTimeMs : null,
    closedAt: timestampFromValue(data.closedAt),
  };
}

function bucketMedian(
  events: ClosedIssueStatsEvent[],
  keyForEvent: (event: ClosedIssueStatsEvent) => string[],
  timeForEvent: (event: ClosedIssueStatsEvent) => number | null = (e) => e.leadTimeMs,
): Record<string, { count: number; medianHours: number | null }> {
  const buckets = new Map<string, number[]>();
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
  return Object.fromEntries(
    [...buckets.entries()]
      .sort((left, right) => right[1].length - left[1].length)
      .slice(0, 20)
      .map(([key, values]) => [
        key,
        {
          count: values.length,
          medianHours: roundedHours(median(values)),
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

  const comparablePairs = selected.filter(
    (event) => event.weightValue !== null && event.actualWeight !== null,
  );

  let estimationAccuracy: EstimationAccuracy | null = null;
  if (comparablePairs.length > 0) {
    const exactMatches = comparablePairs.filter((e) => e.weightValue === e.actualWeight).length;
    const adjacentMatches = comparablePairs.filter((e) =>
      isAdjacentWeight(e.weightValue!, e.actualWeight!),
    ).length;
    const deltas = comparablePairs.map((e) => e.weightValue! - e.actualWeight!);
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
    byWeight: bucketMedian(selected, (event) =>
      event.weightValue === null ? [] : [String(event.weightValue)],
    ),
    byLabel: bucketMedian(selected, (event) => event.labels),
    recentExamples: selected.slice(0, 30).map((event) => ({
      title: truncateText(event.title, 120),
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
    "value must be one of: 1, 2, 4, 8, 16, 32 (powers of 2; 1=tiny, 32=very large).",
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
        manualOverride: false,
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
          manualOverride: false,
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
          manualOverride: false,
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

export const connectGitHub = onCall<WorkspaceRequest, Promise<{ login: string }>>(
  async (request) => {
    const workspaceId = requireNonEmptyString(request.data?.workspaceId, "workspaceId");
    const uid = await verifyWorkspaceMember(request.auth, workspaceId);

    try {
      const { installationId } = await getWorkspaceGitHubToken(workspaceId);
      const login = `GitHub App installation #${installationId}`;

      const now = FieldValue.serverTimestamp();
      await db.doc(`workspaces/${workspaceId}/githubConnections/default`).set(
        {
          connected: true,
          login,
          installationId,
          source: "github_app",
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
      throw new HttpsError("internal", "Failed to connect OpenCI GitHub App");
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
    logger.info("Starting device flow request", {
      workspaceId,
      clientId: clientId.substring(0, 8),
    });
    const data = await githubOAuthRequest<GitHubDeviceCodeResponse>("/login/device/code", {
      client_id: clientId,
      scope: "read:user repo",
    });
    logger.info("Device flow response received", {
      workspaceId,
      hasError: !!data.error,
      hasUserCode: !!data.user_code,
    });

    const error = asString(data.error);
    if (error.length > 0) {
      throw new HttpsError("failed-precondition", asString(data.error_description, error));
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
    logger.error(`startGitHubDeviceFlow failed at step=${step}`, {
      workspaceId,
      message,
      stack,
    });
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
    logger.error("Failed to complete GitHub device flow", {
      workspaceId,
      uid,
      message,
    });
    throw new HttpsError("internal", "Failed to complete GitHub device flow");
  }
});

export const listGitHubRepositories = onCall<
  WorkspaceRequest,
  Promise<ListGitHubRepositoriesResponse>
>(async (request) => {
  const workspaceId = requireNonEmptyString(request.data?.workspaceId, "workspaceId");
  const uid = await verifyWorkspaceMember(request.auth, workspaceId);
  const { token } = await getWorkspaceGitHubToken(workspaceId);

  try {
    const repositories: GitHubRepository[] = [];
    let page = 1;

    while (true) {
      const pageData = await githubRequest<GitHubInstallationRepositoriesResponse>({
        path: "/installation/repositories",
        token,
        queryParameters: {
          per_page: 100,
          page,
        },
      });
      const pageRepos = pageData.repositories ?? [];

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
    logger.error("Failed to list Ima GitHub repositories", {
      workspaceId,
      uid,
      message,
    });
    throw new HttpsError("internal", "Failed to list GitHub repositories");
  }
});

export const getIssuePullRequestDiff = onCall<
  GetIssuePullRequestDiffRequest,
  Promise<GetIssuePullRequestDiffResponse>
>({ region: firebaseRegion, secrets: githubAppSecrets }, async (request) => {
  const workspaceId = requireNonEmptyString(request.data?.workspaceId, "workspaceId");
  const issueId = requireNonEmptyString(request.data?.issueId, "issueId");
  const repository = requireNonEmptyString(request.data?.repository, "repository");
  const pullRequestNumber = asNumber(request.data?.pullRequestNumber);
  const uid = await verifyWorkspaceMember(request.auth, workspaceId);
  const { token, apiBaseUrl } = await getWorkspaceGitHubToken(workspaceId);

  try {
    const linkedPullRequest = await linkedIssuePullRequest({
      workspaceId,
      issueId,
      repository,
      pullRequestNumber,
    });
    const [pullRequest, filesResult, commentsResult] = await Promise.all([
      githubRequest<GitHubPullRequestResponseItem>({
        path: `/repos/${linkedPullRequest.owner}/${linkedPullRequest.repo}/pulls/${pullRequestNumber}`,
        token,
      }),
      fetchPullRequestFiles({
        owner: linkedPullRequest.owner,
        repo: linkedPullRequest.repo,
        number: pullRequestNumber,
        token,
      }),
      fetchPullRequestComments({
        owner: linkedPullRequest.owner,
        repo: linkedPullRequest.repo,
        number: pullRequestNumber,
        token,
      }),
    ]);
    const ci = await fetchPullRequestCiSummary({
      owner: linkedPullRequest.owner,
      repo: linkedPullRequest.repo,
      headSha: asString(pullRequest.head?.sha),
      token,
      apiBaseUrl,
    });
    const files = filesResult.files.map(pullRequestDiffFile);
    const fallbackAdditions = files.reduce((total, file) => total + file.additions, 0);
    const fallbackDeletions = files.reduce((total, file) => total + file.deletions, 0);

    return {
      repository,
      pullRequestNumber,
      title: asString(
        pullRequest.title,
        asString(linkedPullRequest.pullRequest.title, "Pull request"),
      ),
      url: asString(pullRequest.html_url, asString(linkedPullRequest.pullRequest.url)),
      state: asString(pullRequest.state, asString(linkedPullRequest.pullRequest.state, "open")),
      merged: asBoolean(pullRequest.merged, asBoolean(linkedPullRequest.pullRequest.merged)),
      branch: asString(pullRequest.head?.ref, asString(linkedPullRequest.pullRequest.branch)),
      additions: asNumber(pullRequest.additions, fallbackAdditions),
      deletions: asNumber(pullRequest.deletions, fallbackDeletions),
      changedFiles: asNumber(pullRequest.changed_files, files.length),
      ci,
      comments: commentsResult.comments,
      commentsTruncated: commentsResult.commentsTruncated,
      filesTruncated: filesResult.filesTruncated,
      files,
    };
  } catch (error) {
    if (error instanceof HttpsError) {
      throw error;
    }
    logger.error("Failed to get issue pull request diff", {
      workspaceId,
      uid,
      issueId,
      repository,
      pullRequestNumber,
      message: errorMessage(error),
      stack: errorStack(error),
    });
    throw new HttpsError("internal", "Failed to get pull request diff");
  }
});

export const mergeIssuePullRequest = onCall<
  MergeIssuePullRequestRequest,
  Promise<MergeIssuePullRequestResponse>
>({ region: firebaseRegion, secrets: githubAppSecrets }, async (request) => {
  const workspaceId = requireNonEmptyString(request.data?.workspaceId, "workspaceId");
  const issueId = requireNonEmptyString(request.data?.issueId, "issueId");
  const repository = requireNonEmptyString(request.data?.repository, "repository");
  const pullRequestNumber = asNumber(request.data?.pullRequestNumber);
  const mergeMethod = asString(request.data?.mergeMethod, "squash");
  if (!["merge", "squash", "rebase"].includes(mergeMethod)) {
    throw new HttpsError("invalid-argument", "mergeMethod must be merge, squash, or rebase");
  }

  const uid = await verifyWorkspaceMember(request.auth, workspaceId);
  const { token } = await getWorkspaceGitHubToken(workspaceId);

  try {
    const linkedPullRequest = await linkedIssuePullRequest({
      workspaceId,
      issueId,
      repository,
      pullRequestNumber,
    });
    const result = await githubRequest<GitHubMergePullRequestResponseItem>({
      path: `/repos/${linkedPullRequest.owner}/${linkedPullRequest.repo}/pulls/${pullRequestNumber}/merge`,
      token,
      method: "PUT",
      body: { merge_method: mergeMethod },
    });
    const sha = asString(result.sha);
    const merged = asBoolean(result.merged);
    const message = asString(result.message);
    if (merged) {
      const now = Timestamp.now();
      await db.runTransaction(async (transaction) => {
        const issue = await transaction.get(linkedPullRequest.issueRef);
        const pullRequests = recordList(issue.get("pullRequests")).map((item) => {
          if (asString(item.id) !== linkedPullRequest.linkId) {
            return item;
          }
          return {
            ...item,
            state: "closed",
            merged: true,
            mergeSha: sha,
            mergedAt: now,
            updatedAt: now,
          };
        });
        transaction.set(
          linkedPullRequest.issueRef,
          {
            pullRequests,
            statusId: closedStatusId,
            closedAt: FieldValue.serverTimestamp(),
            updatedAt: FieldValue.serverTimestamp(),
          },
          { merge: true },
        );
      });
    }

    return { merged, message, sha };
  } catch (error) {
    if (error instanceof HttpsError) {
      throw error;
    }
    logger.error("Failed to merge issue pull request", {
      workspaceId,
      uid,
      issueId,
      repository,
      pullRequestNumber,
      mergeMethod,
      message: errorMessage(error),
      stack: errorStack(error),
    });
    throw new HttpsError("internal", "Failed to merge pull request");
  }
});

export const importGitHubIssues = onCall<WorkspaceRequest, Promise<ImportGitHubIssuesResponse>>(
  async (request) => {
    const workspaceId = requireNonEmptyString(request.data?.workspaceId, "workspaceId");
    const uid = await verifyWorkspaceMember(request.auth, workspaceId);
    const { token } = await getWorkspaceGitHubToken(workspaceId);
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
        while (true) {
          const pageIssues = await githubRequest<GitHubIssueResponseItem[]>({
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
            batch.set(
              docRef,
              {
                ...keyFields,
                title: asString(issue.title, `#${number}`),
                body: asString(issue.body),
                repo: repository.fullName,
                labels: issueLabels(issue),
                comments: asNumber(issue.comments),
                priority: asString(existingData.priority, "medium"),
                statusId: asString(existingData.statusId, "triage"),
                rank: asNumber(existingData.rank, Date.now() + imported),
                githubIssue: githubIssueFirestoreFields(owner, repo, issue),
                githubUpdatedAt: asTimestamp(issue.updated_at),
                githubCreatedAt: asTimestamp(issue.created_at),
                updatedAt: FieldValue.serverTimestamp(),
                createdAt: existing.exists
                  ? (existingData.createdAt ?? FieldValue.serverTimestamp())
                  : FieldValue.serverTimestamp(),
              },
              { merge: true },
            );
            pendingWrites += 1;
            imported += 1;
            await commitIfNeeded();
          }

          if (pageIssues.length < 100 || page >= 10) {
            break;
          }
          page += 1;
        }
      }

      await commitIfNeeded(true);
      return { imported, repositories: repositories.length };
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.error("Failed to import Ima GitHub issues", {
        workspaceId,
        uid,
        message,
      });
      throw new HttpsError("internal", "Failed to import GitHub issues");
    }
  },
);

export const createGitHubIssue = onCall<
  CreateGitHubIssueRequest,
  Promise<CreateGitHubIssueResponse>
>(async (request) => {
  const workspaceId = requireNonEmptyString(request.data?.workspaceId, "workspaceId");
  const uid = await verifyWorkspaceMember(request.auth, workspaceId);
  const { token } = await getWorkspaceGitHubToken(workspaceId);
  const title = requireNonEmptyString(request.data?.title, "title");
  const repoFullName = requireNonEmptyString(request.data?.repo, "repo");
  const [owner, repo] = repoFullName.split("/");
  if (!owner || !repo) {
    throw new HttpsError("invalid-argument", "repo must be owner/repo");
  }

  const body = asString(request.data?.body);
  const labels = Array.isArray(request.data?.labels)
    ? request.data.labels.filter(
        (label): label is string => typeof label === "string" && label.length > 0,
      )
    : [];

  try {
    logger.info("Creating GitHub issue", {
      workspaceId,
      repoFullName,
      owner,
      repo,
      title,
    });
    const issue = await githubRequest<GitHubIssueResponseItem>({
      path: `/repos/${owner}/${repo}/issues`,
      token,
      method: "POST",
      body: {
        title,
        body,
        labels,
      },
    });

    const number = asNumber(issue.number);
    const nodeId = asString(issue.node_id);
    if (number <= 0 || nodeId.length === 0) {
      throw new HttpsError("failed-precondition", "GitHub issue could not be created");
    }

    const clientIssueId = asString(request.data?.issueId);
    const issueId = clientIssueId.length > 0 ? clientIssueId : issueDocId(owner, repo, number);
    const docRef = db.doc(`workspaces/${workspaceId}/issues/${issueId}`);
    const existingData = clientIssueId.length > 0 ? ((await docRef.get()).data() ?? {}) : {};
    const keyFields = await issueKeyFields(workspaceId, existingData);
    await docRef.set(
      {
        ...keyFields,
        title: asString(issue.title, title),
        body: asString(issue.body, body),
        repo: repoFullName,
        labels: issueLabels(issue),
        comments: asNumber(issue.comments),
        priority: asString(request.data?.priority, "medium"),
        statusId: asString(request.data?.statusId, "triage"),
        rank: asNumber(request.data?.rank, Date.now()),
        dueDate: asTimestamp(request.data?.dueDate),
        githubIssue: githubIssueFirestoreFields(owner, repo, issue),
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
    logger.error("Failed to create Ima GitHub issue", {
      workspaceId,
      uid,
      repoFullName,
      message,
      stack,
    });
    throw new HttpsError("internal", `Failed to create GitHub issue: ${message}`);
  }
});

export const createGitHubSubIssue = onCall<
  CreateGitHubSubIssueRequest,
  Promise<CreateGitHubSubIssueResponse>
>(async (request) => {
  const workspaceId = requireNonEmptyString(request.data?.workspaceId, "workspaceId");
  const uid = await verifyWorkspaceMember(request.auth, workspaceId);
  const { token } = await getWorkspaceGitHubToken(workspaceId);
  const parentIssueId = requireNonEmptyString(request.data?.parentIssueId, "parentIssueId");
  const title = requireNonEmptyString(request.data?.title, "title");
  const body = asString(request.data?.body);

  const parentRef = db.doc(`workspaces/${workspaceId}/issues/${parentIssueId}`);
  const parentDoc = await parentRef.get();
  const parentIssue = parentDoc.data();
  if (!parentIssue) {
    throw new HttpsError("not-found", "Parent issue was not found");
  }
  const parentGithubIssue = parentIssue.githubIssue as Record<string, unknown> | undefined;
  if (!parentGithubIssue) {
    throw new HttpsError("failed-precondition", "Parent issue must be linked to GitHub");
  }

  const owner = requireNonEmptyString(parentGithubIssue.owner, "githubIssue.owner");
  const repo = requireNonEmptyString(parentGithubIssue.repo, "githubIssue.repo");
  const parentNumber = asNumber(parentGithubIssue.number);
  if (parentNumber <= 0) {
    throw new HttpsError("failed-precondition", "Parent GitHub issue number is missing");
  }

  const labels = asStringList(parentIssue.labels);

  try {
    logger.info("Creating GitHub sub-issue", {
      workspaceId,
      parentIssueId,
      owner,
      repo,
      parentNumber,
      title,
    });

    const issue = await githubRequest<GitHubIssueResponseItem>({
      path: `/repos/${owner}/${repo}/issues`,
      token,
      method: "POST",
      body: {
        title,
        body,
        labels,
      },
    });

    const number = asNumber(issue.number);
    const nodeId = asString(issue.node_id);
    const subIssueRestId = asNumber(issue.id);
    if (number <= 0 || nodeId.length === 0 || subIssueRestId <= 0) {
      throw new HttpsError("failed-precondition", "GitHub sub-issue could not be created");
    }

    const updatedParentIssue = await githubRequest<GitHubIssueResponseItem>({
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
    await subIssueRef.set(
      {
        ...keyFields,
        title: asString(issue.title, title),
        body: asString(issue.body, body),
        repo: `${owner}/${repo}`,
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
        updatedAt: FieldValue.serverTimestamp(),
        createdAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    await parentRef.set(
      {
        githubIssue: {
          ...githubIssueFirestoreFields(owner, repo, updatedParentIssue),
          nodeId: asString(parentGithubIssue.nodeId),
          number: parentNumber,
          url: asString(parentGithubIssue.url),
          subIssues: mergedSubIssueSummaries(parentGithubIssue.subIssues, subIssueSummary),
        },
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    return {
      parentIssueId,
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
    logger.error("Failed to create Ima GitHub sub-issue", {
      workspaceId,
      uid,
      parentIssueId,
      message,
      stack,
    });
    throw new HttpsError("internal", `Failed to create GitHub sub-issue: ${message}`);
  }
});

export const startIssueCursorAgent = onCall<
  StartIssueCursorAgentRequest,
  Promise<StartIssueCursorAgentResponse>
>({ timeoutSeconds: 120, secrets: [cursorApiKey, ...githubAppSecrets] }, async (request) => {
  const workspaceId = requireNonEmptyString(request.data?.workspaceId, "workspaceId");
  const issueId = requireNonEmptyString(request.data?.issueId, "issueId");
  const uid = await verifyWorkspaceMember(request.auth, workspaceId);
  const { token: githubToken } = await getWorkspaceGitHubToken(workspaceId);
  const apiKey = cursorApiKey.value();
  if (apiKey.length === 0) {
    throw new HttpsError("failed-precondition", "CURSOR_API_KEY is not configured");
  }

  const issueRef = db.doc(`workspaces/${workspaceId}/issues/${issueId}`);
  const issueDoc = await issueRef.get();
  const issue = issueDoc.data();
  if (!issue) {
    throw new HttpsError("not-found", "Issue was not found");
  }

  const cursorAgent = issue.cursorAgent as Record<string, unknown> | undefined;
  const existingStatus = asString(cursorAgent?.status);
  if (isActiveCursorAgentStatus(existingStatus)) {
    throw new HttpsError("failed-precondition", "Cursor agent is already running for this issue");
  }

  const repoFullName = requireNonEmptyString(issue.repo, "repo");
  const [owner, repo] = repoFullName.split("/");
  if (!owner || !repo) {
    throw new HttpsError("failed-precondition", "Issue repository must be owner/repo");
  }

  const githubIssue = issue.githubIssue as Record<string, unknown> | undefined;
  if (!githubIssue) {
    throw new HttpsError("failed-precondition", "Issue must be linked to GitHub");
  }
  const issueNumber = asNumber(githubIssue.number);
  if (issueNumber <= 0) {
    throw new HttpsError("failed-precondition", "GitHub issue number is missing");
  }

  const runRef = issueRef.collection("cursorAgentRuns").doc();
  const startingRef = await resolveIssueCursorStartingRef(repoFullName, githubToken);
  const repositoryUrl = `https://github.com/${repoFullName}`;
  const prompt = buildCursorAgentPrompt({
    issueId,
    issue,
    githubIssue,
    repoFullName,
  });
  const now = FieldValue.serverTimestamp();
  const currentStatusId = asString(issue.statusId, "triage");
  const shouldMoveToDoing =
    currentStatusId !== closedStatusId && !inProgressStatusIds.has(currentStatusId);

  await issueRef.set(
    {
      cursorAgent: {
        status: "starting",
        requestedBy: uid,
        startingRef,
        repositoryUrl,
        updatedAt: now,
        startedAt: now,
        errorMessage: FieldValue.delete(),
      },
      ...(shouldMoveToDoing ? { statusId: "doing" } : {}),
      updatedAt: now,
    },
    { merge: true },
  );
  await runRef.set({
    status: "starting",
    requestedBy: uid,
    startingRef,
    repositoryUrl,
    prompt,
    createdAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
  });

  const { Agent } = await import("@cursor/sdk");
  let agent: Awaited<ReturnType<typeof Agent.create>> | undefined;
  try {
    agent = await Agent.create({
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
      issueRef.set(
        {
          cursorAgent: {
            status: "running",
            agentId,
            runId,
            runDocumentId: runRef.id,
            requestedBy: uid,
            startingRef,
            repositoryUrl,
            updatedAt: FieldValue.serverTimestamp(),
            startedAt: FieldValue.serverTimestamp(),
            errorMessage: FieldValue.delete(),
          },
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      ),
      runRef.set(
        {
          status: "running",
          agentId,
          runId,
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      ),
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
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.warn("Failed to post Cursor agent start comment", {
        workspaceId,
        issueId,
        repoFullName,
        issueNumber,
        message,
      });
    }

    return { issueId, agentId, runId, status: "running" };
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    await Promise.all([
      issueRef.set(
        {
          cursorAgent: {
            status: "failed",
            requestedBy: uid,
            startingRef,
            repositoryUrl,
            errorMessage: message,
            updatedAt: FieldValue.serverTimestamp(),
          },
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      ),
      runRef.set(
        {
          status: "failed",
          errorMessage: message,
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      ),
    ]);
    logger.error("Failed to start Cursor agent", {
      workspaceId,
      issueId,
      repoFullName,
      message,
    });
    throw new HttpsError("internal", `Failed to start Cursor agent: ${message}`);
  } finally {
    await agent?.[Symbol.asyncDispose]?.();
  }
});

export const backfillIssueKeys = onCall<WorkspaceRequest, Promise<BackfillIssueKeysResponse>>(
  async (request) => {
    const workspaceId = requireNonEmptyString(request.data?.workspaceId, "workspaceId");
    await verifyWorkspaceMember(request.auth, workspaceId);

    const issues = await db.collection(`workspaces/${workspaceId}/issues`).limit(500).get();

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

async function completeCursorAgentFromExistingPullRequest({
  workspaceId,
  issueId,
  cursorAgent,
  pullRequest,
}: {
  workspaceId: string;
  issueId: string;
  cursorAgent: Record<string, unknown> | undefined;
  pullRequest: Record<string, unknown>;
}): Promise<void> {
  const issueRef = db.doc(`workspaces/${workspaceId}/issues/${issueId}`);
  const runDocumentId = asString(cursorAgent?.runDocumentId);
  const update = {
    status: "done",
    pullRequest,
    completedAt: FieldValue.serverTimestamp(),
    updatedAt: FieldValue.serverTimestamp(),
    errorMessage: FieldValue.delete(),
  };
  await Promise.all([
    issueRef.set(
      {
        cursorAgent: update,
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    ),
    ...(runDocumentId.length > 0
      ? [
          issueRef.collection("cursorAgentRuns").doc(runDocumentId).set(
            {
              status: "done",
              pullRequest,
              completedAt: FieldValue.serverTimestamp(),
              updatedAt: FieldValue.serverTimestamp(),
            },
            { merge: true },
          ),
        ]
      : []),
  ]);
}

export const backfillCursorAgentPullRequests = onCall<
  WorkspaceRequest,
  Promise<BackfillCursorAgentPullRequestsResponse>
>(async (request) => {
  const workspaceId = requireNonEmptyString(request.data?.workspaceId, "workspaceId");
  const { token } = await getWorkspaceGitHubToken(workspaceId);
  const issues = await db.collection(`workspaces/${workspaceId}/issues`).limit(500).get();
  const pullRequestsByRepo = new Map<string, GitHubPullRequestResponseItem[]>();
  let inspected = 0;
  let linked = 0;

  for (const issueDoc of issues.docs) {
    const issue = issueDoc.data();
    const cursorAgent = issue.cursorAgent as Record<string, unknown> | undefined;
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
      pullRequests = await githubRequest<GitHubPullRequestResponseItem[]>({
        path: `/repos/${owner}/${repo}/pulls`,
        token,
        queryParameters: {
          state: "all",
          sort: "updated",
          direction: "desc",
          per_page: 100,
        },
      });
      pullRequestsByRepo.set(repoFullName, pullRequests);
    }

    const pullRequest = pullRequests.find((item) => pullRequestMatchesIssue(item, issue));
    if (pullRequest === undefined) {
      continue;
    }

    const pullRequestNumber = asNumber(pullRequest.number);
    const linkedIssues =
      pullRequestNumber > 0
        ? await fetchPullRequestLinkedIssuesSafely({
            owner,
            repo,
            number: pullRequestNumber,
            token,
            workspaceId,
          })
        : [];

    await upsertPullRequestLink({
      workspaceId,
      issueId: issueDoc.id,
      action: asString(pullRequest.state, "open") === "closed" ? "closed" : "opened",
      pullRequest,
      repoFullName,
      branch: asString(pullRequest.head?.ref),
      linkedIssues,
    });
    linked += 1;
  }

  return { inspected, linked };
});

async function syncWorkspacePullRequestLinks({
  workspaceId,
  token,
}: {
  workspaceId: string;
  token: string;
}): Promise<number> {
  const workspaceRef = db.doc(`workspaces/${workspaceId}`);
  const [issues, workspace] = await Promise.all([
    workspaceRef.collection("issues").limit(500).get(),
    workspaceRef.get(),
  ]);
  let linked = 0;

  for (const repoFullName of asStringList(workspace.get("syncedGitHubRepoFullNames"))) {
    const [owner, repo] = repoFullName.split("/");
    if (!owner || !repo) {
      continue;
    }

    let pullRequests: GitHubPullRequestResponseItem[];
    try {
      pullRequests = await githubRequest<GitHubPullRequestResponseItem[]>({
        path: `/repos/${owner}/${repo}/pulls`,
        token,
        queryParameters: {
          state: "all",
          sort: "updated",
          direction: "desc",
          per_page: 100,
        },
      });
    } catch (error) {
      logger.warn("syncGitHubIssues: failed to list pull requests", {
        workspaceId,
        repoFullName,
        message: error instanceof Error ? error.message : String(error),
      });
      continue;
    }

    const processedPullRequestNumbers = new Set<number>();
    for (const issueDoc of issues.docs) {
      const issue = issueDoc.data();
      if (asString(issue.repo) !== repoFullName) {
        continue;
      }

      const pullRequest = pullRequests.find((item) => pullRequestMatchesIssue(item, issue));
      if (pullRequest === undefined) {
        continue;
      }

      const pullRequestNumber = asNumber(pullRequest.number);
      const linkedIssues =
        pullRequestNumber > 0
          ? await fetchPullRequestLinkedIssuesSafely({
              owner,
              repo,
              number: pullRequestNumber,
              token,
              workspaceId,
            })
          : [];

      await upsertPullRequestLink({
        workspaceId,
        issueId: issueDoc.id,
        action: asString(pullRequest.state, "open") === "closed" ? "closed" : "opened",
        pullRequest,
        repoFullName,
        branch: asString(pullRequest.head?.ref),
        linkedIssues,
      });
      linked += 1;
      linked += await upsertPullRequestLinksForLinkedIssues({
        workspaceId,
        owner,
        repo,
        action: asString(pullRequest.state, "open") === "closed" ? "closed" : "opened",
        pullRequest,
        repoFullName,
        branch: asString(pullRequest.head?.ref),
        linkedIssues,
        skipIssueIds: new Set([issueDoc.id]),
      });
      processedPullRequestNumbers.add(pullRequestNumber);
    }

    for (const pullRequest of pullRequests) {
      const pullRequestNumber = asNumber(pullRequest.number);
      if (pullRequestNumber <= 0 || processedPullRequestNumbers.has(pullRequestNumber)) {
        continue;
      }

      const linkedIssues = await fetchPullRequestLinkedIssuesSafely({
        owner,
        repo,
        number: pullRequestNumber,
        token,
        workspaceId,
      });
      if (linkedIssues.length === 0) {
        continue;
      }

      linked += await upsertPullRequestLinksForLinkedIssues({
        workspaceId,
        owner,
        repo,
        action: asString(pullRequest.state, "open") === "closed" ? "closed" : "opened",
        pullRequest,
        repoFullName,
        branch: asString(pullRequest.head?.ref),
        linkedIssues,
      });
    }
  }

  return linked;
}

export async function processImaGitHubAppWebhook(
  event: string,
  body: Record<string, unknown>,
): Promise<Record<string, number> | undefined> {
  if (event === "pull_request") {
    const linked = await syncPullRequestLinksFromEditedWebhook(
      body as GitHubPullRequestWebhookPayload,
    );
    return { linked };
  }

  if (event === "issues") {
    const updated = await syncGitHubIssueFromWebhook(body as GitHubIssueWebhookPayload);
    return { updated };
  }

  if (event === "push") {
    const recorded = await processBranchLogFromPush(body as GitHubPushWebhookPayload);
    return { recorded };
  }

  return undefined;
}

async function syncPullRequestLinksFromEditedWebhook(
  payload: GitHubPullRequestWebhookPayload,
): Promise<number> {
  const action = asString(payload.action);
  if (action !== "edited") {
    return 0;
  }

  const pullRequest = payload.pull_request;
  if (
    payload.changes?.body !== undefined &&
    isOnlyLinkedIssueBlockChange(asString(payload.changes.body.from), asString(pullRequest?.body))
  ) {
    return 0;
  }

  const repoFullName = asString(payload.repository?.full_name);
  const pullRequestNumber = asNumber(pullRequest?.number);
  if (pullRequest === undefined || repoFullName.length === 0 || pullRequestNumber <= 0) {
    return 0;
  }

  const [owner, repo] = repoFullName.split("/");
  if (!owner || !repo) {
    return 0;
  }

  const workspaces = await db
    .collection(firestoreCollectionPaths.workspaces)
    .where("syncedGitHubRepoFullNames", "array-contains", repoFullName)
    .get();
  let linked = 0;

  for (const workspace of workspaces.docs) {
    let token: string;
    try {
      ({ token } = await getWorkspaceGitHubToken(workspace.id));
    } catch (error) {
      logger.warn("syncPullRequestLinks: no GitHub App installation token", {
        workspaceId: workspace.id,
        repoFullName,
        message: error instanceof Error ? error.message : String(error),
      });
      continue;
    }

    const linkedIssues = await fetchPullRequestLinkedIssuesSafely({
      owner,
      repo,
      number: pullRequestNumber,
      token,
      workspaceId: workspace.id,
    });
    linked += await removePullRequestLinkFromUnlinkedIssues({
      workspaceId: workspace.id,
      repoFullName,
      owner,
      repo,
      pullRequestNumber,
      linkedIssues,
    });

    if (linkedIssues.length > 0) {
      linked += await upsertPullRequestLinksForLinkedIssues({
        workspaceId: workspace.id,
        owner,
        repo,
        action: asString(pullRequest.state, "open") === "closed" ? "closed" : "opened",
        pullRequest,
        repoFullName,
        branch: asString(pullRequest.head?.ref),
        linkedIssues,
      });
    }
  }

  return linked;
}

async function upsertPullRequestLink({
  workspaceId,
  issueId,
  action,
  pullRequest,
  repoFullName,
  branch,
  linkedIssues = [],
}: {
  workspaceId: string;
  issueId: string;
  action: string;
  pullRequest: NonNullable<GitHubPullRequestWebhookPayload["pull_request"]>;
  repoFullName: string;
  branch: string;
  linkedIssues?: GitHubPullRequestLinkedIssue[];
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
    const currentStatusId = asString(issue.get("statusId"), "triage");
    const nextStatusId = issueStatusForPullRequest({
      action,
      merged: asBoolean(pullRequest.merged),
      currentStatusId,
      reviewStatusId,
      doneStatusId: closedStatusId,
    });
    const linkId = pullRequestLinkId(owner, repo, number);
    const now = Timestamp.now();
    const existingLink = currentPullRequests.find((item) => asString(item.id) === linkId);
    const linkedPullRequest = pullRequestSummary({
      owner,
      repo,
      pullRequest,
      branch,
      linkedIssues,
    });
    const nextPullRequests = currentPullRequests.filter((item) => asString(item.id) !== linkId);
    nextPullRequests.push({
      id: linkId,
      ...linkedPullRequest,
      linkedAt: timestampFromValue(existingLink?.linkedAt) ?? now,
      updatedAt: now,
    });
    const cursorAgent = issue.get("cursorAgent") as Record<string, unknown> | undefined;
    const shouldCompleteCursorAgent = isActiveCursorAgentStatus(asString(cursorAgent?.status));
    const runDocumentId = asString(cursorAgent?.runDocumentId);
    transaction.set(
      issueRef,
      {
        pullRequests: nextPullRequests,
        ...(nextStatusId === null ? {} : { statusId: nextStatusId }),
        ...(shouldCompleteCursorAgent
          ? {
              cursorAgent: {
                status: "done",
                pullRequest: linkedPullRequest,
                completedAt: FieldValue.serverTimestamp(),
                updatedAt: FieldValue.serverTimestamp(),
                errorMessage: FieldValue.delete(),
              },
            }
          : {}),
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    if (shouldCompleteCursorAgent && runDocumentId.length > 0) {
      transaction.set(
        issueRef.collection("cursorAgentRuns").doc(runDocumentId),
        {
          status: "done",
          pullRequest: linkedPullRequest,
          completedAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
    }
  });
}

async function upsertPullRequestLinksForLinkedIssues({
  workspaceId,
  owner,
  repo,
  action,
  pullRequest,
  repoFullName,
  branch,
  linkedIssues,
  skipIssueIds = new Set<string>(),
}: {
  workspaceId: string;
  owner: string;
  repo: string;
  action: string;
  pullRequest: NonNullable<GitHubPullRequestWebhookPayload["pull_request"]>;
  repoFullName: string;
  branch: string;
  linkedIssues: GitHubPullRequestLinkedIssue[];
  skipIssueIds?: Set<string>;
}): Promise<number> {
  let linked = 0;
  for (const linkedIssue of linkedIssues) {
    const { doc: issueDoc } = await resolveGitHubIssueDocument({
      workspaceId,
      owner,
      repo,
      number: linkedIssue.number,
    });
    if (!issueDoc.exists || skipIssueIds.has(issueDoc.id)) {
      continue;
    }
    const issue = issueDoc.data();
    if (asString(issue?.repo) !== repoFullName) {
      continue;
    }

    await upsertPullRequestLink({
      workspaceId,
      issueId: issueDoc.id,
      action,
      pullRequest,
      repoFullName,
      branch,
      linkedIssues,
    });
    linked += 1;
  }
  return linked;
}

async function removePullRequestLinkFromUnlinkedIssues({
  workspaceId,
  repoFullName,
  owner,
  repo,
  pullRequestNumber,
  linkedIssues,
}: {
  workspaceId: string;
  repoFullName: string;
  owner: string;
  repo: string;
  pullRequestNumber: number;
  linkedIssues: GitHubPullRequestLinkedIssue[];
}): Promise<number> {
  const linkedIssueNumbers = new Set(linkedIssues.map((issue) => issue.number));
  const linkId = pullRequestLinkId(owner, repo, pullRequestNumber);
  const issues = await db
    .collection(`workspaces/${workspaceId}/issues`)
    .where("repo", "==", repoFullName)
    .get();

  let removed = 0;
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

  for (const issueDoc of issues.docs) {
    const issue = issueDoc.data();
    const githubIssue = issue.githubIssue as Record<string, unknown> | undefined;
    const githubIssueNumber = asNumber(githubIssue?.number);
    const currentPullRequests = recordList(issue.pullRequests);
    const hasPullRequestLink = currentPullRequests.some((item) => asString(item.id) === linkId);
    if (!hasPullRequestLink || linkedIssueNumbers.has(githubIssueNumber)) {
      continue;
    }

    batch.set(
      issueDoc.ref,
      {
        pullRequests: currentPullRequests.filter((item) => asString(item.id) !== linkId),
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    pendingWrites += 1;
    removed += 1;
    await commitIfNeeded();
  }

  await commitIfNeeded(true);
  return removed;
}

async function syncGitHubIssueFromWebhook(payload: GitHubIssueWebhookPayload): Promise<number> {
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

  const workspaces = await db
    .collection("workspaces")
    .where("syncedGitHubRepoFullNames", "array-contains", repoFullName)
    .get();
  let updated = 0;

  for (const workspace of workspaces.docs) {
    const workspaceRef = workspace.ref;
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

      const keyFields = await issueKeyFields(workspaceRef.id, existingData);

      let rank = asNumber(existingData.rank);
      if (rank === 0 && !issueDoc.exists) {
        const topIssue = await workspaceRef.collection("issues").orderBy("rank").limit(1).get();
        const topDoc = topIssue.docs[0];
        const topRank = topDoc === undefined ? Date.now() : asNumber(topDoc.get("rank"));
        rank = topRank - 1000;
      }

      await issueRef.set(
        {
          ...keyFields,
          title,
          body,
          repo: repoFullName,
          labels,
          comments: asNumber(ghIssue.comments),
          priority: asString(existingData.priority, "medium"),
          statusId: asString(existingData.statusId, "triage"),
          rank,
          githubIssue: githubIssueFirestoreFields(owner, repo, ghIssue),
          githubUpdatedAt: asTimestamp(ghIssue.updated_at),
          githubCreatedAt: asTimestamp(ghIssue.created_at),
          updatedAt: FieldValue.serverTimestamp(),
          createdAt: issueDoc.exists
            ? (existingData.createdAt ?? FieldValue.serverTimestamp())
            : FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
      updated += 1;
    } else if (action === "closed" || action === "reopened") {
      if (!issueDoc.exists) {
        continue;
      }

      const issueData = issueDoc.data() ?? {};
      const currentStatusId = asString(issueData.statusId, "triage");

      if (action === "closed" && currentStatusId !== closedStatusId) {
        await issueRef.set(
          {
            statusId: closedStatusId,
            "githubIssue.state": "closed",
            updatedAt: FieldValue.serverTimestamp(),
          },
          { merge: true },
        );
        updated += 1;
      } else if (action === "reopened" && currentStatusId === closedStatusId) {
        await issueRef.set(
          {
            statusId: "triage",
            "githubIssue.state": "open",
            updatedAt: FieldValue.serverTimestamp(),
          },
          { merge: true },
        );
        updated += 1;
      }
    }
  }

  return updated;
}

function isBranchLogPath(path: string): boolean {
  return (
    path.startsWith(branchLogPathPrefix) &&
    path.endsWith(".json") &&
    !path.includes("/", branchLogPathPrefix.length)
  );
}

function branchLogPathsFromCommits(
  commits: NonNullable<GitHubPushWebhookPayload["commits"]>,
): string[] {
  const paths = new Set<string>();
  for (const commit of commits) {
    const files = [
      ...((commit.added as string[] | undefined) ?? []),
      ...((commit.modified as string[] | undefined) ?? []),
    ];
    for (const file of files) {
      if (isBranchLogPath(file)) {
        paths.add(file);
      }
    }
  }
  return [...paths].sort();
}

function parseBranchLogEntry(content: string): BranchLogEntry | null {
  try {
    return JSON.parse(content) as BranchLogEntry;
  } catch {
    return null;
  }
}

async function fetchBranchLogEntries({
  owner,
  repo,
  token,
  ref,
  paths,
}: {
  owner: string;
  repo: string;
  token: string;
  ref: string;
  paths: string[];
}): Promise<BranchLogEntry[]> {
  const entries: BranchLogEntry[] = [];
  const queryParameters = ref.length > 0 ? { ref } : undefined;

  for (const path of paths) {
    const fileResponse = await githubRequest<GitHubContentFileResponse>({
      path: `/repos/${owner}/${repo}/contents/${path}`,
      token,
      queryParameters,
    });
    if (asString(fileResponse.encoding) !== "base64") {
      continue;
    }

    const content = Buffer.from(asString(fileResponse.content), "base64").toString("utf8");
    const entry = parseBranchLogEntry(content);
    if (entry !== null) {
      entries.push(entry);
    }
  }

  return entries;
}

async function processBranchLogFromPush(payload: GitHubPushWebhookPayload): Promise<number> {
  const repoFullName = asString(payload.repository?.full_name);
  if (repoFullName.length === 0) {
    return 0;
  }

  const commits = payload.commits ?? [];
  const branchLogPaths = branchLogPathsFromCommits(commits);
  if (branchLogPaths.length === 0) {
    return 0;
  }

  const workspaces = await db
    .collection("workspaces")
    .where("syncedGitHubRepoFullNames", "array-contains", repoFullName)
    .get();
  let recorded = 0;

  for (const workspace of workspaces.docs) {
    const workspaceRef = workspace.ref;
    const workspaceId = workspace.id;
    const ownerUid = asString(workspace.get("ownerUid"));
    if (ownerUid.length === 0) {
      continue;
    }

    let token: string;
    try {
      ({ token } = await getWorkspaceGitHubToken(workspaceId));
    } catch {
      logger.warn("processBranchLog: no GitHub App installation token", {
        workspaceId,
        ownerUid,
      });
      continue;
    }

    const [owner, repo] = repoFullName.split("/");
    if (!owner || !repo) {
      continue;
    }

    let branchLogEntries: BranchLogEntry[];
    try {
      const ref = asString(payload.ref).replace(/^refs\/heads\//u, "");
      branchLogEntries = await fetchBranchLogEntries({
        owner,
        repo,
        token,
        ref,
        paths: branchLogPaths,
      });
    } catch {
      logger.warn("processBranchLog: failed to fetch branch log", {
        workspaceId,
        repoFullName,
      });
      continue;
    }

    for (const entry of branchLogEntries) {
      const branchName = asString(entry.branch);
      const createdAtStr = asString(entry.at);
      if (branchName.length === 0 || createdAtStr.length === 0) {
        continue;
      }

      const parsedIssueKey = extractIssueKey(branchName);
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

      const issueDoc = issueDocs.docs[0]!;
      const existingBranchCreatedAt = timestampFromValue(issueDoc.get("branchCreatedAt"));
      if (existingBranchCreatedAt !== null) {
        continue;
      }

      const cursorAgent = issueDoc.get("cursorAgent") as Record<string, unknown> | undefined;
      const cursorStartedAt = timestampFromValue(cursorAgent?.startedAt);
      const workStartedAt = cursorStartedAt ?? branchCreatedAt;

      await issueDoc.ref.set(
        {
          branchCreatedAt,
          workStartedAt,
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
      recorded += 1;
    }
  }

  return recorded;
}

export const syncGitHubIssues = onCall<WorkspaceRequest, Promise<SyncGitHubIssuesResponse>>(
  async (request) => {
    const workspaceId = requireNonEmptyString(request.data?.workspaceId, "workspaceId");
    const { token } = await getWorkspaceGitHubToken(workspaceId);
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
        await patchGitHubIssueCore({
          owner,
          repo,
          number,
          token,
          title: issue.title,
          body: issue.body,
          statusId: issue.statusId,
        });
        await patchGitHubIssueLabelsSafely({
          workspaceId,
          owner,
          repo,
          number,
          token,
          labels: issue.labels,
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
        logger.warn("Failed to sync Ima GitHub issue", {
          workspaceId,
          issueId,
          error,
        });
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

    try {
      await syncWorkspacePullRequestLinks({ workspaceId, token });
    } catch (error) {
      logger.warn("syncGitHubIssues: failed to sync pull request links", {
        workspaceId,
        message: error instanceof Error ? error.message : String(error),
      });
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
    logger.error("Failed to estimate Ima issue weight", {
      workspaceId,
      issueId,
      uid,
      message,
    });
    throw new HttpsError("internal", "Failed to estimate issue weight");
  }
});

export const issueLifecycleEventLogger = onDocumentWritten(
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

    if (
      inProgressStatusIds.has(afterStatus) &&
      timestampFromValue(after.firstInProgressAt) === null
    ) {
      updates.firstInProgressAt = now;
    }

    if (beforeStatus !== afterStatus && afterStatus === closedStatusId) {
      const createdAt =
        timestampFromValue(after.githubCreatedAt) ?? timestampFromValue(after.createdAt);
      const firstInProgressAt = timestampFromValue(after.firstInProgressAt);
      const cursorAgent = after.cursorAgent as Record<string, unknown> | undefined;
      const cursorStartedAt = timestampFromValue(cursorAgent?.startedAt);
      const branchCreatedAt = timestampFromValue(after.branchCreatedAt);
      const workStartedAt = cursorStartedAt ?? branchCreatedAt ?? firstInProgressAt;
      const workStartSource =
        cursorStartedAt !== null ? "cursorAgent" : branchCreatedAt !== null ? "branch" : "status";
      const leadTimeMs = createdAt === null ? null : now.toMillis() - createdAt.toMillis();
      const cycleTimeMs = workStartedAt === null ? null : now.toMillis() - workStartedAt.toMillis();
      const weightEstimate = issueWeightEstimateMap(after);
      const weightValue = typeof weightEstimate.value === "number" ? weightEstimate.value : null;

      let actualWeight: number | null = null;
      let weightDelta: number | null = null;
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
        logger.info("Closed descendant sub-issues", {
          workspaceId,
          issueId,
          closedSubIssues,
        });
      }
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

export const recomputeResolutionWeights = onCall<
  { workspaceId: string },
  Promise<{ updated: number; skipped: number }>
>({ timeoutSeconds: 300 }, async (request) => {
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
    const resolution = data.resolution as Record<string, unknown> | undefined;
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
  logger.info("recomputeResolutionWeights", { workspaceId, updated, skipped });
  return { updated, skipped };
});

export const autoEstimateIssueWeightOnIssueWrite = onDocumentWritten(
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
    if (!before && after.migratedAt !== undefined) {
      return;
    }
    const afterInputHash = issueWeightInputHash(after);
    if (before && issueWeightInputHash(before) === afterInputHash) {
      return;
    }

    const existing = issueWeightEstimateMap(after);
    if (existing.manualOverride === true) {
      return;
    }
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
      logger.error("autoEstimateIssueWeight: failed", {
        workspaceId,
        issueId,
        message,
      });
    }
  },
);

export const autoSyncIssueToGitHubOnIssueWrite = onDocumentWritten(
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
    const statusChanged = after.statusId !== before?.statusId;

    if (!titleChanged && !bodyChanged && !labelsChanged && !statusChanged) {
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
      ({ token } = await getWorkspaceGitHubToken(workspaceId));
    } catch {
      logger.warn("autoSyncIssueToGitHub: no GitHub App installation token", {
        workspaceId,
        ownerUid,
      });
      return;
    }

    try {
      await patchGitHubIssueCore({
        owner,
        repo,
        number,
        token,
        ...(titleChanged ? { title: after.title } : {}),
        ...(bodyChanged ? { body: after.body } : {}),
        ...(statusChanged ? { statusId: after.statusId } : {}),
      });
      if (labelsChanged) {
        await patchGitHubIssueLabelsSafely({
          workspaceId,
          owner,
          repo,
          number,
          token,
          labels: after.labels,
        });
      }
      logger.info("autoSyncIssueToGitHub: synced", {
        workspaceId,
        owner,
        repo,
        number,
      });
    } catch (error) {
      logger.error("autoSyncIssueToGitHub: failed", {
        workspaceId,
        owner,
        repo,
        number,
        errorMessage: errorMessage(error),
        stack: errorStack(error),
      });
    }
  },
);

export const syncIssuePullRequestLinksToGitHubOnIssueWrite = onDocumentWritten(
  {
    document: "workspaces/{workspaceId}/issues/{issueId}",
    secrets: githubAppSecrets,
  },
  async (event) => {
    const before = event.data?.before?.data();
    const after = event.data?.after?.data();
    if (!before) {
      return;
    }

    const operations = pullRequestBodySyncOperations({ before, after });
    if (operations.length === 0) {
      return;
    }

    const issue = after ?? before;
    const githubIssue = issue.githubIssue as Record<string, unknown> | undefined;
    if (asNumber(githubIssue?.number) <= 0) {
      logger.warn("syncIssuePullRequestLinksToGitHub: issue has no GitHub issue number", {
        workspaceId: event.params.workspaceId,
        issueId: event.params.issueId,
      });
      return;
    }

    const workspaceId = event.params.workspaceId;
    let token: string;
    try {
      ({ token } = await getWorkspaceGitHubToken(workspaceId));
    } catch (error) {
      logger.warn("syncIssuePullRequestLinksToGitHub: no GitHub App installation token", {
        workspaceId,
        issueId: event.params.issueId,
        message: errorMessage(error),
      });
      return;
    }

    for (const operation of operations) {
      try {
        const repoFullName = `${operation.pullRequest.owner}/${operation.pullRequest.repo}`;
        const updated = await syncPullRequestBodyToWorkspaceLinks({
          workspaceId,
          token,
          pullRequest: operation.pullRequest,
          repoFullName,
        });
        if (updated) {
          logger.info("syncIssuePullRequestLinksToGitHub: updated PR body", {
            workspaceId,
            issueId: event.params.issueId,
            action: operation.action,
            owner: operation.pullRequest.owner,
            repo: operation.pullRequest.repo,
            pullRequestNumber: operation.pullRequest.number,
          });
        }
      } catch (error) {
        logger.error("syncIssuePullRequestLinksToGitHub: failed", {
          workspaceId,
          issueId: event.params.issueId,
          action: operation.action,
          owner: operation.pullRequest.owner,
          repo: operation.pullRequest.repo,
          pullRequestNumber: operation.pullRequest.number,
          errorMessage: errorMessage(error),
          stack: errorStack(error),
        });
      }
    }
  },
);
