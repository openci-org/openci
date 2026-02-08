import { SecretManagerServiceClient } from "@google-cloud/secret-manager";
import { FieldValue } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/https";
import * as logger from "firebase-functions/logger";
import { v4 as uuidv4 } from "uuid";

import { db } from "./firebase";
import { secretsCollectionPath, teamsCollectionPath } from "./firestore-collection-paths";

const secretManagerClient = new SecretManagerServiceClient();

export const createSecretV1 = onCall(
  {
    region: "asia-northeast1",
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Unauthenticated");
    }

    const callerUid = request.auth.uid;
    const { name, value, teamId } = request.data as { name: string; value: string; teamId: string };

    if (!name || !value || !teamId) {
      throw new HttpsError("invalid-argument", "Missing name, value, or teamId");
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

    const projectId = process.env.GCLOUD_PROJECT || process.env.GCP_PROJECT;
    if (!projectId) {
      throw new HttpsError("internal", "Project ID not found");
    }

    const secretId = uuidv4();
    const parent = `projects/${projectId}`;

    try {
      await secretManagerClient.createSecret({
        parent,
        secretId,
        secret: {
          replication: {
            automatic: {},
          },
        },
      });

      await secretManagerClient.addSecretVersion({
        parent: `${parent}/secrets/${secretId}`,
        payload: {
          data: Buffer.from(value, "utf8"),
        },
      });

      const documentId = uuidv4();
      await db
        .collection(secretsCollectionPath)
        .doc(documentId)
        .set({
          id: documentId,
          name,
          teamId,
          pathToSecret: `${parent}/secrets/${secretId}`,
          createdAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        });

      logger.info(`Secret created: ${secretId}`, { teamId, name });

      return { success: true, documentId };
    } catch (error: any) {
      if (error.code === 6) {
        await secretManagerClient.addSecretVersion({
          parent: `${parent}/secrets/${secretId}`,
          payload: {
            data: Buffer.from(value, "utf8"),
          },
        });

        const existingDocs = await db
          .collection(secretsCollectionPath)
          .where("teamId", "==", teamId)
          .where("name", "==", name)
          .limit(1)
          .get();

        let documentId: string;
        if (existingDocs.empty) {
          documentId = uuidv4();
          await db
            .collection(secretsCollectionPath)
            .doc(documentId)
            .set({
              id: documentId,
              name,
              teamId,
              pathToSecret: `${parent}/secrets/${secretId}`,
              createdAt: FieldValue.serverTimestamp(),
              updatedAt: FieldValue.serverTimestamp(),
            });
          logger.info(`Secret document created for existing secret: ${secretId}`, { teamId, name });
        } else {
          documentId = existingDocs.docs[0].id;
        }

        logger.info(`Secret updated: ${secretId}`, { teamId, name });
        return { success: true, documentId };
      }

      logger.error("Failed to create secret", error);
      throw new HttpsError("internal", `Failed to create secret: ${error.message}`);
    }
  },
);
