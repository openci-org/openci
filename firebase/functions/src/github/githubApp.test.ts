import { beforeEach, describe, expect, it, vi } from "vitest";
import {
  createCheckRun,
  getInstallationToken,
  GitHubGraphqlError,
  githubGet,
  githubGraphql,
  githubPost,
} from "./githubApp.js";

const { mockCreateAppAuth, mockRequestDefaults, mockOctokitRequest, mockFetch } = vi.hoisted(
  () => ({
    mockCreateAppAuth: vi.fn(),
    mockRequestDefaults: vi.fn(),
    mockOctokitRequest: vi.fn(),
    mockFetch: vi.fn(),
  }),
);

vi.mock("firebase-functions/params", () => ({
  defineSecret: (name: string) => ({
    value: () => {
      if (name === "GITHUB_APP_ID") return "12345";
      if (name === "GITHUB_PRIVATE_KEY") return "private-key";
      throw new Error(`unexpected secret: ${name}`);
    },
  }),
}));

vi.mock("@octokit/auth-app", () => ({
  createAppAuth: (...args: unknown[]) => mockCreateAppAuth(...args),
}));

vi.mock("@octokit/request", () => ({
  request: {
    defaults: (...args: unknown[]) => mockRequestDefaults(...args),
  },
}));

vi.mock("@octokit/rest", () => ({
  Octokit: class MockOctokit {
    request = mockOctokitRequest;
  },
}));

describe("GitHub API helpers", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    vi.stubGlobal("fetch", mockFetch);
    mockRequestDefaults.mockReturnValue("request-with-base-url");
    mockCreateAppAuth.mockReturnValue(
      vi.fn().mockResolvedValue({
        token: "installation-token",
        expiresAt: "2026-01-01T00:00:00Z",
      }),
    );
    mockOctokitRequest.mockResolvedValue({ data: { ok: true } });
    mockFetch.mockResolvedValue({
      ok: true,
      status: 200,
      statusText: "OK",
      json: () => Promise.resolve({ data: {} }),
    });
  });

  it("requests an installation token using GitHub App credentials", async () => {
    const result = await getInstallationToken(123);

    expect(result).toEqual({
      token: "installation-token",
      expiresAt: "2026-01-01T00:00:00Z",
    });
    expect(mockRequestDefaults).toHaveBeenCalledWith({ baseUrl: "https://api.github.com" });
    expect(mockCreateAppAuth).toHaveBeenCalledWith(
      expect.objectContaining({
        appId: "12345",
        privateKey: "private-key",
        installationId: 123,
        timeDifference: 30,
        request: "request-with-base-url",
      }),
    );
  });

  it("sends GET requests with query parameters", async () => {
    mockOctokitRequest.mockResolvedValue({ data: { ok: true } });

    await githubGet("/repos/openci/openci", "token-123", {
      queryParameters: { per_page: 100 },
    });

    expect(mockOctokitRequest).toHaveBeenCalledWith(
      "GET /repos/openci/openci",
      expect.objectContaining({
        per_page: 100,
      }),
    );
  });

  it("sends POST request bodies", async () => {
    mockOctokitRequest.mockResolvedValue({ data: { id: 1 } });

    await githubPost("/repos/openci/openci/issues", "token-123", { title: "hello" });

    expect(mockOctokitRequest).toHaveBeenCalledWith(
      "POST /repos/openci/openci/issues",
      expect.objectContaining({
        title: "hello",
      }),
    );
  });

  it("sends GraphQL requests to the derived endpoint", async () => {
    await githubGraphql("query { viewer { login } }", "token-123", {
      apiBaseUrl: "https://github.example.com/api/v3",
      variables: { owner: "openci" },
    });

    expect(mockFetch).toHaveBeenCalledWith(
      "https://github.example.com/api/graphql",
      expect.objectContaining({
        method: "POST",
        headers: expect.objectContaining({ authorization: "bearer token-123" }),
        body: JSON.stringify({
          query: "query { viewer { login } }",
          variables: { owner: "openci" },
        }),
      }),
    );
  });

  it("throws GraphQL errors with the response details", async () => {
    const errors = [{ message: "Resource not accessible by integration" }];
    mockFetch.mockResolvedValue({
      ok: true,
      status: 200,
      statusText: "OK",
      json: () => Promise.resolve({ data: null, errors }),
    });

    await expect(githubGraphql("query { viewer { login } }", "token-123")).rejects.toMatchObject({
      name: "GitHubGraphqlError",
      status: 200,
      statusText: "OK",
      errors,
    });
    await expect(githubGraphql("query { viewer { login } }", "token-123")).rejects.toBeInstanceOf(
      GitHubGraphqlError,
    );
  });

  it("returns null when check run creation fails", async () => {
    mockOctokitRequest.mockRejectedValue(new Error("bad credentials"));

    const result = await createCheckRun({
      token: "token-123",
      owner: "openci",
      repo: "openci",
      name: "Build",
      headSha: "abc",
      status: "queued",
      detailsUrl: "https://dashboard.openci.org/runs/1",
    });

    expect(result).toBeNull();
  });
});
