import { createSign } from "node:crypto";

import { SecretManagerServiceClient } from "@google-cloud/secret-manager";

import { normalizeGitHubApiBaseUrl } from "./build_job_services.js";
import type { BuildJob } from "./types.js";

const tokenRefreshBufferMs = 5 * 60 * 1000;

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

function isInstallationTokenFresh(expiresAt?: string | null): boolean {
  if (!expiresAt) return false;
  const expiresAtMs = new Date(expiresAt).getTime();
  return Number.isFinite(expiresAtMs) && expiresAtMs - Date.now() > tokenRefreshBufferMs;
}

export async function resolveInstallationToken(
  buildJob: BuildJob,
  projectId: string,
): Promise<string> {
  if (buildJob.installationToken && isInstallationTokenFresh(buildJob.tokenExpiresAt)) {
    return buildJob.installationToken;
  }

  if (buildJob.installationId === null || buildJob.installationId === undefined) {
    if (buildJob.installationToken) return buildJob.installationToken;
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

export async function fetchWorkflowContent(buildJob: BuildJob, projectId: string): Promise<string> {
  const token = await resolveInstallationToken(buildJob, projectId);
  const apiBase = normalizeGitHubApiBaseUrl(buildJob.githubApiBaseUrl);
  const ref = buildJob.commitSha || buildJob.branch || undefined;
  const query = ref ? `?ref=${encodeURIComponent(ref)}` : "";
  const url = `${apiBase}/repos/${buildJob.owner}/${buildJob.repo}/contents/.openci/${buildJob.workflowFileName}${query}`;

  const response = await fetch(url, {
    headers: {
      Authorization: `Bearer ${token}`,
      Accept: "application/vnd.github+json",
      "X-GitHub-Api-Version": "2022-11-28",
    },
  });

  if (!response.ok) {
    throw new Error(
      `Failed to fetch workflow content from GitHub: ${response.status} ${response.statusText}`,
    );
  }

  const data = (await response.json()) as { content?: string; encoding?: string };
  if (!data.content) {
    throw new Error("No content in GitHub response");
  }

  const encoding = data.encoding || "base64";
  if (encoding === "base64") {
    const cleaned = data.content.replace(/\s/g, "");
    return Buffer.from(cleaned, "base64").toString("utf8");
  }

  return data.content;
}
