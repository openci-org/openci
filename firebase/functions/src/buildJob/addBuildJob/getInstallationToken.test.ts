import { beforeEach, describe, expect, it, vi } from "vitest";

import { getInstallationToken } from "./getInstallationToken.js";

const { mockCreateAppAuth, mockRequestDefaults } = vi.hoisted(() => ({
  mockCreateAppAuth: vi.fn(),
  mockRequestDefaults: vi.fn(),
}));

vi.mock("@octokit/auth-app", () => ({
  createAppAuth: (...args: unknown[]) => mockCreateAppAuth(...args),
}));

vi.mock("@octokit/request", () => ({
  request: {
    defaults: (...args: unknown[]) => mockRequestDefaults(...args),
  },
}));

describe("getInstallationToken in addBuildJob", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mockRequestDefaults.mockReturnValue("request-with-base-url");
    mockCreateAppAuth.mockReturnValue(
      vi.fn().mockResolvedValue({
        token: "mock-token",
        expiresAt: "2026-01-01T00:00:00Z",
      }),
    );
  });

  it("requests an installation token with GITHUB_APP_ID, GITHUB_PRIVATE_KEY, and timeDifference", async () => {
    const result = await getInstallationToken(
      123,
      "https://api.github.com",
      "app-id",
      "private-key"
    );

    expect(result).toEqual({
      token: "mock-token",
      expiresAt: "2026-01-01T00:00:00Z",
    });
    expect(mockRequestDefaults).toHaveBeenCalledWith({ baseUrl: "https://api.github.com" });
    expect(mockCreateAppAuth).toHaveBeenCalledWith(
      expect.objectContaining({
        appId: "app-id",
        privateKey: "private-key",
        installationId: 123,
        timeDifference: 30,
        request: "request-with-base-url",
      }),
    );
  });
});
