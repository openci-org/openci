import { defineSecret } from "firebase-functions/params";
import { logger } from "firebase-functions/v2";

import {
  defaultGitHubApiBaseUrl,
  getConfiguredGitHubApiBaseUrl,
  graphqlEndpoint,
} from "./githubUrls.js";

export const githubAppId = defineSecret("GITHUB_APP_ID");
export const githubPrivateKey = defineSecret("GITHUB_PRIVATE_KEY");

export interface InstallationToken {
  token: string;
  expiresAt: string;
}

function graphqlErrorSummary(errors: unknown): string {
  if (errors === undefined) return "";
  try {
    return ` ${JSON.stringify(errors)}`;
  } catch {
    return ` ${String(errors)}`;
  }
}

export class GitHubGraphqlError extends Error {
  readonly status: number;
  readonly statusText: string;
  readonly errors: unknown;

  constructor({
    status,
    statusText,
    errors,
  }: {
    status: number;
    statusText: string;
    errors: unknown;
  }) {
    super(`GitHub GraphQL request failed: ${status} ${statusText}${graphqlErrorSummary(errors)}`);
    this.name = "GitHubGraphqlError";
    this.status = status;
    this.statusText = statusText;
    this.errors = errors;
  }
}

async function createOctokit(token: string, apiBaseUrl: string) {
  const { Octokit } = await import("@octokit/rest");
  return new Octokit({
    auth: token,
    baseUrl: apiBaseUrl,
    userAgent: "OpenCI-Functions",
  });
}

function splitPath(path: string): { route: string; params: Record<string, string> } {
  const url = new URL(path, defaultGitHubApiBaseUrl);
  const route = url.pathname;
  return {
    route,
    params: Object.fromEntries(url.searchParams.entries()),
  };
}

async function githubRequest<T>(
  method: "GET" | "POST" | "PATCH" | "PUT",
  path: string,
  token: string,
  {
    data,
    queryParameters,
    apiBaseUrl,
  }: {
    data?: unknown;
    queryParameters?: Record<string, string | number | boolean | null | undefined>;
    apiBaseUrl?: string;
  } = {},
): Promise<T> {
  const octokit = await createOctokit(token, apiBaseUrl ?? getConfiguredGitHubApiBaseUrl());
  const { route, params } = splitPath(path);
  const response = await octokit.request(`${method} ${route}`, {
    ...params,
    ...queryParameters,
    ...(typeof data === "object" && data !== null ? (data as Record<string, unknown>) : {}),
  });

  return response.data as T;
}

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

export function githubGet<T>(
  path: string,
  token: string,
  options?: {
    queryParameters?: Record<string, string | number | boolean | null | undefined>;
    apiBaseUrl?: string;
  },
): Promise<T> {
  return githubRequest<T>("GET", path, token, options);
}

export function githubPost<T>(
  path: string,
  token: string,
  data?: unknown,
  options?: { apiBaseUrl?: string },
): Promise<T> {
  return githubRequest<T>("POST", path, token, { ...options, data });
}

export function githubPatch<T>(
  path: string,
  token: string,
  data?: unknown,
  options?: { apiBaseUrl?: string },
): Promise<T> {
  return githubRequest<T>("PATCH", path, token, { ...options, data });
}

export function githubPut<T>(
  path: string,
  token: string,
  data?: unknown,
  options?: { apiBaseUrl?: string },
): Promise<T> {
  return githubRequest<T>("PUT", path, token, { ...options, data });
}

export async function githubGraphql<T>(
  query: string,
  token: string,
  { variables, apiBaseUrl }: { variables?: Record<string, unknown>; apiBaseUrl?: string } = {},
): Promise<T> {
  const response = await fetch(graphqlEndpoint(apiBaseUrl ?? getConfiguredGitHubApiBaseUrl()), {
    method: "POST",
    headers: {
      accept: "application/vnd.github.v3+json",
      authorization: `bearer ${token}`,
      "content-type": "application/json; charset=utf-8",
      "user-agent": "OpenCI-Functions",
    },
    body: JSON.stringify({ query, variables: variables ?? {} }),
  });
  const data = (await response.json()) as T & { errors?: unknown };
  if (!response.ok || data.errors !== undefined) {
    throw new GitHubGraphqlError({
      status: response.status,
      statusText: response.statusText,
      errors: data.errors,
    });
  }
  return data;
}
