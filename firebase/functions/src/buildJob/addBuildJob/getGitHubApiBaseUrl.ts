import type { Firestore } from "firebase-admin/firestore";

import { firestoreCollectionPaths } from "../../firestoreData.js";
import { defaultGitHubApiBaseUrl, defaultGitHubBaseUrl } from "../../github/githubUrls.js";

export async function getGitHubBaseUrl(db: Firestore, teamId: string): Promise<string> {
  const docs = await db.collection(firestoreCollectionPaths.teams).doc(teamId).get();
  if (!docs.exists) throw new Error(`Team ${teamId} not found`);
  return docs.data()?.githubBaseUrl ?? defaultGitHubBaseUrl;
}

export function getGitHubApiBaseUrl(baseUrl: string): string {
  if (baseUrl === defaultGitHubBaseUrl) return defaultGitHubApiBaseUrl;
  return `${new URL(baseUrl).origin}/api/v3`;
}
