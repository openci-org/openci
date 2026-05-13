import firebaseFunctionsTest from "firebase-functions-test";
import type { CallableRequest } from "firebase-functions/v2/https";
import { beforeEach, describe, expect, it, vi } from "vitest";
import type { AcceptInvitationResponse } from "./acceptInvitation";
type AuthData = NonNullable<CallableRequest["auth"]>;

const TEAM_ID = "team-aaa-bbb";
const INVITATION_ID = "inv-111-222";
const MOCK_EMAIL = "alice@example.com";
const MOCK_DIFFERENT_EMAIL = "bob@example.com";

const { mockGetInvitationByToken, mockExpireInvitation, mockAcceptInvitationAndJoinTeam } =
  vi.hoisted(() => ({
    mockGetInvitationByToken: vi.fn(),
    mockExpireInvitation: vi.fn(),
    mockAcceptInvitationAndJoinTeam: vi.fn(),
  }));

vi.mock("../firestoreData", () => ({
  getInvitationByToken: (...args: unknown[]) => mockGetInvitationByToken(...args),
  expireInvitation: (...args: unknown[]) => mockExpireInvitation(...args),
  acceptInvitationAndJoinTeam: (...args: unknown[]) => mockAcceptInvitationAndJoinTeam(...args),
}));

const testEnv = firebaseFunctionsTest();

const { acceptInvitation } = await import("./acceptInvitation");

interface AcceptInvitationRequest {
  token: string;
}

const wrapped = testEnv.wrap(acceptInvitation) as (req: {
  data: AcceptInvitationRequest;
  auth?: AuthData;
}) => Promise<AcceptInvitationResponse>;

function makeAuth(
  overrides: {
    uid?: string;
    email?: string;
    email_verified?: boolean;
  } = {},
): AuthData {
  const { uid = "user-123", email = MOCK_EMAIL, email_verified = true } = overrides;
  return {
    uid,
    token: {
      uid,
      email,
      email_verified,
      aud: "",
      auth_time: 0,
      exp: 0,
      firebase: { identities: {}, sign_in_provider: "password" },
      iat: 0,
      iss: "",
      sub: uid,
    },
  } as AuthData;
}

function makePendingInvitation(overrides: Record<string, unknown> = {}) {
  const future = new Date(Date.now() + 86_400_000).toISOString();
  return {
    id: INVITATION_ID,
    email: MOCK_EMAIL,
    status: "PENDING",
    expiresAt: future,
    createdAt: new Date().toISOString(),
    teamNameSnapshot: "Team Alpha",
    team: { id: TEAM_ID, name: "Team Alpha", __typename: "Team_Key" },
    invitedBy: { id: "owner-1", email: "owner@example.com", __typename: "User_Key" },
    __typename: "Invitation_Key",
    ...overrides,
  };
}

const VALID_TOKEN = "test-invitation-token";

