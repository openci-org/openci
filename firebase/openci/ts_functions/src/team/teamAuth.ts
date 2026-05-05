import { HttpsError } from "firebase-functions/v2/https";
import type { CallableRequest } from "firebase-functions/v2/https";

import { getTeamForMember } from "@openci/firestore-data";

export async function verifyTeamMembership(
  auth: CallableRequest["auth"],
  teamId: string,
): Promise<NonNullable<Awaited<ReturnType<typeof getTeamForMember>>["data"]["team"]>> {
  if (!auth) {
    throw new HttpsError("unauthenticated", "Unauthenticated");
  }

  const result = await getTeamForMember({ teamId }, { impersonate: { authClaims: auth.token } });
  const team = result.data.team;
  if (!team) {
    throw new HttpsError("not-found", "Team not found");
  }

  return team;
}
