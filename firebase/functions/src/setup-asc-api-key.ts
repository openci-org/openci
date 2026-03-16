import { FieldValue } from "firebase-admin/firestore";
import { SecretManagerServiceClient } from "@google-cloud/secret-manager";
import { HttpsError, onCall } from "firebase-functions/https";
import * as logger from "firebase-functions/logger";
import { v4 as uuidv4 } from "uuid";

import { db } from "./firebase";
import { secretsCollectionPath, teamsCollectionPath } from "./firestore-collection-paths";

const secretManagerClient = new SecretManagerServiceClient();

const ASC_SECRET_NAMES = [
  "OPENCI_ASC_ISSUER_ID",
  "OPENCI_ASC_KEY_ID",
  "OPENCI_ASC_PRIVATE_KEY",
] as const;

async function createSecretInManager(
  projectId: string,
  name: string,
  value: string,
  teamId: string,
): Promise<string> {
  const secretId = uuidv4();
  const parent = `projects/${projectId}`;

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

  return documentId;
}

export const setupAscApiKeyV1 = onCall(
  {
    region: "asia-northeast1",
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Unauthenticated");
    }

    const callerUid = request.auth.uid;
    const { teamId, issuerId, keyId, privateKey } = request.data as {
      teamId: string;
      issuerId: string;
      keyId: string;
      privateKey: string;
    };

    if (!teamId || !issuerId || !keyId || !privateKey) {
      throw new HttpsError("invalid-argument", "Missing required fields");
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

    const existingSecrets = await db
      .collection(secretsCollectionPath)
      .where("teamId", "==", teamId)
      .where("name", "in", ASC_SECRET_NAMES)
      .get();

    if (!existingSecrets.empty) {
      const existingNames = existingSecrets.docs.map((doc) => doc.data().name);
      throw new HttpsError(
        "already-exists",
        `ASC API Key secrets already exist: ${existingNames.join(", ")}. Delete them first to reconfigure.`,
      );
    }

    const projectId = process.env.GCLOUD_PROJECT || process.env.GCP_PROJECT;
    if (!projectId) {
      throw new HttpsError("internal", "Project ID not found");
    }

    try {
      const values: Record<string, string> = {
        OPENCI_ASC_ISSUER_ID: issuerId,
        OPENCI_ASC_KEY_ID: keyId,
        OPENCI_ASC_PRIVATE_KEY: privateKey,
      };

      const results: Record<string, string> = {};

      for (const [name, value] of Object.entries(values)) {
        results[name] = await createSecretInManager(projectId, name, value, teamId);
      }

      logger.info("ASC API Key setup complete", { teamId, secrets: Object.keys(results) });

      return { success: true, documentIds: results };
    } catch (error: any) {
      if (error instanceof HttpsError) throw error;
      logger.error("Failed to setup ASC API Key", error);
      throw new HttpsError("internal", `Failed to setup ASC API Key: ${error.message}`);
    }
  },
);
