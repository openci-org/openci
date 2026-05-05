import { describe, expect, it } from "vitest";
import {
  buildDashboardRunUrl,
  defaultGitHubApiBaseUrl,
  defaultGitHubBaseUrl,
  getApiBaseUrlFromTeamData,
  getBaseUrlFromTeamData,
  graphqlEndpoint,
} from "./githubUrls";

describe("GitHub URL helpers", () => {
  it("returns default base URLs when team data does not override them", () => {
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
});
