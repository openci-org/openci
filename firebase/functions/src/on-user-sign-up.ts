import { FieldValue } from "firebase-admin/firestore";
import * as logger from "firebase-functions/logger";
import { beforeUserCreated } from "firebase-functions/v2/identity";

import { db } from "./firebase";
import { teamsCollectionPath, usersCollectionPath } from "./firestore-collection-paths";

export const onUserSignUp = beforeUserCreated(
  {
    region: "asia-northeast1",
  },
  async (event) => {
    if (!event.data) {
      throw new Error("No user data in event");
    }

    const userId = event.data.uid;
    const email = event.data.email;

    if (!email) {
      throw new Error("No email found for user");
    }

    const batch = db.batch();

    const teamsRef = db.collection(teamsCollectionPath).doc();
    const teamId = teamsRef.id;

    batch.set(teamsRef, {
      id: teamId,
      name: teamId,
      members: [userId],
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });

    const userRef = db.collection(usersCollectionPath).doc(userId);
    batch.set(userRef, {
      id: userId,
      selectedTeamId: teamId,
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });

    await batch.commit();

    logger.info(`Created personal team ${teamId} for user ${userId}`);
  },
);
