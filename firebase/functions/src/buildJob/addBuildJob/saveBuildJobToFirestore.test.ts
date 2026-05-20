import { beforeEach, describe, expect, it, vi } from "vitest";

const { randomUUID, serverTimestamp } = vi.hoisted(() => ({
  randomUUID: vi.fn(),
  serverTimestamp: Symbol("serverTimestamp"),
}));

vi.mock("node:crypto", () => ({
  randomUUID,
}));

vi.mock("firebase-admin/firestore", () => ({
  FieldValue: {
    serverTimestamp: () => serverTimestamp,
  },
}));

const { saveBuildJobsToFirestore } = await import("./saveBuildJobToFirestore.js");

describe("saveBuildJobsToFirestore", () => {
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
    randomUUID.mockReturnValue("workflow-run-1");
    mockCollection.mockReturnValue({ doc: mockDoc });
    mockDoc.mockImplementation((id: string) => ({ id }));
    mockBatchCommit.mockResolvedValue(undefined);
  });

  it("saves queued and waiting build jobs with resolved dependencies", async () => {
    await saveBuildJobsToFirestore({
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
        workflowRunId: "workflow-run-1",
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
        workflowRunId: "workflow-run-1",
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
    await saveBuildJobsToFirestore({
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

  it("assigns workflow run ids and resolved dependencies per workflow file", async () => {
    randomUUID.mockReturnValueOnce("workflow-run-a").mockReturnValueOnce("workflow-run-b");

    await saveBuildJobsToFirestore({
      db: db as never,
      jobs: [
        {
          documentId: "doc-a-build",
          checkRunId: 101,
          workflowFileName: "a.yaml",
          workflowName: "A",
          jobId: "build",
          spec: {},
        },
        {
          documentId: "doc-b-build",
          checkRunId: 102,
          workflowFileName: "b.yaml",
          workflowName: "B",
          jobId: "build",
          spec: {},
        },
        {
          documentId: "doc-b-test",
          checkRunId: 103,
          workflowFileName: "b.yaml",
          workflowName: "B",
          jobId: "test",
          spec: { needs: "build" },
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
      apiBaseUrl: "https://api.github.com",
      githubBaseUrl: "https://github.com",
    });

    expect(mockBatchSet).toHaveBeenCalledWith(
      { id: "doc-a-build" },
      expect.objectContaining({
        workflowRunId: "workflow-run-a",
        resolvedNeeds: null,
      }),
    );
    expect(mockBatchSet).toHaveBeenCalledWith(
      { id: "doc-b-build" },
      expect.objectContaining({
        workflowRunId: "workflow-run-b",
        resolvedNeeds: null,
      }),
    );
    expect(mockBatchSet).toHaveBeenCalledWith(
      { id: "doc-b-test" },
      expect.objectContaining({
        workflowRunId: "workflow-run-b",
        resolvedNeeds: { build: "doc-b-build" },
      }),
    );
  });

  it("saves matrix metadata and expands needs to all matrix instances", async () => {
    await saveBuildJobsToFirestore({
      db: db as never,
      jobs: [
        {
          documentId: "doc-build-ubuntu",
          checkRunId: 101,
          workflowFileName: "ci.yaml",
          workflowName: "CI",
          jobId: "build[node=24,os=ubuntu-latest]",
          workflowJobKey: "build",
          spec: { "runs-on": "ubuntu-latest" },
          matrix: { node: 24, os: "ubuntu-latest" },
          matrixLabel: "node=24,os=ubuntu-latest",
          matrixIndex: 0,
          matrixGroupKey: "ci.yaml:build",
          matrixFailFast: true,
        },
        {
          documentId: "doc-build-macos",
          checkRunId: 102,
          workflowFileName: "ci.yaml",
          workflowName: "CI",
          jobId: "build[node=24,os=macos-latest]",
          workflowJobKey: "build",
          spec: { "runs-on": "macos-latest" },
          matrix: { node: 24, os: "macos-latest" },
          matrixLabel: "node=24,os=macos-latest",
          matrixIndex: 1,
          matrixGroupKey: "ci.yaml:build",
          matrixFailFast: true,
        },
        {
          documentId: "doc-test",
          checkRunId: 103,
          workflowFileName: "ci.yaml",
          workflowName: "CI",
          jobId: "test",
          spec: { needs: "build" },
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
      apiBaseUrl: "https://api.github.com",
      githubBaseUrl: "https://github.com",
    });

    expect(mockBatchSet).toHaveBeenCalledWith(
      { id: "doc-build-ubuntu" },
      expect.objectContaining({
        jobKey: "build[node=24,os=ubuntu-latest]",
        workflowJobKey: "build",
        matrix: { node: 24, os: "ubuntu-latest" },
        matrixLabel: "node=24,os=ubuntu-latest",
        matrixIndex: 0,
        matrixGroupKey: "ci.yaml:build",
        matrixFailFast: true,
      }),
    );
    expect(mockBatchSet).toHaveBeenCalledWith(
      { id: "doc-test" },
      expect.objectContaining({
        status: "WAITING",
        needs: ["build[node=24,os=ubuntu-latest]", "build[node=24,os=macos-latest]"],
        resolvedNeeds: {
          "build[node=24,os=ubuntu-latest]": "doc-build-ubuntu",
          "build[node=24,os=macos-latest]": "doc-build-macos",
        },
      }),
    );
  });
});
