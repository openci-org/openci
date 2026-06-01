export const BuildJobStatus = {
  WAITING: "WAITING",
  QUEUED: "QUEUED",
  IN_PROGRESS: "IN_PROGRESS",
  SUCCESS: "SUCCESS",
  FAILURE: "FAILURE",
  CANCELLED: "CANCELLED",
  SKIPPED: "SKIPPED",
  TIMED_OUT: "TIMED_OUT",
} as const;
export type BuildJobStatus = (typeof BuildJobStatus)[keyof typeof BuildJobStatus];

export const defaultGitHubApiBaseUrl = "https://api.github.com";
export const defaultGitHubBaseUrl = "https://github.com";
const dashboardBaseUrl = "https://dashboard.openci.org";

function nonEmptyEnv(name: string): string | undefined {
  const value = process.env[name]?.trim();
  return value && value.length > 0 ? value : undefined;
}

export function getConfiguredGitHubBaseUrl(): string {
  return nonEmptyEnv("GITHUB_BASE_URL")?.replace(/\/+$/u, "") ?? defaultGitHubBaseUrl;
}

export function getConfiguredGitHubApiBaseUrl(): string {
  const apiBaseUrl = nonEmptyEnv("GITHUB_API_BASE_URL");
  if (apiBaseUrl) return normalizeGitHubApiBaseUrl(apiBaseUrl);
  const baseUrl = getConfiguredGitHubBaseUrl();
  if (baseUrl === defaultGitHubBaseUrl) return defaultGitHubApiBaseUrl;
  return `${new URL(baseUrl).origin}/api/v3`;
}

export function normalizeGitHubApiBaseUrl(apiBaseUrl?: string | null): string {
  if (!apiBaseUrl) return getConfiguredGitHubApiBaseUrl();
  const normalized = apiBaseUrl.replace(/\/+$/u, "");
  if (normalized === defaultGitHubApiBaseUrl) return defaultGitHubApiBaseUrl;
  if (normalized === defaultGitHubBaseUrl) return defaultGitHubApiBaseUrl;
  if (normalized === `${defaultGitHubApiBaseUrl}/graphql`) return defaultGitHubApiBaseUrl;
  if (normalized.endsWith("/api/v3")) return normalized;
  if (normalized.endsWith("/api/graphql")) return `${new URL(normalized).origin}/api/v3`;
  if (normalized.endsWith("/graphql")) return `${new URL(normalized).origin}/api/v3`;
  return `${new URL(normalized).origin}/api/v3`;
}

export function buildDashboardRunUrl(buildJobId: string): string {
  return `${dashboardBaseUrl}/runs/${encodeURIComponent(buildJobId)}`;
}
