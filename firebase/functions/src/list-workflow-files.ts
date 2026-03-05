import { HttpsError, onCall } from "firebase-functions/https";
import * as logger from "firebase-functions/logger";
import { defineSecret } from "firebase-functions/params";
import { App } from "octokit";

import { db } from "./firebase";
import { teamsCollectionPath } from "./firestore-collection-paths";

const GITHUB_APP_ID = defineSecret("GITHUB_APP_ID");
const GITHUB_PRIVATE_KEY = defineSecret("GITHUB_PRIVATE_KEY");

interface WorkflowFile {
  name: string;
  path: string;
  content: string;
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

    try {
      const app = new App({
        appId: GITHUB_APP_ID.value(),
        privateKey: GITHUB_PRIVATE_KEY.value(),
      });

      for (const installationId of installationIds) {
        try {
          const octokit = await app.getInstallationOctokit(installationId);

          const ref =
            branch ??
            (await octokit.request("GET /repos/{owner}/{repo}", { owner, repo })).data
              .default_branch;

          let contents: any[];
          try {
            const { data } = await octokit.request("GET /repos/{owner}/{repo}/contents/{path}", {
              owner,
              repo,
              path: ".openci",
              ref,
            });

            if (!Array.isArray(data)) {
              return { files: [] };
            }
            contents = data;
          } catch (e: any) {
            if (e.status === 404) {
              return { files: [] };
            }
            throw e;
          }

          const yamlFiles = contents.filter(
            (item: any) =>
              item.type === "file" && (item.name.endsWith(".yaml") || item.name.endsWith(".yml")),
          );

          const files: WorkflowFile[] = await Promise.all(
            yamlFiles.map(async (file: any) => {
              const { data: fileData } = await octokit.request(
                "GET /repos/{owner}/{repo}/contents/{path}",
                {
                  owner,
                  repo,
                  path: file.path,
                  ref,
                },
              );

              const content = Buffer.from((fileData as any).content, "base64").toString("utf-8");

              return {
                name: file.name,
                path: file.path,
                content,
              };
            }),
          );

          return { files };
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
