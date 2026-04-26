import { handleBuildJobStatusChangeById } from "@openci/build-job-services";
import { HttpsError, onCall } from "firebase-functions/v2/https";

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
    await handleBuildJobStatusChangeById(buildJobId, status);
    return { success: true };
  },
);
