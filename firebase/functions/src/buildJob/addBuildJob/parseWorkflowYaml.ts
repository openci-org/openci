import YAML from "yaml";

import type { WorkflowFile } from "./fetchOpenCIWorkflowYamlFiles.js";

export interface ParsedWorkflowFile {
  name: string;
  parsed: Record<string, unknown>;
}

export function parseWorkflowYaml(file: WorkflowFile): ParsedWorkflowFile {
  try {
    const parsed = YAML.parse(file.content);
    if (typeof parsed !== "object" || parsed === null || Array.isArray(parsed)) {
      throw new Error("Workflow YAML must be an object");
    }
    return { name: file.name, parsed: parsed as Record<string, unknown> };
  } catch (error) {
    const message = error instanceof Error ? error.message : String(error);
    throw new Error(`Failed to parse ${file.name}: ${message}`);
  }
}
