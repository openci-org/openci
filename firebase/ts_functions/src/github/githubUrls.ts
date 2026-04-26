import { getTeamById } from "@openci/dataconnect-admin";

export const defaultGitHubApiBaseUrl = "https://api.github.com";
export const defaultGitHubBaseUrl = "https://github.com";

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

export function getApiBaseUrlFromTeamData(teamData?: { githubApiBaseUrl?: string | null } | null): string {
  const apiBaseUrl = teamData?.githubApiBaseUrl;
  if (typeof apiBaseUrl !== "string" || apiBaseUrl.length === 0) {
    return defaultGitHubApiBaseUrl;
  }

  const normalized = apiBaseUrl.replace(/\/+$/u, "");
  if (normalized === `${defaultGitHubApiBaseUrl}/graphql`) {
    return defaultGitHubApiBaseUrl;
  }
  if (normalized.endsWith("/api/graphql")) {
    return `${new URL(normalized).origin}/api/v3`;
  }
  if (normalized.endsWith("/graphql")) {
    return normalized.slice(0, -"/graphql".length);
  }
  return normalized;
}

export function getBaseUrlFromTeamData(teamData?: { githubBaseUrl?: string | null } | null): string {
  const baseUrl = teamData?.githubBaseUrl;
  return typeof baseUrl === "string" && baseUrl.length > 0 ? baseUrl : defaultGitHubBaseUrl;
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
