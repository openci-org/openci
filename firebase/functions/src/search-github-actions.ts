import { HttpsError, onCall } from "firebase-functions/https";
import * as logger from "firebase-functions/logger";
import { defineSecret } from "firebase-functions/params";
import { App } from "octokit";

import { db } from "./firebase";
import { teamsCollectionPath } from "./firestore-collection-paths";

const GITHUB_APP_ID = defineSecret("GITHUB_APP_ID");
const GITHUB_PRIVATE_KEY = defineSecret("GITHUB_PRIVATE_KEY");

export const SEARCH_REPOS_QUERY = `
  query($queryString: String!) {
    search(query: $queryString, type: REPOSITORY, first: 50) {
      nodes {
        ... on Repository {
          nameWithOwner
          description
          stargazerCount
          owner {
            login
            avatarUrl
          }
          url
          defaultBranchRef {
            name
          }
        }
      }
    }
  }
`;

export interface SearchReposQueryResult {
  search: {
    nodes: Array<{
      nameWithOwner: string;
      description: string | null;
      stargazerCount: number;
      owner: {
        login: string;
        avatarUrl: string;
      };
      url: string;
      defaultBranchRef: {
        name: string;
      } | null;
    }>;
  };
}

export const TAGS_QUERY = `
  query($owner: String!, $repo: String!) {
    repository(owner: $owner, name: $repo) {
      refs(refPrefix: "refs/tags/", first: 100, orderBy: {field: TAG_COMMIT_DATE, direction: DESC}) {
        nodes {
          name
        }
      }
    }
  }
`;

export interface TagsQueryResult {
  repository: {
    refs: {
      nodes: Array<{
        name: string;
      }>;
    };
  };
}

export function parseSearchResults(result: SearchReposQueryResult) {
  return result.search.nodes.map((repo) => ({
    fullName: repo.nameWithOwner,
    description: repo.description ?? "",
    stars: repo.stargazerCount,
    owner: repo.owner.login,
    avatarUrl: repo.owner.avatarUrl,
    htmlUrl: repo.url,
    defaultBranch: repo.defaultBranchRef?.name ?? "main",
    isOfficial: repo.owner.login === "actions",
  }));
}

export function parseTags(result: TagsQueryResult): string[] {
  const majorTags: string[] = [];
  const allTags: string[] = [];

  for (const ref of result.repository.refs.nodes) {
    allTags.push(ref.name);
    if (/^v\d+$/.test(ref.name)) {
      majorTags.push(ref.name);
    }
  }

  return majorTags.length > 0 ? majorTags : allTags;
}

export const searchGitHubActions = onCall(
  {
    region: "asia-northeast1",
    secrets: [GITHUB_APP_ID, GITHUB_PRIVATE_KEY],
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Unauthenticated");
    }

    const { teamId, query, type, fullName } = request.data as {
      teamId: string;
      query?: string;
      type: "search" | "tags";
      fullName?: string;
    };

    if (!teamId) {
      throw new HttpsError("invalid-argument", "Missing teamId");
    }

    const teamDoc = await db.collection(teamsCollectionPath).doc(teamId).get();
    if (!teamDoc.exists) {
      throw new HttpsError("not-found", "Team not found");
    }

    const teamData = teamDoc.data()!;
    const members: string[] = teamData.members || [];
    if (!members.includes(request.auth.uid)) {
      throw new HttpsError("permission-denied", "Not a team member");
    }

    const installationIds = (teamData.installationIds as number[]) || [];
    if (installationIds.length === 0) {
      throw new HttpsError("failed-precondition", "GitHub App not installed");
    }

    try {
      const app = new App({
        appId: GITHUB_APP_ID.value(),
        privateKey: GITHUB_PRIVATE_KEY.value(),
      });

      const octokit = await app.getInstallationOctokit(installationIds[0]);

      if (type === "search") {
        const queryString = `${query?.trim() || "github action"} sort:stars-desc`;
        const result = await octokit.graphql<SearchReposQueryResult>(SEARCH_REPOS_QUERY, {
          queryString,
        });

        return { actions: parseSearchResults(result) };
      }

      if (type === "tags") {
        if (!fullName) {
          throw new HttpsError("invalid-argument", "Missing fullName for tags");
        }

        const [owner, repo] = fullName.split("/");
        const result = await octokit.graphql<TagsQueryResult>(TAGS_QUERY, { owner, repo });

        return { tags: parseTags(result) };
      }

      throw new HttpsError("invalid-argument", "Invalid type");
    } catch (error) {
      if (error instanceof HttpsError) throw error;
      logger.error("Failed to search GitHub actions", error);
      throw new HttpsError("internal", "Failed to search GitHub actions");
    }
  },
);
