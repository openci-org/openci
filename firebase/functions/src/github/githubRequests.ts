import {
  defaultGitHubApiBaseUrl,
  getConfiguredGitHubApiBaseUrl,
  graphqlEndpoint,
} from "./githubUrls.js";

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
