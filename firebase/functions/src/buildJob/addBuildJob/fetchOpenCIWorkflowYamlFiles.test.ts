import { request } from "@octokit/request";
import { beforeEach, describe, expect, it, vi } from "vitest";

import { fetchOpenCIWorkflowYamlFiles } from "./fetchOpenCIWorkflowYamlFiles.js";

vi.mock("@octokit/request", () => ({
  request: vi.fn(),
}));

const mockRequest = vi.mocked(request);

describe("fetchOpenCIWorkflowYamlFiles", () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  it("returns an empty array when the .openci directory does not exist", async () => {
    mockRequest.mockRejectedValueOnce({ status: 404 });

    await expect(
      fetchOpenCIWorkflowYamlFiles(
        "openci-org",
        "openci",
        "abc123",
        "installation-token",
        "https://api.github.com",
      ),
    ).resolves.toEqual([]);
  });

  it("rethrows non-404 errors when listing the .openci directory fails", async () => {
    const error = new Error("rate limited");
    mockRequest.mockRejectedValueOnce(error);

    await expect(
      fetchOpenCIWorkflowYamlFiles(
        "openci-org",
        "openci",
        "abc123",
        "installation-token",
        "https://api.github.com",
      ),
    ).rejects.toThrow(error);
  });

  it("fetches only yaml workflow files from the .openci directory", async () => {
    mockRequest
      .mockResolvedValueOnce({
        data: [
          { type: "file", name: "ci.yaml", path: ".openci/ci.yaml" },
          { type: "file", name: "README.md", path: ".openci/README.md" },
        ],
      } as never)
      .mockResolvedValueOnce({ data: "name: CI" } as never);

    await expect(
      fetchOpenCIWorkflowYamlFiles(
        "openci-org",
        "openci",
        "abc123",
        "installation-token",
        "https://api.github.com",
      ),
    ).resolves.toEqual([{ name: "ci.yaml", content: "name: CI" }]);

    expect(mockRequest).toHaveBeenNthCalledWith(2, "GET /repos/{owner}/{repo}/contents/{path}", {
      baseUrl: "https://api.github.com",
      owner: "openci-org",
      repo: "openci",
      path: ".openci/ci.yaml",
      ref: "abc123",
      headers: {
        authorization: "bearer installation-token",
        accept: "application/vnd.github.raw+json",
      },
    });
  });
});
