import type { Firestore } from "firebase-admin/firestore";

import { firestoreCollectionPaths } from "../../firestoreData.js";
import { getApiBaseUrlFromTeamData, getBaseUrlFromTeamData } from "../../github/githubUrls.js";

export async function getGitHubBaseUrl(db: Firestore, teamId: string): Promise<string> {
  const docs = await db.collection(firestoreCollectionPaths.teams).doc(teamId).get();
  if (!docs.exists) throw new Error(`Team ${teamId} not found`);
  return getBaseUrlFromTeamData(docs.data());
}

export function getGitHubApiBaseUrl(baseUrl: string): string {
  return getApiBaseUrlFromTeamData({ githubBaseUrl: baseUrl });
}
