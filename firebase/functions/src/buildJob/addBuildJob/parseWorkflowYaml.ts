import YAML from "yaml";

import type { WorkflowFile } from "./fetchOpenCIWorkflowYamlFiles.js";

export interface ParsedWorkflowFile {
  workflowFileName: string;
  workflowName: string;
  parsed: Record<string, unknown>;
}

export function parseWorkflowYaml(file: WorkflowFile): ParsedWorkflowFile {
  try {
    const parsed = YAML.parse(file.content);
    if (typeof parsed !== "object" || parsed === null || Array.isArray(parsed)) {
      throw new Error("Workflow YAML must be an object");
    }
    const workflowName =
      typeof parsed.name === "string" ? parsed.name : file.name.replace(/\.(yaml|yml)$/u, "");
    return { workflowFileName: file.name, workflowName, parsed: parsed as Record<string, unknown> };
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    throw new Error(`Failed to parse ${file.name}: ${message}`);
  }
}
