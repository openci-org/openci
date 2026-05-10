import { getFirestore } from "firebase-admin/firestore";

import { extractJobs, filterValidWorkflows } from "./extractJobs.js";
import { fetchOpenCIWorkflowYamlFiles } from "./fetchOpenCIWorkflowYamlFiles.js";
import { getGitHubApiBaseUrl, getGitHubBaseUrl } from "./getGitHubApiBaseUrl.js";
import { getInstallationToken } from "./getInstallationToken.js";
import { getTeamIdByInstallationId } from "./getTeamIdByInstallationId.js";
import { matchesTrigger } from "./matchesTrigger.js";
import { parseWorkflowYaml } from "./parseWorkflowYaml.js";

export interface AddBuildJobParams {
  installationId: number;
  commitSha: string;
  branch: string;
  owner: string;
  repo: string;
  appId: string;
  privateKey: string;
  triggerType: string;
}

export async function addBuildJob(params: AddBuildJobParams) {
  const db = getFirestore();
  const teamId = await getTeamIdByInstallationId(db, params.installationId);
  const githubBaseUrl = await getGitHubBaseUrl(db, teamId);
  const apiBaseUrl = getGitHubApiBaseUrl(githubBaseUrl);
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

  const parsedWorkflows = workflowYamlFiles.map(parseWorkflowYaml);

  if (parsedWorkflows.length === 0) {
    return;
  }

  const matchedWorkflows = parsedWorkflows.filter((w) =>
    matchesTrigger(w.parsed, params.triggerType, params.branch),
  );

  if (matchedWorkflows.length === 0) {
    return;
  }

  const validWorkflows = filterValidWorkflows(matchedWorkflows);
  const jobs = extractJobs(validWorkflows);
  if (jobs.length === 0) {
    return;
  }

  // TODO: GitHub Check Run を作成
  // TODO: build job を Firestore に保存
}
