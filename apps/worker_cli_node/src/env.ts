import { SecretManagerServiceClient } from "@google-cloud/secret-manager";

import { getEnvironmentVariables, getSecrets, updateEnvironmentVariable } from "./firestore.js";
import { fetchWorkflowContent } from "./github.js";
import { logInfo, logWarning } from "./logger.js";
import type { BuildJob } from "./types.js";

function escapeRegExp(value: string): string {
  return value.replace(/[.*+?^${}()|[\]\\]/gu, "\\$&");
}

export async function buildEnvVars(input: {
  buildJob: BuildJob;
  projectId: string;
  buildJobId: string;
  runId: string;
  workflowContent?: string | null;
}): Promise<Record<string, string>> {
  const { buildJob, projectId, buildJobId, runId, workflowContent } = input;
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
      const isReferenced =
        workflowContent === undefined ||
        workflowContent === null ||
        new RegExp(`\\b${escapeRegExp(row.key)}\\b`).test(workflowContent);

      if (!isReferenced) {
        continue;
      }

      const current = Number.parseInt(value, 10);
      if (Number.isFinite(current)) {
        const nextValue = String(current + 1);
        await updateEnvironmentVariable(row.id, nextValue);
        await logInfo(buildJobId, runId, `Auto-incremented ${row.key}: ${value} -> ${nextValue}`);
        value = nextValue;
      }
    }
    envVars[row.key] = value;
  }

  const customEnvCount = rows.filter((row) => envVars[row.key] !== undefined).length;
  if (customEnvCount > 0) {
    await logInfo(buildJobId, runId, `Loaded ${customEnvCount} environment variable(s)`);
  }
  if (tagName) {
    await logInfo(buildJobId, runId, `Tag: ${tagName} (available as $OPENCI_TAG)`);
  }
  return envVars;
}

export async function buildSecretVars(input: {
  buildJob: BuildJob;
  projectId: string;
  serviceAccountPath: string;
  buildJobId: string;
  runId: string;
  workflowContent?: string | null;
}): Promise<Record<string, string>> {
  const { buildJob, projectId, buildJobId, runId, workflowContent } = input;
  const secrets: Record<string, string> = {
    ...(buildJob.installationToken ? { OPENCI_GITHUB_TOKEN: buildJob.installationToken } : {}),
    ...(!buildJob.githubBaseUrl && buildJob.installationToken
      ? { GITHUB_TOKEN: buildJob.installationToken }
      : {}),
  };

  if (!buildJob.teamId) return secrets;

  const rows = await getSecrets(buildJob.teamId);
  if (rows.length === 0) return secrets;

  // 使用されているシークレット名をワークフロー定義から抽出する
  let usedSecretNames: Set<string> | null = null;
  if (workflowContent !== undefined && workflowContent !== null) {
    usedSecretNames = extractSecretNames(workflowContent);
    await logInfo(
      buildJobId,
      runId,
      `Referenced secret(s) in workflow: ${Array.from(usedSecretNames).join(", ") || "(none)"}`,
    );
  } else if (buildJob.workflowFileName && workflowContent === undefined) {
    try {
      await logInfo(
        buildJobId,
        runId,
        `Fetching workflow ${buildJob.workflowFileName} from GitHub to analyze used secrets...`,
      );
      const content = await fetchWorkflowContent(buildJob, projectId);
      usedSecretNames = extractSecretNames(content);
      await logInfo(
        buildJobId,
        runId,
        `Referenced secret(s) in workflow: ${Array.from(usedSecretNames).join(", ") || "(none)"}`,
      );
    } catch (error) {
      await logWarning(
        buildJobId,
        runId,
        `Failed to fetch or analyze workflow file; falling back to loading all secrets: ${String(error)}`,
      );
    }
  }

  // 抽出されたシークレットのみに絞り込む（抽出に失敗した場合はすべてをロード）
  const targetRows = rows.filter((row) => {
    if (!usedSecretNames) return true; // 抽出失敗時はフォールバックですべてロード
    return usedSecretNames.has(row.name);
  });

  if (targetRows.length === 0) {
    await logInfo(buildJobId, runId, "No secrets need to be loaded");
    return secrets;
  }

  await logInfo(buildJobId, runId, `Loading ${targetRows.length} secret(s) from Secret Manager...`);
  const client = new SecretManagerServiceClient();
  for (const row of targetRows) {
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
  await logInfo(buildJobId, runId, `Loaded ${targetRows.length} secret(s)`);
  return secrets;
}

export function envFileContent(values: Record<string, string>): string {
  return Object.entries(values)
    .map(([key, value]) => `${key}=${value.replaceAll("\n", "\\n")}`)
    .join("\n");
}

export function extractSecretNames(content: string): Set<string> {
  const secretNames = new Set<string>();
  const regex = /secrets(?:\.([a-zA-Z0-9_-]+)|\[\s*(?:"([^"]+)"|'([^']+)')\s*\])/gi;
  let match;
  while ((match = regex.exec(content)) !== null) {
    const name = match[1] || match[2] || match[3];
    if (name) {
      secretNames.add(name);
    }
  }
  return secretNames;
}
