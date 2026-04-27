import { SecretManagerServiceClient } from "@google-cloud/secret-manager";

import { getEnvironmentVariables, getSecrets, updateEnvironmentVariable } from "./dataconnect.js";
import { logInfo, logWarning } from "./logger.js";
import type { BuildJob } from "./types.js";

export async function buildEnvVars(input: {
  buildJob: BuildJob;
  projectId: string;
  buildJobId: string;
  runId: string;
}): Promise<Record<string, string>> {
  const { buildJob, projectId, buildJobId, runId } = input;
  const tagName = buildJob.tagName;
  const tagVersion = tagName ? tagName.replace(/^[vV]/, "") : undefined;
  const envVars: Record<string, string> = {
    LANG: "en_US.UTF-8",
    OPENCI_PROJECT_ID: projectId,
    ...(tagName ? { OPENCI_TAG: tagName, OPENCI_TAG_VERSION: tagVersion ?? tagName } : {}),
    ...(buildJob.teamId ? { OPENCI_TEAM_ID: buildJob.teamId } : {}),
  };

  if (!buildJob.teamId) return envVars;

  const rows = await getEnvironmentVariables(buildJob.teamId);
  for (const row of rows) {
    let value = row.value;
    if (row.autoIncrement) {
      const current = Number.parseInt(value, 10);
      if (Number.isFinite(current)) {
        await updateEnvironmentVariable(row.id, String(current + 1));
        await logInfo(buildJobId, runId, `Auto-incremented ${row.key}: ${value} -> ${current + 1}`);
      }
    }
    envVars[row.key] = value;
  }

  if (rows.length > 0) {
    await logInfo(buildJobId, runId, `Loaded ${rows.length} environment variable(s)`);
  }
  if (tagName) {
    await logInfo(buildJobId, runId, `Tag: ${tagName} (available as $OPENCI_TAG)`);
  }
  return envVars;
}

export async function buildSecretVars(input: {
  buildJob: BuildJob;
  serviceAccountPath: string;
  buildJobId: string;
  runId: string;
}): Promise<Record<string, string>> {
  const { buildJob, buildJobId, runId } = input;
  const secrets: Record<string, string> = {
    ...(buildJob.installationToken ? { OPENCI_GITHUB_TOKEN: buildJob.installationToken } : {}),
    ...(!buildJob.githubBaseUrl && buildJob.installationToken
      ? { GITHUB_TOKEN: buildJob.installationToken }
      : {}),
  };

  if (!buildJob.teamId) return secrets;

  const rows = await getSecrets(buildJob.teamId);
  if (rows.length === 0) return secrets;

  await logInfo(buildJobId, runId, `Loading ${rows.length} secret(s) from Secret Manager...`);
  const client = new SecretManagerServiceClient();
  for (const row of rows) {
    if (!row.pathToSecret) continue;
    try {
      const [version] = await client.accessSecretVersion({
        name: `${row.pathToSecret}/versions/latest`,
      });
      const data = version.payload?.data;
      if (data) secrets[row.name] = Buffer.from(data).toString("utf8");
    } catch (error) {
      await logWarning(buildJobId, runId, `Failed to load secret "${row.name}": ${String(error)}`);
    }
  }
  await logInfo(buildJobId, runId, `Loaded ${rows.length} secret(s)`);
  return secrets;
}

export function envFileContent(values: Record<string, string>): string {
  return Object.entries(values)
    .map(([key, value]) => `${key}=${value.replaceAll("\n", "\\n")}`)
    .join("\n");
}
