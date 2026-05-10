import type { Firestore, QueryDocumentSnapshot } from "firebase-admin/firestore";
import { logger } from "firebase-functions/v2";

import { firestoreCollectionPaths, getTeamById } from "../../firestoreData.js";
import { getInstallationToken, githubPatch } from "../../github/githubApp.js";
import { upsertLinkedIssueBlocks } from "../../issues/issueLinkingHelpers.js";
import { asString } from "../dashboardPayloadHelpers.js";
import {
  findIssueKeyFromPullRequestBranch,
  findRepoFullNameFromPullRequestPayload,
  isOpenedPullRequestPayload,
  type DashboardPullRequestPayload,
} from "../dashboardPullRequestPayloadHelpers.js";

interface GitHubPullRequestIssueLinkPayload extends DashboardPullRequestPayload {
  installation?: {
    id?: unknown;
  };
  pull_request?: DashboardPullRequestPayload["pull_request"] & {
    number?: unknown;
    body?: unknown;
  };
}

interface GitHubIssueLink {
  number: number;
  issueKey: string;
}

function asNumber(value: unknown): number {
  return typeof value === "number" && Number.isFinite(value) ? value : 0;
}

function splitRepoFullName(repoFullName: string): { owner: string; repo: string } | null {
  const [owner, repo] = repoFullName.split("/");
  return owner !== undefined && repo !== undefined ? { owner, repo } : null;
}

async function githubApiBaseUrlForWorkspace(workspaceId: string): Promise<string> {
  const team = await getTeamById({ teamId: workspaceId });
  return asString(team.data.team?.githubApiBaseUrl, "https://api.github.com");
}

function githubIssueLinkFromIssueDoc(
  issueDoc: QueryDocumentSnapshot,
  repoFullName: string,
  fallbackIssueKey: string,
): GitHubIssueLink | null {
  if (asString(issueDoc.get("repo")) !== repoFullName) {
    return null;
  }

  const githubIssue = issueDoc.get("githubIssue") as Record<string, unknown> | undefined;
  const number = asNumber(githubIssue?.number);
  if (number <= 0) {
    return null;
  }

  const issueKey = asString(issueDoc.get("issueKey"), fallbackIssueKey).toUpperCase();
  if (issueKey.length === 0) {
    return null;
  }

  return { number, issueKey };
}

async function findGitHubIssueLinksForIssueAndSubIssues({
  issueDoc,
  repoFullName,
  fallbackIssueKey,
}: {
  issueDoc: QueryDocumentSnapshot;
  repoFullName: string;
  fallbackIssueKey: string;
}): Promise<GitHubIssueLink[]> {
  const links: GitHubIssueLink[] = [];
  const parentLink = githubIssueLinkFromIssueDoc(issueDoc, repoFullName, fallbackIssueKey);
  if (parentLink !== null) {
    links.push(parentLink);
  }

  const seenIssueIds = new Set([issueDoc.id]);
  const pendingParentIssueIds = [issueDoc.id];
  while (pendingParentIssueIds.length > 0) {
    const parentIssueId = pendingParentIssueIds.shift();
    if (parentIssueId === undefined) {
      continue;
    }

    const childIssues = await issueDoc.ref.parent
      .where("githubIssue.parentIssue.issueId", "==", parentIssueId)
      .get();
    for (const childIssueDoc of childIssues.docs) {
      if (seenIssueIds.has(childIssueDoc.id)) {
        continue;
      }

      seenIssueIds.add(childIssueDoc.id);
      pendingParentIssueIds.push(childIssueDoc.id);

      const childLink = githubIssueLinkFromIssueDoc(childIssueDoc, repoFullName, fallbackIssueKey);
      if (childLink !== null) {
        links.push(childLink);
      }
    }
  }

  return links;
}

export async function linkGitHubIssueToPullRequest(
  db: Firestore,
  payload: GitHubPullRequestIssueLinkPayload,
): Promise<void> {
  if (!isOpenedPullRequestPayload(payload)) {
    return;
  }

  const repoFullName = findRepoFullNameFromPullRequestPayload(payload);
  if (repoFullName === null) {
    return;
  }

  const issueKey = findIssueKeyFromPullRequestBranch(payload);
  if (issueKey === null) {
    return;
  }

  const repoParts = splitRepoFullName(repoFullName);
  const pullRequestNumber = asNumber(payload.pull_request?.number);
  const installationId = asNumber(payload.installation?.id);
  if (repoParts === null || pullRequestNumber <= 0 || installationId <= 0) {
    return;
  }

  const workspacesQuerySnapshot = await db
    .collection(firestoreCollectionPaths.workspaces)
    .where("syncedGitHubRepoFullNames", "array-contains", repoFullName)
    .get();

  let currentBody = asString(payload.pull_request?.body);
  for (const workspaceQueryDocumentSnapshot of workspacesQuerySnapshot.docs) {
    const issueDocs = await workspaceQueryDocumentSnapshot.ref
      .collection("issues")
      .where("issueKey", "==", issueKey)
      .where("repo", "==", repoFullName)
      .limit(1)
      .get();

    const issueDoc = issueDocs.docs[0];
    if (issueDoc === undefined) {
      continue;
    }

    const githubIssueLinks = await findGitHubIssueLinksForIssueAndSubIssues({
      issueDoc,
      repoFullName,
      fallbackIssueKey: issueKey,
    });
    if (githubIssueLinks.length === 0) {
      continue;
    }

    const nextBody = upsertLinkedIssueBlocks(
      currentBody,
      githubIssueLinks.map((link) => ({
        githubIssueNumber: link.number,
        imaIssueKey: link.issueKey,
      })),
    );
    if (nextBody === currentBody) {
      continue;
    }

    try {
      const apiBaseUrl = await githubApiBaseUrlForWorkspace(workspaceQueryDocumentSnapshot.id);
      const { token } = await getInstallationToken(installationId, { apiBaseUrl });
      await githubPatch(
        `/repos/${repoParts.owner}/${repoParts.repo}/pulls/${pullRequestNumber}`,
        token,
        { body: nextBody },
        { apiBaseUrl },
      );
      currentBody = nextBody;
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      logger.warn("linkGitHubIssueToPullRequest: failed to update PR body", {
        workspaceId: workspaceQueryDocumentSnapshot.id,
        repoFullName,
        issueKey,
        githubIssueNumbers: githubIssueLinks.map((link) => link.number),
        message,
      });
    }
  }
}
