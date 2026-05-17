import { Buffer } from "node:buffer";

import { getFirestore } from "firebase-admin/firestore";
import { defineSecret } from "firebase-functions/params";
import { logger } from "firebase-functions/v2";
import { onDocumentCreated } from "firebase-functions/v2/firestore";
import { HttpsError, onCall } from "firebase-functions/v2/https";
import OpenAI from "openai";

import { BuildJobStatus, firestoreCollectionPaths, listLatestBuildLogs } from "../firestoreData.js";
import {
  getInstallationToken,
  githubAppId,
  githubGet,
  githubPost,
  githubPrivateKey,
  githubPut,
} from "../github/githubApp.js";
import { getApiBaseUrlFromTeamData } from "../github/githubUrls.js";
import { verifyTeamMembership } from "../team/teamAuth.js";

export const openAiApiKey = defineSecret("OPENAI_API_KEY");

const ciCdFixRequestsCollection = "ci_cd_fix_requests_v0";
const ciCdFixModel = "gpt-5.5";
const maxLogCharacters = 80_000;
const maxWorkflowCharacters = 120_000;

interface StartCiCdFixRequest {
  buildJobId: string;
}

interface StartCiCdFixResponse {
  requestId: string;
}

interface ApplyCiCdFixRequest {
  requestId: string;
}

interface ReviseCiCdFixRequest {
  requestId: string;
  instruction: string;
}

interface ApplyCiCdFixResponse {
  mode: "direct" | "pull_request";
  branch: string;
  commitSha?: string;
  pullRequestUrl?: string;
  pullRequestNumber?: number;
}

interface BuildJobData {
  teamId?: unknown;
  owner?: unknown;
  repo?: unknown;
  status?: unknown;
  workflowName?: unknown;
  workflowFileName?: unknown;
  branch?: unknown;
  jobKey?: unknown;
  latestRunId?: unknown;
  commitSha?: unknown;
}

interface CiCdFixFile {
  path: string;
  oldContent: string;
  newContent: string;
  added: number;
  removed: number;
  lines: Array<{ kind: "context" | "added" | "removed"; text: string }>;
}

interface CiCdFixSuggestion {
  failureReason: string;
  fixSummary: string[];
  warnings: string[];
  commitMessage: string;
  files: CiCdFixFile[];
}

interface GitHubContentResponse {
  content?: unknown;
  encoding?: unknown;
  sha?: unknown;
}

function db() {
  return getFirestore();
}

function requireNonEmptyString(value: unknown, field: string): string {
  if (typeof value !== "string" || value.length === 0) {
    throw new HttpsError("invalid-argument", `${field} is required`);
  }
  return value;
}

function errorMessage(error: unknown): string {
  return error instanceof Error ? error.message : String(error);
}

function stringValue(value: unknown): string | undefined {
  return typeof value === "string" && value.length > 0 ? value : undefined;
}

function getInstallationIds(teamData: FirebaseFirestore.DocumentData): number[] {
  const installationIds = Array.isArray(teamData.installationIds) ? teamData.installationIds : [];
  const ids = installationIds.filter((id): id is number => typeof id === "number");
  if (ids.length === 0) {
    throw new HttpsError("failed-precondition", "GitHub App is not installed for this team");
  }
  return ids;
}

function workflowPathFromBuildJob(buildJob: BuildJobData): string {
  const fileName = stringValue(buildJob.workflowFileName) ?? "workflow.yaml";
  return fileName.startsWith(".openci/") ? fileName : `.openci/${fileName}`;
}

function decodeGitHubContent(file: GitHubContentResponse): string {
  const content = requireNonEmptyString(file.content, "content");
  const encoding = requireNonEmptyString(file.encoding, "encoding");
  if (encoding !== "base64") {
    throw new Error(`Unsupported GitHub content encoding: ${encoding}`);
  }
  return Buffer.from(content.replace(/\s/g, ""), "base64").toString("utf8");
}

