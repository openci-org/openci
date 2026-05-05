import { HttpsError, onCall } from "firebase-functions/v2/https";
import { onDocumentUpdated } from "firebase-functions/v2/firestore";

import { BuildJobStatus } from "../firestoreData";
import { verifyBuildJobMembership } from "./auth";
import {
  type BuildJob,
  generateFailureSummary as generateFailureSummaryForBuildJob,
} from "./services";

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

export const generateFailureSummaryOnBuildJobFailure = onDocumentUpdated(
  {
    document: "build_jobs_v0/{buildJobId}",
    timeoutSeconds: 120,
  },
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    if (!after) return;
    if (before?.status === BuildJobStatus.FAILURE || after.status !== BuildJobStatus.FAILURE) {
      return;
    }
    if (after.failureSummaryStatus === "generating" || after.failureSummaryStatus === "done") {
      return;
    }

    await generateFailureSummaryForBuildJob({
      id: event.params.buildJobId,
      ...after,
    } as BuildJob);
  },
);
