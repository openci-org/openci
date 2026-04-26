import { randomUUID } from "node:crypto";

import { logger } from "firebase-functions/v2";
import YAML from "yaml";

import {
  createBuildJob,
  findTeamByInstallation,
  getWorkflowFile,
} from "@openci/dataconnect-admin";
import { createCheckRun, getInstallationToken, githubGet, githubGraphql } from "./githubApp";
import {
  buildDashboardRunUrl,
  defaultGitHubApiBaseUrl,
  defaultGitHubBaseUrl,
  getGitHubApiBaseUrl,
  getGitHubBaseUrl,
} from "./githubUrls";
import { extractJobs, matchesTrigger, workflowFileDocId } from "./workflowParser";

export type GitHubEventType =
  | "pull_request"
  | "push"
  | "create"
  | "release"
  | "issue_comment"
  | "unknown";

export interface WebhookEvent {
  event: GitHubEventType;
  action?: string;
  ref?: string;
  refType?: string;
  repository?: {
    fullName: string;
    name: string;
    defaultBranch: string;
    owner: string;
  };
  sender?: { login: string };
  installation?: { id: number };
  pullRequest?: {
    number: number;
    headSha: string;
    headRef: string;
    baseRef: string;
  };
  release?: { tagName: string; htmlUrl?: string };
  comment?: { body: string };
  raw: Record<string, unknown>;
}

interface TriggerInfo {
  triggerType: string;
  branch?: string;
  triggerBranch?: string;
  tagName?: string;
  releaseName?: string;
}

const openciDirQuery = `
  query($owner: String!, $repo: String!, $expression: String!) {
    repository(owner: $owner, name: $repo) {
      object(expression: $expression) {
        ... on Tree {
          entries {
            name
            type
            object {
              ... on Blob { text }
            }
          }
        }
      }
    }
  }
`;

interface OpenciDirEntry {
  name?: string;
  type?: string;
  object?: { text?: string } | null;
}

interface OpenciDirResponse {
  data?: {
    repository?: {
      object?: {
        entries?: OpenciDirEntry[];
      } | null;
    } | null;
  };
}

export function webhookEventFromRequest(event: string, body: Record<string, unknown>): WebhookEvent {
  const repository = typeof body.repository === "object" && body.repository !== null
    ? (body.repository as Record<string, unknown>)
    : undefined;
  const fullName = typeof repository?.full_name === "string" ? repository.full_name : "";
  const pullRequest = typeof body.pull_request === "object" && body.pull_request !== null
    ? (body.pull_request as Record<string, unknown>)
    : undefined;
  const prHead = typeof pullRequest?.head === "object" && pullRequest.head !== null
    ? (pullRequest.head as Record<string, unknown>)
    : undefined;
  const prBase = typeof pullRequest?.base === "object" && pullRequest.base !== null
    ? (pullRequest.base as Record<string, unknown>)
    : undefined;
  const installation = typeof body.installation === "object" && body.installation !== null
    ? (body.installation as Record<string, unknown>)
    : undefined;
  const sender = typeof body.sender === "object" && body.sender !== null
    ? (body.sender as Record<string, unknown>)
    : undefined;
  const release = typeof body.release === "object" && body.release !== null
    ? (body.release as Record<string, unknown>)
    : undefined;
  const comment = typeof body.comment === "object" && body.comment !== null
    ? (body.comment as Record<string, unknown>)
    : undefined;

  return {
    event: ["pull_request", "push", "create", "release", "issue_comment"].includes(event)
      ? (event as GitHubEventType)
      : "unknown",
    raw: body,
    action: typeof body.action === "string" ? body.action : undefined,
    ref: typeof body.ref === "string" ? body.ref : undefined,
    refType: typeof body.ref_type === "string" ? body.ref_type : undefined,
    repository: repository
      ? {
          fullName,
          name: typeof repository.name === "string" ? repository.name : "",
          defaultBranch:
            typeof repository.default_branch === "string" ? repository.default_branch : "main",
          owner: fullName.split("/")[0] ?? "",
        }
      : undefined,
    sender: sender ? { login: typeof sender.login === "string" ? sender.login : "" } : undefined,
    installation: installation
      ? { id: typeof installation.id === "number" ? installation.id : 0 }
      : undefined,
    pullRequest: pullRequest
      ? {
          number: typeof pullRequest.number === "number" ? pullRequest.number : 0,
          headSha: typeof prHead?.sha === "string" ? prHead.sha : "",
          headRef: typeof prHead?.ref === "string" ? prHead.ref : "",
          baseRef: typeof prBase?.ref === "string" ? prBase.ref : "",
        }
      : undefined,
    release: release
      ? {
          tagName: typeof release.tag_name === "string" ? release.tag_name : "",
          htmlUrl: typeof release.html_url === "string" ? release.html_url : undefined,
        }
      : undefined,
    comment: comment ? { body: typeof comment.body === "string" ? comment.body : "" } : undefined,
  };
}

