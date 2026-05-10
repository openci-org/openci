import { randomUUID } from "node:crypto";

import { FieldValue, type Firestore } from "firebase-admin/firestore";

import { defaultGitHubApiBaseUrl, defaultGitHubBaseUrl } from "../../github/githubUrls.js";
import type { JobWithCheckRun } from "./createCheckRun.js";

const buildJobsCollection = "build_jobs_v0";

const BuildJobStatus = {
  WAITING: "WAITING",
  QUEUED: "QUEUED",
} as const;

function buildJobSpecFields(spec: Record<string, unknown>, jobDocumentIds: Record<string, string>) {
  const rawNeeds = spec.needs;
  const needs = Array.isArray(rawNeeds)
    ? rawNeeds.map(String)
    : typeof rawNeeds === "string"
      ? [rawNeeds]
      : [];
  const hasNeeds = needs.length > 0;
  const resolvedNeeds = hasNeeds
    ? Object.fromEntries(
        needs
          .map((need) => [need, jobDocumentIds[need]])
          .filter((entry): entry is [string, string] => typeof entry[1] === "string"),
      )
    : null;
  const runsOn = spec["runs-on"];

  return {
    needs: hasNeeds ? needs : null,
    resolvedNeeds,
    runsOn: typeof runsOn === "string" ? runsOn : null,
    status: hasNeeds ? BuildJobStatus.WAITING : BuildJobStatus.QUEUED,
  };
}

export interface SaveBuildJobToFirestoreParams {
  db: Firestore;
  jobs: JobWithCheckRun[];
  owner: string;
  repo: string;
  teamId: string;
  installationId: number;
  installationToken: string;
  tokenExpiresAt: string;
  checkRunCommitSha: string;
  triggerType: string;
  branch: string;
  apiBaseUrl: string;
  githubBaseUrl: string;
}

export async function saveBuildJobToFirestore(
  params: SaveBuildJobToFirestoreParams,
): Promise<void> {
  const batch = params.db.batch();
  const workflowRunId = randomUUID();
  const jobDocumentIds: Record<string, string> = {};
  for (const job of params.jobs) {
    jobDocumentIds[job.jobId] = job.documentId;
  }

  for (const job of params.jobs) {
    const specFields = buildJobSpecFields(job.spec, jobDocumentIds);
    const buildJobRef = params.db.collection(buildJobsCollection).doc(job.documentId);

    batch.set(buildJobRef, {
      id: job.documentId,
      status: specFields.status,
      owner: params.owner,
      repo: params.repo,
      teamId: params.teamId,
      workflowId: null,
      workflowFileName: job.workflowName,
      workflowName: job.workflowName,
      jobKey: job.jobId,
      workflowRunId,
      needs: specFields.needs,
      resolvedNeeds: specFields.resolvedNeeds,
      installationId: String(params.installationId),
      installationToken: params.installationToken,
      tokenExpiresAt: params.tokenExpiresAt,
      checkRunId: String(job.checkRunId),
      commitSha: params.checkRunCommitSha,
      pullRequestNumber: null,
      event: params.triggerType,
      action: null,
      repository: `${params.owner}/${params.repo}`,
      sender: null,
      runsOn: specFields.runsOn,
      runCount: 0,
      latestRunId: null,
      tagName: null,
      branch: params.branch,
      releaseName: null,
      retriedFromBuildJobId: null,
      retriedFromWorkflowRunId: null,
      githubApiBaseUrl: params.apiBaseUrl !== defaultGitHubApiBaseUrl ? params.apiBaseUrl : null,
      githubBaseUrl: params.githubBaseUrl !== defaultGitHubBaseUrl ? params.githubBaseUrl : null,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
  }

  await batch.commit();
}
