import { createAppAuth } from "@octokit/auth-app";
import { request } from "@octokit/request";

import type { InstallationToken } from "../../github/githubRequests.js";

export async function getInstallationToken(
  installationId: number,
  apiBaseUrl: string,
  appId: string,
  privateKey: string,
): Promise<InstallationToken> {
  const auth = createAppAuth({
    appId,
    privateKey,
    installationId,
    timeDifference: 30,
    request: request.defaults({ baseUrl: apiBaseUrl }),
  });
  const data = await auth({ type: "installation" });

  return {
    token: data.token,
    expiresAt: data.expiresAt,
  };
}
