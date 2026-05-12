import { beforeEach, describe, expect, it, vi } from "vitest";

import type { AddBuildJobParams } from "./addBuildJob.js";

const {
  mockCreateCheckRun,
  mockDb,
  mockExtractJobs,
  mockFetchOpenCIWorkflowYamlFiles,
  mockFilterValidWorkflows,
  mockGetFirestore,
  mockGetGitHubApiBaseUrl,
  mockGetGitHubBaseUrl,
  mockGetInstallationToken,
  mockGetTeamIdByInstallationId,
  mockMatchesTrigger,
  mockParseWorkflowYaml,
  mockSaveBuildJobToFirestore,
} = vi.hoisted(() => ({
  mockCreateCheckRun: vi.fn(),
  mockDb: { id: "mock-db" },
  mockExtractJobs: vi.fn(),
  mockFetchOpenCIWorkflowYamlFiles: vi.fn(),
  mockFilterValidWorkflows: vi.fn(),
  mockGetFirestore: vi.fn(),
  mockGetGitHubApiBaseUrl: vi.fn(),
  mockGetGitHubBaseUrl: vi.fn(),
  mockGetInstallationToken: vi.fn(),
  mockGetTeamIdByInstallationId: vi.fn(),
  mockMatchesTrigger: vi.fn(),
  mockParseWorkflowYaml: vi.fn(),
  mockSaveBuildJobToFirestore: vi.fn(),
}));

vi.mock("firebase-admin/firestore", () => ({
  getFirestore: () => mockGetFirestore(),
}));

vi.mock("./createCheckRun.js", () => ({
  createCheckRun: (...args: unknown[]) => mockCreateCheckRun(...args),
}));

vi.mock("./extractJobs.js", () => ({
  extractJobs: (...args: unknown[]) => mockExtractJobs(...args),
  filterValidWorkflows: (...args: unknown[]) => mockFilterValidWorkflows(...args),
}));

vi.mock("./fetchOpenCIWorkflowYamlFiles.js", () => ({
  fetchOpenCIWorkflowYamlFiles: (...args: unknown[]) => mockFetchOpenCIWorkflowYamlFiles(...args),
}));

vi.mock("./getGitHubApiBaseUrl.js", () => ({
  getGitHubApiBaseUrl: (...args: unknown[]) => mockGetGitHubApiBaseUrl(...args),
  getGitHubBaseUrl: (...args: unknown[]) => mockGetGitHubBaseUrl(...args),
}));

vi.mock("./getInstallationToken.js", () => ({
  getInstallationToken: (...args: unknown[]) => mockGetInstallationToken(...args),
}));

vi.mock("./getTeamIdByInstallationId.js", () => ({
  getTeamIdByInstallationId: (...args: unknown[]) => mockGetTeamIdByInstallationId(...args),
}));

vi.mock("./matchesTrigger.js", () => ({
  matchesTrigger: (...args: unknown[]) => mockMatchesTrigger(...args),
}));

vi.mock("./parseWorkflowYaml.js", () => ({
  parseWorkflowYaml: (...args: unknown[]) => mockParseWorkflowYaml(...args),
}));

vi.mock("./saveBuildJobToFirestore.js", () => ({
  saveBuildJobToFirestore: (...args: unknown[]) => mockSaveBuildJobToFirestore(...args),
}));

const { addBuildJob } = await import("./addBuildJob.js");

const params: AddBuildJobParams = {
  installationId: 123,
  commitSha: "abc123",
  branch: "feature/test",
  triggerBranch: "main",
  pullRequestNumber: 42,
  owner: "openci",
  repo: "openci",
  appId: "app-id",
  privateKey: "private-key",
  triggerType: "pull_request",
};

