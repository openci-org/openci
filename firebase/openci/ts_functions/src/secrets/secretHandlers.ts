import { generateKeyPairSync, randomUUID } from "node:crypto";

import { logger } from "firebase-functions/v2";
import { HttpsError, onCall } from "firebase-functions/v2/https";

import {
  createSecretMetadata,
  deleteSecretMetadata,
  findSecretByNameForTeam,
  getSecretPathForTeam,
  listWorkflowsForTeam,
  updateSecretMetadata,
  updateWorkflowSecretKeys,
} from "@openci/dataconnect-admin";
import {
  addSecretVersionByPath,
  createSecretWithValue,
  deleteSecretByPath,
} from "../secretManager";
import { verifyTeamMembership } from "../team/teamAuth";

interface CreateSecretRequest {
  name: string;
  value: string;
  teamId: string;
}

interface DeleteSecretRequest {
  documentId: string;
  teamId: string;
}

interface UpdateSecretRequest extends DeleteSecretRequest {
  name: string;
  value?: string;
}

interface GenerateCertificateKeyRequest {
  teamId: string;
}

interface SetupAscApiKeyRequest {
  teamId: string;
  issuerId: string;
  keyId: string;
  privateKey: string;
}

interface SuccessResponse {
  success: true;
}

function requireNonEmptyString(value: unknown, field: string): string {
  if (typeof value !== "string" || value.length === 0) {
    throw new HttpsError("invalid-argument", `${field} is required`);
  }
  return value;
}

async function assertSecretNameAvailable(teamId: string, name: string): Promise<void> {
  const duplicateCheck = await findSecretByNameForTeam({ teamId, name });

  if (duplicateCheck.data.secrets.length > 0) {
    throw new HttpsError("already-exists", `Secret with name "${name}" already exists`);
  }
}

async function createStoredSecret(teamId: string, name: string, value: string): Promise<string> {
  const secretId = randomUUID();
  const pathToSecret = await createSecretWithValue(secretId, value);
  const documentId = randomUUID();
  await createSecretMetadata({ id: documentId, name, teamId, pathToSecret });
  return documentId;
}

async function getSecretForTeam(
  documentId: string,
  teamId: string,
): Promise<{
  data: {
    id: string;
    name: string;
    teamId: string;
    pathToSecret?: string | null;
  };
}> {
  const result = await getSecretPathForTeam({ id: documentId, teamId });
  const secret = result.data.secret;
  if (!secret) {
    throw new HttpsError("not-found", "Secret not found");
  }
  return { data: secret };
}

export const createSecretV1 = onCall<
  CreateSecretRequest,
  Promise<SuccessResponse & { documentId: string }>
>(async (request) => {
  const teamId = requireNonEmptyString(request.data?.teamId, "teamId");
  const name = requireNonEmptyString(request.data?.name, "name");
  const value = requireNonEmptyString(request.data?.value, "value");
  await verifyTeamMembership(request.auth, teamId);
  await assertSecretNameAvailable(teamId, name);

  try {
    const documentId = await createStoredSecret(teamId, name, value);
    logger.info("Secret created", { teamId, name, documentId });
    return { success: true, documentId };
  } catch (error) {
    if (error instanceof HttpsError) throw error;
    logger.error("Failed to create secret", { teamId, name, error });
    throw new HttpsError("internal", `Failed to create secret: ${String(error)}`);
  }
});

export const deleteSecretV1 = onCall<DeleteSecretRequest, Promise<SuccessResponse>>(
  async (request) => {
    const teamId = requireNonEmptyString(request.data?.teamId, "teamId");
    const documentId = requireNonEmptyString(request.data?.documentId, "documentId");
    await verifyTeamMembership(request.auth, teamId);
    const { data } = await getSecretForTeam(documentId, teamId);

    try {
      if (typeof data.pathToSecret === "string" && data.pathToSecret.length > 0) {
        try {
          await deleteSecretByPath(data.pathToSecret);
        } catch (error) {
          logger.warn("Failed to delete from Secret Manager", {
            pathToSecret: data.pathToSecret,
            error,
          });
        }
      }

      await deleteSecretMetadata({ id: documentId });
      logger.info("Secret deleted", { teamId, documentId, name: data.name });
      return { success: true };
    } catch (error) {
      if (error instanceof HttpsError) throw error;
      logger.error("Failed to delete secret", { teamId, documentId, error });
      throw new HttpsError("internal", `Failed to delete secret: ${String(error)}`);
    }
  },
);

