import { getFirestore } from "firebase-admin/firestore";

import { createCheckRun } from "./createCheckRun.js";
import { extractJobs, filterValidWorkflows } from "./extractJobs.js";
import { fetchOpenCIWorkflowYamlFiles } from "./fetchOpenCIWorkflowYamlFiles.js";
import { getGitHubApiBaseUrl, getGitHubBaseUrl } from "./getGitHubApiBaseUrl.js";
import { getInstallationToken } from "./getInstallationToken.js";
import { getTeamIdByInstallationId } from "./getTeamIdByInstallationId.js";
import { matchesTrigger } from "./matchesTrigger.js";
import { parseWorkflowYaml } from "./parseWorkflowYaml.js";
import { saveBuildJobToFirestore } from "./saveBuildJobToFirestore.js";

export type AddBuildJobTriggerType = "push" | "pull_request";

export interface AddBuildJobParams {
  installationId: number;
  commitSha: string;
  branch: string;
  triggerBranch?: string;
  pullRequestNumber?: number | null;
  owner: string;
  repo: string;
  appId: string;
  privateKey: string;
  triggerType: AddBuildJobTriggerType;
}

export async function addBuildJob(params: AddBuildJobParams) {
  const db = getFirestore();
  const teamId = await getTeamIdByInstallationId(db, params.installationId);
  if (!teamId) {
    return;
  }
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
    matchesTrigger(w.parsed, params.triggerType, params.triggerBranch ?? params.branch),
  );

  if (matchedWorkflows.length === 0) {
    return;
  }

  const validWorkflows = filterValidWorkflows(matchedWorkflows);
  const jobs = extractJobs(validWorkflows);
  if (jobs.length === 0) {
    return;
  }

  const jobsWithCheckRuns = await createCheckRun({
    jobs,
    token,
    owner: params.owner,
    repo: params.repo,
    headSha: params.commitSha,
    apiBaseUrl,
  });

  if (jobsWithCheckRuns.length === 0) {
    return;
  }

  await saveBuildJobToFirestore({
    db,
    jobs: jobsWithCheckRuns,
    owner: params.owner,
    repo: params.repo,
    teamId,
    installationId: params.installationId,
    installationToken: token,
    tokenExpiresAt: expiresAt,
    checkRunCommitSha: params.commitSha,
    pullRequestNumber: params.pullRequestNumber ?? null,
    triggerType: params.triggerType,
    branch: params.branch,
    apiBaseUrl,
    githubBaseUrl,
  });
}
