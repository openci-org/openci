import { HttpsError, onCall } from "firebase-functions/https";
import * as logger from "firebase-functions/logger";
import { defineSecret } from "firebase-functions/params";
import { App } from "octokit";

import { db } from "./firebase";
import { teamsCollectionPath } from "./firestore-collection-paths";

const GITHUB_APP_ID = defineSecret("GITHUB_APP_ID");
const GITHUB_PRIVATE_KEY = defineSecret("GITHUB_PRIVATE_KEY");

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
        const searchQuery = query?.trim() || "github action";
        const { data } = await octokit.request("GET /search/repositories", {
          q: searchQuery,
          sort: "stars",
          order: "desc",
          per_page: 50,
        });

        const actions = data.items.map((repo: any) => ({
          fullName: repo.full_name,
          description: repo.description ?? "",
          stars: repo.stargazers_count,
          owner: repo.owner.login,
          avatarUrl: repo.owner.avatar_url,
          htmlUrl: repo.html_url,
          defaultBranch: repo.default_branch ?? "main",
          isOfficial: repo.owner.login === "actions",
        }));

        return { actions };
      }

      if (type === "tags") {
        if (!fullName) {
          throw new HttpsError("invalid-argument", "Missing fullName for tags");
        }

        const [owner, repo] = fullName.split("/");
        const { data: tags } = await octokit.request("GET /repos/{owner}/{repo}/tags", {
          owner,
          repo,
          per_page: 100,
        });

        const majorTags: string[] = [];
        const allTags: string[] = [];

        for (const tag of tags) {
          allTags.push(tag.name);
          if (/^v\d+$/.test(tag.name)) {
            majorTags.push(tag.name);
          }
        }

        return { tags: majorTags.length > 0 ? majorTags : allTags };
      }

      throw new HttpsError("invalid-argument", "Invalid type");
    } catch (error) {
      if (error instanceof HttpsError) throw error;
      logger.error("Failed to search GitHub actions", error);
      throw new HttpsError("internal", "Failed to search GitHub actions");
    }
  },
);
