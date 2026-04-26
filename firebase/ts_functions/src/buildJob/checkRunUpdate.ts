import { updateCheckRunById } from "@openci/build-job-services";
import { HttpsError, onCall } from "firebase-functions/v2/https";

interface CheckRunUpdateRequest {
  buildJobId: string;
  runStatus: string;
  conclusion?: string;
}

function requireNonEmptyString(value: unknown, field: string): string {
  if (typeof value !== "string" || value.length === 0) {
    throw new HttpsError("invalid-argument", `${field} is required`);
  }
  return value;
}

function normalizeRunStatus(value: string): "in_progress" | "completed" {
  if (value === "in_progress" || value === "completed") return value;
  throw new HttpsError("invalid-argument", `Unknown runStatus: ${value}`);
}

function normalizeConclusion(value: unknown): "success" | "failure" | undefined {
  if (value === undefined || value === null) return undefined;
  if (value === "success" || value === "failure") return value;
  throw new HttpsError("invalid-argument", `Unknown conclusion: ${String(value)}`);
}

export const checkRunUpdate = onCall<CheckRunUpdateRequest, Promise<{ success: true }>>(
  async (request) => {
    const buildJobId = requireNonEmptyString(request.data?.buildJobId, "buildJobId");
    const runStatus = normalizeRunStatus(
      requireNonEmptyString(request.data?.runStatus, "runStatus"),
    );
    const conclusion = normalizeConclusion(request.data?.conclusion);
    await updateCheckRunById(buildJobId, runStatus, conclusion);
    return { success: true };
  },
);
