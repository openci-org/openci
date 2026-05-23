import { beforeEach, describe, expect, it, vi } from "vitest";
import { githubGet, githubGraphql, GitHubGraphqlError, githubPost } from "./githubRequests.js";

const { mockRequestDefaults, mockOctokitRequest, mockFetch } = vi.hoisted(() => ({
  mockRequestDefaults: vi.fn(),
  mockOctokitRequest: vi.fn(),
  mockFetch: vi.fn(),
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

describe("GitHub REST/GraphQL API helpers", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    vi.stubGlobal("fetch", mockFetch);
    mockRequestDefaults.mockReturnValue("request-with-base-url");
    mockOctokitRequest.mockResolvedValue({ data: { ok: true } });
    mockFetch.mockResolvedValue({
      ok: true,
      status: 200,
      statusText: "OK",
      json: () => Promise.resolve({ data: {} }),
    });
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
});
