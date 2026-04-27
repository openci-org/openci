import { HttpsError } from "firebase-functions/v2/https";
import type { CallableRequest } from "firebase-functions/v2/https";

import { verifyTeamMembership } from "../team/teamAuth";
import { getBuildJobOrThrow, type BuildJob } from "./services";

function requireAuth(auth: CallableRequest["auth"]): NonNullable<CallableRequest["auth"]> {
  if (!auth) {
    throw new HttpsError("unauthenticated", "Unauthenticated");
  }
  return auth;
}

export async function verifyBuildJobMembership(
  auth: CallableRequest["auth"],
  buildJobId: string,
): Promise<BuildJob> {
  const callerAuth = requireAuth(auth);
  let buildJob: BuildJob;

  try {
    buildJob = await getBuildJobOrThrow(buildJobId);
  } catch (error) {
    if (error instanceof Error && error.message === "Build job not found") {
      throw new HttpsError("not-found", "Build job not found");
    }
    throw error;
  }

  const teamId =
    typeof buildJob.teamId === "string" && buildJob.teamId.length > 0 ? buildJob.teamId : undefined;
  if (!teamId) {
    throw new HttpsError("failed-precondition", "Build job is not associated with a team");
  }

  await verifyTeamMembership(callerAuth, teamId);
  return buildJob;
}
