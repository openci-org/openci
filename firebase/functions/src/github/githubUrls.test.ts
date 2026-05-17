import { afterEach, describe, expect, it } from "vitest";
import {
  buildDashboardRunUrl,
  defaultGitHubApiBaseUrl,
  defaultGitHubAppSlug,
  defaultGitHubBaseUrl,
  getApiBaseUrlFromTeamData,
  getBaseUrlFromTeamData,
  getConfiguredGitHubApiBaseUrl,
  getConfiguredGitHubAppSlug,
  getConfiguredGitHubBaseUrl,
  getGitHubAppInstallationPath,
  graphqlEndpoint,
} from "./githubUrls";

describe("GitHub URL helpers", () => {
  const originalGitHubBaseUrl = process.env.GITHUB_BASE_URL;
  const originalGitHubApiBaseUrl = process.env.GITHUB_API_BASE_URL;
  const originalGitHubAppSlug = process.env.GITHUB_APP_SLUG;

  afterEach(() => {
    restoreEnv("GITHUB_BASE_URL", originalGitHubBaseUrl);
    restoreEnv("GITHUB_API_BASE_URL", originalGitHubApiBaseUrl);
    restoreEnv("GITHUB_APP_SLUG", originalGitHubAppSlug);
  });

  it("returns default base URLs when team data does not override them", () => {
    delete process.env.GITHUB_BASE_URL;
    delete process.env.GITHUB_API_BASE_URL;
    expect(getApiBaseUrlFromTeamData()).toBe(defaultGitHubApiBaseUrl);
    expect(getBaseUrlFromTeamData()).toBe(defaultGitHubBaseUrl);
  });

  it("returns team-specific GitHub URLs", () => {
    expect(
      getApiBaseUrlFromTeamData({ githubApiBaseUrl: "https://github.example.com/api/v3" }),
    ).toBe("https://github.example.com/api/v3");
    expect(getBaseUrlFromTeamData({ githubBaseUrl: "https://github.example.com" })).toBe(
      "https://github.example.com",
    );
  });

  it("derives enterprise API URLs from web base URLs", () => {
    expect(getApiBaseUrlFromTeamData({ githubBaseUrl: "https://github.example.com" })).toBe(
      "https://github.example.com/api/v3",
    );
    expect(getApiBaseUrlFromTeamData({ githubApiBaseUrl: " https://github.example.com/ " })).toBe(
      "https://github.example.com/api/v3",
    );
    expect(getApiBaseUrlFromTeamData({ githubApiBaseUrl: "https://github.com" })).toBe(
      defaultGitHubApiBaseUrl,
    );
    expect(getApiBaseUrlFromTeamData({ githubApiBaseUrl: "https://github.example.com/path" })).toBe(
      "https://github.example.com/api/v3",
    );
  });

  it("normalizes GraphQL endpoint values to REST API base URLs", () => {
    expect(getApiBaseUrlFromTeamData({ githubApiBaseUrl: "https://api.github.com/graphql" })).toBe(
      defaultGitHubApiBaseUrl,
    );
    expect(
      getApiBaseUrlFromTeamData({ githubApiBaseUrl: "https://github.example.com/api/graphql" }),
    ).toBe("https://github.example.com/api/v3");
  });

  it("builds GitHub.com and enterprise GraphQL endpoints", () => {
    expect(graphqlEndpoint(defaultGitHubApiBaseUrl)).toBe("https://api.github.com/graphql");
    expect(graphqlEndpoint("https://api.github.com/graphql")).toBe(
      "https://api.github.com/graphql",
    );
    expect(graphqlEndpoint("https://github.example.com/api/v3")).toBe(
      "https://github.example.com/api/graphql",
    );
    expect(graphqlEndpoint("https://github.example.com/api/graphql")).toBe(
      "https://github.example.com/api/graphql",
    );
  });

  it("builds dashboard run URLs", () => {
    expect(buildDashboardRunUrl("build job 1")).toBe(
      "https://dashboard.openci.org/runs/build%20job%201",
    );
  });

  it("uses global GitHub host configuration when team data does not override it", () => {
    process.env.GITHUB_BASE_URL = " https://github.enterprise.example/ ";
    delete process.env.GITHUB_API_BASE_URL;

    expect(getConfiguredGitHubBaseUrl()).toBe("https://github.enterprise.example");
    expect(getConfiguredGitHubApiBaseUrl()).toBe("https://github.enterprise.example/api/v3");
    expect(getBaseUrlFromTeamData()).toBe("https://github.enterprise.example");
    expect(getApiBaseUrlFromTeamData()).toBe("https://github.enterprise.example/api/v3");
  });

  it("allows a global GitHub API URL and app slug override", () => {
    process.env.GITHUB_BASE_URL = "https://github.enterprise.example";
    process.env.GITHUB_API_BASE_URL = "https://github.enterprise.example/api/v3/";
    process.env.GITHUB_APP_SLUG = "openci-enterprise";

    expect(getConfiguredGitHubApiBaseUrl()).toBe("https://github.enterprise.example/api/v3");
    expect(getConfiguredGitHubAppSlug()).toBe("openci-enterprise");
  });

  it("defaults the GitHub app slug for GitHub.com", () => {
    delete process.env.GITHUB_APP_SLUG;

    expect(getConfiguredGitHubAppSlug()).toBe(defaultGitHubAppSlug);
  });

  it("uses the standard install path for enterprise GitHub Apps", () => {
    process.env.GITHUB_APP_SLUG = "openci";

    expect(getGitHubAppInstallationPath("https://github.enterprise.example")).toBe(
      "/github-apps/openci/installations/new",
    );
  });

  it("keeps the existing select target path for GitHub.com", () => {
    process.env.GITHUB_APP_SLUG = "openci-org";

    expect(getGitHubAppInstallationPath(defaultGitHubBaseUrl)).toBe(
      "/apps/openci-org/installations/select_target",
    );
  });
});

function restoreEnv(name: string, value: string | undefined): void {
  if (value === undefined) {
    delete process.env[name];
    return;
  }
  process.env[name] = value;
}
