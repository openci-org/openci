import { defineSecret } from "firebase-functions/params";
import { logger } from "firebase-functions/v2";

import { githubPost, type InstallationToken } from "./githubRequests.js";
import { getConfiguredGitHubApiBaseUrl } from "./githubUrls.js";

export const githubAppId = defineSecret("GITHUB_APP_ID");
export const githubPrivateKey = defineSecret("GITHUB_PRIVATE_KEY");

export async function getInstallationToken(
  installationId: number,
  { apiBaseUrl }: { apiBaseUrl?: string } = {},
): Promise<InstallationToken> {
  const [{ createAppAuth }, { request }] = await Promise.all([
    import("@octokit/auth-app"),
    import("@octokit/request"),
  ]);
  const appId = githubAppId.value();
  const privateKey = githubPrivateKey.value();
  const auth = createAppAuth({
    appId,
    privateKey,
    installationId,
    timeDifference: 30,
    request: request.defaults({ baseUrl: apiBaseUrl ?? getConfiguredGitHubApiBaseUrl() }),
  });
  const data = await auth({ type: "installation" });

  return {
    token: data.token,
    expiresAt: data.expiresAt,
  };
}

export async function createCheckRun({
  token,
  owner,
  repo,
  name,
  headSha,
  status,
  detailsUrl,
  apiBaseUrl,
}: {
  token: string;
  owner: string;
  repo: string;
  name: string;
  headSha: string;
  status: string;
  detailsUrl: string;
  apiBaseUrl?: string;
}): Promise<number | null> {
  try {
    const data = await githubPost<{ id?: number }>(
      `/repos/${owner}/${repo}/check-runs`,
      token,
      {
        name,
        head_sha: headSha,
        status,
        started_at: new Date().toISOString(),
        details_url: detailsUrl,
      },
      { apiBaseUrl: apiBaseUrl ?? getConfiguredGitHubApiBaseUrl() },
    );
    return typeof data.id === "number" ? data.id : null;
  } catch (error) {
    logger.error("Failed to create check run", { owner, repo, error });
    return null;
  }
}
