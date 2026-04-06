import { generateKeyPairSync } from "crypto";
import { FieldValue } from "firebase-admin/firestore";
import { SecretManagerServiceClient } from "@google-cloud/secret-manager";
import { HttpsError, onCall } from "firebase-functions/https";
import * as logger from "firebase-functions/logger";
import { v4 as uuidv4 } from "uuid";

import { db } from "./firebase";
import { secretsCollectionPath, teamsCollectionPath } from "./firestore-collection-paths";

const secretManagerClient = new SecretManagerServiceClient();

export const generateCertificateKeyV1 = onCall(
  {
    region: "asia-northeast1",
  },
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
    const members: string[] = teamData.members || [];

    if (!members.includes(callerUid)) {
      throw new HttpsError("permission-denied", "You are not a member of this team");
    }

    const secretName = "OPENCI_CERTIFICATE_PRIVATE_KEY";

    const duplicateCheck = await db
      .collection(secretsCollectionPath)
      .where("teamId", "==", teamId)
      .where("name", "==", secretName)
      .limit(1)
      .get();

    if (!duplicateCheck.empty) {
      throw new HttpsError(
        "already-exists",
        `Secret "${secretName}" already exists. Delete the existing one first to regenerate.`,
      );
    }

    const projectId = process.env.GCLOUD_PROJECT || process.env.GCP_PROJECT;
    if (!projectId) {
      throw new HttpsError("internal", "Project ID not found");
    }

    try {
      const { privateKey } = generateKeyPairSync("rsa", {
        modulusLength: 2048,
        privateKeyEncoding: { type: "pkcs8", format: "pem" },
        publicKeyEncoding: { type: "spki", format: "pem" },
      });

      const secretId = uuidv4();
      const parent = `projects/${projectId}`;

      await secretManagerClient.createSecret({
        parent,
        secretId,
        secret: {
          replication: {
            userManaged: {
              replicas: [{ location: "asia-northeast1" }],
            },
          },
        },
      });

      await secretManagerClient.addSecretVersion({
        parent: `${parent}/secrets/${secretId}`,
        payload: {
          data: Buffer.from(privateKey, "utf8"),
        },
      });

      const documentId = uuidv4();
      await db
        .collection(secretsCollectionPath)
        .doc(documentId)
        .set({
          id: documentId,
          name: secretName,
          teamId,
          pathToSecret: `${parent}/secrets/${secretId}`,
          createdAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        });

      logger.info(`Certificate key generated: ${secretId}`, { teamId, secretName });

      return { success: true, documentId };
    } catch (error: any) {
      logger.error("Failed to generate certificate key", error);
      throw new HttpsError("internal", `Failed to generate certificate key: ${error.message}`);
    }
  },
);