export const updateSecretV1 = onCall<UpdateSecretRequest, Promise<SuccessResponse>>(
  async (request) => {
    const teamId = requireNonEmptyString(request.data?.teamId, "teamId");
    const documentId = requireNonEmptyString(request.data?.documentId, "documentId");
    const name = requireNonEmptyString(request.data?.name, "name");
    await verifyTeamMembership(request.auth, teamId);
    const { data } = await getSecretForTeam(documentId, teamId);
    const oldName = typeof data.name === "string" ? data.name : "";

    if (name !== oldName) {
      await assertSecretNameAvailable(teamId, name);
    }

    try {
      if (typeof request.data?.value === "string") {
        const pathToSecret = requireNonEmptyString(data.pathToSecret, "pathToSecret");
        await addSecretVersionByPath(pathToSecret, request.data.value);
      }

      await updateSecretMetadata({ id: documentId, name });

      if (name !== oldName) {
        const workflowsResult = await listWorkflowsForTeam({ teamId });

        for (const workflowData of workflowsResult.data.workflows) {
          const steps = Array.isArray(workflowData.workflowSteps) ? workflowData.workflowSteps : [];
          let hasChanges = false;
          const updatedSteps = steps.map((step) => {
            const stepMap =
              typeof step === "object" && step !== null ? (step as Record<string, unknown>) : {};
            const requiredSecrets = Array.isArray(stepMap.requiredSecrets)
              ? stepMap.requiredSecrets
              : [];
            const updatedSecrets = requiredSecrets.map((secret) => {
              const secretMap =
                typeof secret === "object" && secret !== null
                  ? (secret as Record<string, unknown>)
                  : {};
              if (secretMap.secretDocumentId === documentId) {
                hasChanges = true;
                return { ...secretMap, key: name };
              }
              return secretMap;
            });
            return { ...stepMap, requiredSecrets: updatedSecrets };
          });

          if (hasChanges) {
            await updateWorkflowSecretKeys({ id: workflowData.id, workflowSteps: updatedSteps });
          }
        }
      }

      logger.info("Secret updated", { teamId, documentId, name });
      return { success: true };
    } catch (error) {
      if (error instanceof HttpsError) throw error;
      logger.error("Failed to update secret", { teamId, documentId, error });
      throw new HttpsError("internal", `Failed to update secret: ${String(error)}`);
    }
  },
);

export const generateCertificateKeyV1 = onCall<
  GenerateCertificateKeyRequest,
  Promise<SuccessResponse & { documentId: string }>
>(async (request) => {
  const teamId = requireNonEmptyString(request.data?.teamId, "teamId");
  const secretName = "OPENCI_CERTIFICATE_PRIVATE_KEY";
  await verifyTeamMembership(request.auth, teamId);
  await assertSecretNameAvailable(teamId, secretName);

  try {
    const { privateKey } = generateKeyPairSync("rsa", {
      modulusLength: 2048,
      privateKeyEncoding: { type: "pkcs8", format: "pem" },
      publicKeyEncoding: { type: "spki", format: "pem" },
    });
    const documentId = await createStoredSecret(teamId, secretName, privateKey);
    logger.info("Certificate key generated", { teamId, documentId });
    return { success: true, documentId };
  } catch (error) {
    if (error instanceof HttpsError) throw error;
    logger.error("Failed to generate certificate key", { teamId, error });
    throw new HttpsError("internal", `Failed to generate certificate key: ${String(error)}`);
  }
});

export const setupAscApiKeyV1 = onCall<
  SetupAscApiKeyRequest,
  Promise<SuccessResponse & { documentIds: Record<string, string> }>
>(async (request) => {
  const teamId = requireNonEmptyString(request.data?.teamId, "teamId");
  const issuerId = requireNonEmptyString(request.data?.issuerId, "issuerId");
  const keyId = requireNonEmptyString(request.data?.keyId, "keyId");
  const privateKey = requireNonEmptyString(request.data?.privateKey, "privateKey");
  await verifyTeamMembership(request.auth, teamId);

  const ascSecretNames = ["OPENCI_ASC_ISSUER_ID", "OPENCI_ASC_KEY_ID", "OPENCI_ASC_PRIVATE_KEY"];
  const existingSecrets = await Promise.all(
    ascSecretNames.map((name) => findSecretByNameForTeam({ teamId, name })),
  );
  const existingNames = existingSecrets.flatMap((result) =>
    result.data.secrets.map((secret) => secret.name),
  );

  if (existingNames.length > 0) {
    throw new HttpsError(
      "already-exists",
      `ASC API Key secrets already exist: ${existingNames}. Delete them first to reconfigure.`,
    );
  }

  try {
    const values = {
      OPENCI_ASC_ISSUER_ID: issuerId,
      OPENCI_ASC_KEY_ID: keyId,
      OPENCI_ASC_PRIVATE_KEY: privateKey,
    };
    const documentIds: Record<string, string> = {};

    for (const [name, value] of Object.entries(values)) {
      documentIds[name] = await createStoredSecret(teamId, name, value);
    }

    logger.info("ASC API Key setup complete", { teamId, secrets: Object.keys(documentIds) });
    return { success: true, documentIds };
  } catch (error) {
    if (error instanceof HttpsError) throw error;
    logger.error("Failed to setup ASC API Key", { teamId, error });
    throw new HttpsError("internal", `Failed to setup ASC API Key: ${String(error)}`);
  }
});
