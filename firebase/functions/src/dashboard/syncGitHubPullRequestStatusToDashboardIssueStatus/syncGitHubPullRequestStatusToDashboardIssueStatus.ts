import { FieldValue, type Firestore } from "firebase-admin/firestore";

import { firestoreCollectionPaths } from "../../firestoreData.js";
import { asString } from "../dashboardPayloadHelpers.js";
import {
  findIssueKeyFromPullRequestBranch,
  findRepoFullNameFromPullRequestPayload,
  isOpenedPullRequestPayload,
  type DashboardPullRequestPayload,
} from "../dashboardPullRequestPayloadHelpers.js";

const reviewStatusId = "review";
const doneStatusId = "done";

export type DashboardPullRequestWebhookPayload = DashboardPullRequestPayload;

export async function syncGitHubPullRequestStatusToDashboardIssueStatus(
  db: Firestore,
  payload: DashboardPullRequestWebhookPayload,
): Promise<void> {
  if (!isOpenedPullRequestPayload(payload)) {
    return;
  }

  const repoFullName = findRepoFullNameFromPullRequestPayload(payload);
  if (repoFullName === null) {
    return;
  }

  const issueKey = findIssueKeyFromPullRequestBranch(payload);
  if (issueKey === null) {
    return;
  }

  const workspacesRef = db.collection(firestoreCollectionPaths.workspaces);
  const workspacesQuerySnapshot = await workspacesRef
    .where("syncedGitHubRepoFullNames", "array-contains", repoFullName)
    .get();

  if (workspacesQuerySnapshot.empty) {
    return;
  }

  for (const workspaceQueryDocumentSnapshot of workspacesQuerySnapshot.docs) {
    const issueDocs = await workspaceQueryDocumentSnapshot.ref
      .collection("issues")
      .where("issueKey", "==", issueKey)
      .where("repo", "==", repoFullName)
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
