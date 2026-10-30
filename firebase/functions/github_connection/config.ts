export interface ConnectionConfig {
  apiBaseUrl: string;
  baseUrl: string;
  appId: string;
  clientId: string;
  clientSecret: string;
  callbackUrl: string;
  returnUrl: string;
  installationUrl?: string;
}

function endpoint(value: string): URL {
  const url = new URL(value);
  if (
    !["https:", "http:"].includes(url.protocol) ||
    url.username ||
    url.password ||
    url.search ||
    url.hash ||
    (url.protocol === "http:" && !["localhost", "127.0.0.1", "[::1]"].includes(url.hostname))
  )
    throw new Error("Invalid GitHub connection endpoint");
  return url;
}

export function connectionConfig(env: NodeJS.ProcessEnv): ConnectionConfig {
  const required = (name: string): string => {
    const value = env[name]?.trim();
    if (!value) throw new Error("GitHub connection is not configured");
    return value;
  };
  const api = endpoint(env.GITHUB_API_BASE_URL?.trim() || "https://api.github.com");
  api.pathname = api.pathname.replace(/\/+$/, "");
  const apiBaseUrl = api.toString().replace(/\/$/, "");
  const baseUrl =
    apiBaseUrl === "https://api.github.com"
      ? "https://github.com"
      : apiBaseUrl.endsWith("/api/v3")
        ? apiBaseUrl.slice(0, -7)
        : (() => {
            throw new Error("GitHub Enterprise API must end in /api/v3");
          })();
  const appId = required("GITHUB_APP_ID");
  if (!/^[1-9][0-9]*$/.test(appId)) throw new Error("Invalid GitHub App ID");
  const installationUrl = env.GITHUB_APP_INSTALLATION_URL?.trim();
  if (installationUrl) {
    const install = endpoint(installationUrl);
    if (
      install.origin !== new URL(baseUrl).origin ||
      !install.pathname.startsWith(`${new URL(baseUrl).pathname.replace(/\/$/, "")}/apps/`)
    )
      throw new Error("Installation link must belong to the configured GitHub host");
  }
  return {
    apiBaseUrl,
    baseUrl,
    appId,
    clientId: required("GITHUB_APP_CLIENT_ID"),
    clientSecret: required("GITHUB_APP_CLIENT_SECRET"),
    callbackUrl: endpoint(required("GITHUB_OAUTH_REDIRECT_URI")).toString(),
    returnUrl: endpoint(required("GITHUB_CONNECTION_RETURN_URL")).toString(),
    ...(installationUrl ? { installationUrl } : {}),
  };
}

export function authorizationUrl(
  config: ConnectionConfig,
  state: string,
  challenge: string,
): string {
  const url = new URL(`${config.baseUrl}/login/oauth/authorize`);
  url.search = new URLSearchParams({
    client_id: config.clientId,
    redirect_uri: config.callbackUrl,
    state,
    code_challenge: challenge,
    code_challenge_method: "S256",
  }).toString();
  return url.toString();
}
