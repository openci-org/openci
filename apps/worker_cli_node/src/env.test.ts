import { beforeEach, describe, expect, it, vi } from "vitest";

import { buildEnvVars, envFileContent } from "./env.js";
import { getEnvironmentVariables, updateEnvironmentVariable } from "./firestore.js";
import { logInfo } from "./logger.js";

vi.mock("./firestore.js", () => ({
  getEnvironmentVariables: vi.fn(),
  getSecrets: vi.fn(),
  updateEnvironmentVariable: vi.fn(),
}));

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
});
