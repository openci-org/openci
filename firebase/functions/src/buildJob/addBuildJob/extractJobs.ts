import type { ParsedWorkflowFile } from "./parseWorkflowYaml.js";

export interface ExtractedJob {
  workflowName: string;
  jobId: string;
  spec: Record<string, unknown>;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  if (typeof value !== "object") return false; // 文字列・数値などを除外
  if (value === null) return false; // typeof null === "object" のバグを除外
  if (Array.isArray(value)) return false; // 配列を除外
  return true;
}

export interface WorkflowWithJobs {
  name: string;
  jobs: Record<string, unknown>;
}

export function filterValidWorkflows(workflows: ParsedWorkflowFile[]): WorkflowWithJobs[] {
  const validWorkflows: WorkflowWithJobs[] = [];
  for (const workflow of workflows) {
    const jobs = workflow.parsed.jobs;
    if (!isRecord(jobs)) {
      console.warn(`extractJobs: skipping ${workflow.name} (no valid jobs object)`);
      continue;
    }
    validWorkflows.push({ name: workflow.name, jobs });
  }
  return validWorkflows;
}

export function extractJobs(workflows: WorkflowWithJobs[]): ExtractedJob[] {
  const result: ExtractedJob[] = [];
  for (const workflow of workflows) {
    let didExtract = false;
    for (const [jobId, spec] of Object.entries(workflow.jobs)) {
      if (!isRecord(spec)) {
        console.warn(`extractJobs: skipping job "${jobId}" in ${workflow.name} (not an object)`);
        continue;
      }
      result.push({ workflowName: workflow.name, jobId, spec });
      didExtract = true;
    }

    if (!didExtract) {
      console.warn(`extractJobs: no jobs extracted from ${workflow.name}`);
    }
  }

  return result;
}