describe("addBuildJob", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mockGetFirestore.mockReturnValue(mockDb);
    mockGetTeamIdByInstallationId.mockResolvedValue("team-1");
    mockGetGitHubBaseUrl.mockResolvedValue("https://github.com");
    mockGetGitHubApiBaseUrl.mockReturnValue("https://api.github.com");
    mockGetInstallationToken.mockResolvedValue({
      token: "installation-token",
      expiresAt: "2026-01-01T00:00:00Z",
    });
    mockSaveBuildJobToFirestore.mockResolvedValue(undefined);
  });

  it("does nothing when no workflow YAML files exist", async () => {
    mockFetchOpenCIWorkflowYamlFiles.mockResolvedValue([]);

    await addBuildJob(params);

    expect(mockFetchOpenCIWorkflowYamlFiles).toHaveBeenCalledWith(
      "openci",
      "openci",
      "abc123",
      "installation-token",
      "https://api.github.com",
    );
    expect(mockCreateCheckRun).not.toHaveBeenCalled();
    expect(mockSaveBuildJobToFirestore).not.toHaveBeenCalled();
  });

  it("does nothing when the installation is not linked to a team", async () => {
    mockGetTeamIdByInstallationId.mockResolvedValue(undefined);

    await addBuildJob(params);

    expect(mockGetInstallationToken).not.toHaveBeenCalled();
    expect(mockFetchOpenCIWorkflowYamlFiles).not.toHaveBeenCalled();
    expect(mockCreateCheckRun).not.toHaveBeenCalled();
    expect(mockSaveBuildJobToFirestore).not.toHaveBeenCalled();
  });

  it("filters workflows using the trigger branch when provided", async () => {
    const workflowFile = { name: "ci.yaml", content: "name: CI" };
    const parsedWorkflow = {
      workflowFileName: "ci.yaml",
      workflowName: "CI",
      parsed: { on: { pull_request: {} } },
    };
    mockFetchOpenCIWorkflowYamlFiles.mockResolvedValue([workflowFile]);
    mockParseWorkflowYaml.mockReturnValue(parsedWorkflow);
    mockMatchesTrigger.mockReturnValue(false);

    await addBuildJob(params);

    expect(mockMatchesTrigger).toHaveBeenCalledWith(parsedWorkflow.parsed, "pull_request", "main");
    expect(mockExtractJobs).not.toHaveBeenCalled();
    expect(mockCreateCheckRun).not.toHaveBeenCalled();
    expect(mockSaveBuildJobToFirestore).not.toHaveBeenCalled();
  });

  it("creates check runs and saves matched jobs", async () => {
    const workflowFile = { name: "ci.yaml", content: "name: CI" };
    const parsedWorkflow = {
      workflowFileName: "ci.yaml",
      workflowName: "CI",
      parsed: { on: { pull_request: {} } },
    };
    const validWorkflow = { workflowFileName: "ci.yaml", workflowName: "CI", jobs: { build: {} } };
    const extractedJob = {
      workflowFileName: "ci.yaml",
      workflowName: "CI",
      jobId: "build",
      spec: {},
    };
    const jobWithCheckRun = { ...extractedJob, documentId: "job-1", checkRunId: 101 };
    mockFetchOpenCIWorkflowYamlFiles.mockResolvedValue([workflowFile]);
    mockParseWorkflowYaml.mockReturnValue(parsedWorkflow);
    mockMatchesTrigger.mockReturnValue(true);
    mockFilterValidWorkflows.mockReturnValue([validWorkflow]);
    mockExtractJobs.mockReturnValue([extractedJob]);
    mockCreateCheckRun.mockResolvedValue([jobWithCheckRun]);

    await addBuildJob(params);

    expect(mockCreateCheckRun).toHaveBeenCalledWith({
      jobs: [extractedJob],
      token: "installation-token",
      owner: "openci",
      repo: "openci",
      headSha: "abc123",
      apiBaseUrl: "https://api.github.com",
    });
    expect(mockSaveBuildJobToFirestore).toHaveBeenCalledWith({
      db: mockDb,
      jobs: [jobWithCheckRun],
      owner: "openci",
      repo: "openci",
      teamId: "team-1",
      installationId: 123,
      installationToken: "installation-token",
      tokenExpiresAt: "2026-01-01T00:00:00Z",
      checkRunCommitSha: "abc123",
      pullRequestNumber: 42,
      triggerType: "pull_request",
      branch: "feature/test",
      apiBaseUrl: "https://api.github.com",
      githubBaseUrl: "https://github.com",
    });
  });
});
