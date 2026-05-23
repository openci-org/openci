import { beforeEach, describe, expect, it, vi } from "vitest";
import { createCheckRun, getInstallationToken } from "./githubApp.js";

const { mockCreateAppAuth, mockRequestDefaults, mockOctokitRequest } = vi.hoisted(() => ({
  mockCreateAppAuth: vi.fn(),
  mockRequestDefaults: vi.fn(),
  mockOctokitRequest: vi.fn(),
}));

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

// mock githubPost from githubRequests to avoid real network call in createCheckRun
vi.mock("./githubRequests.js", () => ({
  githubPost: (...args: unknown[]) => mockOctokitRequest(...args),
}));

describe("GitHub App Helpers", () => {
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
