import { SecretManagerServiceClient } from "@google-cloud/secret-manager";
import { FieldValue } from "firebase-admin/firestore";
import { onCall } from "firebase-functions/https";
import * as logger from "firebase-functions/logger";
import { v4 as uuidv4 } from "uuid";

import { db } from "./firebase";
import { secretsCollectionPath } from "./firestore-collection-paths";

const secretManagerClient = new SecretManagerServiceClient();

export const createSecretV1 = onCall(
  {
    region: "asia-northeast1",
  },
  async (request) => {
    if (!request.auth) {
      throw new Error("Unauthenticated");
    }

    const userId = request.auth.uid;
    const { name, value } = request.data as { name: string; value: string };

    if (!name || !value) {
      throw new Error("Missing name or value");
    }

    const projectId = process.env.GCLOUD_PROJECT || process.env.GCP_PROJECT;
    if (!projectId) {
      throw new Error("Project ID not found");
    }

    const secretId = `user-${userId}-${name}`;
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
          userId,
          pathToSecret: `${parent}/secrets/${secretId}`,
          createdAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        });

      logger.info(`Secret created: ${secretId}`, { userId, name });

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
          .where("userId", "==", userId)
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
              userId,
              pathToSecret: `${parent}/secrets/${secretId}`,
              createdAt: FieldValue.serverTimestamp(),
              updatedAt: FieldValue.serverTimestamp(),
            });
          logger.info(`Secret document created for existing secret: ${secretId}`, { userId, name });
        } else {
          documentId = existingDocs.docs[0].id;
        }

        logger.info(`Secret updated: ${secretId}`, { userId, name });
        return { success: true, documentId };
      }

      logger.error("Failed to create secret", error);
      throw new Error(`Failed to create secret: ${error.message}`);
    }
  },
);
