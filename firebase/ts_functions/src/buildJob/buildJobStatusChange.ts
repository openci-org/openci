import { HttpsError, onCall } from "firebase-functions/v2/https";

import { verifyBuildJobMembership } from "./auth";
import { handleBuildJobStatusChange } from "./services";

interface BuildJobStatusChangeRequest {
  buildJobId: string;
  status: string;
}

function requireNonEmptyString(value: unknown, field: string): string {
  if (typeof value !== "string" || value.length === 0) {
    throw new HttpsError("invalid-argument", `${field} is required`);
  }
  return value;
}

export const buildJobStatusChange = onCall<BuildJobStatusChangeRequest, Promise<{ success: true }>>(
  async (request) => {
    const buildJobId = requireNonEmptyString(request.data?.buildJobId, "buildJobId");
    const status = requireNonEmptyString(request.data?.status, "status");
    const buildJob = await verifyBuildJobMembership(request.auth, buildJobId);
    await handleBuildJobStatusChange(buildJob, status);
    return { success: true };
  },
);
