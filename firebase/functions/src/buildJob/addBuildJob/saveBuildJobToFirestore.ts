import { randomUUID } from "node:crypto";

import { FieldValue, type Firestore } from "firebase-admin/firestore";

import { firestoreCollectionPaths } from "../../firestoreData.js";
import { defaultGitHubApiBaseUrl, defaultGitHubBaseUrl } from "../../github/githubUrls.js";
import type { AddBuildJobTriggerType } from "./addBuildJob.js";
import type { JobWithCheckRun } from "./createCheckRun.js";

const BuildJobStatus = {
  WAITING: "WAITING",
  QUEUED: "QUEUED",
} as const;

function buildJobSpecFields(
  spec: Record<string, unknown>,
  jobDocumentIds: Record<string, string>,
  jobInstanceKeysBySourceKey: Record<string, string[]>,
) {
  const rawNeeds = spec.needs;
  const rawNeedKeys = Array.isArray(rawNeeds)
    ? rawNeeds.map(String)
    : typeof rawNeeds === "string"
      ? [rawNeeds]
      : [];
  const needs = rawNeedKeys.flatMap((need) => jobInstanceKeysBySourceKey[need] ?? [need]);
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

function getOrCreateWorkflowRunId(
  workflowRunIds: Map<string, string>,
  workflowFileName: string,
): string {
  const existing = workflowRunIds.get(workflowFileName);
  if (existing) return existing;

  const workflowRunId = randomUUID();
  workflowRunIds.set(workflowFileName, workflowRunId);
  return workflowRunId;
}

export interface SaveBuildJobsToFirestoreParams {
  db: Firestore;
  jobs: JobWithCheckRun[];
  owner: string;
  repo: string;
  teamId: string;
  installationId: number;
  installationToken: string;
  tokenExpiresAt: string;
  checkRunCommitSha: string;
  pullRequestNumber: number | null;
  triggerType: AddBuildJobTriggerType;
  branch: string;
  apiBaseUrl: string;
  githubBaseUrl: string;
}

export async function saveBuildJobsToFirestore(
  params: SaveBuildJobsToFirestoreParams,
): Promise<void> {
  const batch = params.db.batch();
  const workflowRunIds = new Map<string, string>();
  const jobDocumentIdsByWorkflow = new Map<string, Record<string, string>>();
  const jobInstanceKeysBySourceKeyByWorkflow = new Map<string, Record<string, string[]>>();
  for (const job of params.jobs) {
    getOrCreateWorkflowRunId(workflowRunIds, job.workflowFileName);

    const jobDocumentIds = jobDocumentIdsByWorkflow.get(job.workflowFileName) ?? {};
    jobDocumentIds[job.jobId] = job.documentId;
    jobDocumentIdsByWorkflow.set(job.workflowFileName, jobDocumentIds);

    const sourceKey = job.workflowJobKey ?? job.jobId;
    const jobInstanceKeysBySourceKey =
      jobInstanceKeysBySourceKeyByWorkflow.get(job.workflowFileName) ?? {};
    jobInstanceKeysBySourceKey[sourceKey] = [
      ...(jobInstanceKeysBySourceKey[sourceKey] ?? []),
      job.jobId,
    ];
    jobInstanceKeysBySourceKeyByWorkflow.set(job.workflowFileName, jobInstanceKeysBySourceKey);
  }

  for (const job of params.jobs) {
    const workflowRunId = getOrCreateWorkflowRunId(workflowRunIds, job.workflowFileName);
    const jobDocumentIds = jobDocumentIdsByWorkflow.get(job.workflowFileName) ?? {};
    const jobInstanceKeysBySourceKey =
      jobInstanceKeysBySourceKeyByWorkflow.get(job.workflowFileName) ?? {};
    const specFields = buildJobSpecFields(job.spec, jobDocumentIds, jobInstanceKeysBySourceKey);
    const buildJobRef = params.db
      .collection(firestoreCollectionPaths.buildJobs)
      .doc(job.documentId);

    batch.set(buildJobRef, {
      id: job.documentId,
      status: specFields.status,
      owner: params.owner,
      repo: params.repo,
      teamId: params.teamId,
      workflowId: null,
      workflowFileName: job.workflowFileName,
      workflowName: job.workflowName,
      jobKey: job.jobId,
      workflowJobKey: job.workflowJobKey ?? null,
      matrix: job.matrix ?? null,
      matrixLabel: job.matrixLabel ?? null,
      matrixIndex: job.matrixIndex ?? null,
      matrixGroupKey: job.matrixGroupKey ?? null,
      matrixFailFast: job.matrixFailFast ?? null,
      workflowRunId,
      needs: specFields.needs,
      resolvedNeeds: specFields.resolvedNeeds,
      installationId: String(params.installationId),
      installationToken: params.installationToken,
      tokenExpiresAt: params.tokenExpiresAt,
      checkRunId: String(job.checkRunId),
      commitSha: params.checkRunCommitSha,
      pullRequestNumber: params.pullRequestNumber,
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
