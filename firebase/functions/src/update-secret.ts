import { SecretManagerServiceClient } from "@google-cloud/secret-manager";
import { FieldValue } from "firebase-admin/firestore";
import { HttpsError, onCall } from "firebase-functions/https";
import * as logger from "firebase-functions/logger";

import { db } from "./firebase";
import {
  secretsCollectionPath,
  teamsCollectionPath,
  workflowsCollectionPath,
} from "./firestore-collection-paths";

const secretManagerClient = new SecretManagerServiceClient();

export const updateSecretV1 = onCall(
  {
    region: "asia-northeast1",
  },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Unauthenticated");
    }

    const callerUid = request.auth.uid;
    const { documentId, name, value, teamId } = request.data as {
      documentId: string;
      name: string;
      value?: string;
      teamId: string;
    };

    if (!documentId || !name || !teamId) {
      throw new HttpsError("invalid-argument", "Missing documentId, name, or teamId");
    }

    // Verify team membership
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

    // Get existing secret document
    const secretRef = db.collection(secretsCollectionPath).doc(documentId);
    const secretDoc = await secretRef.get();

    if (!secretDoc.exists) {
      throw new HttpsError("not-found", "Secret not found");
    }

    const secretData = secretDoc.data()!;

    if (secretData.teamId !== teamId) {
      throw new HttpsError("permission-denied", "Secret does not belong to this team");
    }

    const oldName = secretData.name as string;

    // Check for duplicate name (only if name is being changed)
    if (name !== oldName) {
      const duplicateCheck = await db
        .collection(secretsCollectionPath)
        .where("teamId", "==", teamId)
        .where("name", "==", name)
        .limit(1)
        .get();

      if (!duplicateCheck.empty) {
        throw new HttpsError("already-exists", `Secret with name "${name}" already exists`);
      }
    }

    const projectId = process.env.GCLOUD_PROJECT || process.env.GCP_PROJECT;
    if (!projectId) {
      throw new HttpsError("internal", "Project ID not found");
    }

    try {
      // Update secret value in Secret Manager if a new value is provided
      if (value) {
        const pathToSecret = secretData.pathToSecret as string;
        await secretManagerClient.addSecretVersion({
          parent: pathToSecret,
          payload: {
            data: Buffer.from(value, "utf8"),
          },
        });
        logger.info(`Secret value updated for: ${documentId}`, { teamId, name });
      }

      // Update Firestore document
      await secretRef.update({
        name,
        updatedAt: FieldValue.serverTimestamp(),
      });

      // If name changed, update all workflows that reference this secret
      if (name !== oldName) {
        const workflowsSnapshot = await db
          .collection(workflowsCollectionPath)
          .where("teamId", "==", teamId)
          .get();

        const batch = db.batch();
        let updatedCount = 0;

        for (const workflowDoc of workflowsSnapshot.docs) {
          const workflowData = workflowDoc.data();
          const steps = workflowData.workflowSteps as any[];
          let hasChanges = false;

          const updatedSteps = steps.map((step) => {
            const requiredSecrets = (step.requiredSecrets as any[]) || [];
            const updatedSecrets = requiredSecrets.map((secret: any) => {
              if (secret.secretDocumentId === documentId) {
                hasChanges = true;
                return { ...secret, key: name };
              }
              return secret;
            });
            return { ...step, requiredSecrets: updatedSecrets };
          });

          if (hasChanges) {
            batch.update(workflowDoc.ref, { workflowSteps: updatedSteps });
            updatedCount++;
          }
        }

        if (updatedCount > 0) {
          await batch.commit();
          logger.info(`Updated ${updatedCount} workflows with new secret name`, {
            teamId,
            oldName,
            newName: name,
          });
        }
      }

      logger.info(`Secret updated: ${documentId}`, { teamId, name });
      return { success: true };
    } catch (error: any) {
      logger.error("Failed to update secret", error);
      throw new HttpsError("internal", `Failed to update secret: ${error.message}`);
    }
  },
);
