import { describe, expect, it } from "vitest";

import {
  parseSearchResults,
  parseTags,
  SEARCH_REPOS_QUERY,
  TAGS_QUERY,
  type SearchReposQueryResult,
  type TagsQueryResult,
} from "./search-github-actions";

describe("SEARCH_REPOS_QUERY", () => {
  it("should contain search query fields", () => {
    expect(SEARCH_REPOS_QUERY).toContain("search(query: $queryString");
    expect(SEARCH_REPOS_QUERY).toContain("nameWithOwner");
    expect(SEARCH_REPOS_QUERY).toContain("stargazerCount");
    expect(SEARCH_REPOS_QUERY).toContain("avatarUrl");
    expect(SEARCH_REPOS_QUERY).toContain("defaultBranchRef");
  });
});

describe("TAGS_QUERY", () => {
  it("should contain refs query fields", () => {
    expect(TAGS_QUERY).toContain('refs(refPrefix: "refs/tags/"');
    expect(TAGS_QUERY).toContain("nodes");
    expect(TAGS_QUERY).toContain("name");
  });
});

describe("parseSearchResults", () => {
  it("should map repository fields correctly", () => {
    const result: SearchReposQueryResult = {
      search: {
        nodes: [
          {
            nameWithOwner: "actions/checkout",
            description: "Checkout a Git repository",
            stargazerCount: 5000,
            owner: { login: "actions", avatarUrl: "https://avatar.example.com/actions" },
            url: "https://github.com/actions/checkout",
            defaultBranchRef: { name: "main" },
          },
        ],
      },
    };

    const actions = parseSearchResults(result);
    expect(actions).toHaveLength(1);
    expect(actions[0]).toEqual({
      fullName: "actions/checkout",
      description: "Checkout a Git repository",
      stars: 5000,
      owner: "actions",
      avatarUrl: "https://avatar.example.com/actions",
      htmlUrl: "https://github.com/actions/checkout",
      defaultBranch: "main",
      isOfficial: true,
    });
  });

  it("should mark non-actions owner as unofficial", () => {
    const result: SearchReposQueryResult = {
      search: {
        nodes: [
          {
            nameWithOwner: "user/my-action",
            description: null,
            stargazerCount: 100,
            owner: { login: "user", avatarUrl: "https://avatar.example.com/user" },
            url: "https://github.com/user/my-action",
            defaultBranchRef: { name: "master" },
          },
        ],
      },
    };

    const actions = parseSearchResults(result);
    expect(actions[0].isOfficial).toBe(false);
    expect(actions[0].description).toBe("");
  });

  it("should default to 'main' when defaultBranchRef is null", () => {
    const result: SearchReposQueryResult = {
      search: {
        nodes: [
          {
            nameWithOwner: "user/repo",
            description: "desc",
            stargazerCount: 0,
            owner: { login: "user", avatarUrl: "https://avatar.example.com" },
            url: "https://github.com/user/repo",
            defaultBranchRef: null,
          },
        ],
      },
    };

    const actions = parseSearchResults(result);
    expect(actions[0].defaultBranch).toBe("main");
  });

  it("should return empty array for empty results", () => {
    const result: SearchReposQueryResult = {
      search: { nodes: [] },
    };

    expect(parseSearchResults(result)).toEqual([]);
  });
});

describe("parseTags", () => {
  it("should return major tags when present", () => {
    const result: TagsQueryResult = {
      repository: {
        refs: {
          nodes: [
            { name: "v4" },
            { name: "v4.2.0" },
            { name: "v3" },
            { name: "v3.5.1" },
            { name: "v2" },
          ],
        },
      },
    };

    expect(parseTags(result)).toEqual(["v4", "v3", "v2"]);
  });

  it("should return all tags when no major tags exist", () => {
    const result: TagsQueryResult = {
      repository: {
        refs: {
          nodes: [{ name: "v1.0.0" }, { name: "v0.9.0" }, { name: "beta-1" }],
        },
      },
    };

    expect(parseTags(result)).toEqual(["v1.0.0", "v0.9.0", "beta-1"]);
  });

  it("should return empty array for no tags", () => {
    const result: TagsQueryResult = {
      repository: {
        refs: {
          nodes: [],
        },
      },
    };

    expect(parseTags(result)).toEqual([]);
  });

  it("should only match strict major version pattern", () => {
    const result: TagsQueryResult = {
      repository: {
        refs: {
          nodes: [{ name: "v1" }, { name: "v12" }, { name: "v1a" }, { name: "1" }, { name: "v" }],
        },
      },
    };

    expect(parseTags(result)).toEqual(["v1", "v12"]);
  });
});
