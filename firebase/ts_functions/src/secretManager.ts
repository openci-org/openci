import { SecretManagerServiceClient } from "@google-cloud/secret-manager";

interface AccessSecretVersionResponse {
  payload?: {
    data?: Uint8Array | string | null;
  } | null;
}

export function resolveProjectId(override?: string): string {
  const projectId = override ?? process.env.GCLOUD_PROJECT ?? process.env.GOOGLE_CLOUD_PROJECT;
  if (!projectId || projectId.trim().length === 0) {
    throw new Error("GCLOUD_PROJECT environment variable is not set.");
  }
  return projectId;
}

export function buildSecretPath(projectId: string, secretId: string): string {
  if (secretId.trim().length === 0) {
    throw new Error("secretId must not be empty.");
  }
  return `projects/${projectId}/secrets/${secretId}/versions/latest`;
}

export function extractSecretData(
  response: AccessSecretVersionResponse,
  secretId: string,
): string {
  const data = response.payload?.data;
  if (!data) {
    throw new Error(`Secret "${secretId}" has no data.`);
  }
  return Buffer.from(data).toString("utf8");
}

export async function accessSecret(secretId: string): Promise<string> {
  const projectId = resolveProjectId();
  const client = new SecretManagerServiceClient();
  const [response] = await client.accessSecretVersion({
    name: buildSecretPath(projectId, secretId),
  });
  return extractSecretData(response, secretId);
}

export async function createSecretWithValue(secretId: string, value: string): Promise<string> {
  const projectId = resolveProjectId();
  const parent = `projects/${projectId}`;
  const client = new SecretManagerServiceClient();

  await client.createSecret({
    parent,
    secretId,
    secret: {
      replication: {
        automatic: {},
      },
    },
  });

  await client.addSecretVersion({
    parent: `${parent}/secrets/${secretId}`,
    payload: {
      data: Buffer.from(value, "utf8"),
    },
  });

  return `${parent}/secrets/${secretId}`;
}

export async function addSecretVersionByPath(secretPath: string, value: string): Promise<void> {
  const client = new SecretManagerServiceClient();
  await client.addSecretVersion({
    parent: secretPath,
    payload: {
      data: Buffer.from(value, "utf8"),
    },
  });
}

export async function deleteSecretByPath(secretPath: string): Promise<void> {
  const client = new SecretManagerServiceClient();
  await client.deleteSecret({ name: secretPath });
}
