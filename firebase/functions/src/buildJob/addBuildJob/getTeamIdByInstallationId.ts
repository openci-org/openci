import type { Firestore } from "firebase-admin/firestore";

import { firestoreCollectionPaths } from "../../firestoreData.js";

export async function getTeamIdByInstallationId(
  db: Firestore,
  installationId: number,
): Promise<string> {
  const qs = await db
    .collection(firestoreCollectionPaths.teams)
    .where("installationIds", "array-contains", installationId)
    .limit(1)
    .get();
  if (qs.empty) throw new Error(`No team found for installation ${installationId}`);
  return qs.docs[0]!.id;
}
