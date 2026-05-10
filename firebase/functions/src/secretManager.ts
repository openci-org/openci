import { SecretManagerServiceClient } from "@google-cloud/secret-manager";

export function resolveProjectId(override?: string): string {
  const projectId = override ?? process.env.GCLOUD_PROJECT ?? process.env.GOOGLE_CLOUD_PROJECT;
  if (!projectId || projectId.trim().length === 0) {
    throw new Error("GCLOUD_PROJECT environment variable is not set.");
  }
  return projectId;
}

export async function accessSecretByPath(secretPath: string): Promise<string> {
  const client = new SecretManagerServiceClient();
  const [response] = await client.accessSecretVersion({
    name: `${secretPath}/versions/latest`,
  });
  const data = response.payload?.data;
  if (!data) {
    throw new Error(`Secret at "${secretPath}" has no data.`);
  }
  return Buffer.from(data).toString("utf8");
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
