import firebaseFunctionsTest from "firebase-functions-test";
import type { CallableRequest } from "firebase-functions/v2/https";
import { beforeEach, describe, expect, it, vi } from "vitest";

type AuthData = NonNullable<CallableRequest["auth"]>;

const { BuildJobStatus, mockGetBuildJob, mockUpdateBuildJobStatus, mockVerifyTeamMembership } =
  vi.hoisted(() => ({
    BuildJobStatus: {
      QUEUED: "QUEUED",
      IN_PROGRESS: "IN_PROGRESS",
      SUCCESS: "SUCCESS",
      CANCELLED: "CANCELLED",
    } as const,
    mockGetBuildJob: vi.fn(),
    mockUpdateBuildJobStatus: vi.fn(),
    mockVerifyTeamMembership: vi.fn(),
  }));

vi.mock("@openci/firestore-data", () => ({
  BuildJobStatus,
  getBuildJob: (...args: unknown[]) => mockGetBuildJob(...args),
  updateBuildJobStatus: (...args: unknown[]) => mockUpdateBuildJobStatus(...args),
}));

vi.mock("../team/teamAuth", () => ({
  verifyTeamMembership: (...args: unknown[]) => mockVerifyTeamMembership(...args),
}));

const testEnv = firebaseFunctionsTest();
const { cancelBuildJob } = await import("./cancelBuildJob");

const wrapped = testEnv.wrap(cancelBuildJob) as (req: {
  data: { buildJobId?: string };
  auth?: AuthData;
}) => Promise<{ success: true }>;

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

describe("cancelBuildJob", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mockUpdateBuildJobStatus.mockResolvedValue({});
    mockVerifyTeamMembership.mockResolvedValue({});
  });

  it("rejects unauthenticated calls", async () => {
    await expect(wrapped({ data: { buildJobId: "job-1" } })).rejects.toThrow(
      expect.objectContaining({ code: "unauthenticated" }),
    );
  });

  it("cancels queued build jobs for team members", async () => {
    mockGetBuildJob.mockResolvedValue({
      data: { buildJob: { status: BuildJobStatus.QUEUED, teamId: "team-1" } },
    });

    const result = await wrapped({ data: { buildJobId: "job-1" }, auth: makeAuth() });

    expect(result).toEqual({ success: true });
    expect(mockUpdateBuildJobStatus).toHaveBeenCalledWith({
      id: "job-1",
      status: BuildJobStatus.CANCELLED,
    });
  });

  it("rejects completed build jobs", async () => {
    mockGetBuildJob.mockResolvedValue({
      data: { buildJob: { status: BuildJobStatus.SUCCESS, teamId: "team-1" } },
    });

    await expect(wrapped({ data: { buildJobId: "job-1" }, auth: makeAuth() })).rejects.toThrow(
      expect.objectContaining({ code: "failed-precondition" }),
    );
  });
});
