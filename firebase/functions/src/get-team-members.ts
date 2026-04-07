import { getAuth } from "firebase-admin/auth";
import { HttpsError, onCall } from "firebase-functions/https";

import { db } from "./firebase";
import { teamsCollectionPath } from "./firestore-collection-paths";

export const getTeamMembers = onCall(
  { region: "asia-northeast1" },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Unauthenticated");
    }

    const callerUid = request.auth.uid;
    const { teamId } = request.data as { teamId: string };

    if (!teamId) {
      throw new HttpsError("invalid-argument", "Missing teamId");
    }

    const teamRef = db.collection(teamsCollectionPath).doc(teamId);
    const teamDoc = await teamRef.get();

    if (!teamDoc.exists) {
      throw new HttpsError("not-found", "Team not found");
    }

    const teamData = teamDoc.data()!;
    const memberUids: string[] = teamData.members || [];

    if (!memberUids.includes(callerUid)) {
      throw new HttpsError("permission-denied", "You are not a member of this team");
    }

    // Resolve UIDs to user info via Firebase Auth
    const members = await Promise.all(
      memberUids.map(async (uid) => {
        try {
          const userRecord = await getAuth().getUser(uid);
          return {
            uid,
            email: userRecord.email ?? null,
            displayName: userRecord.displayName ?? null,
            photoURL: userRecord.photoURL ?? null,
          };
        } catch {
          return {
            uid,
            email: null,
            displayName: null,
            photoURL: null,
          };
        }
      }),
    );

    return { members };
  },
);