describe("acceptInvitation", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("rejects unauthenticated calls", async () => {
    await expect(wrapped({ data: { token: VALID_TOKEN } })).rejects.toThrow(
      expect.objectContaining({ code: "unauthenticated" }),
    );
  });

  it("accepts a valid token invitation even when email is unverified", async () => {
    mockGetInvitationByToken.mockResolvedValue({
      data: { invitations: [makePendingInvitation()] },
    });
    mockAcceptInvitationAndJoinTeam.mockResolvedValue({});

    const result = await wrapped({
      data: { token: VALID_TOKEN },
      auth: makeAuth({ email_verified: false }),
    });

    expect(result).toEqual({
      status: "accepted",
      teamId: TEAM_ID,
      teamName: "Team Alpha",
    });
  });

  it("rejects auth with no email", async () => {
    await expect(
      wrapped({
        data: { token: VALID_TOKEN },
        auth: makeAuth({ email: "" }),
      }),
    ).rejects.toThrow(
      expect.objectContaining({
        code: "failed-precondition",
        message: expect.stringContaining("no email"),
      }),
    );
  });

  it("rejects missing token", async () => {
    await expect(
      wrapped({ data: {} as AcceptInvitationRequest, auth: makeAuth() }),
    ).rejects.toThrow(expect.objectContaining({ code: "invalid-argument" }));
  });

  it("rejects empty string token", async () => {
    await expect(wrapped({ data: { token: "" }, auth: makeAuth() })).rejects.toThrow(
      expect.objectContaining({ code: "invalid-argument" }),
    );
  });

  it("throws not-found when no invitation matches", async () => {
    mockGetInvitationByToken.mockResolvedValue({
      data: { invitations: [] },
    });
    await expect(wrapped({ data: { token: VALID_TOKEN }, auth: makeAuth() })).rejects.toThrow(
      expect.objectContaining({ code: "not-found" }),
    );
  });

  it("throws permission-denied when email does not match", async () => {
    mockGetInvitationByToken.mockResolvedValue({
      data: { invitations: [makePendingInvitation({ email: MOCK_DIFFERENT_EMAIL })] },
    });
    await expect(wrapped({ data: { token: VALID_TOKEN }, auth: makeAuth() })).rejects.toThrow(
      expect.objectContaining({ code: "permission-denied" }),
    );
  });

  it("throws failed-precondition for ACCEPTED invitation", async () => {
    mockGetInvitationByToken.mockResolvedValue({
      data: { invitations: [makePendingInvitation({ status: "ACCEPTED" })] },
    });

    await expect(wrapped({ data: { token: VALID_TOKEN }, auth: makeAuth() })).rejects.toThrow(
      expect.objectContaining({
        code: "failed-precondition",
        message: expect.stringContaining("already been accepted"),
      }),
    );
  });

  it("repairs and accepts an already accepted invitation for the same user", async () => {
    mockGetInvitationByToken.mockResolvedValue({
      data: {
        invitations: [makePendingInvitation({ status: "ACCEPTED", acceptedById: "user-123" })],
      },
    });
    mockAcceptInvitationAndJoinTeam.mockResolvedValue({});

    const result = await wrapped({
      data: { token: VALID_TOKEN },
      auth: makeAuth({ uid: "user-123" }),
    });

    expect(result).toEqual({
      status: "accepted",
      teamId: TEAM_ID,
      teamName: "Team Alpha",
    });
    expect(mockAcceptInvitationAndJoinTeam).toHaveBeenCalledOnce();
  });

  it("throws deadline-exceeded for EXPIRED invitation", async () => {
    mockGetInvitationByToken.mockResolvedValue({
      data: { invitations: [makePendingInvitation({ status: "EXPIRED" })] },
    });
    await expect(wrapped({ data: { token: VALID_TOKEN }, auth: makeAuth() })).rejects.toThrow(
      expect.objectContaining({ code: "deadline-exceeded" }),
    );
  });

  it("throws internal for unhandled invitation status", async () => {
    mockGetInvitationByToken.mockResolvedValue({
      data: { invitations: [makePendingInvitation({ status: "UNKNOWN" })] },
    });

    await expect(wrapped({ data: { token: VALID_TOKEN }, auth: makeAuth() })).rejects.toThrow(
      expect.objectContaining({ code: "internal" }),
    );
  });

  it("expires and rejects a PENDING invitation past expiresAt", async () => {
    const past = new Date(Date.now() - 1000).toISOString();
    mockGetInvitationByToken.mockResolvedValue({
      data: { invitations: [makePendingInvitation({ expiresAt: past })] },
    });

    await expect(wrapped({ data: { token: VALID_TOKEN }, auth: makeAuth() })).rejects.toThrow(
      expect.objectContaining({ code: "deadline-exceeded" }),
    );

    expect(mockExpireInvitation).toHaveBeenCalledOnce();
    expect(mockExpireInvitation).toHaveBeenCalledWith(
      { id: INVITATION_ID },
      expect.objectContaining({ impersonate: expect.any(Object) }),
    );
  });

  it("accepts a valid PENDING invitation and returns team info", async () => {
    mockGetInvitationByToken.mockResolvedValue({
      data: { invitations: [makePendingInvitation()] },
    });
    mockAcceptInvitationAndJoinTeam.mockResolvedValue({});

    const result = await wrapped({
      data: { token: VALID_TOKEN },
      auth: makeAuth(),
    });

    expect(result).toEqual({
      status: "accepted",
      teamId: TEAM_ID,
      teamName: "Team Alpha",
    });

    expect(mockAcceptInvitationAndJoinTeam).toHaveBeenCalledOnce();
    expect(mockAcceptInvitationAndJoinTeam).toHaveBeenCalledWith(
      { id: INVITATION_ID, teamId: TEAM_ID },
      expect.objectContaining({ impersonate: expect.any(Object) }),
    );
  });

  it("accepts invitation when email cases differ", async () => {
    mockGetInvitationByToken.mockResolvedValue({
      data: { invitations: [makePendingInvitation({ email: "Alice@Example.COM" })] },
    });
    mockAcceptInvitationAndJoinTeam.mockResolvedValue({});

    const result = await wrapped({
      data: { token: VALID_TOKEN },
      auth: makeAuth({ email: "alice@example.com" }),
    });

    expect(result).toEqual({
      status: "accepted",
      teamId: TEAM_ID,
      teamName: "Team Alpha",
    });
  });
});
