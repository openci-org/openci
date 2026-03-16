import { SecretManagerServiceClient } from "@google-cloud/secret-manager";
import { HttpsError, onCall } from "firebase-functions/https";
import * as logger from "firebase-functions/logger";

import { db } from "./firebase";
import { secretsCollectionPath, teamsCollectionPath } from "./firestore-collection-paths";

const secretManagerClient = new SecretManagerServiceClient();

export const deleteSecretV1 = onCall(
  {
    region: "asia-northeast1",
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Unauthenticated");
    }

    const callerUid = request.auth.uid;
    const { documentId, teamId } = request.data as { documentId: string; teamId: string };

    if (!documentId || !teamId) {
      throw new HttpsError("invalid-argument", "Missing documentId or teamId");
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

    const secretDocRef = db.collection(secretsCollectionPath).doc(documentId);
    const secretDoc = await secretDocRef.get();

    if (!secretDoc.exists) {
      throw new HttpsError("not-found", "Secret not found");
    }

    const secretData = secretDoc.data()!;

    if (secretData.teamId !== teamId) {
      throw new HttpsError("permission-denied", "Secret does not belong to this team");
    }

    try {
      const pathToSecret = secretData.pathToSecret as string | undefined;
      if (pathToSecret) {
        await secretManagerClient.deleteSecret({ name: pathToSecret }).catch((err: any) => {
          logger.warn(`Failed to delete from Secret Manager: ${err.message}`, { pathToSecret });
        });
      }

      await secretDocRef.delete();

      logger.info(`Secret deleted: ${documentId}`, { teamId, name: secretData.name });

      return { success: true };
    } catch (error: any) {
      logger.error("Failed to delete secret", error);
      throw new HttpsError("internal", `Failed to delete secret: ${error.message}`);
    }
  },
);
