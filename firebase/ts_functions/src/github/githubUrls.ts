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
  return typeof apiBaseUrl === "string" && apiBaseUrl.length > 0
    ? apiBaseUrl
    : defaultGitHubApiBaseUrl;
}

export function getBaseUrlFromTeamData(teamData?: { githubBaseUrl?: string | null } | null): string {
  const baseUrl = teamData?.githubBaseUrl;
  return typeof baseUrl === "string" && baseUrl.length > 0 ? baseUrl : defaultGitHubBaseUrl;
}

export function graphqlEndpoint(apiBaseUrl: string): string {
  if (apiBaseUrl === defaultGitHubApiBaseUrl) {
    return `${apiBaseUrl}/graphql`;
  }

  const url = new URL(apiBaseUrl);
  return `${url.protocol}//${url.host}/api/graphql`;
}

const dashboardBaseUrl = "https://dashboard.openci.org";

export function buildDashboardRunUrl(buildJobId: string): string {
  return `${dashboardBaseUrl}/runs/${encodeURIComponent(buildJobId)}`;
}
