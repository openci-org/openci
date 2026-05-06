import { generateKeyPairSync, randomBytes, randomUUID } from "node:crypto";
import { mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { promisify } from "node:util";
import { execFile } from "node:child_process";

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
} from "../firestoreData";
import {
  accessSecretByPath,
  addSecretVersionByPath,
  createSecretWithValue,
  deleteSecretByPath,
} from "../secretManager";
import { verifyTeamMembership } from "../team/teamAuth";

const execFileAsync = promisify(execFile);

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

interface RegisterDeveloperIdCertificateRequest {
  teamId: string;
  certificateBase64: string;
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

const developerIdPrivateKeySecretName = "OPENCI_DEVELOPER_ID_PRIVATE_KEY";
const developerIdCertificateP12SecretName = "OPENCI_DEVELOPER_ID_CERTIFICATE_P12";
const developerIdCertificatePasswordSecretName = "OPENCI_DEVELOPER_ID_CERTIFICATE_PASSWORD";

function requireNonEmptyString(value: unknown, field: string): string {
  if (typeof value !== "string" || value.length === 0) {
    throw new HttpsError("invalid-argument", `${field} is required`);
  }
  return value;
}

function emailAddressFromAuth(auth: { token?: { email?: unknown } } | undefined): string {
  const email = auth?.token?.email;
  if (typeof email === "string" && email.includes("@")) {
    return email;
  }
  return "developer@openci.io";
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

async function findSingleSecretForTeam(teamId: string, name: string) {
  const result = await findSecretByNameForTeam({ teamId, name });
  const secrets = result.data.secrets;
  if (secrets.length === 0) {
    throw new HttpsError("failed-precondition", `Secret "${name}" is not configured`);
  }
  return secrets[0] as { id: string; name: string; teamId: string; pathToSecret?: string | null };
}

async function runOpenSsl(args: string[], cwd: string): Promise<void> {
  try {
    await execFileAsync("openssl", args, { cwd });
  } catch (error) {
    logger.error("openssl command failed", { args, error });
    throw new HttpsError("internal", "Failed to process certificate with openssl");
  }
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
          const updatedSteps = steps.map((step: unknown) => {
            const stepMap =
              typeof step === "object" && step !== null ? (step as Record<string, unknown>) : {};
            const requiredSecrets = Array.isArray(stepMap.requiredSecrets)
              ? stepMap.requiredSecrets
              : [];
            const updatedSecrets = requiredSecrets.map((secret: unknown) => {
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

export const generateDeveloperIdCsrV1 = onCall<
  GenerateCertificateKeyRequest,
  Promise<SuccessResponse & { documentId: string; csrPem: string }>
>(async (request) => {
  const teamId = requireNonEmptyString(request.data?.teamId, "teamId");
  await verifyTeamMembership(request.auth, teamId);
  await assertSecretNameAvailable(teamId, developerIdPrivateKeySecretName);

  const tmpDir = await mkdtemp(join(tmpdir(), "openci-developer-id-csr-"));
  try {
    const keyPath = join(tmpDir, "developer-id.key.pem");
    const csrPath = join(tmpDir, "developer-id.csr.pem");
    const { privateKey } = generateKeyPairSync("rsa", {
      modulusLength: 2048,
      privateKeyEncoding: { type: "pkcs8", format: "pem" },
      publicKeyEncoding: { type: "spki", format: "pem" },
    });
    await writeFile(keyPath, privateKey, "utf8");
    await runOpenSsl(
      [
        "req",
        "-new",
        "-key",
        keyPath,
        "-out",
        csrPath,
        "-subj",
        `/emailAddress=${emailAddressFromAuth(request.auth)}/CN=OpenCI Developer ID Application/C=JP/O=OpenCI`,
      ],
      tmpDir,
    );
    const csrPem = await readFile(csrPath, "utf8");
    const documentId = await createStoredSecret(teamId, developerIdPrivateKeySecretName, privateKey);
    logger.info("Developer ID CSR generated", { teamId, documentId });
    return { success: true, documentId, csrPem };
  } catch (error) {
    if (error instanceof HttpsError) throw error;
    logger.error("Failed to generate Developer ID CSR", { teamId, error });
    throw new HttpsError("internal", `Failed to generate Developer ID CSR: ${String(error)}`);
  } finally {
    await rm(tmpDir, { recursive: true, force: true });
  }
});

export const registerDeveloperIdCertificateV1 = onCall<
  RegisterDeveloperIdCertificateRequest,
  Promise<SuccessResponse & { documentIds: Record<string, string> }>
>(async (request) => {
  const teamId = requireNonEmptyString(request.data?.teamId, "teamId");
  const certificateBase64 = requireNonEmptyString(request.data?.certificateBase64, "certificateBase64");
  await verifyTeamMembership(request.auth, teamId);

  const finalSecretNames = [
    developerIdCertificateP12SecretName,
    developerIdCertificatePasswordSecretName,
  ];
  const existingFinalSecrets = await Promise.all(
    finalSecretNames.map((name) => findSecretByNameForTeam({ teamId, name })),
  );
  const existingNames = existingFinalSecrets.flatMap((result) =>
    result.data.secrets.map((secret: { name: string }) => secret.name),
  );
  if (existingNames.length > 0) {
    throw new HttpsError(
      "already-exists",
      `Developer ID certificate secrets already exist: ${existingNames}. Delete them first to reconfigure.`,
    );
  }

  const privateKeySecret = await findSingleSecretForTeam(teamId, developerIdPrivateKeySecretName);
  const privateKeyPath = requireNonEmptyString(privateKeySecret.pathToSecret, "pathToSecret");
  const privateKey = await accessSecretByPath(privateKeyPath);
  const tmpDir = await mkdtemp(join(tmpdir(), "openci-developer-id-p12-"));

  try {
    const keyPath = join(tmpDir, "developer-id.key.pem");
    const certInputPath = join(tmpDir, "developer-id.cer");
    const certPemPath = join(tmpDir, "developer-id.cert.pem");
    const p12Path = join(tmpDir, "developer-id.p12");
    await writeFile(keyPath, privateKey, "utf8");
    await writeFile(certInputPath, Buffer.from(certificateBase64, "base64"));

    try {
      await runOpenSsl(["x509", "-inform", "DER", "-in", certInputPath, "-out", certPemPath], tmpDir);
    } catch {
      await runOpenSsl(["x509", "-inform", "PEM", "-in", certInputPath, "-out", certPemPath], tmpDir);
    }

    const password = randomBytes(24).toString("base64url");
    await runOpenSsl(
      [
        "pkcs12",
        "-export",
        "-inkey",
        keyPath,
        "-in",
        certPemPath,
        "-out",
        p12Path,
        "-passout",
        `pass:${password}`,
        "-legacy",
      ],
      tmpDir,
    );
    const p12Base64 = (await readFile(p12Path)).toString("base64");

    const documentIds: Record<string, string> = {};
    documentIds[developerIdCertificateP12SecretName] = await createStoredSecret(
      teamId,
      developerIdCertificateP12SecretName,
      p12Base64,
    );
    documentIds[developerIdCertificatePasswordSecretName] = await createStoredSecret(
      teamId,
      developerIdCertificatePasswordSecretName,
      password,
    );

    try {
      await deleteSecretByPath(privateKeyPath);
      await deleteSecretMetadata({ id: privateKeySecret.id });
    } catch (cleanupError) {
      logger.warn("Failed to clean up temporary Developer ID private key secret", {
        teamId,
        privateKeySecretId: privateKeySecret.id,
        cleanupError,
      });
    }
    logger.info("Developer ID certificate registered", { teamId, secrets: Object.keys(documentIds) });
    return { success: true, documentIds };
  } catch (error) {
    if (error instanceof HttpsError) throw error;
    logger.error("Failed to register Developer ID certificate", { teamId, error });
    throw new HttpsError(
      "internal",
      `Failed to register Developer ID certificate: ${String(error)}`,
    );
  } finally {
    await rm(tmpDir, { recursive: true, force: true });
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
    result.data.secrets.map((secret: { name: string }) => secret.name),
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