function extractJsonObject(text: string): unknown {
  const fenced = /```(?:json)?\s*([\s\S]*?)\s*```/u.exec(text);
  const source = fenced?.[1] ?? text;
  const firstBrace = source.indexOf("{");
  const lastBrace = source.lastIndexOf("}");
  if (firstBrace < 0 || lastBrace <= firstBrace) {
    throw new Error("LLM response did not contain a JSON object");
  }
  return JSON.parse(source.slice(firstBrace, lastBrace + 1)) as unknown;
}

function asStringArray(value: unknown): string[] {
  return Array.isArray(value)
    ? value.filter((entry): entry is string => typeof entry === "string")
    : [];
}

function countChangedLines(lines: Array<{ kind: string }>): { added: number; removed: number } {
  let added = 0;
  let removed = 0;
  for (const line of lines) {
    if (line.kind === "added") added += 1;
    if (line.kind === "removed") removed += 1;
  }
  return { added, removed };
}

function createSimpleDiff(oldContent: string, newContent: string): CiCdFixFile["lines"] {
  if (oldContent === newContent) return [{ kind: "context", text: "[no changes]" }];
  const oldLines = oldContent.split("\n");
  const newLines = newContent.split("\n");
  let prefix = 0;
  while (
    prefix < oldLines.length &&
    prefix < newLines.length &&
    oldLines[prefix] === newLines[prefix]
  ) {
    prefix += 1;
  }
  let oldSuffix = oldLines.length - 1;
  let newSuffix = newLines.length - 1;
  while (
    oldSuffix >= prefix &&
    newSuffix >= prefix &&
    oldLines[oldSuffix] === newLines[newSuffix]
  ) {
    oldSuffix -= 1;
    newSuffix -= 1;
  }

  const before = oldLines.slice(Math.max(0, prefix - 3), prefix);
  const after = newLines.slice(newSuffix + 1, Math.min(newLines.length, newSuffix + 4));
  return [
    ...before.map((text) => ({ kind: "context" as const, text })),
    ...oldLines.slice(prefix, oldSuffix + 1).map((text) => ({ kind: "removed" as const, text })),
    ...newLines.slice(prefix, newSuffix + 1).map((text) => ({ kind: "added" as const, text })),
    ...after.map((text) => ({ kind: "context" as const, text })),
  ];
}

function parseSuggestion(
  value: unknown,
  oldContent: string,
  workflowPath: string,
): CiCdFixSuggestion {
  if (typeof value !== "object" || value === null) {
    throw new Error("LLM response JSON must be an object");
  }
  const object = value as Record<string, unknown>;
  const newContent = requireNonEmptyString(object.newContent, "newContent");
  const lines = createSimpleDiff(oldContent, newContent);
  const counts = countChangedLines(lines);
  if (newContent === oldContent) {
    throw new Error("LLM did not change the workflow file");
  }
  return {
    failureReason: stringValue(object.failureReason) ?? "CI/CD failure detected.",
    fixSummary: asStringArray(object.fixSummary).slice(0, 8),
    warnings: asStringArray(object.warnings).slice(0, 8),
    commitMessage: stringValue(object.commitMessage) ?? "Fix CI/CD workflow",
    files: [
      {
        path: workflowPath,
        oldContent,
        newContent,
        added: counts.added,
        removed: counts.removed,
        lines,
      },
    ],
  };
}

async function createOpenAiResponse(input: string): Promise<string> {
  const openai = new OpenAI({ apiKey: openAiApiKey.value() });
  const response = await openai.responses.create({
    model: ciCdFixModel,
    max_output_tokens: 8192,
    instructions:
      "You are an expert CI/CD engineer for OpenCI. Return strict JSON only. Never include markdown outside JSON.",
    input,
  });
  const text = response.output_text;
  if (text.length === 0) {
    throw new Error("OpenAI response did not contain text");
  }
  return text;
}

