import type { ParsedWorkflowFile } from "./parseWorkflowYaml.js";

export interface ExtractedJob {
  workflowFileName: string;
  workflowName: string;
  jobId: string;
  spec: Record<string, unknown>;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  if (typeof value !== "object") return false;
  if (value === null) return false;
  if (Array.isArray(value)) return false;
  return true;
}

export interface WorkflowWithJobs {
  workflowFileName: string;
  workflowName: string;
  jobs: Record<string, unknown>;
}

export function filterValidWorkflows(workflows: ParsedWorkflowFile[]): WorkflowWithJobs[] {
  const validWorkflows: WorkflowWithJobs[] = [];
  for (const workflow of workflows) {
    const jobs = workflow.parsed.jobs;
    if (!isRecord(jobs)) {
      console.warn(`extractJobs: skipping ${workflow.workflowFileName} (no valid jobs object)`);
      continue;
    }
    validWorkflows.push({
      workflowFileName: workflow.workflowFileName,
      workflowName: workflow.workflowName,
      jobs,
    });
  }
  return validWorkflows;
}

export function extractJobs(workflows: WorkflowWithJobs[]): ExtractedJob[] {
  const result: ExtractedJob[] = [];
  for (const workflow of workflows) {
    let didExtract = false;
    for (const [jobId, spec] of Object.entries(workflow.jobs)) {
      if (!isRecord(spec)) {
        console.warn(
          `extractJobs: skipping job "${jobId}" in ${workflow.workflowFileName} (not an object)`,
        );
        continue;
      }
      result.push({
        workflowFileName: workflow.workflowFileName,
        workflowName: workflow.workflowName,
        jobId,
        spec,
      });
      didExtract = true;
    }

    if (!didExtract) {
      console.warn(`extractJobs: no jobs extracted from ${workflow.workflowFileName}`);
    }
  }

  return result;
}
