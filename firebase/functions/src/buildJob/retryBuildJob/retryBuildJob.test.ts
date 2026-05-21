import firebaseFunctionsTest from "firebase-functions-test";
import type { CallableRequest } from "firebase-functions/v2/https";
import { beforeEach, describe, expect, it, vi } from "vitest";

type AuthData = NonNullable<CallableRequest["auth"]>;

const {
  BuildJobStatus,
  mockCreateBuildJob,
  mockCreateCheckRun,
  mockGetBuildJob,
  mockGetInstallationToken,
  mockRandomUUID,
  mockVerifyTeamMembership,
} = vi.hoisted(() => ({
  BuildJobStatus: {
    WAITING: "WAITING",
    QUEUED: "QUEUED",
  } as const,
  mockCreateBuildJob: vi.fn(),
  mockCreateCheckRun: vi.fn(),
  mockGetBuildJob: vi.fn(),
  mockGetInstallationToken: vi.fn(),
  mockRandomUUID: vi.fn(),
  mockVerifyTeamMembership: vi.fn(),
}));

vi.mock("node:crypto", () => ({
  randomUUID: () => mockRandomUUID(),
}));

vi.mock("../../firestoreData", () => ({
  BuildJobStatus,
  createBuildJob: (...args: unknown[]) => mockCreateBuildJob(...args),
  getBuildJob: (...args: unknown[]) => mockGetBuildJob(...args),
}));

vi.mock("../../github/githubApp", () => ({
  createCheckRun: (...args: unknown[]) => mockCreateCheckRun(...args),
  getInstallationToken: (...args: unknown[]) => mockGetInstallationToken(...args),
}));

vi.mock("../../team/teamAuth", () => ({
  verifyTeamMembership: (...args: unknown[]) => mockVerifyTeamMembership(...args),
}));

const testEnv = firebaseFunctionsTest();
const { retryBuildJob } = await import("./retryBuildJob");

const wrappedRetryBuildJob = testEnv.wrap(retryBuildJob) as (req: {
  data: { buildJobId?: string };
  auth?: AuthData;
}) => Promise<{ success: true; newBuildJobId: string }>;

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

function expectNoUndefined(value: unknown): void {
  if (Array.isArray(value)) {
    for (const entry of value) {
      expectNoUndefined(entry);
    }
    return;
  }
  if (value === null || typeof value !== "object") return;
  for (const [key, entry] of Object.entries(value as Record<string, unknown>)) {
    expect(entry, key).not.toBeUndefined();
    expectNoUndefined(entry);
  }
}

