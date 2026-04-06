import { SecretManagerServiceClient } from "@google-cloud/secret-manager";
import { HttpsError, onCall } from "firebase-functions/https";
import * as logger from "firebase-functions/logger";
import { v4 as uuidv4 } from "uuid";

import { db } from "./firebase";
import { secretsCollectionPath } from "./firestore-collection-paths";

const secretManagerClient = new SecretManagerServiceClient();

export const migrateSecretsReplicationV1 = onCall(
  {
    region: "asia-northeast1",
    timeoutSeconds: 540,
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Unauthenticated");
    }

    const projectId = process.env.GCLOUD_PROJECT || process.env.GCP_PROJECT;
    if (!projectId) {
      throw new HttpsError("internal", "Project ID not found");
    }

    const secretsSnapshot = await db.collection(secretsCollectionPath).get();

    if (secretsSnapshot.empty) {
      return { migrated: 0, skipped: 0, failed: 0, details: [] };
    }

    let migrated = 0;
    let skipped = 0;
    let failed = 0;
    const details: { name: string; status: string; reason?: string }[] = [];

    for (const doc of secretsSnapshot.docs) {
      const data = doc.data();
      const secretName = data.name as string;
      const oldPath = data.pathToSecret as string | undefined;

      if (!oldPath) {
        skipped++;
        details.push({ name: secretName, status: "skipped", reason: "no pathToSecret" });
        continue;
      }

      try {
        const [secret] = await secretManagerClient.getSecret({ name: oldPath });
        const replication = secret.replication;

        if (replication?.userManaged) {
          skipped++;
          details.push({ name: secretName, status: "skipped", reason: "already userManaged" });
          continue;
        }

        const [version] = await secretManagerClient.accessSecretVersion({
          name: `${oldPath}/versions/latest`,
        });
        const secretValue = version.payload?.data;
        if (!secretValue) {
          failed++;
          details.push({ name: secretName, status: "failed", reason: "could not read secret value" });
          continue;
        }

        const newSecretId = uuidv4();
        const parent = `projects/${projectId}`;
        const newPath = `${parent}/secrets/${newSecretId}`;

        await secretManagerClient.createSecret({
          parent,
          secretId: newSecretId,
          secret: {
            replication: {
              userManaged: {
                replicas: [{ location: "asia-northeast1" }],
              },
            },
          },
        });

        await secretManagerClient.addSecretVersion({
          parent: newPath,
          payload: { data: secretValue },
        });

        await db.collection(secretsCollectionPath).doc(doc.id).update({
          pathToSecret: newPath,
        });

        await secretManagerClient.deleteSecret({ name: oldPath }).catch((err: any) => {
          logger.warn(`Failed to delete old secret: ${err.message}`, { oldPath });
        });

        migrated++;
        details.push({ name: secretName, status: "migrated" });
        logger.info(`Migrated secret: ${secretName}`, { oldPath, newPath });
      } catch (error: any) {
        failed++;
        details.push({ name: secretName, status: "failed", reason: error.message });
        logger.error(`Failed to migrate secret: ${secretName}`, error);
      }
    }

    logger.info("Migration complete", { migrated, skipped, failed });
    return { migrated, skipped, failed, details };
  },
);
