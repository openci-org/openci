import { logger } from "firebase-functions/v2";
import { HttpsError, onCall } from "firebase-functions/v2/https";

import { BuildJobStatus, getBuildJob, updateBuildJobStatus } from "../firestoreData";
import { verifyTeamMembership } from "../team/teamAuth";

interface CancelBuildJobRequest {
  buildJobId: string;
}

function requireNonEmptyString(value: unknown, field: string): string {
  if (typeof value !== "string" || value.length === 0) {
    throw new HttpsError("invalid-argument", `${field} is required`);
  }
  return value;
}

export const cancelBuildJob = onCall<CancelBuildJobRequest, Promise<{ success: true }>>(
  async (request) => {
    const auth = request.auth;
    if (!auth) {
      throw new HttpsError("unauthenticated", "Unauthenticated");
    }

    const buildJobId = requireNonEmptyString(request.data?.buildJobId, "buildJobId");
    const jobResult = await getBuildJob({ id: buildJobId });
    const jobData = jobResult.data.buildJob;
    if (!jobData) {
      throw new HttpsError("not-found", "Build job not found");
    }

    const currentStatus = jobData.status;
    if (currentStatus !== BuildJobStatus.QUEUED && currentStatus !== BuildJobStatus.IN_PROGRESS) {
      throw new HttpsError(
        "failed-precondition",
        `Cannot cancel a build job with status '${currentStatus}'`,
      );
    }

    const teamId = typeof jobData.teamId === "string" ? jobData.teamId : undefined;
    if (teamId) {
      await verifyTeamMembership(auth, teamId);
    }

    await updateBuildJobStatus({ id: buildJobId, status: BuildJobStatus.CANCELLED });
    logger.info("Build job cancelled", {
      buildJobId,
      callerUid: auth.uid,
      teamId,
      previousStatus: currentStatus,
    });

    return { success: true };
  },
);
