import { FieldValue, type Firestore } from "firebase-admin/firestore";

import { firestoreCollectionPaths } from "../firestoreData.js";
import {
  type DashboardPullRequestWebhookPayload,
  findDashboardIssueStatusSyncTarget,
} from "./dashboardIssueStatusSyncTarget.js";

const reviewStatusId = "review";
const doneStatusId = "done";

function asString(value: unknown, fallback = ""): string {
  return typeof value === "string" && value.length > 0 ? value : fallback;
}

export async function syncGitHubPullRequestStatusToDashboardIssueStatus(
  db: Firestore,
  payload: DashboardPullRequestWebhookPayload,
): Promise<void> {
  const target = findDashboardIssueStatusSyncTarget(payload);
  if (target === null) {
    return;
  }

  const workspacesRef = db.collection(firestoreCollectionPaths.workspaces);
  const workspacesQuerySnapshot = await workspacesRef
    .where("syncedGitHubRepoFullNames", "array-contains", target.repoFullName)
    .get();

  if (workspacesQuerySnapshot.empty) {
    return;
  }

  for (const workspaceQueryDocumentSnapshot of workspacesQuerySnapshot.docs) {
    const issueDocs = await workspaceQueryDocumentSnapshot.ref
      .collection("issues")
      .where("issueKey", "==", target.issueKey)
      .where("repo", "==", target.repoFullName)
      .limit(1)
      .get();

    if (issueDocs.empty) {
      continue;
    }

    const issueDoc = issueDocs.docs[0];
    if (issueDoc === undefined) {
      continue;
    }

    const currentStatusId = asString(issueDoc.get("statusId"), "triage");
    if (currentStatusId === reviewStatusId || currentStatusId === doneStatusId) {
      continue;
    }

    await issueDoc.ref.set(
      {
        statusId: reviewStatusId,
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  }
}