function buildPrompt({
  buildJob,
  workflowPath,
  workflowContent,
  logs,
  userInstruction,
}: {
  buildJob: BuildJobData;
  workflowPath: string;
  workflowContent: string;
  logs: string;
  userInstruction?: string;
}): string {
  return `You are fixing an OpenCI CI/CD workflow.

OpenCI workflows are GitHub Actions-like YAML files stored in .openci/*.yaml and executed locally by act.

Repository: ${stringValue(buildJob.owner)}/${stringValue(buildJob.repo)}
Branch: ${stringValue(buildJob.branch) ?? "main"}
Workflow: ${stringValue(buildJob.workflowName) ?? ""}
Workflow file: ${workflowPath}
Job: ${stringValue(buildJob.jobKey) ?? ""}
Commit: ${stringValue(buildJob.commitSha) ?? ""}

Rules:
- Return Japanese copy for failureReason, fixSummary, and warnings.
- Only change the provided workflow file.
- Preserve unrelated jobs and deployment steps.
- Keep actions/checkout@v4 as the first step if it is already first.
- Prefer minimal, practical changes.
- Do not invent OpenCI actions or action inputs.
- If the user provided an instruction, follow it unless it conflicts with the logs or OpenCI compatibility.
- Return ONLY JSON with this shape:
{
  "failureReason": "short Japanese explanation",
  "fixSummary": ["Japanese bullet"],
  "warnings": ["Japanese warning"],
  "commitMessage": "short English commit message",
  "newContent": "complete replacement content for the workflow file"
}

Current workflow file:
--- FILE: ${workflowPath} ---
${workflowContent.slice(0, maxWorkflowCharacters)}

User instruction:
${userInstruction ?? "(none)"}

Recent failing logs:
${logs.slice(0, maxLogCharacters)}`;
}

async function getBuildJob(buildJobId: string): Promise<BuildJobData> {
  const snapshot = await db().collection(firestoreCollectionPaths.buildJobs).doc(buildJobId).get();
  if (!snapshot.exists) {
    throw new HttpsError("not-found", "Build job not found");
  }
  return snapshot.data() as BuildJobData;
}

async function getRequest(requestId: string): Promise<FirebaseFirestore.DocumentSnapshot> {
  const snapshot = await db().collection(ciCdFixRequestsCollection).doc(requestId).get();
  if (!snapshot.exists) {
    throw new HttpsError("not-found", "CI/CD fix request not found");
  }
  return snapshot;
}

async function findInstallationToken({
  teamData,
  owner,
  repo,
}: {
  teamData: FirebaseFirestore.DocumentData;
  owner: string;
  repo: string;
}): Promise<{ token: string; apiBaseUrl: string }> {
  const apiBaseUrl = getApiBaseUrlFromTeamData(teamData);
  for (const installationId of getInstallationIds(teamData)) {
    const { token } = await getInstallationToken(installationId, { apiBaseUrl });
    try {
      await githubGet(`/repos/${owner}/${repo}`, token, { apiBaseUrl });
      return { token, apiBaseUrl };
    } catch {
      continue;
    }
  }
  throw new HttpsError("not-found", "Repository not found in any installation");
}

