import { HttpsError, onCall } from "firebase-functions/v2/https";

import { BuildJobStatus } from "@openci/firestore-data";
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

function requireBuildJobStatus(value: unknown): BuildJobStatus {
  const status = requireNonEmptyString(value, "status");
  if ((Object.values(BuildJobStatus) as string[]).includes(status)) {
    return status as BuildJobStatus;
  }
  throw new HttpsError("invalid-argument", `Invalid build job status: ${status}`);
}

export const buildJobStatusChange = onCall<BuildJobStatusChangeRequest, Promise<{ success: true }>>(
  async (request) => {
    const buildJobId = requireNonEmptyString(request.data?.buildJobId, "buildJobId");
    const status = requireBuildJobStatus(request.data?.status);
    const buildJob = await verifyBuildJobMembership(request.auth, buildJobId);
    await handleBuildJobStatusChange(buildJob, status);
    return { success: true };
  },
);