describe("retryBuildJob", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mockCreateBuildJob.mockResolvedValue({});
    mockCreateCheckRun.mockResolvedValue(undefined);
    mockGetInstallationToken.mockResolvedValue({
      token: "installation-token",
      expiresAt: "2026-01-01T00:00:00Z",
    });
    mockRandomUUID.mockReturnValue("new-build-job");
    mockVerifyTeamMembership.mockResolvedValue({});
  });

  it("retries a build job and creates a new queued job", async () => {
    mockCreateCheckRun.mockResolvedValue(999);
    mockGetBuildJob.mockResolvedValue({
      data: {
        buildJob: {
          owner: "openci-org",
          repo: "openci",
          teamId: "team-1",
          workflowName: "CI",
          workflowFileName: "ci.yaml",
          jobKey: "build",
          workflowJobKey: "build",
          installationId: "123",
          installationToken: "existing-token",
          tokenExpiresAt: "2999-01-01T00:00:00Z",
          commitSha: "abc123",
          pullRequestNumber: 42,
          branch: "feature/retry",
        },
      },
    });

    const result = await wrappedRetryBuildJob({
      data: { buildJobId: "build-job-1" },
      auth: makeAuth(),
    });

    expect(result).toEqual({ success: true, newBuildJobId: "new-build-job" });
    expect(mockVerifyTeamMembership).toHaveBeenCalledWith(
      expect.objectContaining({ uid: "user-123" }),
      "team-1",
    );
    expect(mockGetInstallationToken).not.toHaveBeenCalled();
    expect(mockCreateCheckRun).toHaveBeenCalledWith(
      expect.objectContaining({
        token: "existing-token",
        owner: "openci-org",
        repo: "openci",
        name: "CI / build",
        headSha: "abc123",
        status: "in_progress",
        detailsUrl: expect.stringContaining("new-build-job"),
      }),
    );
    expect(mockCreateBuildJob).toHaveBeenCalledOnce();
    expect(mockCreateBuildJob).toHaveBeenCalledWith(
      expect.objectContaining({
        id: "new-build-job",
        owner: "openci-org",
        repo: "openci",
        teamId: "team-1",
        workflowName: "CI",
        workflowFileName: "ci.yaml",
        jobKey: "build",
        workflowJobKey: "build",
        status: BuildJobStatus.QUEUED,
        workflowRunId: null,
        needs: null,
        resolvedNeeds: null,
        installationToken: "existing-token",
        tokenExpiresAt: "2999-01-01T00:00:00Z",
        checkRunId: 999,
        commitSha: "abc123",
        pullRequestNumber: 42,
        branch: "feature/retry",
        runCount: 0,
        latestRunId: null,
        retriedFromBuildJobId: "build-job-1",
      }),
    );
  });

  it("refreshes an expired installation token before retrying", async () => {
    mockCreateCheckRun.mockResolvedValue(1001);
    mockGetInstallationToken.mockResolvedValue({
      token: "refreshed-token",
      expiresAt: "2999-01-01T00:00:00Z",
    });
    mockGetBuildJob.mockResolvedValue({
      data: {
        buildJob: {
          owner: "openci-org",
          repo: "openci",
          teamId: "team-1",
          workflowName: "CI",
          jobKey: "build",
          installationId: "123",
          installationToken: "expired-token",
          tokenExpiresAt: "2020-01-01T00:00:00Z",
          commitSha: "abc123",
          githubApiBaseUrl: "https://github.example.com/api/v3",
        },
      },
    });

    const result = await wrappedRetryBuildJob({
      data: { buildJobId: "build-job-1" },
      auth: makeAuth(),
    });

    expect(result).toEqual({ success: true, newBuildJobId: "new-build-job" });
    expect(mockGetInstallationToken).toHaveBeenCalledWith(123, {
      apiBaseUrl: "https://github.example.com/api/v3",
    });
    expect(mockCreateCheckRun).toHaveBeenCalledWith(
      expect.objectContaining({
        token: "refreshed-token",
        owner: "openci-org",
        repo: "openci",
        name: "CI / build",
        headSha: "abc123",
        status: "in_progress",
        apiBaseUrl: "https://github.example.com/api/v3",
      }),
    );
    expect(mockCreateBuildJob).toHaveBeenCalledWith(
      expect.objectContaining({
        id: "new-build-job",
        status: BuildJobStatus.QUEUED,
        installationToken: "refreshed-token",
        tokenExpiresAt: "2999-01-01T00:00:00Z",
        checkRunId: 1001,
        githubApiBaseUrl: "https://github.example.com/api/v3",
        retriedFromBuildJobId: "build-job-1",
      }),
    );
  });

  it("normalizes missing optional fields before creating a retried build job", async () => {
    mockGetBuildJob.mockResolvedValue({
      data: {
        buildJob: {
          owner: "openci-org",
          repo: "openci",
          teamId: "team-1",
          workflowName: "CI",
          jobKey: "build",
          sender: { login: undefined },
        },
      },
    });

    const result = await wrappedRetryBuildJob({
      data: { buildJobId: "build-job-1" },
      auth: makeAuth(),
    });

    expect(result).toEqual({ success: true, newBuildJobId: "new-build-job" });
    expect(mockCreateBuildJob).toHaveBeenCalledOnce();
    const retriedJob = mockCreateBuildJob.mock.calls[0][0] as Record<string, unknown>;
    expectNoUndefined(retriedJob);
    expect(retriedJob).toEqual(
      expect.objectContaining({
        id: "new-build-job",
        workflowJobKey: null,
        matrix: null,
        matrixLabel: null,
        matrixIndex: null,
        matrixGroupKey: null,
        matrixFailFast: null,
        installationToken: null,
        tokenExpiresAt: null,
        checkRunId: null,
        workflowRunId: null,
        needs: null,
        resolvedNeeds: null,
        latestRunId: null,
        retriedFromBuildJobId: "build-job-1",
        sender: { login: null },
      }),
    );
  });
});
