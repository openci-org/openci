import firebaseFunctionsTest from "firebase-functions-test";
import type { CallableRequest } from "firebase-functions/v2/https";
import { beforeEach, describe, expect, it, vi } from "vitest";

type AuthData = NonNullable<CallableRequest["auth"]>;

const { mockVerifyTeamMembership, mockGetAscCredentials, mockGenerateAscJwt, mockAscApiFetch } =
  vi.hoisted(() => ({
    mockVerifyTeamMembership: vi.fn(),
    mockGetAscCredentials: vi.fn(),
    mockGenerateAscJwt: vi.fn(),
    mockAscApiFetch: vi.fn(),
  }));

vi.mock("../team/teamAuth", () => ({
  verifyTeamMembership: (...args: unknown[]) => mockVerifyTeamMembership(...args),
}));

vi.mock("./ascClient", () => ({
  getAscCredentials: (...args: unknown[]) => mockGetAscCredentials(...args),
  generateAscJwt: (...args: unknown[]) => mockGenerateAscJwt(...args),
  ascApiFetch: (...args: unknown[]) => mockAscApiFetch(...args),
}));

const testEnv = firebaseFunctionsTest();

const { ascListApps, ascListBuilds, ascSubmitToTestFlight } = await import("./ascHandlers");

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

describe("ASC handlers", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mockVerifyTeamMembership.mockResolvedValue({});
    mockGetAscCredentials.mockResolvedValue({
      issuerId: "issuer",
      keyId: "key",
      privateKey: "private",
    });
    mockGenerateAscJwt.mockReturnValue("asc-token");
  });

  it("lists ASC apps", async () => {
    mockAscApiFetch.mockResolvedValue({
      data: [
        {
          id: "app-1",
          attributes: { name: "OpenCI", bundleId: "org.openci.app", sku: "SKU" },
        },
      ],
    });
    const wrapped = testEnv.wrap(ascListApps) as (req: {
      data: { teamId: string };
      auth?: AuthData;
    }) => Promise<{ apps: unknown[] }>;

    const result = await wrapped({ data: { teamId: "team-1" }, auth: makeAuth() });

    expect(result).toEqual({
      apps: [{ id: "app-1", name: "OpenCI", bundleId: "org.openci.app", sku: "SKU" }],
    });
  });

  it("lists ASC builds", async () => {
    mockAscApiFetch.mockResolvedValue({
      included: [{ type: "preReleaseVersions", id: "pre-1", attributes: { version: "1.0.0" } }],
      data: [
        {
          id: "build-1",
          attributes: { version: "42" },
          relationships: { preReleaseVersion: { data: { id: "pre-1" } } },
        },
      ],
    });
    const wrapped = testEnv.wrap(ascListBuilds) as (req: {
      data: { teamId: string; appId: string };
      auth?: AuthData;
    }) => Promise<{ builds: unknown[] }>;

    const result = await wrapped({ data: { teamId: "team-1", appId: "app-1" }, auth: makeAuth() });

    expect(result.builds).toEqual([expect.objectContaining({ id: "build-1", version: "1.0.0" })]);
    expect(mockAscApiFetch).toHaveBeenCalledWith(
      expect.objectContaining({ path: expect.stringContaining("filter[app]=app-1") }),
    );
  });

  it("submits a build to the first external TestFlight group", async () => {
    mockAscApiFetch
      .mockResolvedValueOnce({
        data: [
          { id: "internal", attributes: { name: "Internal", isInternalGroup: true } },
          { id: "external", attributes: { name: "External Testers", isInternalGroup: false } },
        ],
      })
      .mockResolvedValueOnce({});
    const wrapped = testEnv.wrap(ascSubmitToTestFlight) as (req: {
      data: { teamId: string; buildId: string };
      auth?: AuthData;
    }) => Promise<{ success: true; betaGroupName: string }>;

    const result = await wrapped({
      data: { teamId: "team-1", buildId: "build-1" },
      auth: makeAuth(),
    });

    expect(result).toEqual({ success: true, betaGroupName: "External Testers" });
    expect(mockAscApiFetch).toHaveBeenLastCalledWith(
      expect.objectContaining({
        path: "/betaGroups/external/relationships/builds",
        method: "POST",
      }),
    );
  });
});
