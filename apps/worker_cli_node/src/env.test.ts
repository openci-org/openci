import { beforeEach, describe, expect, it, vi } from "vitest";

import { buildEnvVars, buildSecretVars, envFileContent, extractSecretNames } from "./env.js";
import { getEnvironmentVariables, getSecrets, updateEnvironmentVariable } from "./firestore.js";
import { logInfo } from "./logger.js";

vi.mock("./firestore.js", () => ({
  getEnvironmentVariables: vi.fn(),
  getSecrets: vi.fn(),
  updateEnvironmentVariable: vi.fn(),
}));

vi.mock("@google-cloud/secret-manager", () => {
  class MockSecretManagerServiceClient {
    accessSecretVersion = vi.fn().mockResolvedValue([
      {
        payload: { data: Buffer.from("secret-value") },
      },
    ]);
  }
  return {
    SecretManagerServiceClient: MockSecretManagerServiceClient,
  };
});

vi.mock("./logger.js", () => ({
  logInfo: vi.fn(),
  logWarning: vi.fn(),
}));

const mockGetEnvironmentVariables = vi.mocked(getEnvironmentVariables);
const mockUpdateEnvironmentVariable = vi.mocked(updateEnvironmentVariable);
const mockLogInfo = vi.mocked(logInfo);

describe("buildEnvVars", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("passes the incremented value to the workflow environment", async () => {
    mockGetEnvironmentVariables.mockResolvedValue([
      { id: "env-1", key: "OPENCI_RUN_NUMBER", value: "2554", autoIncrement: true },
    ]);

    const envVars = await buildEnvVars({
      buildJob: {
        id: "job-1",
        status: "QUEUED",
        owner: "openci-org",
        repo: "openci",
        teamId: "team-1",
      },
      projectId: "project-1",
      buildJobId: "job-1",
      runId: "run-1",
    });

    expect(mockUpdateEnvironmentVariable).toHaveBeenCalledWith("env-1", "2555");
    expect(envVars.OPENCI_RUN_NUMBER).toBe("2555");
    expect(envFileContent(envVars)).toContain("OPENCI_RUN_NUMBER=2555");
    expect(mockLogInfo).toHaveBeenCalledWith(
      "job-1",
      "run-1",
      "Auto-incremented OPENCI_RUN_NUMBER: 2554 -> 2555",
    );
  });

  it("keeps non-numeric auto-increment values unchanged", async () => {
    mockGetEnvironmentVariables.mockResolvedValue([
      { id: "env-1", key: "OPENCI_RUN_NUMBER", value: "latest", autoIncrement: true },
    ]);

    const envVars = await buildEnvVars({
      buildJob: {
        id: "job-1",
        status: "QUEUED",
        owner: "openci-org",
        repo: "openci",
        teamId: "team-1",
      },
      projectId: "project-1",
      buildJobId: "job-1",
      runId: "run-1",
    });

    expect(mockUpdateEnvironmentVariable).not.toHaveBeenCalled();
    expect(envVars.OPENCI_RUN_NUMBER).toBe("latest");
  });

  it("only increments and loads auto-increment variables referenced in workflowContent", async () => {
    mockGetEnvironmentVariables.mockResolvedValue([
      { id: "env-1", key: "OPENCI_RUN_NUMBER", value: "2554", autoIncrement: true },
      { id: "env-2", key: "ANOTHER_RUN_NUMBER", value: "100", autoIncrement: true },
    ]);

    const envVars = await buildEnvVars({
      buildJob: {
        id: "job-1",
        status: "QUEUED",
        owner: "openci-org",
        repo: "openci",
        teamId: "team-1",
      },
      projectId: "project-1",
      buildJobId: "job-1",
      runId: "run-1",
      workflowContent: "echo ${{ env.OPENCI_RUN_NUMBER }}",
    });

    expect(mockUpdateEnvironmentVariable).toHaveBeenCalledWith("env-1", "2555");
    expect(envVars.OPENCI_RUN_NUMBER).toBe("2555");

    expect(mockUpdateEnvironmentVariable).not.toHaveBeenCalledWith("env-2", expect.any(String));
    expect(envVars.ANOTHER_RUN_NUMBER).toBeUndefined();
  });
});

describe("extractSecretNames", () => {
  it("extracts secrets from workflow content", () => {
    const yaml = `
      name: CI
      on: push
      jobs:
        build:
          runs-on: ubuntu-latest
          steps:
            - name: Checkout
              uses: actions/checkout@v4
            - name: Run tests
              env:
                API_KEY: \${{ secrets.API_KEY }}
                SECRET_TOKEN: \${{ secrets['MY_SECRET_TOKEN'] }}
                ANOTHER: \${{ secrets["ANOTHER_SECRET"] }}
                GITHUB_TOKEN: \${{ secrets.GITHUB_TOKEN }}
              run: npm test
    `;
    const names = extractSecretNames(yaml);
    expect(names).toEqual(
      new Set(["API_KEY", "MY_SECRET_TOKEN", "ANOTHER_SECRET", "GITHUB_TOKEN"]),
    );
  });

  it("returns empty set if no secrets found", () => {
    const yaml = `
      name: CI
      on: push
    `;
    const names = extractSecretNames(yaml);
    expect(names.size).toBe(0);
  });
});

describe("buildSecretVars", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("only loads secrets referenced in workflowContent", async () => {
    vi.mocked(getSecrets).mockResolvedValue([
      { name: "API_KEY", pathToSecret: "projects/123/secrets/API_KEY" },
      { name: "UNUSED_SECRET", pathToSecret: "projects/123/secrets/UNUSED" },
    ]);

    const secrets = await buildSecretVars({
      buildJob: {
        id: "job-1",
        status: "QUEUED",
        owner: "openci-org",
        repo: "openci",
        teamId: "team-1",
      },
      projectId: "project-1",
      serviceAccountPath: "/path/to/sa",
      buildJobId: "job-1",
      runId: "run-1",
      workflowContent: "echo ${{ secrets.API_KEY }}",
    });

    expect(secrets.API_KEY).toBe("secret-value");
    expect(secrets.UNUSED_SECRET).toBeUndefined();
  });

  it("loads all secrets if workflowContent is null (fallback)", async () => {
    vi.mocked(getSecrets).mockResolvedValue([
      { name: "API_KEY", pathToSecret: "projects/123/secrets/API_KEY" },
      { name: "UNUSED_SECRET", pathToSecret: "projects/123/secrets/UNUSED" },
    ]);

    const secrets = await buildSecretVars({
      buildJob: {
        id: "job-1",
        status: "QUEUED",
        owner: "openci-org",
        repo: "openci",
        teamId: "team-1",
      },
      projectId: "project-1",
      serviceAccountPath: "/path/to/sa",
      buildJobId: "job-1",
      runId: "run-1",
      workflowContent: null,
    });

    expect(secrets.API_KEY).toBe("secret-value");
    expect(secrets.UNUSED_SECRET).toBe("secret-value");
  });
});
