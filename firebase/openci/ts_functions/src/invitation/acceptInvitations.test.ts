import firebaseFunctionsTest from "firebase-functions-test";
import type { CallableRequest } from "firebase-functions/v2/https";
import { beforeEach, describe, expect, it, vi } from "vitest";
import type { AcceptInvitationsResponse } from "./acceptInvitations";

type AuthData = NonNullable<CallableRequest["auth"]>;

const TEAM_ID = "team-aaa-bbb";
const SECOND_TEAM_ID = "team-ccc-ddd";
const INVITATION_ID = "inv-111-222";
const EXPIRED_INVITATION_ID = "inv-expired";
const MOCK_EMAIL = "alice@example.com";

const { mockListMyPendingInvitations, mockExpireInvitation, mockAcceptInvitationAndJoinTeam } =
  vi.hoisted(() => ({
    mockListMyPendingInvitations: vi.fn(),
    mockExpireInvitation: vi.fn(),
    mockAcceptInvitationAndJoinTeam: vi.fn(),
  }));

vi.mock("@openci/dataconnect-admin", () => ({
  listMyPendingInvitations: (...args: unknown[]) => mockListMyPendingInvitations(...args),
  expireInvitation: (...args: unknown[]) => mockExpireInvitation(...args),
  acceptInvitationAndJoinTeam: (...args: unknown[]) => mockAcceptInvitationAndJoinTeam(...args),
}));

const testEnv = firebaseFunctionsTest();

const { acceptInvitations } = await import("./acceptInvitations");

const wrapped = testEnv.wrap(acceptInvitations) as (req: {
  data?: unknown;
  auth?: AuthData;
}) => Promise<AcceptInvitationsResponse>;

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
    teamNameSnapshot: "Team Alpha",
    expiresAt: future,
    createdAt: new Date().toISOString(),
    team: { id: TEAM_ID, name: "Team Alpha", __typename: "Team_Key" },
    __typename: "Invitation_Key",
    ...overrides,
  };
}

describe("acceptInvitations", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("rejects unauthenticated calls", async () => {
    await expect(wrapped({ data: undefined })).rejects.toThrow(
      expect.objectContaining({ code: "unauthenticated" }),
    );
  });

  it("returns an empty result when auth has no email", async () => {
    const result = await wrapped({
      data: undefined,
      auth: makeAuth({ email: "" }),
    });

    expect(result).toEqual({
      joinedTeams: [],
      message: "No email found",
    });
    expect(mockListMyPendingInvitations).not.toHaveBeenCalled();
  });

  it("rejects unverified email", async () => {
    await expect(
      wrapped({
        data: undefined,
        auth: makeAuth({ email_verified: false }),
      }),
    ).rejects.toThrow(
      expect.objectContaining({
        code: "failed-precondition",
        message: expect.stringContaining("verified email"),
      }),
    );
  });

  it("returns no pending invitations when none match", async () => {
    mockListMyPendingInvitations.mockResolvedValue({
      data: { invitations: [] },
    });

    const result = await wrapped({ data: undefined, auth: makeAuth() });

    expect(result).toEqual({
      joinedTeams: [],
      message: "No pending invitations",
    });
    expect(mockListMyPendingInvitations).toHaveBeenCalledOnce();
  });

  it("expires and skips expired invitations", async () => {
    const past = new Date(Date.now() - 1000).toISOString();
    mockListMyPendingInvitations.mockResolvedValue({
      data: {
        invitations: [
          makePendingInvitation({
            id: EXPIRED_INVITATION_ID,
            expiresAt: past,
          }),
        ],
      },
    });
    mockExpireInvitation.mockResolvedValue({});

    const result = await wrapped({ data: undefined, auth: makeAuth() });

    expect(result).toEqual({
      joinedTeams: [],
      message: "No valid invitations",
    });
    expect(mockExpireInvitation).toHaveBeenCalledWith(
      { id: EXPIRED_INVITATION_ID },
      expect.objectContaining({ impersonate: expect.any(Object) }),
    );
    expect(mockAcceptInvitationAndJoinTeam).not.toHaveBeenCalled();
  });

  it("accepts a valid invitation and returns joined team info", async () => {
    mockListMyPendingInvitations.mockResolvedValue({
      data: { invitations: [makePendingInvitation()] },
    });
    mockAcceptInvitationAndJoinTeam.mockResolvedValue({});

    const result = await wrapped({ data: undefined, auth: makeAuth() });

    expect(result).toEqual({
      joinedTeams: [{ teamId: TEAM_ID, teamName: "Team Alpha" }],
      message: "Joined 1 team(s)",
    });
    expect(mockAcceptInvitationAndJoinTeam).toHaveBeenCalledWith(
      { id: INVITATION_ID, teamId: TEAM_ID },
      expect.objectContaining({ impersonate: expect.any(Object) }),
    );
  });

  it("accepts only valid invitations when valid and expired invitations are mixed", async () => {
    const past = new Date(Date.now() - 1000).toISOString();
    mockListMyPendingInvitations.mockResolvedValue({
      data: {
        invitations: [
          makePendingInvitation({
            id: EXPIRED_INVITATION_ID,
            expiresAt: past,
          }),
          makePendingInvitation({
            id: "inv-second",
            teamNameSnapshot: "Team Beta",
            team: { id: SECOND_TEAM_ID, name: "Team Beta", __typename: "Team_Key" },
          }),
        ],
      },
    });
    mockExpireInvitation.mockResolvedValue({});
    mockAcceptInvitationAndJoinTeam.mockResolvedValue({});

    const result = await wrapped({ data: undefined, auth: makeAuth() });

    expect(result).toEqual({
      joinedTeams: [{ teamId: SECOND_TEAM_ID, teamName: "Team Beta" }],
      message: "Joined 1 team(s)",
    });
    expect(mockExpireInvitation).toHaveBeenCalledOnce();
    expect(mockAcceptInvitationAndJoinTeam).toHaveBeenCalledOnce();
  });
});
