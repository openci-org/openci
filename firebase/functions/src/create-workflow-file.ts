import { HttpsError, onCall } from "firebase-functions/https";
import * as logger from "firebase-functions/logger";
import { defineSecret } from "firebase-functions/params";
import { App } from "octokit";

import { db } from "./firebase";
import { teamsCollectionPath } from "./firestore-collection-paths";

const GITHUB_APP_ID = defineSecret("GITHUB_APP_ID");
const GITHUB_PRIVATE_KEY = defineSecret("GITHUB_PRIVATE_KEY");

type CommitMode = "direct" | "pull_request";

interface CreateWorkflowFileRequest {
  teamId: string;
  repository: string;
  branch: string;
  fileName: string;
  content: string;
  commitMode: CommitMode;
  commitMessage?: string;
}

export const createWorkflowFile = onCall(
  {
    region: "asia-northeast1",
    secrets: [GITHUB_APP_ID, GITHUB_PRIVATE_KEY],
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Unauthenticated");
    }

    const { teamId, repository, branch, fileName, content, commitMode, commitMessage } =
      request.data as CreateWorkflowFileRequest;

    if (!teamId || !repository || !branch || !fileName || !content || !commitMode) {
      throw new HttpsError("invalid-argument", "Missing required fields");
    }

    if (!fileName.endsWith(".yaml") && !fileName.endsWith(".yml")) {
      throw new HttpsError("invalid-argument", "File name must end with .yaml or .yml");
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
    const filePath = `.openci/${fileName}`;
    const message = commitMessage || `Add workflow: ${fileName}`;

    try {
      const app = new App({
        appId: GITHUB_APP_ID.value(),
        privateKey: GITHUB_PRIVATE_KEY.value(),
      });

      for (const installationId of installationIds) {
        try {
          const octokit = await app.getInstallationOctokit(installationId);

          if (commitMode === "direct") {
            const { data: refData } = await octokit.request(
              "GET /repos/{owner}/{repo}/git/ref/{ref}",
              {
                owner,
                repo,
                ref: `heads/${branch}`,
              },
            );

            const latestCommitSha = refData.object.sha;

            const { data: blob } = await octokit.request("POST /repos/{owner}/{repo}/git/blobs", {
              owner,
              repo,
              content: Buffer.from(content).toString("base64"),
              encoding: "base64",
            });

            const { data: latestCommit } = await octokit.request(
              "GET /repos/{owner}/{repo}/git/commits/{commit_sha}",
              { owner, repo, commit_sha: latestCommitSha },
            );

            const { data: tree } = await octokit.request("POST /repos/{owner}/{repo}/git/trees", {
              owner,
              repo,
              base_tree: latestCommit.tree.sha,
              tree: [
                {
                  path: filePath,
                  mode: "100644",
                  type: "blob",
                  sha: blob.sha,
                },
              ],
            });

            const { data: newCommit } = await octokit.request(
              "POST /repos/{owner}/{repo}/git/commits",
              {
                owner,
                repo,
                message,
                tree: tree.sha,
                parents: [latestCommitSha],
              },
            );

            await octokit.request("PATCH /repos/{owner}/{repo}/git/refs/{ref}", {
              owner,
              repo,
              ref: `heads/${branch}`,
              sha: newCommit.sha,
            });

            return {
              mode: "direct",
              commitSha: newCommit.sha,
              branch,
            };
          } else {
            const newBranchName = `openci/add-${fileName.replace(/\.(yaml|yml)$/, "")}-${Date.now()}`;

            const { data: refData } = await octokit.request(
              "GET /repos/{owner}/{repo}/git/ref/{ref}",
              {
                owner,
                repo,
                ref: `heads/${branch}`,
              },
            );

            await octokit.request("POST /repos/{owner}/{repo}/git/refs", {
              owner,
              repo,
              ref: `refs/heads/${newBranchName}`,
              sha: refData.object.sha,
            });

            await octokit.request("PUT /repos/{owner}/{repo}/contents/{path}", {
              owner,
              repo,
              path: filePath,
              message,
              content: Buffer.from(content).toString("base64"),
              branch: newBranchName,
            });

            const { data: pr } = await octokit.request("POST /repos/{owner}/{repo}/pulls", {
              owner,
              repo,
              title: message,
              head: newBranchName,
              base: branch,
              body: `This workflow file was created by OpenCI.\n\nFile: \`${filePath}\``,
            });

            return {
              mode: "pull_request",
              pullRequestUrl: pr.html_url,
              pullRequestNumber: pr.number,
              branch: newBranchName,
            };
          }
        } catch (e) {
          if (e instanceof HttpsError) throw e;
          continue;
        }
      }

      throw new HttpsError("not-found", "Repository not found in any installation");
    } catch (error) {
      if (error instanceof HttpsError) throw error;
      logger.error("Failed to create workflow file", error);
      throw new HttpsError("internal", "Failed to create workflow file");
    }
  },
);
