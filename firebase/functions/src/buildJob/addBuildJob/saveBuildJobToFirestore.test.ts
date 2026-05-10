import { beforeEach, describe, expect, it, vi } from "vitest";

const { serverTimestamp } = vi.hoisted(() => ({
  serverTimestamp: Symbol("serverTimestamp"),
}));

vi.mock("firebase-admin/firestore", () => ({
  FieldValue: {
    serverTimestamp: () => serverTimestamp,
  },
}));

const { saveBuildJobToFirestore } = await import("./saveBuildJobToFirestore.js");

describe("saveBuildJobToFirestore", () => {
  const mockBatchCommit = vi.fn();
  const mockBatchSet = vi.fn();
  const mockCollection = vi.fn();
  const mockDoc = vi.fn();
  const db = {
    batch: () => ({
      commit: mockBatchCommit,
      set: mockBatchSet,
    }),
    collection: mockCollection,
  };

  beforeEach(() => {
    vi.clearAllMocks();
    mockCollection.mockReturnValue({ doc: mockDoc });
    mockDoc.mockImplementation((id: string) => ({ id }));
    mockBatchCommit.mockResolvedValue(undefined);
  });

  it("saves queued and waiting build jobs with resolved dependencies", async () => {
    await saveBuildJobToFirestore({
      db: db as never,
      jobs: [
        {
          documentId: "doc-build",
          checkRunId: 101,
          workflowFileName: "ci.yaml",
          workflowName: "CI",
          jobId: "build",
          spec: { "runs-on": "ubuntu-latest" },
        },
        {
          documentId: "doc-test",
          checkRunId: 102,
          workflowFileName: "ci.yaml",
          workflowName: "CI",
          jobId: "test",
          spec: { needs: "build", "runs-on": "macos-latest" },
        },
      ],
      owner: "openci",
      repo: "openci",
      teamId: "team-1",
      installationId: 123,
      installationToken: "token-123",
      tokenExpiresAt: "2026-01-01T00:00:00Z",
      checkRunCommitSha: "abc123",
      pullRequestNumber: 42,
      triggerType: "pull_request",
      branch: "feature/test",
      apiBaseUrl: "https://api.github.com",
      githubBaseUrl: "https://github.com",
    });

    expect(mockCollection).toHaveBeenCalledWith("build_jobs_v0");
    expect(mockDoc).toHaveBeenCalledWith("doc-build");
    expect(mockDoc).toHaveBeenCalledWith("doc-test");

    expect(mockBatchSet).toHaveBeenCalledWith(
      { id: "doc-build" },
      expect.objectContaining({
        id: "doc-build",
        status: "QUEUED",
        workflowFileName: "ci.yaml",
        workflowName: "CI",
        jobKey: "build",
        needs: null,
        resolvedNeeds: null,
        runsOn: "ubuntu-latest",
        checkRunId: "101",
        commitSha: "abc123",
        pullRequestNumber: 42,
        githubApiBaseUrl: null,
        githubBaseUrl: null,
        createdAt: serverTimestamp,
        updatedAt: serverTimestamp,
      }),
    );
    expect(mockBatchSet).toHaveBeenCalledWith(
      { id: "doc-test" },
      expect.objectContaining({
        id: "doc-test",
        status: "WAITING",
        jobKey: "test",
        needs: ["build"],
        resolvedNeeds: { build: "doc-build" },
        runsOn: "macos-latest",
        checkRunId: "102",
      }),
    );
    expect(mockBatchCommit).toHaveBeenCalledOnce();
  });

  it("stores custom GitHub Enterprise URLs", async () => {
    await saveBuildJobToFirestore({
      db: db as never,
      jobs: [
        {
          documentId: "doc-build",
          checkRunId: 101,
          workflowFileName: "ci.yaml",
          workflowName: "CI",
          jobId: "build",
          spec: {},
        },
      ],
      owner: "openci",
      repo: "openci",
      teamId: "team-1",
      installationId: 123,
      installationToken: "token-123",
      tokenExpiresAt: "2026-01-01T00:00:00Z",
      checkRunCommitSha: "abc123",
      pullRequestNumber: null,
      triggerType: "push",
      branch: "main",
      apiBaseUrl: "https://github.example.com/api/v3",
      githubBaseUrl: "https://github.example.com",
    });

    expect(mockBatchSet).toHaveBeenCalledWith(
      { id: "doc-build" },
      expect.objectContaining({
        githubApiBaseUrl: "https://github.example.com/api/v3",
        githubBaseUrl: "https://github.example.com",
      }),
    );
  });
});
