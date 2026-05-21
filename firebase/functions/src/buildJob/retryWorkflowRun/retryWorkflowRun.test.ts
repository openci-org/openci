import firebaseFunctionsTest from "firebase-functions-test";
import type { CallableRequest } from "firebase-functions/v2/https";
import { beforeEach, describe, expect, it, vi } from "vitest";

type AuthData = NonNullable<CallableRequest["auth"]>;

const {
  BuildJobStatus,
  mockCreateBuildJob,
  mockCreateCheckRun,
  mockGetInstallationToken,
  mockListBuildJobsByWorkflowRun,
  mockRandomUUID,
  mockVerifyTeamMembership,
} = vi.hoisted(() => ({
  BuildJobStatus: {
    WAITING: "WAITING",
    QUEUED: "QUEUED",
  } as const,
  mockCreateBuildJob: vi.fn(),
  mockCreateCheckRun: vi.fn(),
  mockGetInstallationToken: vi.fn(),
  mockListBuildJobsByWorkflowRun: vi.fn(),
  mockRandomUUID: vi.fn(),
  mockVerifyTeamMembership: vi.fn(),
}));

vi.mock("node:crypto", () => ({
  randomUUID: () => mockRandomUUID(),
}));

vi.mock("../../firestoreData", () => ({
  BuildJobStatus,
  createBuildJob: (...args: unknown[]) => mockCreateBuildJob(...args),
  listBuildJobsByWorkflowRun: (...args: unknown[]) => mockListBuildJobsByWorkflowRun(...args),
}));

vi.mock("../../github/githubApp", () => ({
  createCheckRun: (...args: unknown[]) => mockCreateCheckRun(...args),
  getInstallationToken: (...args: unknown[]) => mockGetInstallationToken(...args),
}));

vi.mock("../../team/teamAuth", () => ({
  verifyTeamMembership: (...args: unknown[]) => mockVerifyTeamMembership(...args),
}));

const testEnv = firebaseFunctionsTest();
const { retryWorkflowRun } = await import("./retryWorkflowRun");

const wrappedRetryWorkflowRun = testEnv.wrap(retryWorkflowRun) as (req: {
  data: { workflowRunId?: string; workflowFileName?: string };
  auth?: AuthData;
}) => Promise<{ success: true; newWorkflowRunId: string; newBuildJobIds: string[] }>;

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

