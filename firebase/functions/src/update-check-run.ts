import * as logger from "firebase-functions/logger";
import { onDocumentCreated, onDocumentUpdated } from "firebase-functions/firestore";

import { db } from "./firebase";
import { buildJobsCollectionPath, runsSubcollectionPath } from "./firestore-collection-paths";

async function patchCheckRun(
  owner: string,
  repo: string,
  checkRunId: number,
  installationToken: string,
  status: string,
  conclusion?: string,
) {
  const url = `https://api.github.com/repos/${owner}/${repo}/check-runs/${checkRunId}`;

  const body: Record<string, string> = { status };
  if (conclusion) {
    body.conclusion = conclusion;
  }

  const response = await fetch(url, {
    method: "PATCH",
    headers: {
      "Authorization": `Bearer ${installationToken}`,
      "Accept": "application/vnd.github.v3+json",
      "User-Agent": "OpenCI-Worker",
    },
    body: JSON.stringify(body),
  });

  if (response.ok) {
    logger.info(`Updated check run ${checkRunId} to ${status} (${conclusion ?? "n/a"})`);
  } else {
    const text = await response.text();
    logger.error(`Failed to update check run ${checkRunId}: ${response.status} ${text}`);
  }
}

export const onRunCreated = onDocumentCreated(
  {
    document: `${buildJobsCollectionPath}/{buildJobId}/${runsSubcollectionPath}/{runId}`,
    region: "asia-northeast1",
  },
  async (event) => {
    const buildJobId = event.params.buildJobId;

    const buildJobDoc = await db.collection(buildJobsCollectionPath).doc(buildJobId).get();
    if (!buildJobDoc.exists) return;

    const buildJobData = buildJobDoc.data()!;
    const checkRunId = buildJobData.checkRunId as number | null;
    if (!checkRunId) return;

    try {
      await patchCheckRun(
        buildJobData.owner,
        buildJobData.repo,
        checkRunId,
        buildJobData.installationToken,
        "in_progress",
      );
    } catch (e) {
      logger.error(`Error updating check run to in_progress`, e);
    }
  },
);

export const onRunUpdated = onDocumentUpdated(
  {
    document: `${buildJobsCollectionPath}/{buildJobId}/${runsSubcollectionPath}/{runId}`,
    region: "asia-northeast1",
  },
  async (event) => {
    const before = event.data?.before?.data();
    const after = event.data?.after?.data();

    if (!before || !after) return;
    if (before.status === after.status) return;
    if (after.status !== "completed") return;

    const buildJobId = event.params.buildJobId;

    const buildJobDoc = await db.collection(buildJobsCollectionPath).doc(buildJobId).get();
    if (!buildJobDoc.exists) {
      logger.error(`Build job ${buildJobId} not found`);
      return;
    }

    const buildJobData = buildJobDoc.data()!;
    const checkRunId = buildJobData.checkRunId as number | null;
    if (!checkRunId) return;

    try {
      await patchCheckRun(
        buildJobData.owner,
        buildJobData.repo,
        checkRunId,
        buildJobData.installationToken,
        "completed",
        after.conclusion,
      );
    } catch (e) {
      logger.error(`Error updating check run to completed`, e);
    }
  },
);
