import { HttpsError, onCall } from "firebase-functions/https";
import * as logger from "firebase-functions/logger";
import { defineSecret } from "firebase-functions/params";
import { App } from "octokit";

import { db } from "./firebase";
import { teamsCollectionPath } from "./firestore-collection-paths";

const GITHUB_APP_ID = defineSecret("GITHUB_APP_ID");
const GITHUB_PRIVATE_KEY = defineSecret("GITHUB_PRIVATE_KEY");

export const DEFAULT_BRANCH_QUERY = `
  query($owner: String!, $repo: String!) {
    repository(owner: $owner, name: $repo) {
      defaultBranchRef {
        name
      }
    }
  }
`;

export interface DefaultBranchQueryResult {
  repository: {
    defaultBranchRef: {
      name: string;
    } | null;
  };
}

export const listDirectories = onCall(
  {
    region: "asia-northeast1",
    secrets: [GITHUB_APP_ID, GITHUB_PRIVATE_KEY],
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Unauthenticated");
    }

    const { teamId, repository } = request.data as {
      teamId: string;
      repository: string;
    };

    if (!teamId || !repository) {
      throw new HttpsError("invalid-argument", "Missing teamId or repository");
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

    const [owner, repo] = repository.split("/");

    try {
      const app = new App({
        appId: GITHUB_APP_ID.value(),
        privateKey: GITHUB_PRIVATE_KEY.value(),
      });

      for (const installationId of installationIds) {
        try {
          const octokit = await app.getInstallationOctokit(installationId);

          const branchResult = await octokit.graphql<DefaultBranchQueryResult>(
            DEFAULT_BRANCH_QUERY,
            { owner, repo },
          );

          const defaultBranch = branchResult.repository.defaultBranchRef?.name;
          if (!defaultBranch) {
            throw new HttpsError("not-found", "Default branch not found");
          }

          const { data: treeData } = await octokit.request(
            "GET /repos/{owner}/{repo}/git/trees/{tree_sha}",
            {
              owner,
              repo,
              tree_sha: defaultBranch,
              recursive: "true",
            },
          );

          const directories = [
            ".",
            ...treeData.tree
              .filter((item: any) => item.type === "tree")
              .map((item: any) => item.path)
              .sort(),
          ];

          return { directories };
        } catch {
          continue;
        }
      }

      throw new HttpsError("not-found", "Repository not found in any installation");
    } catch (error) {
      if (error instanceof HttpsError) throw error;
      logger.error("Failed to list directories", error);
      throw new HttpsError("internal", "Failed to list directories");
    }
  },
);
