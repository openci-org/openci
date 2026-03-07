import { HttpsError, onCall } from "firebase-functions/https";
import * as logger from "firebase-functions/logger";
import { defineSecret } from "firebase-functions/params";
import { App } from "octokit";

import { db } from "./firebase";
import { teamsCollectionPath } from "./firestore-collection-paths";

const GITHUB_APP_ID = defineSecret("GITHUB_APP_ID");
const GITHUB_PRIVATE_KEY = defineSecret("GITHUB_PRIVATE_KEY");

const BRANCHES_QUERY = `
  query($owner: String!, $repo: String!, $cursor: String) {
    repository(owner: $owner, name: $repo) {
      defaultBranchRef { name }
      refs(refPrefix: "refs/heads/", first: 100, after: $cursor, orderBy: {field: TAG_COMMIT_DATE, direction: DESC}) {
        nodes {
          name
          target {
            ... on Commit { committedDate }
          }
        }
        pageInfo { hasNextPage endCursor }
      }
    }
  }
`;

interface BranchNode {
  name: string;
  target: { committedDate: string };
}

interface BranchesQueryResult {
  repository: {
    defaultBranchRef: { name: string } | null;
    refs: {
      nodes: BranchNode[];
      pageInfo: { hasNextPage: boolean; endCursor: string | null };
    };
  };
}

export const listBranches = onCall(
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

          const allBranches: BranchNode[] = [];
          let cursor: string | null = null;
          let defaultBranchName: string | null = null;

          while (true) {
            const result: BranchesQueryResult = await octokit.graphql<BranchesQueryResult>(
              BRANCHES_QUERY,
              {
                owner,
                repo,
                cursor,
              },
            );

            if (!defaultBranchName) {
              defaultBranchName = result.repository.defaultBranchRef?.name ?? null;
            }

            allBranches.push(...result.repository.refs.nodes);

            if (!result.repository.refs.pageInfo.hasNextPage) break;
            cursor = result.repository.refs.pageInfo.endCursor;
          }

          const branches = allBranches
            .sort((a, b) => {
              if (a.name === defaultBranchName) return -1;
              if (b.name === defaultBranchName) return 1;
              return (
                new Date(b.target.committedDate).getTime() -
                new Date(a.target.committedDate).getTime()
              );
            })
            .map((b) => b.name);

          return { branches };
        } catch {
          continue;
        }
      }

      throw new HttpsError("not-found", "Repository not found in any installation");
    } catch (error) {
      if (error instanceof HttpsError) throw error;
      logger.error("Failed to list branches", error);
      throw new HttpsError("internal", "Failed to list branches");
    }
  },
);
