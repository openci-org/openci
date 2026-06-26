import { logger } from "firebase-functions/v2";

import { findTeamByInstallation, tryMarkCiNotificationSent } from "../firestoreData.js";
import { getInstallationToken, githubGraphql } from "./githubApp.js";
import { getApiBaseUrlFromTeamData } from "./githubUrls.js";

interface PullRequestCiNotificationInput {
  installationId: number;
  owner: string;
  repo: string;
  headSha: string;
  pullRequestNumber?: number;
}

interface StatusCheckRollupContext {
  __typename?: string;
  name?: string | null;
  status?: string | null;
  conclusion?: string | null;
}

interface CommitCiState {
  contexts: StatusCheckRollupContext[];
  hasNextPage: boolean;
  pullRequests: Array<{
    number?: number | null;
    state?: string | null;
    headRefOid?: string | null;
    headRefName?: string | null;
  }>;
}

interface StatusCheckRollupResponse {
  repository?: {
    object?: {
      associatedPullRequests?: {
        nodes?: CommitCiState["pullRequests"];
      } | null;
      statusCheckRollup?: {
        contexts?: {
          nodes?: StatusCheckRollupContext[];
          pageInfo?: {
            hasNextPage?: boolean;
          };
        } | null;
      } | null;
    } | null;
  } | null;
}

const statusCheckRollupQuery = `
  query PullRequestCiNotificationStatus($owner: String!, $repo: String!, $headSha: GitObjectID!) {
    repository(owner: $owner, name: $repo) {
      object(oid: $headSha) {
        ... on Commit {
          associatedPullRequests(first: 10) {
            nodes {
              number
              state
              headRefOid
              headRefName
            }
          }
          statusCheckRollup {
            contexts(first: 100) {
              nodes {
                __typename
                ... on CheckRun {
                  name
                  status
                  conclusion
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

function safeNotificationIdPart(value: string): string {
  return value.replace(/[^A-Za-z0-9_-]/gu, "_");
}

function isSuccessfulContext(context: StatusCheckRollupContext): boolean {
  return (
    context.__typename === "CheckRun" &&
    context.status === "COMPLETED" &&
    context.conclusion === "SUCCESS"
  );
}

function serializeNotificationError(error: unknown): unknown {
  if (error instanceof Error) {
    const record = error as unknown as Record<string, unknown>;
    return {
      name: error.name,
      message: error.message,
      ...(record.status !== undefined ? { status: record.status } : {}),
      ...(record.errors !== undefined ? { errors: record.errors } : {}),
    };
  }
  return error;
}

function resolvePullRequest(
  state: CommitCiState,
  headSha: string,
  pullRequestNumber?: number,
): CommitCiState["pullRequests"][number] | undefined {
  if (pullRequestNumber !== undefined) {
    return state.pullRequests.find(
      (pullRequest) =>
        pullRequest.number === pullRequestNumber && pullRequest.headRefOid === headSha,
    );
  }
  return state.pullRequests.find(
    (pullRequest) => pullRequest.state === "OPEN" && pullRequest.headRefOid === headSha,
  );
}

async function fetchCommitCiState({
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
}): Promise<CommitCiState | undefined> {
  let response: StatusCheckRollupResponse;
  try {
    response = await githubGraphql<StatusCheckRollupResponse>(statusCheckRollupQuery, token, {
      variables: { owner, repo, headSha },
      apiBaseUrl,
    });
  } catch (error) {
    logger.warn("Skipping CI passed notification because commit CI state could not be fetched", {
      owner,
      repo,
      headSha,
      error: serializeNotificationError(error),
    });
    return undefined;
  }

  const commit = response.repository?.object;
  if (!commit) return undefined;

  return {
    contexts: commit.statusCheckRollup?.contexts?.nodes ?? [],
    hasNextPage: commit.statusCheckRollup?.contexts?.pageInfo?.hasNextPage === true,
    pullRequests: commit.associatedPullRequests?.nodes ?? [],
  };
}

export async function notifyPullRequestCiPassedIfReady({
  installationId,
  owner,
  repo,
  headSha,
  pullRequestNumber,
}: PullRequestCiNotificationInput): Promise<void> {
  const teams = await findTeamByInstallation({ installationId });
  const team = teams.data.teams[0];
  if (!team?.id) return;

  const apiBaseUrl = getApiBaseUrlFromTeamData(team);
  const { token } = await getInstallationToken(installationId, { apiBaseUrl });
  const state = await fetchCommitCiState({ owner, repo, headSha, token, apiBaseUrl });
  if (!state) return;
  if (state.hasNextPage) {
    logger.warn("Skipping CI passed notification because statusCheckRollup is paginated", {
      owner,
      repo,
      headSha,
    });
    return;
  }

  const pullRequest = resolvePullRequest(state, headSha, pullRequestNumber);
  const resolvedPullRequestNumber = pullRequest?.number;
  if (resolvedPullRequestNumber === undefined || resolvedPullRequestNumber === null) return;
  if (state.contexts.length === 0) return;
  if (!state.contexts.every(isSuccessfulContext)) return;

  const notificationId = [
    "pull_request_ci_passed",
    safeNotificationIdPart(owner),
    safeNotificationIdPart(repo),
    String(resolvedPullRequestNumber),
    safeNotificationIdPart(headSha),
  ].join("_");
  const marker = await tryMarkCiNotificationSent({
    id: notificationId,
    owner,
    repo,
    pullRequestNumber: resolvedPullRequestNumber,
    headSha,
    kind: "pull_request_ci_passed",
  });
  if (!marker.data.inserted) return;
}
