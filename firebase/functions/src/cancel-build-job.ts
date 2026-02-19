import { HttpsError, onCall } from "firebase-functions/https";
import * as logger from "firebase-functions/logger";

import { db } from "./firebase";
import { buildJobsCollectionPath, teamsCollectionPath } from "./firestore-collection-paths";

export const cancelBuildJob = onCall(
  {
    region: "asia-northeast1",
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Unauthenticated");
    }

    const callerUid = request.auth.uid;
    const { buildJobId } = request.data as { buildJobId: string };

    if (!buildJobId) {
      throw new HttpsError("invalid-argument", "Missing buildJobId");
    }

    const jobRef = db.collection(buildJobsCollectionPath).doc(buildJobId);
    const jobDoc = await jobRef.get();

    if (!jobDoc.exists) {
      throw new HttpsError("not-found", "Build job not found");
    }

    const jobData = jobDoc.data()!;
    const currentStatus = jobData.status;

    // Only queued or in_progress jobs can be cancelled
    if (currentStatus !== "queued" && currentStatus !== "in_progress") {
      throw new HttpsError(
        "failed-precondition",
        `Cannot cancel a build job with status '${currentStatus}'`,
      );
    }

    // Verify team membership
    const teamId = jobData.teamId;
    if (teamId) {
      const teamRef = db.collection(teamsCollectionPath).doc(teamId);
      const teamDoc = await teamRef.get();

      if (!teamDoc.exists) {
        throw new HttpsError("not-found", "Team not found");
      }

      const teamData = teamDoc.data()!;
      const members: string[] = teamData.members || [];

      if (!members.includes(callerUid)) {
        throw new HttpsError("permission-denied", "You are not a member of this team");
      }
    }

    // Update build job status to cancelled
    await jobRef.update({
      status: "cancelled",
    });

    // If the job has a check run, update it to cancelled via the worker
    // The worker will detect the cancelled status and handle GitHub check run update

    logger.info(`Build job cancelled: ${buildJobId}`, {
      callerUid,
      teamId,
      previousStatus: currentStatus,
    });

    return { success: true };
  },
);