async function processCiCdFixRequest(requestId: string): Promise<void> {
  const ref = db().collection(ciCdFixRequestsCollection).doc(requestId);
  const snapshot = await ref.get();
  const request = snapshot.data();
  if (!request || request.status !== "queued") return;

  const buildJob = await getBuildJob(requireNonEmptyString(request.buildJobId, "buildJobId"));
  const teamId = requireNonEmptyString(buildJob.teamId, "teamId");
  const owner = requireNonEmptyString(buildJob.owner, "owner");
  const repo = requireNonEmptyString(buildJob.repo, "repo");
  const branch = stringValue(buildJob.branch) ?? "main";
  const workflowPath = workflowPathFromBuildJob(buildJob);

  await ref.set(
    { status: "collecting_context", updatedAt: new Date(), branch, workflowPath },
    { merge: true },
  );

  const teamSnapshot = await db().collection(firestoreCollectionPaths.teams).doc(teamId).get();
  const teamData = teamSnapshot.data();
  if (!teamData) throw new HttpsError("not-found", "Team not found");
  const { token, apiBaseUrl } = await findInstallationToken({ teamData, owner, repo });
  const workflowFile = await githubGet<GitHubContentResponse>(
    `/repos/${owner}/${repo}/contents/${workflowPath}`,
    token,
    { queryParameters: { ref: branch }, apiBaseUrl },
  );
  const oldContent = decodeGitHubContent(workflowFile);

  const latestRunId = requireNonEmptyString(buildJob.latestRunId, "latestRunId");
  const logsResult = await listLatestBuildLogs({
    buildJobId: request.buildJobId,
    runId: latestRunId,
    limit: 300,
  });
  const logs = ((logsResult.data.buildLogs as Array<{ message?: string }>) ?? [])
    .slice()
    .reverse()
    .map((log) => log.message ?? "")
    .join("\n");

  await ref.set({ status: "generating_fix", updatedAt: new Date() }, { merge: true });
  const responseText = await createOpenAiResponse(
    buildPrompt({
      buildJob,
      workflowPath,
      workflowContent: oldContent,
      logs,
      userInstruction: stringValue(request.userInstruction),
    }),
  );
  const suggestion = parseSuggestion(extractJsonObject(responseText), oldContent, workflowPath);

  await ref.set(
    {
      status: "ready",
      model: ciCdFixModel,
      repository: `${owner}/${repo}`,
      owner,
      repo,
      branch,
      workflowPath,
      jobKey: stringValue(buildJob.jobKey) ?? null,
      commitSha: stringValue(buildJob.commitSha) ?? null,
      ...suggestion,
      updatedAt: new Date(),
      readyAt: new Date(),
    },
    { merge: true },
  );
}

