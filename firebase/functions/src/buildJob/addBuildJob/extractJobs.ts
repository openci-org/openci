import type { ParsedWorkflowFile } from "./parseWorkflowYaml.js";
import {
  expandMatrix,
  matrixInstanceKey,
  matrixLabel,
  resolveMatrixExpressions,
  type MatrixCell,
} from "./matrix.js";

export interface ExtractedJob {
  workflowFileName: string;
  workflowName: string;
  jobId: string;
  workflowJobKey?: string;
  spec: Record<string, unknown>;
  matrix?: MatrixCell;
  matrixLabel?: string;
  matrixIndex?: number;
  matrixGroupKey?: string;
  matrixFailFast?: boolean;
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
      const matrixCells = expandMatrix(spec.strategy);
      if (matrixCells !== null) {
        for (const [matrixIndex, matrix] of matrixCells.entries()) {
          result.push({
            workflowFileName: workflow.workflowFileName,
            workflowName: workflow.workflowName,
            jobId: matrixInstanceKey(jobId, matrix),
            workflowJobKey: jobId,
            spec: resolveMatrixExpressions(spec, matrix) as Record<string, unknown>,
            matrix,
            matrixLabel: matrixLabel(matrix),
            matrixIndex,
            matrixGroupKey: `${workflow.workflowFileName}:${jobId}`,
            matrixFailFast: (spec.strategy as Record<string, unknown>)["fail-fast"] !== false,
          });
          didExtract = true;
        }
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
