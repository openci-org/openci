import { getTeamById } from "../firestoreData.js";

export const defaultGitHubApiBaseUrl = "https://api.github.com";
export const defaultGitHubBaseUrl = "https://github.com";
export const defaultGitHubAppSlug = "openci-org";

function nonEmptyEnv(name: string): string | undefined {
  const value = process.env[name]?.trim();
  return value && value.length > 0 ? value : undefined;
}

function normalizeUrl(value: string): string {
  return value.trim().replace(/\/+$/u, "");
}

export function getConfiguredGitHubBaseUrl(): string {
  const baseUrl = nonEmptyEnv("GITHUB_BASE_URL");
  return baseUrl === undefined ? defaultGitHubBaseUrl : normalizeUrl(baseUrl);
}

export function getConfiguredGitHubApiBaseUrl(): string {
  const apiBaseUrl = nonEmptyEnv("GITHUB_API_BASE_URL");
  if (apiBaseUrl !== undefined) {
    return getApiBaseUrlFromValue(apiBaseUrl);
  }
  return getApiBaseUrlFromValue(getConfiguredGitHubBaseUrl());
}

export function getConfiguredGitHubAppSlug(): string {
  return nonEmptyEnv("GITHUB_APP_SLUG") ?? defaultGitHubAppSlug;
}

export function getGitHubAppInstallationPath(baseUrl: string): string {
  const normalizedBaseUrl = normalizeUrl(baseUrl);
  const appSlug = getConfiguredGitHubAppSlug();
  if (normalizedBaseUrl === defaultGitHubBaseUrl) {
    return `/apps/${appSlug}/installations/select_target`;
  }
  return `/github-apps/${appSlug}/installations/new`;
}

export async function getGitHubApiBaseUrl(teamId?: string | null): Promise<string> {
  if (!teamId) {
    return defaultGitHubApiBaseUrl;
  }

  const result = await getTeamById({ teamId });
  return getApiBaseUrlFromTeamData(result.data.team);
}

export async function getGitHubBaseUrl(teamId?: string | null): Promise<string> {
  if (!teamId) {
    return defaultGitHubBaseUrl;
  }

  const result = await getTeamById({ teamId });
  return getBaseUrlFromTeamData(result.data.team);
}

export function getApiBaseUrlFromTeamData(
  teamData?: { githubApiBaseUrl?: string | null; githubBaseUrl?: string | null } | null,
): string {
  const apiBaseUrl =
    typeof teamData?.githubApiBaseUrl === "string" && teamData.githubApiBaseUrl.trim().length > 0
      ? teamData.githubApiBaseUrl
      : teamData?.githubBaseUrl;
  if (typeof apiBaseUrl !== "string" || apiBaseUrl.trim().length === 0) {
    return getConfiguredGitHubApiBaseUrl();
  }

  return getApiBaseUrlFromValue(apiBaseUrl);
}

function getApiBaseUrlFromValue(apiBaseUrl: string): string {
  const normalized = normalizeUrl(apiBaseUrl);
  if (normalized === defaultGitHubApiBaseUrl) {
    return defaultGitHubApiBaseUrl;
  }
  if (normalized === defaultGitHubBaseUrl) {
    return defaultGitHubApiBaseUrl;
  }
  if (normalized === `${defaultGitHubApiBaseUrl}/graphql`) {
    return defaultGitHubApiBaseUrl;
  }
  if (normalized.endsWith("/api/v3")) {
    return normalized;
  }
  if (normalized.endsWith("/api/graphql")) {
    return `${new URL(normalized).origin}/api/v3`;
  }
  if (normalized.endsWith("/graphql")) {
    return `${new URL(normalized).origin}/api/v3`;
  }
  return `${new URL(normalized).origin}/api/v3`;
}

export function getBaseUrlFromTeamData(
  teamData?: { githubBaseUrl?: string | null } | null,
): string {
  const baseUrl = teamData?.githubBaseUrl?.trim();
  return typeof baseUrl === "string" && baseUrl.length > 0
    ? normalizeUrl(baseUrl)
    : getConfiguredGitHubBaseUrl();
}

export function graphqlEndpoint(apiBaseUrl: string): string {
  const normalizedApiBaseUrl = getApiBaseUrlFromTeamData({ githubApiBaseUrl: apiBaseUrl });
  if (normalizedApiBaseUrl === defaultGitHubApiBaseUrl) {
    return `${normalizedApiBaseUrl}/graphql`;
  }

  const url = new URL(normalizedApiBaseUrl);
  return `${url.protocol}//${url.host}/api/graphql`;
}

const dashboardBaseUrl = "https://dashboard.openci.org";

export function buildDashboardRunUrl(buildJobId: string): string {
  return `${dashboardBaseUrl}/runs/${encodeURIComponent(buildJobId)}`;
}
