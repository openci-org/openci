import { FieldValue } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/https";
import * as logger from "firebase-functions/logger";
import { defineSecret } from "firebase-functions/params";
import { App } from "octokit";

import { db } from "../firebase";
import {
  teamsCollectionPath,
  workflowFilesCollectionPath,
} from "../firestore-collection-paths";
import { OPENCI_DIR_QUERY, OpenciDirEntry } from "./queries";

const GITHUB_APP_ID = defineSecret("GITHUB_APP_ID");
const GITHUB_PRIVATE_KEY = defineSecret("GITHUB_PRIVATE_KEY");

/**
 * Generate a stable document ID for a workflow file.
 */
export function workflowFileDocId(
  teamId: string,
  repository: string,
  branch: string,
  fileName: string,
): string {
  return `${teamId}_${repository.replace("/", "_")}_${branch}_${fileName}`;
}

/**
 * Sync .openci/ workflow files from GitHub to Firestore.
 * Shared logic used by both webhook handler and manual sync callable.
 */
export async function syncWorkflowFilesToFirestore(params: {
  teamId: string;
  repository: string;
  branch: string;
  octokit: any;
}): Promise<{ synced: number; deleted: number }> {
  const { teamId, repository, branch, octokit } = params;
  const [owner, repo] = repository.split("/");

  const expression = `${branch}:.openci`;

  let entries: OpenciDirEntry[] = [];
  try {
    const result = await octokit.graphql(OPENCI_DIR_QUERY, {
      owner,
      repo,
      expression,
    });
    entries = (result as any).repository.object?.entries ?? [];
  } catch (e: any) {
    if (e.message?.includes("Could not resolve to an object")) {
      // .openci/ directory does not exist — delete all cached files for this repo/branch
      await deleteAllWorkflowFiles(teamId, repository, branch);
      return { synced: 0, deleted: 0 };
    }
    throw e;
  }

  const yamlEntries = entries.filter(
    (entry) =>
      entry.type === "blob" &&
      (entry.name.endsWith(".yaml") || entry.name.endsWith(".yml")) &&
      entry.object?.text,
  );

  const batch = db.batch();
  const currentFileNames = new Set<string>();
  let syncedCount = 0;

  for (const entry of yamlEntries) {
    const docId = workflowFileDocId(teamId, repository, branch, entry.name);
    const docRef = db.collection(workflowFilesCollectionPath).doc(docId);

    currentFileNames.add(entry.name);

    batch.set(
      docRef,
      {
        teamId,
        repository,
        branch,
        fileName: entry.name,
        filePath: `.openci/${entry.name}`,
        content: entry.object!.text,
        updatedAt: FieldValue.serverTimestamp(),
        syncedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    syncedCount++;
  }

  await batch.commit();

  // Delete workflow files that no longer exist in the repository
  const deletedCount = await deleteRemovedWorkflowFiles(
    teamId,
    repository,
    branch,
    currentFileNames,
  );

  logger.info(
    `Synced ${syncedCount} workflow files, deleted ${deletedCount} for ${repository}@${branch}`,
  );

  return { synced: syncedCount, deleted: deletedCount };
}

async function deleteAllWorkflowFiles(
  teamId: string,
  repository: string,
  branch: string,
): Promise<number> {
  const snapshot = await db
    .collection(workflowFilesCollectionPath)
    .where("teamId", "==", teamId)
    .where("repository", "==", repository)
    .where("branch", "==", branch)
    .get();

  if (snapshot.empty) return 0;

  const batch = db.batch();
  for (const doc of snapshot.docs) {
    batch.delete(doc.ref);
  }
  await batch.commit();

  return snapshot.size;
}

async function deleteRemovedWorkflowFiles(
  teamId: string,
  repository: string,
  branch: string,
  currentFileNames: Set<string>,
): Promise<number> {
  const snapshot = await db
    .collection(workflowFilesCollectionPath)
    .where("teamId", "==", teamId)
    .where("repository", "==", repository)
    .where("branch", "==", branch)
    .get();

  const toDelete = snapshot.docs.filter(
    (doc) => !currentFileNames.has(doc.data().fileName),
  );

  if (toDelete.length === 0) return 0;

  const batch = db.batch();
  for (const doc of toDelete) {
    batch.delete(doc.ref);
  }
  await batch.commit();

  return toDelete.length;
}

/**
 * Manual sync callable — fallback for initial setup or missed webhooks.
 */
export const syncWorkflowFiles = onCall(
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
      throw new HttpsError(
        "permission-denied",
        "You are not a member of this team",
      );
    }

    const installationIds = (teamData.installationIds as number[]) || [];

    if (installationIds.length === 0) {
      throw new HttpsError(
        "failed-precondition",
        "GitHub App is not installed for this team",
      );
    }

    const [owner, repo] = repository.split("/");
    const targetBranch = branch ?? "HEAD";

    try {
      const app = new App({
        appId: GITHUB_APP_ID.value(),
        privateKey: GITHUB_PRIVATE_KEY.value(),
      });

      for (const installationId of installationIds) {
        try {
          const octokit = await app.getInstallationOctokit(installationId);

          // Verify repository access
          await octokit.request("GET /repos/{owner}/{repo}", { owner, repo });

          const result = await syncWorkflowFilesToFirestore({
            teamId,
            repository,
            branch: targetBranch,
            octokit,
          });

          return result;
        } catch (e) {
          if (e instanceof HttpsError) throw e;
          continue;
        }
      }

      throw new HttpsError(
        "not-found",
        "Repository not found in any installation",
      );
    } catch (error) {
      if (error instanceof HttpsError) throw error;
      logger.error("Failed to sync workflow files", error);
      throw new HttpsError("internal", "Failed to sync workflow files");
    }
  },
);
