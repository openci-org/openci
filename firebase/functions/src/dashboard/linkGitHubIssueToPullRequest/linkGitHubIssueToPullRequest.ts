import type { Firestore } from "firebase-admin/firestore";
import { logger } from "firebase-functions/v2";

import { firestoreCollectionPaths, getTeamById } from "../../firestoreData.js";
import { getInstallationToken, githubPatch } from "../../github/githubApp.js";
import { upsertLinkedIssueBlock } from "../../issues/issueLinkingHelpers.js";
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

    const githubIssue = issueDoc.get("githubIssue") as Record<string, unknown> | undefined;
    const githubIssueNumber = asNumber(githubIssue?.number);
    if (githubIssueNumber <= 0) {
      continue;
    }

    const nextBody = upsertLinkedIssueBlock(currentBody, githubIssueNumber, issueKey);
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
        githubIssueNumber,
        message,
      });
    }
  }
}
