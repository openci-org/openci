import { HttpsError, onCall } from "firebase-functions/https";
import * as logger from "firebase-functions/logger";
import { defineSecret } from "firebase-functions/params";
import { App } from "octokit";

import { db } from "../firebase";
import { teamsCollectionPath } from "../firestore-collection-paths";

const GITHUB_APP_ID = defineSecret("GITHUB_APP_ID");
const GITHUB_PRIVATE_KEY = defineSecret("GITHUB_PRIVATE_KEY");

export const listRepositories = onCall(
  {
    region: "asia-northeast1",
    secrets: [GITHUB_APP_ID, GITHUB_PRIVATE_KEY],
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Unauthenticated");
    }

    const { teamId } = request.data as { teamId: string };

    if (!teamId) {
      throw new HttpsError("invalid-argument", "Missing teamId");
    }

    const teamRef = db.collection(teamsCollectionPath).doc(teamId);
    const teamDoc = await teamRef.get();

    if (!teamDoc.exists) {
      throw new HttpsError("not-found", "Team not found");
    }

    const teamData = teamDoc.data()!;
    const members: string[] = teamData.members || [];

    if (!members.includes(request.auth.uid)) {
      throw new HttpsError("permission-denied", "You are not a member of this team");
    }

    const installationIds = (teamData.installationIds as number[]) || [];

    if (installationIds.length === 0) {
      throw new HttpsError("failed-precondition", "GitHub App is not installed for this team");
    }

    try {
      const app = new App({
        appId: GITHUB_APP_ID.value(),
        privateKey: GITHUB_PRIVATE_KEY.value(),
      });

      const allRepositories: any[] = [];

      for (const installationId of installationIds) {
        const octokit = await app.getInstallationOctokit(installationId);

        const { data } = await octokit.request("GET /installation/repositories", {
          per_page: 100,
        });

        const repos = data.repositories.map((repo: any) => ({
          fullName: repo.full_name,
          name: repo.name,
          owner: repo.owner.login,
          private: repo.private,
          defaultBranch: repo.default_branch,
        }));

        allRepositories.push(...repos);
      }

      return { repositories: allRepositories };
    } catch (error) {
      logger.error("Failed to list repositories", error);
      throw new HttpsError("internal", "Failed to list repositories");
    }
  },
);