describe("retryWorkflowRun", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mockRandomUUID.mockReset();
    mockCreateBuildJob.mockResolvedValue({});
    mockCreateCheckRun.mockResolvedValue(undefined);
    mockGetInstallationToken.mockResolvedValue({
      token: "installation-token",
      expiresAt: "2026-01-01T00:00:00Z",
    });
    mockVerifyTeamMembership.mockResolvedValue({});
  });

  it("retries a workflow run and recreates jobs with resolved dependencies", async () => {
    mockRandomUUID
      .mockReturnValueOnce("new-workflow-run")
      .mockReturnValueOnce("new-build-job")
      .mockReturnValueOnce("new-test-job");
    mockCreateCheckRun.mockResolvedValueOnce(1001).mockResolvedValueOnce(1002);
    mockListBuildJobsByWorkflowRun.mockResolvedValue({
      data: {
        buildJobs: [
          {
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
            branch: "feature/retry",
          },
          {
            owner: "openci-org",
            repo: "openci",
            teamId: "team-1",
            workflowName: "CI",
            workflowFileName: "ci.yaml",
            jobKey: "test",
            workflowJobKey: "test",
            needs: ["build"],
            installationId: "123",
            installationToken: "existing-token",
            tokenExpiresAt: "2999-01-01T00:00:00Z",
            commitSha: "abc123",
            branch: "feature/retry",
          },
        ],
      },
    });

    const result = await wrappedRetryWorkflowRun({
      data: { workflowRunId: "workflow-run-1" },
      auth: makeAuth(),
    });

    expect(result).toEqual({
      success: true,
      newWorkflowRunId: "new-workflow-run",
      newBuildJobIds: ["new-build-job", "new-test-job"],
    });
    expect(mockVerifyTeamMembership).toHaveBeenCalledWith(
      expect.objectContaining({ uid: "user-123" }),
      "team-1",
    );
    expect(mockGetInstallationToken).not.toHaveBeenCalled();
    expect(mockCreateCheckRun).toHaveBeenNthCalledWith(
      1,
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
    expect(mockCreateCheckRun).toHaveBeenNthCalledWith(
      2,
      expect.objectContaining({
        token: "existing-token",
        owner: "openci-org",
        repo: "openci",
        name: "CI / test",
        headSha: "abc123",
        status: "queued",
        detailsUrl: expect.stringContaining("new-test-job"),
      }),
    );
    expect(mockCreateBuildJob).toHaveBeenCalledTimes(2);
    expect(mockCreateBuildJob).toHaveBeenNthCalledWith(
      1,
      expect.objectContaining({
        id: "new-build-job",
        status: BuildJobStatus.QUEUED,
        workflowRunId: "new-workflow-run",
        jobKey: "build",
        workflowJobKey: "build",
        needs: null,
        resolvedNeeds: null,
        installationToken: "existing-token",
        tokenExpiresAt: "2999-01-01T00:00:00Z",
        checkRunId: 1001,
        runCount: 0,
        latestRunId: null,
        retriedFromWorkflowRunId: "workflow-run-1",
      }),
    );
    expect(mockCreateBuildJob).toHaveBeenNthCalledWith(
      2,
      expect.objectContaining({
        id: "new-test-job",
        status: BuildJobStatus.WAITING,
        workflowRunId: "new-workflow-run",
        jobKey: "test",
        workflowJobKey: "test",
        needs: ["build"],
        resolvedNeeds: { build: "new-build-job" },
        installationToken: "existing-token",
        tokenExpiresAt: "2999-01-01T00:00:00Z",
        checkRunId: 1002,
        runCount: 0,
        latestRunId: null,
        retriedFromWorkflowRunId: "workflow-run-1",
      }),
    );
  });

  it("refreshes an expired installation token before retrying a workflow run", async () => {
    mockRandomUUID.mockReturnValueOnce("new-workflow-run").mockReturnValueOnce("new-build-job");
    mockCreateCheckRun.mockResolvedValue(1001);
    mockGetInstallationToken.mockResolvedValue({
      token: "refreshed-token",
      expiresAt: "2999-01-01T00:00:00Z",
    });
    mockListBuildJobsByWorkflowRun.mockResolvedValue({
      data: {
        buildJobs: [
          {
            owner: "openci-org",
            repo: "openci",
            teamId: "team-1",
            workflowName: "CI",
            workflowFileName: "ci.yaml",
            jobKey: "build",
            installationId: "123",
            installationToken: "expired-token",
            tokenExpiresAt: "2020-01-01T00:00:00Z",
            commitSha: "abc123",
            githubApiBaseUrl: "https://github.example.com/api/v3",
          },
        ],
      },
    });

    const result = await wrappedRetryWorkflowRun({
      data: { workflowRunId: "workflow-run-1" },
      auth: makeAuth(),
    });

    expect(result).toEqual({
      success: true,
      newWorkflowRunId: "new-workflow-run",
      newBuildJobIds: ["new-build-job"],
    });
    expect(mockGetInstallationToken).toHaveBeenCalledWith(123, {
      apiBaseUrl: "https://github.example.com/api/v3",
    });
    expect(mockCreateCheckRun).toHaveBeenCalledWith(
      expect.objectContaining({
        token: "refreshed-token",
        owner: "openci-org",
        repo: "openci",
        name: "CI",
        headSha: "abc123",
        status: "in_progress",
        apiBaseUrl: "https://github.example.com/api/v3",
      }),
    );
    expect(mockCreateBuildJob).toHaveBeenCalledWith(
      expect.objectContaining({
        id: "new-build-job",
        status: BuildJobStatus.QUEUED,
        workflowRunId: "new-workflow-run",
        installationToken: "refreshed-token",
        tokenExpiresAt: "2999-01-01T00:00:00Z",
        checkRunId: 1001,
        githubApiBaseUrl: "https://github.example.com/api/v3",
        retriedFromWorkflowRunId: "workflow-run-1",
      }),
    );
  });

  it("normalizes missing optional fields before creating retried workflow jobs", async () => {
    mockRandomUUID.mockReturnValueOnce("new-workflow-run").mockReturnValueOnce("new-build-job");
    mockListBuildJobsByWorkflowRun.mockResolvedValue({
      data: {
        buildJobs: [
          {
            owner: "openci-org",
            repo: "openci",
            teamId: "team-1",
            workflowName: "CI",
            workflowFileName: "ci.yaml",
            jobKey: "build",
          },
        ],
      },
    });

    const result = await wrappedRetryWorkflowRun({
      data: { workflowRunId: "workflow-run-1" },
      auth: makeAuth(),
    });

    expect(result).toEqual({
      success: true,
      newWorkflowRunId: "new-workflow-run",
      newBuildJobIds: ["new-build-job"],
    });
    expect(mockCreateBuildJob).toHaveBeenCalledOnce();
    const retriedJob = mockCreateBuildJob.mock.calls[0][0] as Record<string, unknown>;
    expectNoUndefined(retriedJob);
    expect(retriedJob).toEqual(
      expect.objectContaining({
        id: "new-build-job",
        status: BuildJobStatus.QUEUED,
        workflowRunId: "new-workflow-run",
        workflowJobKey: null,
        needs: null,
        resolvedNeeds: null,
        checkRunId: null,
        latestRunId: null,
        retriedFromWorkflowRunId: "workflow-run-1",
      }),
    );
  });
});
