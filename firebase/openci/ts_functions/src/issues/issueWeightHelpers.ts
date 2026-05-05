import { createHash } from "node:crypto";

export const issueWeightPromptVersion = "issue-weight-v2";
const maxIssueBodyCharsForWeight = 4000;

export const validWeights = [1, 2, 4, 8, 16, 32] as const;
export type IssueWeight = (typeof validWeights)[number];

export function isValidWeight(value: number): value is IssueWeight {
  return (validWeights as readonly number[]).includes(value);
}

export function isAdjacentWeight(a: number, b: number): boolean {
  const idxA = validWeights.indexOf(a as IssueWeight);
  const idxB = validWeights.indexOf(b as IssueWeight);
  if (idxA < 0 || idxB < 0) return false;
  return Math.abs(idxA - idxB) <= 1;
}

function asString(value: unknown, fallback = ""): string {
  return typeof value === "string" && value.length > 0 ? value : fallback;
}

function asNumber(value: unknown, fallback = 0): number {
  return typeof value === "number" ? value : fallback;
}

function asStringList(value: unknown): string[] {
  if (!Array.isArray(value)) {
    return [];
  }
  return value.filter((item): item is string => typeof item === "string" && item.length > 0);
}

export function truncateText(value: string, maxLength: number): string {
  return value.length <= maxLength ? value : `${value.slice(0, maxLength)}\n[truncated]`;
}

export function issueWeightInput(issue: Record<string, unknown>): Record<string, unknown> {
  return {
    title: truncateText(asString(issue.title), 300),
    body: truncateText(asString(issue.body), maxIssueBodyCharsForWeight),
    repo: asString(issue.repo),
    labels: asStringList(issue.labels).slice(0, 30),
    comments: asNumber(issue.comments),
    priority: asString(issue.priority, "medium"),
  };
}

export function issueWeightInputHash(issue: Record<string, unknown>): string {
  return createHash("sha256")
    .update(
      JSON.stringify({ promptVersion: issueWeightPromptVersion, issue: issueWeightInput(issue) }),
    )
    .digest("hex");
}

export function parseWeightEstimateResponse(responseText: string): {
  value: number;
  confidence: number;
  reason: string;
} {
  const start = responseText.indexOf("{");
  const end = responseText.lastIndexOf("}");
  if (start < 0 || end <= start) {
    throw new Error("LLM response did not include JSON");
  }
  const parsed = JSON.parse(responseText.slice(start, end + 1)) as Record<string, unknown>;
  const value = asNumber(parsed.value);
  const confidence = asNumber(parsed.confidence);
  const reason = truncateText(asString(parsed.reason), 240);
  if (!Number.isInteger(value) || !isValidWeight(value)) {
    throw new Error(`LLM response value must be one of ${validWeights.join(", ")}`);
  }
  if (confidence < 0 || confidence > 1) {
    throw new Error("LLM response confidence must be between 0 and 1");
  }
  if (reason.length === 0) {
    throw new Error("LLM response reason is required");
  }
  return { value, confidence, reason };
}