function extractTriggerInfo(event: WebhookEvent): TriggerInfo | undefined {
  if (event.event === "pull_request" && event.pullRequest) {
    return {
      triggerType: "pullRequest",
      branch: event.pullRequest.headRef,
      triggerBranch: event.pullRequest.baseRef,
    };
  }
  if (event.event === "push") {
    const branch = (event.ref ?? "").replace(/^refs\/heads\//u, "");
    return { triggerType: "push", branch, triggerBranch: branch };
  }
  if (event.event === "create" && event.refType === "tag") {
    return { triggerType: "tag", tagName: event.ref };
  }
  if (event.event === "release") {
    const rawRelease = typeof event.raw.release === "object" && event.raw.release !== null
      ? (event.raw.release as Record<string, unknown>)
      : {};
    return {
      triggerType: "release",
      tagName: event.release?.tagName,
      releaseName: typeof rawRelease.name === "string" ? rawRelease.name : undefined,
    };
  }
  return undefined;
}

async function findTeamIdForInstallation(installationId: number): Promise<string | undefined> {
  const result = await findTeamByInstallation({ installationId });
  return result.data.teams[0]?.id;
}

async function resolveCommitSha(
  event: WebhookEvent,
  triggerInfo: TriggerInfo,
  token: string,
  apiBaseUrl: string,
): Promise<string | undefined> {
  if (event.event === "pull_request") return event.pullRequest?.headSha;
  if (event.event === "push") {
    const headCommit = typeof event.raw.head_commit === "object" && event.raw.head_commit !== null
      ? (event.raw.head_commit as Record<string, unknown>)
      : {};
    return typeof headCommit.id === "string"
      ? headCommit.id
      : typeof event.raw.after === "string"
        ? event.raw.after
        : undefined;
  }
  const tagName = triggerInfo.tagName;
  if (tagName && event.repository) {
    const data = await githubGet<{ sha?: string }>(
      `/repos/${event.repository.fullName}/commits/${tagName}`,
      token,
      { apiBaseUrl },
    );
    return data.sha;
  }
  return undefined;
}

async function fetchOpenciDir(
  owner: string,
  repo: string,
  expression: string,
  token: string,
  apiBaseUrl: string,
): Promise<OpenciDirEntry[]> {
  try {
    const result = await githubGraphql<OpenciDirResponse>(openciDirQuery, token, {
      variables: { owner, repo, expression },
      apiBaseUrl,
    });
    return result.data?.repository?.object?.entries ?? [];
  } catch (error) {
    if (!String(error).includes("Could not resolve to an object")) {
      logger.error("Failed to list .openci directory", { error });
    }
    return [];
  }
}

function parseYaml(content: string): Record<string, unknown> | undefined {
  try {
    const parsed = YAML.parse(content) as unknown;
    return typeof parsed === "object" && parsed !== null && !Array.isArray(parsed)
      ? (parsed as Record<string, unknown>)
      : undefined;
  } catch (error) {
    logger.error("Failed to parse YAML", { error });
    return undefined;
  }
}

export async function handleBuildTrigger(event: WebhookEvent): Promise<void> {
  const installationId = event.installation?.id;
  if (!installationId) throw new Error("No installation ID in webhook event");
  const triggerInfo = extractTriggerInfo(event);
  if (!triggerInfo || !event.repository) return;

  const teamId = await findTeamIdForInstallation(installationId);
  const apiBaseUrl = await getGitHubApiBaseUrl(teamId);
  const githubBaseUrl = await getGitHubBaseUrl(teamId);
  const { token, expiresAt } = await getInstallationToken(installationId, { apiBaseUrl });
  const commitSha = await resolveCommitSha(event, triggerInfo, token, apiBaseUrl);
  const queryRef = commitSha ?? (triggerInfo.triggerBranch ? `heads/${triggerInfo.triggerBranch}` : undefined);
  if (!queryRef) return;

  const entries = await fetchOpenciDir(
    event.repository.owner,
    event.repository.name,
    `${queryRef}:.openci`,
    token,
    apiBaseUrl,
  );
  const yamlEntries = entries.filter(
    (entry) =>
      entry.type === "blob" &&
      typeof entry.name === "string" &&
      (entry.name.endsWith(".yaml") || entry.name.endsWith(".yml")) &&
      typeof entry.object?.text === "string",
  );

  for (const entry of yamlEntries) {
    try {
      const parsed = parseYaml(entry.object!.text!);
      if (!parsed) continue;
      const workflowName =
        typeof parsed.name === "string" ? parsed.name : entry.name!.replace(/\.(yaml|yml)$/u, "");
      if (!matchesTrigger(parsed, triggerInfo.triggerType, triggerInfo.triggerBranch)) continue;
      const jobInfos = extractJobs(parsed);
      if (jobInfos.length === 0) continue;

      if (teamId) {
        const wfBranch = triggerInfo.triggerBranch ?? "HEAD";
        const wfDoc = await getWorkflowFile({
          id: workflowFileDocId(teamId, event.repository.fullName, wfBranch, entry.name!),
        });
        if (wfDoc.data.workflowFile?.enabled === false) continue;
      }

      const workflowRunId = randomUUID();
      const jobDocIds = new Map(jobInfos.map((job) => [job.jobKey, randomUUID()]));
      for (const jobInfo of jobInfos) {
        const documentId = jobDocIds.get(jobInfo.jobKey)!;
        const hasNeeds = jobInfo.needs.length > 0;
        const resolvedNeeds = hasNeeds
          ? Object.fromEntries(
              jobInfo.needs
                .map((needKey) => [needKey, jobDocIds.get(needKey)])
                .filter((entry): entry is [string, string] => typeof entry[1] === "string"),
            )
          : null;
        const checkRunId = commitSha
          ? await createCheckRun({
              token,
              owner: event.repository.owner,
              repo: event.repository.name,
              name: jobInfos.length > 1 ? `${workflowName} / ${jobInfo.jobKey}` : workflowName,
              headSha: commitSha,
              status: "queued",
              detailsUrl: buildDashboardRunUrl(documentId),
              apiBaseUrl,
            })
          : null;
        await createBuildJob({
          id: documentId,
          status: hasNeeds ? "waiting" : "queued",
          owner: event.repository.owner,
          repo: event.repository.name,
          teamId: teamId ?? null,
          workflowId: null,
          workflowFileName: entry.name ?? null,
          workflowName,
          jobKey: jobInfo.jobKey,
          workflowRunId,
          needs: jobInfo.needs.length > 0 ? jobInfo.needs : null,
          resolvedNeeds,
          installationId: String(installationId),
          installationToken: token,
          tokenExpiresAt: expiresAt,
          checkRunId: checkRunId === null ? null : String(checkRunId),
          commitSha: commitSha ?? null,
          pullRequestNumber: event.pullRequest?.number ?? null,
          event: event.event,
          action: event.action ?? null,
          repository: event.repository.fullName,
          sender: event.sender?.login ?? null,
          runsOn: jobInfo.runsOn ?? null,
          runCount: 0,
          latestRunId: null,
          tagName: triggerInfo.tagName ?? null,
          branch: triggerInfo.branch ?? null,
          releaseName: triggerInfo.releaseName ?? null,
          retriedFromBuildJobId: null,
          retriedFromWorkflowRunId: null,
          githubApiBaseUrl: apiBaseUrl !== defaultGitHubApiBaseUrl ? apiBaseUrl : null,
          githubBaseUrl: githubBaseUrl !== defaultGitHubBaseUrl ? githubBaseUrl : null,
        });
      }
    } catch (error) {
      logger.error("Failed to process workflow file", { file: entry.name, error });
    }
  }
}

export async function routeWebhookEvent(event: WebhookEvent): Promise<void> {
  if (event.event === "pull_request") {
    if (event.action === "opened" || event.action === "synchronize") await handleBuildTrigger(event);
    return;
  }
  if (event.event === "push") {
    if ((event.ref ?? "").startsWith("refs/tags/")) return;
    await handleBuildTrigger(event);
    return;
  }
  if (event.event === "create" && event.refType === "tag") {
    await handleBuildTrigger(event);
    return;
  }
  if (event.event === "release" && event.action === "published") {
    await handleBuildTrigger(event);
  }
}
