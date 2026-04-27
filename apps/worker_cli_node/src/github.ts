import { createSign } from "node:crypto";

import { SecretManagerServiceClient } from "@google-cloud/secret-manager";
import { normalizeGitHubApiBaseUrl } from "@openci/build-job-services";

import type { BuildJob } from "./types.js";

function base64UrlEncode(input: string | Buffer): string {
  return Buffer.from(input)
    .toString("base64")
    .replaceAll("+", "-")
    .replaceAll("/", "_")
    .replaceAll("=", "");
}

async function accessProjectSecret(projectId: string, name: string): Promise<string> {
  const client = new SecretManagerServiceClient();
  const [version] = await client.accessSecretVersion({
    name: `projects/${projectId}/secrets/${name}/versions/latest`,
  });
  const data = version.payload?.data;
  if (!data) throw new Error(`Secret ${name} has no payload`);
  return Buffer.from(data).toString("utf8");
}

async function createGitHubAppJwt(projectId: string): Promise<string> {
  const [appId, privateKey] = await Promise.all([
    accessProjectSecret(projectId, "GITHUB_APP_ID"),
    accessProjectSecret(projectId, "GITHUB_PRIVATE_KEY"),
  ]);
  const nowSeconds = Math.floor(Date.now() / 1000);
  const header = { alg: "RS256", typ: "JWT" };
  const payload = {
    iat: nowSeconds - 60,
    exp: nowSeconds + 540,
    iss: appId,
  };
  const signingInput = `${base64UrlEncode(JSON.stringify(header))}.${base64UrlEncode(JSON.stringify(payload))}`;
  const signature = createSign("RSA-SHA256").update(signingInput).sign(privateKey);
  return `${signingInput}.${base64UrlEncode(signature)}`;
}

export async function resolveInstallationToken(
  buildJob: BuildJob,
  projectId: string,
): Promise<string> {
  if (buildJob.installationToken) return buildJob.installationToken;

  if (buildJob.installationId === null || buildJob.installationId === undefined) {
    throw new Error("installationToken and installationId are missing");
  }

  const jwt = await createGitHubAppJwt(projectId);
  const response = await fetch(
    `${normalizeGitHubApiBaseUrl(buildJob.githubApiBaseUrl)}/app/installations/${String(
      buildJob.installationId,
    )}/access_tokens`,
    {
      method: "POST",
      headers: {
        Authorization: `Bearer ${jwt}`,
        Accept: "application/vnd.github+json",
        "X-GitHub-Api-Version": "2022-11-28",
      },
    },
  );
  const data = (await response.json()) as { token?: string; message?: string };
  if (!response.ok || typeof data.token !== "string") {
    throw new Error(
      data.message ?? `Failed to create GitHub installation token: ${response.status}`,
    );
  }
  return data.token;
}

export async function withInstallationToken(
  buildJob: BuildJob,
  projectId: string,
): Promise<BuildJob> {
  return {
    ...buildJob,
    installationToken: await resolveInstallationToken(buildJob, projectId),
  };
}
