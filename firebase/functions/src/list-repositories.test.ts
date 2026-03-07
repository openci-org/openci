import { describe, expect, it } from "vitest";

import {
  parseRepositories,
  REPOSITORIES_QUERY,
  type RepositoriesQueryResult,
} from "./list-repositories";

describe("REPOSITORIES_QUERY", () => {
  it("should query viewer repositories with pagination", () => {
    expect(REPOSITORIES_QUERY).toContain("viewer");
    expect(REPOSITORIES_QUERY).toContain("repositories(first: 100");
    expect(REPOSITORIES_QUERY).toContain("after: $cursor");
    expect(REPOSITORIES_QUERY).toContain("nameWithOwner");
    expect(REPOSITORIES_QUERY).toContain("isPrivate");
    expect(REPOSITORIES_QUERY).toContain("defaultBranchRef");
    expect(REPOSITORIES_QUERY).toContain("pageInfo");
    expect(REPOSITORIES_QUERY).toContain("hasNextPage");
    expect(REPOSITORIES_QUERY).toContain("endCursor");
  });
});

describe("parseRepositories", () => {
  it("should map repository fields correctly", () => {
    const result: RepositoriesQueryResult = {
      viewer: {
        repositories: {
          nodes: [
            {
              nameWithOwner: "org/repo-one",
              name: "repo-one",
              owner: { login: "org" },
              isPrivate: true,
              defaultBranchRef: { name: "main" },
            },
            {
              nameWithOwner: "org/repo-two",
              name: "repo-two",
              owner: { login: "org" },
              isPrivate: false,
              defaultBranchRef: { name: "develop" },
            },
          ],
          pageInfo: { hasNextPage: false, endCursor: null },
        },
      },
    };

    const repos = parseRepositories(result);
    expect(repos).toHaveLength(2);
    expect(repos[0]).toEqual({
      fullName: "org/repo-one",
      name: "repo-one",
      owner: "org",
      private: true,
      defaultBranch: "main",
    });
    expect(repos[1]).toEqual({
      fullName: "org/repo-two",
      name: "repo-two",
      owner: "org",
      private: false,
      defaultBranch: "develop",
    });
  });

  it("should default to 'main' when defaultBranchRef is null", () => {
    const result: RepositoriesQueryResult = {
      viewer: {
        repositories: {
          nodes: [
            {
              nameWithOwner: "user/repo",
              name: "repo",
              owner: { login: "user" },
              isPrivate: false,
              defaultBranchRef: null,
            },
          ],
          pageInfo: { hasNextPage: false, endCursor: null },
        },
      },
    };

    const repos = parseRepositories(result);
    expect(repos[0].defaultBranch).toBe("main");
  });

  it("should return empty array for empty nodes", () => {
    const result: RepositoriesQueryResult = {
      viewer: {
        repositories: {
          nodes: [],
          pageInfo: { hasNextPage: false, endCursor: null },
        },
      },
    };

    expect(parseRepositories(result)).toEqual([]);
  });
});
