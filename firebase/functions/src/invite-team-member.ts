import { getAuth } from "firebase-admin/auth";
import { FieldValue } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/https";
import * as logger from "firebase-functions/logger";

import { db } from "./firebase";
import { teamsCollectionPath } from "./firestore-collection-paths";

export const inviteTeamMember = onCall(
  {
    region: "asia-northeast1",
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Unauthenticated");
    }

    const callerUid = request.auth.uid;
    const { email, teamId } = request.data as { email: string; teamId: string };

    if (!email || !teamId) {
      throw new HttpsError("invalid-argument", "Missing email or teamId");
    }

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

    let inviteeUid: string;
    try {
      const userRecord = await getAuth().getUserByEmail(email);
      inviteeUid = userRecord.uid;
    } catch (error: any) {
      if (error.code === "auth/user-not-found") {
        throw new HttpsError("not-found", `No user found with email: ${email}`);
      }
      throw new HttpsError("internal", error.message);
    }

    if (members.includes(inviteeUid)) {
      throw new HttpsError("already-exists", "User is already a member of this team");
    }

    await teamRef.update({
      members: FieldValue.arrayUnion(inviteeUid),
      updatedAt: FieldValue.serverTimestamp(),
    });

    logger.info(`User ${inviteeUid} added to team ${teamId} by ${callerUid}`);

    return { success: true, inviteeUid };
  },
);
