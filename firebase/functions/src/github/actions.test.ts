import firebaseFunctionsTest from "firebase-functions-test";
import type { CallableRequest } from "firebase-functions/v2/https";
import { beforeEach, describe, expect, it, vi } from "vitest";
import type { SearchGitHubActionsResponse } from "./actions";

type AuthData = NonNullable<CallableRequest["auth"]>;

const { mockVerifyTeamMembership, mockGetInstallationToken, mockGithubGet } = vi.hoisted(() => ({
  mockVerifyTeamMembership: vi.fn(),
  mockGetInstallationToken: vi.fn(),
  mockGithubGet: vi.fn(),
}));

vi.mock("../team/teamAuth", () => ({
  verifyTeamMembership: (...args: unknown[]) => mockVerifyTeamMembership(...args),
}));

vi.mock("./githubApp", () => ({
  getInstallationToken: (...args: unknown[]) => mockGetInstallationToken(...args),
}));

vi.mock("./githubRequests", () => ({
  githubGet: (...args: unknown[]) => mockGithubGet(...args),
}));

const testEnv = firebaseFunctionsTest();

const { searchGitHubActions } = await import("./actions");

const wrapped = testEnv.wrap(searchGitHubActions) as (req: {
  data: { teamId?: string; type?: string; query?: string; fullName?: string };
  auth?: AuthData;
}) => Promise<SearchGitHubActionsResponse>;

function makeAuth(): AuthData {
  return {
    uid: "user-123",
    token: {
      uid: "user-123",
      aud: "",
      auth_time: 0,
      exp: 0,
      firebase: { identities: {}, sign_in_provider: "password" },
      iat: 0,
      iss: "",
      sub: "user-123",
    },
  } as AuthData;
}

describe("searchGitHubActions", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mockVerifyTeamMembership.mockResolvedValue({ installationIds: [101] });
    mockGetInstallationToken.mockResolvedValue({ token: "installation-token", expiresAt: "" });
  });

  it("searches GitHub repositories for actions", async () => {
    mockGithubGet.mockResolvedValue({
      items: [
        {
          full_name: "actions/checkout",
          description: "Checkout a repository",
          stargazers_count: 1000,
          owner: { login: "actions", avatar_url: "https://example.com/avatar.png" },
          html_url: "https://github.com/actions/checkout",
          default_branch: "main",
        },
      ],
    });

    const result = await wrapped({
      data: { teamId: "team-1", type: "search", query: "checkout" },
      auth: makeAuth(),
    });

    expect(result).toEqual({
      actions: [
        {
          fullName: "actions/checkout",
          description: "Checkout a repository",
          stars: 1000,
          owner: "actions",
          avatarUrl: "https://example.com/avatar.png",
          htmlUrl: "https://github.com/actions/checkout",
          defaultBranch: "main",
          isOfficial: true,
        },
      ],
    });
    expect(mockGithubGet).toHaveBeenCalledWith(
      "/search/repositories",
      "installation-token",
      expect.objectContaining({
        queryParameters: {
          q: "checkout",
          sort: "stars",
          order: "desc",
          per_page: 50,
        },
      }),
    );
  });

  it("returns major version tags when present", async () => {
    mockGithubGet.mockResolvedValue([{ name: "v4" }, { name: "v3" }, { name: "v4.1.0" }]);

    const result = await wrapped({
      data: { teamId: "team-1", type: "tags", fullName: "actions/checkout" },
      auth: makeAuth(),
    });

    expect(result).toEqual({ tags: ["v4", "v3"] });
  });

  it("returns all tags when no major version tags exist", async () => {
    mockGithubGet.mockResolvedValue([{ name: "main" }, { name: "release-1" }]);

    const result = await wrapped({
      data: { teamId: "team-1", type: "tags", fullName: "actions/checkout" },
      auth: makeAuth(),
    });

    expect(result).toEqual({ tags: ["main", "release-1"] });
  });
});
