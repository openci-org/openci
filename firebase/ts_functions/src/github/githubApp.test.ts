import { beforeEach, describe, expect, it, vi } from "vitest";
import {
  createCheckRun,
  getInstallationToken,
  githubGet,
  githubGraphql,
  githubPost,
} from "./githubApp";

const {
  mockAccessSecret,
  mockCreateAppAuth,
  mockRequestDefaults,
  mockOctokitRequest,
  mockGraphqlDefaults,
  mockGraphqlWithAuth,
} = vi.hoisted(() => ({
  mockAccessSecret: vi.fn(),
  mockCreateAppAuth: vi.fn(),
  mockRequestDefaults: vi.fn(),
  mockOctokitRequest: vi.fn(),
  mockGraphqlDefaults: vi.fn(),
  mockGraphqlWithAuth: vi.fn(),
}));

vi.mock("../secretManager", () => ({
  accessSecret: (secretId: string) => mockAccessSecret(secretId),
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

vi.mock("@octokit/graphql", () => ({
  graphql: {
    defaults: (...args: unknown[]) => mockGraphqlDefaults(...args),
  },
}));

describe("GitHub API helpers", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mockRequestDefaults.mockReturnValue("request-with-base-url");
    mockCreateAppAuth.mockReturnValue(
      vi.fn().mockResolvedValue({
        token: "installation-token",
        expiresAt: "2026-01-01T00:00:00Z",
      }),
    );
    mockOctokitRequest.mockResolvedValue({ data: { ok: true } });
    mockGraphqlDefaults.mockReturnValue(mockGraphqlWithAuth);
    mockGraphqlWithAuth.mockResolvedValue({ data: {} });
  });

  it("requests an installation token using GitHub App credentials", async () => {
    mockAccessSecret.mockImplementation((secretId: string) => {
      if (secretId === "GITHUB_APP_ID") return Promise.resolve("12345");
      if (secretId === "GITHUB_PRIVATE_KEY") return Promise.resolve("private-key");
      throw new Error(`unexpected secret: ${secretId}`);
    });

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

    expect(mockGraphqlDefaults).toHaveBeenCalledWith(
      expect.objectContaining({
        baseUrl: "https://github.example.com/api/graphql",
        headers: { authorization: "bearer token-123" },
      }),
    );
    expect(mockGraphqlWithAuth).toHaveBeenCalledWith("query { viewer { login } }", {
      owner: "openci",
    });
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
