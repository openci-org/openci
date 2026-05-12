import type { Firestore } from "firebase-admin/firestore";

import { firestoreCollectionPaths } from "../../firestoreData.js";

export async function getTeamIdByInstallationId(
  db: Firestore,
  installationId: number,
): Promise<string | undefined> {
  const qs = await db
    .collection(firestoreCollectionPaths.teams)
    .where("installationIds", "array-contains", installationId)
    .limit(1)
    .get();
  if (qs.empty) return undefined;
  return qs.docs[0]!.id;
}
