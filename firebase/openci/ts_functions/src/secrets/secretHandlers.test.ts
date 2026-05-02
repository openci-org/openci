import firebaseFunctionsTest from "firebase-functions-test";
import type { CallableRequest } from "firebase-functions/v2/https";
import { beforeEach, describe, expect, it, vi } from "vitest";

type AuthData = NonNullable<CallableRequest["auth"]>;

const {
  mockVerifyTeamMembership,
  mockCreateSecretWithValue,
  mockDeleteSecretByPath,
  mockAddSecretVersionByPath,
  mockFindSecretByNameForTeam,
  mockCreateSecretMetadata,
  mockGetSecretPathForTeam,
  mockDeleteSecretMetadata,
  mockUpdateSecretMetadata,
  mockListWorkflowsForTeam,
  mockUpdateWorkflowSecretKeys,
} = vi.hoisted(() => ({
  mockVerifyTeamMembership: vi.fn(),
  mockCreateSecretWithValue: vi.fn(),
  mockDeleteSecretByPath: vi.fn(),
  mockAddSecretVersionByPath: vi.fn(),
  mockFindSecretByNameForTeam: vi.fn(),
  mockCreateSecretMetadata: vi.fn(),
  mockGetSecretPathForTeam: vi.fn(),
  mockDeleteSecretMetadata: vi.fn(),
  mockUpdateSecretMetadata: vi.fn(),
  mockListWorkflowsForTeam: vi.fn(),
  mockUpdateWorkflowSecretKeys: vi.fn(),
}));

vi.mock("../team/teamAuth", () => ({
  verifyTeamMembership: (...args: unknown[]) => mockVerifyTeamMembership(...args),
}));

vi.mock("../secretManager", () => ({
  createSecretWithValue: (...args: unknown[]) => mockCreateSecretWithValue(...args),
  deleteSecretByPath: (...args: unknown[]) => mockDeleteSecretByPath(...args),
  addSecretVersionByPath: (...args: unknown[]) => mockAddSecretVersionByPath(...args),
}));

vi.mock("@openci/dataconnect-admin", () => ({
  findSecretByNameForTeam: (...args: unknown[]) => mockFindSecretByNameForTeam(...args),
  createSecretMetadata: (...args: unknown[]) => mockCreateSecretMetadata(...args),
  getSecretPathForTeam: (...args: unknown[]) => mockGetSecretPathForTeam(...args),
  deleteSecretMetadata: (...args: unknown[]) => mockDeleteSecretMetadata(...args),
  updateSecretMetadata: (...args: unknown[]) => mockUpdateSecretMetadata(...args),
  listWorkflowsForTeam: (...args: unknown[]) => mockListWorkflowsForTeam(...args),
  updateWorkflowSecretKeys: (...args: unknown[]) => mockUpdateWorkflowSecretKeys(...args),
}));

const testEnv = firebaseFunctionsTest();

const { createSecretV1, deleteSecretV1, setupAscApiKeyV1, updateSecretV1 } =
  await import("./secretHandlers");

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

describe("secret handlers", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mockVerifyTeamMembership.mockResolvedValue({});
    mockCreateSecretWithValue.mockResolvedValue("projects/test/secrets/secret-id");
    mockDeleteSecretByPath.mockResolvedValue(undefined);
    mockAddSecretVersionByPath.mockResolvedValue(undefined);
    mockFindSecretByNameForTeam.mockResolvedValue({ data: { secrets: [] } });
    mockCreateSecretMetadata.mockResolvedValue({});
    mockGetSecretPathForTeam.mockResolvedValue({
      data: {
        secret: {
          id: "doc-1",
          teamId: "team-1",
          name: "API_KEY",
          pathToSecret: "projects/test/secrets/secret-id",
        },
      },
    });
    mockDeleteSecretMetadata.mockResolvedValue({});
    mockUpdateSecretMetadata.mockResolvedValue({});
    mockListWorkflowsForTeam.mockResolvedValue({ data: { workflows: [] } });
    mockUpdateWorkflowSecretKeys.mockResolvedValue({});
  });

  it("creates a secret document and Secret Manager secret", async () => {
    const wrapped = testEnv.wrap(createSecretV1) as (req: {
      data: { teamId: string; name: string; value: string };
      auth?: AuthData;
    }) => Promise<{ success: true; documentId: string }>;

    const result = await wrapped({
      data: { teamId: "team-1", name: "API_KEY", value: "secret-value" },
      auth: makeAuth(),
    });

    expect(result.success).toBe(true);
    expect(result.documentId).toEqual(expect.any(String));
    expect(mockCreateSecretWithValue).toHaveBeenCalledWith(expect.any(String), "secret-value");
    expect(mockCreateSecretMetadata).toHaveBeenCalledWith(
      expect.objectContaining({
        name: "API_KEY",
        teamId: "team-1",
        pathToSecret: "projects/test/secrets/secret-id",
      }),
    );
  });

  it("rejects duplicate secret names", async () => {
    mockFindSecretByNameForTeam.mockResolvedValue({ data: { secrets: [{ name: "API_KEY" }] } });
    const wrapped = testEnv.wrap(createSecretV1) as (req: {
      data: { teamId: string; name: string; value: string };
      auth?: AuthData;
    }) => Promise<unknown>;

    await expect(
      wrapped({
        data: { teamId: "team-1", name: "API_KEY", value: "secret-value" },
        auth: makeAuth(),
      }),
    ).rejects.toThrow(expect.objectContaining({ code: "already-exists" }));
  });

  it("deletes a secret from Secret Manager and Firestore", async () => {
    const wrapped = testEnv.wrap(deleteSecretV1) as (req: {
      data: { teamId: string; documentId: string };
      auth?: AuthData;
    }) => Promise<{ success: true }>;

    const result = await wrapped({
      data: { teamId: "team-1", documentId: "doc-1" },
      auth: makeAuth(),
    });

    expect(result).toEqual({ success: true });
    expect(mockDeleteSecretByPath).toHaveBeenCalledWith("projects/test/secrets/secret-id");
    expect(mockDeleteSecretMetadata).toHaveBeenCalledWith({ id: "doc-1" });
  });

  it("adds a new Secret Manager version when updating a value", async () => {
    const wrapped = testEnv.wrap(updateSecretV1) as (req: {
      data: { teamId: string; documentId: string; name: string; value?: string };
      auth?: AuthData;
    }) => Promise<{ success: true }>;

    const result = await wrapped({
      data: { teamId: "team-1", documentId: "doc-1", name: "API_KEY", value: "new-value" },
      auth: makeAuth(),
    });

    expect(result).toEqual({ success: true });
    expect(mockAddSecretVersionByPath).toHaveBeenCalledWith(
      "projects/test/secrets/secret-id",
      "new-value",
    );
  });

  it("creates all ASC credential secrets", async () => {
    const wrapped = testEnv.wrap(setupAscApiKeyV1) as (req: {
      data: { teamId: string; issuerId: string; keyId: string; privateKey: string };
      auth?: AuthData;
    }) => Promise<{ success: true; documentIds: Record<string, string> }>;

    const result = await wrapped({
      data: {
        teamId: "team-1",
        issuerId: "issuer",
        keyId: "key",
        privateKey: "private",
      },
      auth: makeAuth(),
    });

    expect(result.success).toBe(true);
    expect(Object.keys(result.documentIds)).toEqual([
      "OPENCI_ASC_ISSUER_ID",
      "OPENCI_ASC_KEY_ID",
      "OPENCI_ASC_PRIVATE_KEY",
    ]);
    expect(mockCreateSecretWithValue).toHaveBeenCalledTimes(3);
  });
});
