import { HttpsError, onCall } from "firebase-functions/v2/https";

import { verifyBuildJobMembership } from "./auth";
import { generateFailureSummary as generateFailureSummaryForBuildJob } from "./services";

interface GenerateFailureSummaryRequest {
  buildJobId: string;
}

function requireNonEmptyString(value: unknown, field: string): string {
  if (typeof value !== "string" || value.length === 0) {
    throw new HttpsError("invalid-argument", `${field} is required`);
  }
  return value;
}

export const generateFailureSummary = onCall<
  GenerateFailureSummaryRequest,
  Promise<{ success: true }>
>({ timeoutSeconds: 120 }, async (request) => {
  const buildJobId = requireNonEmptyString(request.data?.buildJobId, "buildJobId");
  const buildJob = await verifyBuildJobMembership(request.auth, buildJobId);
  await generateFailureSummaryForBuildJob(buildJob);
  return { success: true };
});
