import type { Firestore } from "firebase-admin/firestore";
import { describe, expect, it } from "vitest";

import { getGitHubApiBaseUrl, getGitHubBaseUrl } from "./getGitHubApiBaseUrl";

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
