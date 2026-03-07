import { HttpsError, onCall } from "firebase-functions/https";
import * as logger from "firebase-functions/logger";
import { defineSecret } from "firebase-functions/params";
import { App } from "octokit";

import { db } from "./firebase";
import { teamsCollectionPath } from "./firestore-collection-paths";

const GITHUB_APP_ID = defineSecret("GITHUB_APP_ID");
const GITHUB_PRIVATE_KEY = defineSecret("GITHUB_PRIVATE_KEY");

export const WORKFLOW_FILES_QUERY = `
  query($owner: String!, $repo: String!, $expression: String!) {
    repository(owner: $owner, name: $repo) {
      object(expression: $expression) {
        ... on Tree {
          entries {
            name
            type
            object {
              ... on Blob {
                text
              }
            }
          }
        }
      }
    }
  }
`;

export interface WorkflowFilesQueryResult {
  repository: {
    object: {
      entries: Array<{
        name: string;
        type: string;
        object: {
          text: string;
        } | null;
      }>;
    } | null;
  };
}

interface WorkflowFile {
  name: string;
  path: string;
  content: string;
}

export function parseWorkflowFiles(result: WorkflowFilesQueryResult): WorkflowFile[] {
  if (!result.repository.object) {
    return [];
  }

  return result.repository.object.entries
    .filter(
      (entry) =>
        entry.type === "blob" &&
        (entry.name.endsWith(".yaml") || entry.name.endsWith(".yml")) &&
        entry.object?.text != null,
    )
    .map((entry) => ({
      name: entry.name,
      path: `.openci/${entry.name}`,
      content: entry.object!.text,
    }));
}

export const listWorkflowFiles = onCall(
  {
    region: "asia-northeast1",
    secrets: [GITHUB_APP_ID, GITHUB_PRIVATE_KEY],
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Unauthenticated");
    }

    const { teamId, repository, branch } = request.data as {
      teamId: string;
      repository: string;
      branch?: string;
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
    const expression = `${branch ?? "HEAD"}:.openci`;

    try {
      const app = new App({
        appId: GITHUB_APP_ID.value(),
        privateKey: GITHUB_PRIVATE_KEY.value(),
      });

      for (const installationId of installationIds) {
        try {
          const octokit = await app.getInstallationOctokit(installationId);

          const result = await octokit.graphql<WorkflowFilesQueryResult>(WORKFLOW_FILES_QUERY, {
            owner,
            repo,
            expression,
          });

          return { files: parseWorkflowFiles(result) };
        } catch (e) {
          if (e instanceof HttpsError) throw e;
          continue;
        }
      }

      throw new HttpsError("not-found", "Repository not found in any installation");
    } catch (error) {
      if (error instanceof HttpsError) throw error;
      logger.error("Failed to list workflow files", error);
      throw new HttpsError("internal", "Failed to list workflow files");
    }
  },
);
