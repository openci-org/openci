import { logger } from "firebase-functions/v2";
import { HttpsError, onCall } from "firebase-functions/v2/https";

import { verifyTeamMembership } from "../team/teamAuth.js";
import { getInstallationToken } from "./githubApp.js";
import { githubGet } from "./githubRequests.js";
import { getApiBaseUrlFromTeamData } from "./githubUrls.js";

interface SearchGitHubActionsRequest {
  teamId: string;
  type?: string;
  query?: string;
  fullName?: string;
}

export interface GitHubActionSearchResult {
  fullName: string;
  description: string;
  stars: number;
  owner: string;
  avatarUrl: string;
  htmlUrl: string;
  defaultBranch: string;
  isOfficial: boolean;
}

export interface SearchGitHubActionsResponse {
  actions?: GitHubActionSearchResult[];
  tags?: string[];
}

interface SearchRepositoriesResponse {
  items?: Array<{
    full_name?: unknown;
    description?: unknown;
    stargazers_count?: unknown;
    owner?: {
      login?: unknown;
      avatar_url?: unknown;
    };
    html_url?: unknown;
    default_branch?: unknown;
  }>;
}

interface TagResponse {
  name?: unknown;
}

function requireNonEmptyString(value: unknown, field: string): string {
  if (typeof value !== "string" || value.length === 0) {
    throw new HttpsError("invalid-argument", `${field} is required`);
  }
  return value;
}

function getInstallationIds(teamData: FirebaseFirestore.DocumentData): number[] {
  const installationIds = Array.isArray(teamData.installationIds) ? teamData.installationIds : [];
  const ids = installationIds.filter((id): id is number => typeof id === "number");
  if (ids.length === 0) {
    throw new HttpsError("failed-precondition", "GitHub App is not installed for this team");
  }
  return ids;
}

export const searchGitHubActions = onCall<
  SearchGitHubActionsRequest,
  Promise<SearchGitHubActionsResponse>
>(async (request) => {
  const teamId = requireNonEmptyString(request.data?.teamId, "teamId");
  const type = request.data?.type ?? "search";
  const teamData = await verifyTeamMembership(request.auth, teamId);
  const installationIds = getInstallationIds(teamData);
  const apiBaseUrl = getApiBaseUrlFromTeamData(teamData);

  try {
    const { token } = await getInstallationToken(installationIds[0]!, { apiBaseUrl });

    if (type === "search") {
      const query =
        typeof request.data?.query === "string" && request.data.query.trim().length > 0
          ? request.data.query.trim()
          : "github action";
      const data = await githubGet<SearchRepositoriesResponse>("/search/repositories", token, {
        queryParameters: {
          q: query,
          sort: "stars",
          order: "desc",
          per_page: 50,
        },
        apiBaseUrl,
      });

      const actions = (data.items ?? []).map((repo) => {
        const owner = repo.owner ?? {};
        const ownerLogin = typeof owner.login === "string" ? owner.login : "";
        return {
          fullName: typeof repo.full_name === "string" ? repo.full_name : "",
          description: typeof repo.description === "string" ? repo.description : "",
          stars: typeof repo.stargazers_count === "number" ? repo.stargazers_count : 0,
          owner: ownerLogin,
          avatarUrl: typeof owner.avatar_url === "string" ? owner.avatar_url : "",
          htmlUrl: typeof repo.html_url === "string" ? repo.html_url : "",
          defaultBranch: typeof repo.default_branch === "string" ? repo.default_branch : "main",
          isOfficial: ownerLogin === "actions",
        };
      });

      return { actions };
    }

    if (type === "tags") {
      const fullName = requireNonEmptyString(request.data?.fullName, "fullName");
      const [owner, repo] = fullName.split("/");
      if (!owner || !repo) {
        throw new HttpsError("invalid-argument", "fullName must be in owner/repo format");
      }

      const tagsResponse = await githubGet<TagResponse[]>(`/repos/${owner}/${repo}/tags`, token, {
        queryParameters: { per_page: 100 },
        apiBaseUrl,
      });
      const allTags = tagsResponse
        .map((tag) => tag.name)
        .filter((name): name is string => typeof name === "string");
      const majorTags = allTags.filter((name) => /^v\d+$/.test(name));

      return { tags: majorTags.length > 0 ? majorTags : allTags };
    }

    throw new HttpsError("invalid-argument", "Invalid type");
  } catch (error) {
    if (error instanceof HttpsError) {
      throw error;
    }
    logger.error("Failed to search GitHub actions", { teamId, type, error });
    throw new HttpsError("internal", "Failed to search GitHub actions");
  }
});
