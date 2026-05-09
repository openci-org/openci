import type { Firestore } from "firebase-admin/firestore";
import { describe, expect, it } from "vitest";

import {
  filterYamlFiles,
  getGitHubApiBaseUrl,
  getGitHubBaseUrl,
  getTeamIdByInstallationId,
} from "./addBuildJob";

describe("getTeamIdByInstallationId", () => {
  function fakeDb(queryResult: { empty: boolean; docs: Array<{ id: string }> }): Firestore {
    return {
      collection: () => ({
        where: () => ({
          limit: () => ({
            get: async () => queryResult,
          }),
        }),
      }),
    } as unknown as Firestore;
  }

  it("returns teamId when team exists", async () => {
    const db = fakeDb({ empty: false, docs: [{ id: "team-abc" }] });

    const result = await getTeamIdByInstallationId(db, 12345);

    expect(result).toBe("team-abc");
  });

  it("throws when no team found", async () => {
    const db = fakeDb({ empty: true, docs: [] });

    await expect(getTeamIdByInstallationId(db, 99999)).rejects.toThrow(
      "No team found for installation 99999",
    );
  });
});

describe("getGitHubBaseUrl", () => {
  function fakeDb(docResult: {
    exists: boolean;
    data: () => Record<string, unknown> | undefined;
  }): Firestore {
    return {
      collection: () => ({
        doc: () => ({
          get: async () => docResult,
        }),
      }),
    } as unknown as Firestore;
  }

  it("returns custom base URL when set", async () => {
    const db = fakeDb({
      exists: true,
      data: () => ({ githubBaseUrl: "https://github.openci.org" }),
    });

    const result = await getGitHubBaseUrl(db, "team-1");

    expect(result).toBe("https://github.openci.org");
  });

  it("returns default base URL when not set", async () => {
    const db = fakeDb({
      exists: true,
      data: () => ({}),
    });

    const result = await getGitHubBaseUrl(db, "team-1");

    expect(result).toBe("https://github.com");
  });

  it("throws when team not found", async () => {
    const db = fakeDb({
      exists: false,
      data: () => undefined,
    });

    await expect(getGitHubBaseUrl(db, "no-such-team")).rejects.toThrow(
      "Team no-such-team not found",
    );
  });
});

describe("getGitHubApiBaseUrl", () => {
  it("returns default API URL for github.com", () => {
    expect(getGitHubApiBaseUrl("https://github.com")).toBe("https://api.github.com");
  });

  it("returns /api/v3 path for GitHub Enterprise", () => {
    expect(getGitHubApiBaseUrl("https://github.openci.org")).toBe(
      "https://github.openci.org/api/v3",
    );
  });

  it("strips path from Enterprise URL", () => {
    expect(getGitHubApiBaseUrl("https://github.openci.org/some/path")).toBe(
      "https://github.openci.org/api/v3",
    );
  });
});

describe("filterYamlFiles", () => {
  it("returns only .yaml and .yml files", () => {
    const entries = [
      { type: "file", name: "ci.yaml", path: ".openci/ci.yaml" },
      { type: "file", name: "deploy.yml", path: ".openci/deploy.yml" },
      { type: "file", name: "README.md", path: ".openci/README.md" },
      { type: "dir", name: "scripts", path: ".openci/scripts" },
    ];

    expect(filterYamlFiles(entries)).toEqual([
      { type: "file", name: "ci.yaml", path: ".openci/ci.yaml" },
      { type: "file", name: "deploy.yml", path: ".openci/deploy.yml" },
    ]);
  });

  it("excludes directories even if named .yaml", () => {
    const entries = [{ type: "dir", name: "weird.yaml", path: ".openci/weird.yaml" }];

    expect(filterYamlFiles(entries)).toEqual([]);
  });

  it("returns empty array when no yaml files", () => {
    const entries = [{ type: "file", name: "config.json", path: ".openci/config.json" }];

    expect(filterYamlFiles(entries)).toEqual([]);
  });
});
