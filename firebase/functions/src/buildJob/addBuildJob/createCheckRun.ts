import { randomUUID } from "node:crypto";

import { request } from "@octokit/request";

import { buildDashboardRunUrl } from "../../github/githubUrls.js";
import type { ExtractedJob } from "./extractJobs.js";

interface PostCheckRunParams {
  token: string;
  owner: string;
  repo: string;
  name: string;
  headSha: string;
  status: "queued" | "in_progress" | "completed";
  detailsUrl: string;
  apiBaseUrl: string;
}

export interface CreateCheckRunParams {
  jobs: ExtractedJob[];
  token: string;
  owner: string;
  repo: string;
  headSha: string;
  apiBaseUrl: string;
}

export type JobWithCheckRun = ExtractedJob & {
  documentId: string;
  checkRunId: number;
};

function checkRunJobName(job: ExtractedJob): string {
  const jobKey = job.workflowJobKey ?? job.jobId;
  const suffix = job.matrixLabel ? ` (${job.matrixLabel})` : "";
  return `${job.workflowName} / ${jobKey}${suffix}`;
}

async function postCheckRun(params: PostCheckRunParams): Promise<number> {
  const res = await request("POST /repos/{owner}/{repo}/check-runs", {
    baseUrl: params.apiBaseUrl,
    owner: params.owner,
    repo: params.repo,
    headers: {
      authorization: `bearer ${params.token}`,
      accept: "application/vnd.github+json",
      "X-GitHub-Api-Version": "2022-11-28",
    },
    name: params.name,
    head_sha: params.headSha,
    status: params.status,
    started_at: new Date().toISOString(),
    details_url: params.detailsUrl,
  });

  if (typeof res.data.id !== "number") {
    throw new Error(
      `GitHub check run response did not include an id for ${params.owner}/${params.repo}`,
    );
  }

  return res.data.id;
}

export async function createCheckRun(params: CreateCheckRunParams): Promise<JobWithCheckRun[]> {
  const jobCountsByWorkflow: Record<string, number> = {};
  for (const job of params.jobs) {
    jobCountsByWorkflow[job.workflowName] = (jobCountsByWorkflow[job.workflowName] ?? 0) + 1;
  }

  return Promise.all(
    params.jobs.map(async (job) => {
      const documentId = randomUUID();
      const checkRunName =
        (jobCountsByWorkflow[job.workflowName] ?? 0) > 1 ? checkRunJobName(job) : job.workflowName;
      const checkRunId = await postCheckRun({
        token: params.token,
        owner: params.owner,
        repo: params.repo,
        name: checkRunName,
        headSha: params.headSha,
        status: "queued",
        detailsUrl: buildDashboardRunUrl(documentId),
        apiBaseUrl: params.apiBaseUrl,
      });

      return { ...job, documentId, checkRunId };
    }),
  );
}