async function applyFix({
  requestId,
  mode,
  auth,
}: {
  requestId: string;
  mode: "direct" | "pull_request";
  auth: Parameters<typeof verifyTeamMembership>[0];
}): Promise<ApplyCiCdFixResponse> {
  const snapshot = await getRequest(requestId);
  const request = snapshot.data() as Record<string, unknown>;
  const teamId = requireNonEmptyString(request.teamId, "teamId");
  const teamData = await verifyTeamMembership(auth, teamId);
  if (request.status !== "ready") {
    throw new HttpsError("failed-precondition", "CI/CD fix request is not ready");
  }
  const owner = requireNonEmptyString(request.owner, "owner");
  const repo = requireNonEmptyString(request.repo, "repo");
  const branch = requireNonEmptyString(request.branch, "branch");
  const files = Array.isArray(request.files) ? request.files : [];
  const file = files[0] as Record<string, unknown> | undefined;
  if (!file) throw new HttpsError("failed-precondition", "CI/CD fix request has no file changes");
  const path = requireNonEmptyString(file.path, "file.path");
  const newContent = requireNonEmptyString(file.newContent, "file.newContent");
  const message = stringValue(request.commitMessage) ?? "Fix CI/CD workflow";
  const { token, apiBaseUrl } = await findInstallationToken({ teamData, owner, repo });
  const existing = await githubGet<GitHubContentResponse>(
    `/repos/${owner}/${repo}/contents/${path}`,
    token,
    { queryParameters: { ref: branch }, apiBaseUrl },
  );
  const existingSha = requireNonEmptyString(existing.sha, "existing.sha");
  const content = Buffer.from(newContent, "utf8").toString("base64");

  if (mode === "direct") {
    const updated = await githubPut<{ commit?: { sha?: string } }>(
      `/repos/${owner}/${repo}/contents/${path}`,
      token,
      { message, content, branch, sha: existingSha },
      { apiBaseUrl },
    );
    const commitSha = stringValue(updated.commit?.sha);
    await snapshot.ref.set(
      {
        status: "committed",
        commitSha: commitSha ?? null,
        updatedAt: new Date(),
        committedAt: new Date(),
      },
      { merge: true },
    );
    return { mode: "direct", branch, commitSha };
  }

  const branchSlug = path
    .replace(/^\.openci\//u, "")
    .replace(/\.(yaml|yml)$/u, "")
    .replace(/[^a-zA-Z0-9._-]+/gu, "-");
  const newBranchName = `openci/fix-${branchSlug}-${Date.now()}`;
  const refData = await githubGet<{ object?: { sha?: string } }>(
    `/repos/${owner}/${repo}/git/ref/heads/${branch}`,
    token,
    { apiBaseUrl },
  );
  await githubPost(
    `/repos/${owner}/${repo}/git/refs`,
    token,
    { ref: `refs/heads/${newBranchName}`, sha: refData.object?.sha },
    { apiBaseUrl },
  );
  await githubPut(
    `/repos/${owner}/${repo}/contents/${path}`,
    token,
    { message, content, branch: newBranchName, sha: existingSha },
    { apiBaseUrl },
  );
  const pr = await githubPost<{ html_url?: string; number?: number }>(
    `/repos/${owner}/${repo}/pulls`,
    token,
    {
      title: message,
      head: newBranchName,
      base: branch,
      body: `This CI/CD fix was generated by OpenCI.\n\nRequest: \`${requestId}\`\nFile: \`${path}\``,
    },
    { apiBaseUrl },
  );
  const pullRequestUrl = requireNonEmptyString(pr.html_url, "pullRequestUrl");
  const pullRequestNumber = typeof pr.number === "number" ? pr.number : undefined;
  await snapshot.ref.set(
    {
      status: "pr_created",
      branch: newBranchName,
      pullRequestUrl,
      pullRequestNumber: pullRequestNumber ?? null,
      updatedAt: new Date(),
      prCreatedAt: new Date(),
    },
    { merge: true },
  );
  return { mode: "pull_request", branch: newBranchName, pullRequestUrl, pullRequestNumber };
}

export const startCiCdFix = onCall<StartCiCdFixRequest, Promise<StartCiCdFixResponse>>(
  { timeoutSeconds: 30, memory: "256MiB" },
  async (request) => {
    const buildJobId = requireNonEmptyString(request.data?.buildJobId, "buildJobId");
    const buildJob = await getBuildJob(buildJobId);
    const teamId = requireNonEmptyString(buildJob.teamId, "teamId");
    await verifyTeamMembership(request.auth, teamId);
    if (
      buildJob.status !== BuildJobStatus.FAILURE &&
      buildJob.status !== BuildJobStatus.TIMED_OUT
    ) {
      throw new HttpsError("failed-precondition", "Build job is not failed or timed out");
    }
    if (!stringValue(buildJob.latestRunId)) {
      throw new HttpsError("failed-precondition", "Build job has no logs");
    }
    const doc = db().collection(ciCdFixRequestsCollection).doc();
    await doc.set({
      id: doc.id,
      status: "queued",
      teamId,
      buildJobId,
      userId: request.auth?.uid ?? null,
      repository: `${stringValue(buildJob.owner) ?? ""}/${stringValue(buildJob.repo) ?? ""}`,
      owner: stringValue(buildJob.owner) ?? null,
      repo: stringValue(buildJob.repo) ?? null,
      branch: stringValue(buildJob.branch) ?? "main",
      workflowName: stringValue(buildJob.workflowName) ?? null,
      workflowPath: workflowPathFromBuildJob(buildJob),
      jobKey: stringValue(buildJob.jobKey) ?? null,
      commitSha: stringValue(buildJob.commitSha) ?? null,
      createdAt: new Date(),
      updatedAt: new Date(),
    });
    return { requestId: doc.id };
  },
);

export const reviseCiCdFix = onCall<ReviseCiCdFixRequest, Promise<StartCiCdFixResponse>>(
  { timeoutSeconds: 30, memory: "256MiB" },
  async (request) => {
    const requestId = requireNonEmptyString(request.data?.requestId, "requestId");
    const instruction = requireNonEmptyString(request.data?.instruction, "instruction").slice(
      0,
      4000,
    );
    const snapshot = await getRequest(requestId);
    const source = snapshot.data() as Record<string, unknown>;
    const teamId = requireNonEmptyString(source.teamId, "teamId");
    await verifyTeamMembership(request.auth, teamId);
    const buildJobId = requireNonEmptyString(source.buildJobId, "buildJobId");
    const buildJob = await getBuildJob(buildJobId);
    const doc = db().collection(ciCdFixRequestsCollection).doc();
    await doc.set({
      id: doc.id,
      status: "queued",
      teamId,
      buildJobId,
      parentRequestId: requestId,
      userInstruction: instruction,
      userId: request.auth?.uid ?? null,
      repository:
        stringValue(source.repository) ??
        `${stringValue(buildJob.owner) ?? ""}/${stringValue(buildJob.repo) ?? ""}`,
      owner: stringValue(source.owner) ?? stringValue(buildJob.owner) ?? null,
      repo: stringValue(source.repo) ?? stringValue(buildJob.repo) ?? null,
      branch: stringValue(source.branch) ?? stringValue(buildJob.branch) ?? "main",
      workflowName: stringValue(source.workflowName) ?? stringValue(buildJob.workflowName) ?? null,
      workflowPath: stringValue(source.workflowPath) ?? workflowPathFromBuildJob(buildJob),
      jobKey: stringValue(source.jobKey) ?? stringValue(buildJob.jobKey) ?? null,
      commitSha: stringValue(source.commitSha) ?? stringValue(buildJob.commitSha) ?? null,
      createdAt: new Date(),
      updatedAt: new Date(),
    });
    return { requestId: doc.id };
  },
);

export const generateCiCdFixOnRequest = onDocumentCreated(
  {
    document: `${ciCdFixRequestsCollection}/{requestId}`,
    timeoutSeconds: 300,
    memory: "1GiB",
    secrets: [githubAppId, githubPrivateKey, openAiApiKey],
  },
  async (event) => {
    const requestId = event.params.requestId;
    try {
      await processCiCdFixRequest(requestId);
    } catch (error) {
      logger.error("Failed to generate CI/CD fix", { requestId, error: errorMessage(error) });
      await db()
        .collection(ciCdFixRequestsCollection)
        .doc(requestId)
        .set(
          {
            status: "failed",
            error: errorMessage(error),
            updatedAt: new Date(),
            failedAt: new Date(),
          },
          { merge: true },
        );
    }
  },
);

export const commitCiCdFix = onCall<ApplyCiCdFixRequest, Promise<ApplyCiCdFixResponse>>(
  {
    timeoutSeconds: 120,
    memory: "512MiB",
    secrets: [githubAppId, githubPrivateKey],
  },
  async (request) => {
    return applyFix({
      requestId: requireNonEmptyString(request.data?.requestId, "requestId"),
      mode: "direct",
      auth: request.auth,
    });
  },
);

export const createCiCdFixPullRequest = onCall<ApplyCiCdFixRequest, Promise<ApplyCiCdFixResponse>>(
  {
    timeoutSeconds: 120,
    memory: "512MiB",
    secrets: [githubAppId, githubPrivateKey],
  },
  async (request) => {
    return applyFix({
      requestId: requireNonEmptyString(request.data?.requestId, "requestId"),
      mode: "pull_request",
      auth: request.auth,
    });
  },
);
