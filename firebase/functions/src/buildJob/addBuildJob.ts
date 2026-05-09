import { createAppAuth } from "@octokit/auth-app";
import { request } from "@octokit/request";
import type { Firestore } from "firebase-admin/firestore";
import { getFirestore } from "firebase-admin/firestore";
import { firestoreCollectionPaths } from "../firestoreData.js";
import type { InstallationToken } from "../github/githubApp.js";
import { defaultGitHubApiBaseUrl, defaultGitHubBaseUrl } from "../github/githubUrls.js";

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

export async function getGitHubBaseUrl(db: Firestore, teamId: string): Promise<string> {
  const docs = await db.collection(firestoreCollectionPaths.teams).doc(teamId).get();
  if (!docs.exists) throw new Error(`Team ${teamId} not found`);
  return docs.data()?.githubBaseUrl ?? defaultGitHubBaseUrl;
}

async function getInstallationToken(
  installationId: number,
  apiBaseUrl: string,
  appId: string,
  privateKey: string,
): Promise<InstallationToken> {
  const auth = createAppAuth({
    appId,
    privateKey,
    installationId,
    request: request.defaults({ baseUrl: apiBaseUrl }),
  });
  const data = await auth({ type: "installation" });

  return {
    token: data.token,
    expiresAt: data.expiresAt,
  };
}

export function getGitHubApiBaseUrl(baseUrl: string): string {
  if (baseUrl === defaultGitHubBaseUrl) return defaultGitHubApiBaseUrl;
  return `${new URL(baseUrl).origin}/api/v3`;
}

export interface WorkflowFile {
  name: string;
  content: string;
}

export function filterYamlFiles(
  entries: Array<{ type: string; name: string; path: string }>,
): Array<{ name: string; path: string }> {
  return entries.filter(
    (item) => item.type === "file" && (item.name.endsWith(".yaml") || item.name.endsWith(".yml")),
  );
}

export async function fetchOpenCIWorkflowYamlFiles(
  owner: string,
  repo: string,
  commitSha: string,
  token: string,
  apiBaseUrl: string,
): Promise<WorkflowFile[]> {
  const res = await request("GET /repos/{owner}/{repo}/contents/{path}", {
    baseUrl: apiBaseUrl,
    owner,
    repo,
    path: ".openci",
    ref: commitSha,
    headers: { authorization: `bearer ${token}` },
  });

  if (!Array.isArray(res.data)) {
    throw new Error(`.openci is not a directory in ${owner}/${repo} at ${commitSha}`);
  }

  const yamlFiles = filterYamlFiles(res.data);

  if (yamlFiles.length === 0) return [];

  return Promise.all(
    yamlFiles.map(async (item) => {
      const file = await request("GET /repos/{owner}/{repo}/contents/{path}", {
        baseUrl: apiBaseUrl,
        owner,
        repo,
        path: item.path,
        ref: commitSha,
        headers: {
          authorization: `bearer ${token}`,
          accept: "application/vnd.github.raw+json",
        },
      });
      return { name: item.name, content: file.data as unknown as string };
    }),
  );
}

export async function resolveTeamContext(db: Firestore, installationId: number) {
  const teamId = await getTeamIdByInstallationId(db, installationId);
  const githubBaseUrl = await getGitHubBaseUrl(db, teamId);
  const apiBaseUrl = getGitHubApiBaseUrl(githubBaseUrl);
  return { teamId, githubBaseUrl, apiBaseUrl };
}

export interface AddBuildJobParams {
  installationId: number;
  commitSha: string;
  branch: string;
  owner: string;
  repo: string;
  appId: string;
  privateKey: string;
}

export async function addBuildJob(params: AddBuildJobParams) {
  const db = getFirestore();
  const { teamId, githubBaseUrl, apiBaseUrl } = await resolveTeamContext(db, params.installationId);
  const { token, expiresAt } = await getInstallationToken(
    params.installationId,
    apiBaseUrl,
    params.appId,
    params.privateKey,
  );

  const workflowYamlFiles = await fetchOpenCIWorkflowYamlFiles(
    params.owner,
    params.repo,
    params.commitSha,
    token,
    apiBaseUrl,
  );

  if (workflowYamlFiles.length === 0) {
    return;
  }

  // トリガー条件にマッチする？
  //
}
