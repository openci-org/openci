import firebaseFunctionsTest from "firebase-functions-test";
import type { CallableRequest } from "firebase-functions/v2/https";
import { beforeEach, describe, expect, it, vi } from "vitest";
import type {
  ListBranchesResponse,
  ListDirectoriesResponse,
  ListRepositoriesResponse,
  ListWorkflowFilesResponse,
} from "./repositories";

type AuthData = NonNullable<CallableRequest["auth"]>;

const {
  mockVerifyTeamMembership,
  mockGetInstallationToken,
  mockGithubGet,
  mockGithubGraphql,
  mockGithubPost,
  mockGithubPatch,
  mockGithubPut,
} = vi.hoisted(() => ({
  mockVerifyTeamMembership: vi.fn(),
  mockGetInstallationToken: vi.fn(),
  mockGithubGet: vi.fn(),
  mockGithubGraphql: vi.fn(),
  mockGithubPost: vi.fn(),
  mockGithubPatch: vi.fn(),
  mockGithubPut: vi.fn(),
}));

vi.mock("../team/teamAuth", () => ({
  verifyTeamMembership: (...args: unknown[]) => mockVerifyTeamMembership(...args),
}));

vi.mock("./githubApp", () => ({
  getInstallationToken: (...args: unknown[]) => mockGetInstallationToken(...args),
}));

vi.mock("./githubRequests", () => ({
  githubGet: (...args: unknown[]) => mockGithubGet(...args),
  githubGraphql: (...args: unknown[]) => mockGithubGraphql(...args),
  githubPost: (...args: unknown[]) => mockGithubPost(...args),
  githubPatch: (...args: unknown[]) => mockGithubPatch(...args),
  githubPut: (...args: unknown[]) => mockGithubPut(...args),
}));

const testEnv = firebaseFunctionsTest();

const { createWorkflowFile, listBranches, listDirectories, listRepositories, listWorkflowFiles } =
  await import("./repositories");

const wrappedListRepositories = testEnv.wrap(listRepositories) as (req: {
  data: { teamId?: string };
  auth?: AuthData;
}) => Promise<ListRepositoriesResponse>;

const wrappedListBranches = testEnv.wrap(listBranches) as (req: {
  data: { teamId?: string; repository?: string };
  auth?: AuthData;
}) => Promise<ListBranchesResponse>;

const wrappedListDirectories = testEnv.wrap(listDirectories) as (req: {
  data: { teamId?: string; repository?: string };
  auth?: AuthData;
}) => Promise<ListDirectoriesResponse>;

const wrappedListWorkflowFiles = testEnv.wrap(listWorkflowFiles) as (req: {
  data: { teamId?: string; repository?: string; branch?: string };
  auth?: AuthData;
}) => Promise<ListWorkflowFilesResponse>;

const wrappedCreateWorkflowFile = testEnv.wrap(createWorkflowFile) as (req: {
  data: {
    teamId?: string;
    repository?: string;
    branch?: string;
    fileName?: string;
    content?: string;
    commitMode?: string;
  };
  auth?: AuthData;
}) => Promise<unknown>;

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

describe("listRepositories", () => {
  beforeEach(() => {
    vi.resetAllMocks();
    mockVerifyTeamMembership.mockResolvedValue({
      installationIds: [101],
      githubApiBaseUrl: "https://github.example.com/api/v3",
    });
    mockGetInstallationToken.mockResolvedValue({ token: "installation-token", expiresAt: "" });
  });

  it("rejects missing teamId", async () => {
    await expect(wrappedListRepositories({ data: {}, auth: makeAuth() })).rejects.toThrow(
      expect.objectContaining({ code: "invalid-argument" }),
    );
  });

  it("lists installation repositories", async () => {
    mockGithubGet.mockResolvedValue({
      repositories: [
        {
          full_name: "openci/openci",
          name: "openci",
          owner: { login: "openci" },
          private: true,
          default_branch: "main",
        },
      ],
    });

    const result = await wrappedListRepositories({
      data: { teamId: "team-1" },
      auth: makeAuth(),
    });

    expect(result).toEqual({
      repositories: [
        {
          fullName: "openci/openci",
          name: "openci",
          owner: "openci",
          private: true,
          defaultBranch: "main",
        },
      ],
    });
    expect(mockGetInstallationToken).toHaveBeenCalledWith(101, {
      apiBaseUrl: "https://github.example.com/api/v3",
    });
    expect(mockGithubGet).toHaveBeenCalledWith("/installation/repositories", "installation-token", {
      queryParameters: { per_page: 100, page: 1 },
      apiBaseUrl: "https://github.example.com/api/v3",
    });
  });

  it("lists repositories across all pages", async () => {
    mockGithubGet
      .mockResolvedValueOnce({
        repositories: Array.from({ length: 100 }, (_, index) => ({
          full_name: `openci/repo-${index}`,
          name: `repo-${index}`,
          owner: { login: "openci" },
          private: false,
          default_branch: "main",
        })),
      })
      .mockResolvedValueOnce({
        repositories: [
          {
            full_name: "openci/repo-100",
            name: "repo-100",
            owner: { login: "openci" },
            private: false,
            default_branch: "main",
          },
        ],
      });

    const result = await wrappedListRepositories({
      data: { teamId: "team-1" },
      auth: makeAuth(),
    });

    expect(result.repositories).toHaveLength(101);
    expect(result.repositories.at(-1)?.fullName).toBe("openci/repo-100");
    expect(mockGithubGet).toHaveBeenNthCalledWith(
      2,
      "/installation/repositories",
      "installation-token",
      {
        queryParameters: { per_page: 100, page: 2 },
        apiBaseUrl: "https://github.example.com/api/v3",
      },
    );
  });
});

describe("listBranches", () => {
  beforeEach(() => {
    vi.resetAllMocks();
    mockVerifyTeamMembership.mockResolvedValue({ installationIds: [101] });
    mockGetInstallationToken.mockResolvedValue({ token: "installation-token", expiresAt: "" });
  });

  it("rejects repositories that are not owner/repo", async () => {
    await expect(
      wrappedListBranches({
        data: { teamId: "team-1", repository: "openci" },
        auth: makeAuth(),
      }),
    ).rejects.toThrow(expect.objectContaining({ code: "invalid-argument" }));
  });

  it("sorts the default branch first and the rest by name", async () => {
    mockGithubGet
      .mockResolvedValueOnce({ default_branch: "main" })
      .mockResolvedValueOnce([{ name: "old" }, { name: "main" }, { name: "new" }]);

    const result = await wrappedListBranches({
      data: { teamId: "team-1", repository: "openci/openci" },
      auth: makeAuth(),
    });

    expect(result).toEqual({ branches: ["main", "new", "old"] });
    expect(mockGithubGet).toHaveBeenCalledWith(
      "/repos/openci/openci",
      "installation-token",
      expect.objectContaining({ apiBaseUrl: "https://api.github.com" }),
    );
    expect(mockGithubGet).toHaveBeenCalledWith(
      "/repos/openci/openci/branches",
      "installation-token",
      expect.objectContaining({
        apiBaseUrl: "https://api.github.com",
        queryParameters: { per_page: 100, page: 1 },
      }),
    );
  });

  it("tries the next installation when a repository is not available", async () => {
    mockVerifyTeamMembership.mockResolvedValue({ installationIds: [101, 202] });
    mockGetInstallationToken
      .mockResolvedValueOnce({ token: "first-token", expiresAt: "" })
      .mockResolvedValueOnce({ token: "second-token", expiresAt: "" });
    mockGithubGet
      .mockRejectedValueOnce(new Error("not found"))
      .mockResolvedValueOnce({ default_branch: "main" })
      .mockResolvedValueOnce([{ name: "main" }]);

    const result = await wrappedListBranches({
      data: { teamId: "team-1", repository: "openci/openci" },
      auth: makeAuth(),
    });

    expect(result).toEqual({ branches: ["main"] });
    expect(mockGetInstallationToken).toHaveBeenCalledTimes(2);
  });
});

describe("listDirectories", () => {
  beforeEach(() => {
    vi.resetAllMocks();
    mockVerifyTeamMembership.mockResolvedValue({ installationIds: [101] });
    mockGetInstallationToken.mockResolvedValue({ token: "installation-token", expiresAt: "" });
  });

  it("returns dot plus sorted nested directories", async () => {
    mockGithubGraphql.mockResolvedValue({
      data: {
        repository: {
          object: {
            entries: [
              {
                name: "lib",
                type: "tree",
                object: {
                  entries: [{ name: "src", type: "tree" }],
                },
              },
              { name: "README.md", type: "blob" },
              { name: "apps", type: "tree" },
            ],
          },
        },
      },
    });

    const result = await wrappedListDirectories({
      data: { teamId: "team-1", repository: "openci/openci" },
      auth: makeAuth(),
    });

    expect(result).toEqual({ directories: [".", "apps", "lib", "lib/src"] });
    expect(mockGithubGraphql).toHaveBeenCalledWith(
      expect.stringContaining("expression"),
      "installation-token",
      expect.objectContaining({
        variables: { owner: "openci", repo: "openci", expression: "HEAD:" },
      }),
    );
  });
});

describe("listWorkflowFiles", () => {
  beforeEach(() => {
    vi.resetAllMocks();
    mockVerifyTeamMembership.mockResolvedValue({ installationIds: [101] });
    mockGetInstallationToken.mockResolvedValue({ token: "installation-token", expiresAt: "" });
  });

  it("returns YAML files from the .openci directory", async () => {
    mockGithubGraphql.mockResolvedValue({
      data: {
        repository: {
          object: {
            entries: [
              { name: "build.yaml", type: "blob", object: { text: "name: build" } },
              { name: "notes.txt", type: "blob", object: { text: "ignore me" } },
              { name: "deploy.yml", type: "blob", object: { text: "name: deploy" } },
            ],
          },
        },
      },
    });

    const result = await wrappedListWorkflowFiles({
      data: { teamId: "team-1", repository: "openci/openci", branch: "main" },
      auth: makeAuth(),
    });

    expect(result).toEqual({
      files: [
        { name: "build.yaml", path: ".openci/build.yaml", content: "name: build" },
        { name: "deploy.yml", path: ".openci/deploy.yml", content: "name: deploy" },
      ],
    });
    expect(mockGithubGraphql).toHaveBeenCalledWith(
      expect.stringContaining("Blob"),
      "installation-token",
      expect.objectContaining({
        variables: { owner: "openci", repo: "openci", expression: "main:.openci" },
      }),
    );
  });

  it("returns an empty file list when .openci does not exist", async () => {
    mockGithubGraphql.mockRejectedValue(new Error("Could not resolve to an object"));

    const result = await wrappedListWorkflowFiles({
      data: { teamId: "team-1", repository: "openci/openci" },
      auth: makeAuth(),
    });

    expect(result).toEqual({ files: [] });
  });
});

describe("createWorkflowFile", () => {
  beforeEach(() => {
    vi.resetAllMocks();
    mockVerifyTeamMembership.mockResolvedValue({ installationIds: [101] });
    mockGetInstallationToken.mockResolvedValue({ token: "installation-token", expiresAt: "" });
  });

  it("creates a direct commit", async () => {
    mockGithubGet
      .mockResolvedValueOnce({ object: { sha: "latest-sha" } })
      .mockResolvedValueOnce({ tree: { sha: "base-tree-sha" } });
    mockGithubPost
      .mockResolvedValueOnce({ sha: "blob-sha" })
      .mockResolvedValueOnce({ sha: "tree-sha" })
      .mockResolvedValueOnce({ sha: "commit-sha" });
    mockGithubPatch.mockResolvedValue({});

    const result = await wrappedCreateWorkflowFile({
      data: {
        teamId: "team-1",
        repository: "openci/openci",
        branch: "main",
        fileName: "build.yaml",
        content: "name: build",
        commitMode: "direct",
      },
      auth: makeAuth(),
    });

    expect(result).toEqual({ mode: "direct", commitSha: "commit-sha", branch: "main" });
    expect(mockGithubPatch).toHaveBeenCalledOnce();
  });

  it("resolves HEAD to the repository default branch before writing", async () => {
    mockGithubGet
      .mockResolvedValueOnce({ default_branch: "trunk" })
      .mockResolvedValueOnce({ object: { sha: "latest-sha" } })
      .mockResolvedValueOnce({ tree: { sha: "base-tree-sha" } });
    mockGithubPost
      .mockResolvedValueOnce({ sha: "blob-sha" })
      .mockResolvedValueOnce({ sha: "tree-sha" })
      .mockResolvedValueOnce({ sha: "commit-sha" });
    mockGithubPatch.mockResolvedValue({});

    const result = await wrappedCreateWorkflowFile({
      data: {
        teamId: "team-1",
        repository: "openci/openci",
        branch: "HEAD",
        fileName: "build.yaml",
        content: "name: build",
        commitMode: "direct",
      },
      auth: makeAuth(),
    });

    expect(result).toEqual({ mode: "direct", commitSha: "commit-sha", branch: "trunk" });
    expect(mockGithubGet).toHaveBeenNthCalledWith(
      1,
      "/repos/openci/openci",
      "installation-token",
      expect.objectContaining({ apiBaseUrl: "https://api.github.com" }),
    );
    expect(mockGithubGet).toHaveBeenNthCalledWith(
      2,
      "/repos/openci/openci/git/ref/heads/trunk",
      "installation-token",
      expect.objectContaining({ apiBaseUrl: "https://api.github.com" }),
    );
    expect(mockGithubPatch).toHaveBeenCalledWith(
      "/repos/openci/openci/git/refs/heads/trunk",
      "installation-token",
      { sha: "commit-sha" },
      expect.objectContaining({ apiBaseUrl: "https://api.github.com" }),
    );
  });

  it("uses a GHES API base URL when resolving HEAD before writing", async () => {
    mockVerifyTeamMembership.mockResolvedValue({
      installationIds: [39413],
      githubBaseUrl: "https://github.enterprise.example",
    });
    mockGetInstallationToken.mockResolvedValue({ token: "ghes-token", expiresAt: "" });
    mockGithubGet
      .mockResolvedValueOnce({ default_branch: "main" })
      .mockResolvedValueOnce({ object: { sha: "latest-sha" } })
      .mockResolvedValueOnce({ tree: { sha: "base-tree-sha" } });
    mockGithubPost
      .mockResolvedValueOnce({ sha: "blob-sha" })
      .mockResolvedValueOnce({ sha: "tree-sha" })
      .mockResolvedValueOnce({ sha: "commit-sha" });
    mockGithubPatch.mockResolvedValue({});

    const result = await wrappedCreateWorkflowFile({
      data: {
        teamId: "team-1",
        repository: "enterprise/mobile",
        branch: "HEAD",
        fileName: "build.yaml",
        content: "name: build",
        commitMode: "direct",
      },
      auth: makeAuth(),
    });

    const apiBaseUrl = "https://github.enterprise.example/api/v3";
    expect(result).toEqual({ mode: "direct", commitSha: "commit-sha", branch: "main" });
    expect(mockGetInstallationToken).toHaveBeenCalledWith(39413, { apiBaseUrl });
    expect(mockGithubGet).toHaveBeenNthCalledWith(1, "/repos/enterprise/mobile", "ghes-token", {
      apiBaseUrl,
    });
    expect(mockGithubGet).toHaveBeenNthCalledWith(
      2,
      "/repos/enterprise/mobile/git/ref/heads/main",
      "ghes-token",
      { apiBaseUrl },
    );
    expect(mockGithubPost).toHaveBeenNthCalledWith(
      1,
      "/repos/enterprise/mobile/git/blobs",
      "ghes-token",
      { content: Buffer.from("name: build", "utf8").toString("base64"), encoding: "base64" },
      { apiBaseUrl },
    );
    expect(mockGithubPatch).toHaveBeenCalledWith(
      "/repos/enterprise/mobile/git/refs/heads/main",
      "ghes-token",
      { sha: "commit-sha" },
      { apiBaseUrl },
    );
  });

  it("passes the existing content SHA when creating a PR for an existing GHES workflow file", async () => {
    mockVerifyTeamMembership.mockResolvedValue({
      installationIds: [39413],
      githubBaseUrl: "https://github.enterprise.example",
    });
    mockGetInstallationToken.mockResolvedValue({ token: "ghes-token", expiresAt: "" });
    const nowSpy = vi.spyOn(Date, "now").mockReturnValue(1_779_029_000_000);
    const newBranchName = "openci/add-flutter-ci-1779029000000";
    mockGithubGet
      .mockResolvedValueOnce({ object: { sha: "base-sha" } })
      .mockResolvedValueOnce({ sha: "existing-content-sha" });
    mockGithubPost.mockResolvedValueOnce({}).mockResolvedValueOnce({
      html_url: "https://github.enterprise.example/enterprise/mobile/pull/12",
      number: 12,
    });

    try {
      const result = await wrappedCreateWorkflowFile({
        data: {
          teamId: "team-1",
          repository: "enterprise/mobile",
          branch: "main",
          fileName: "flutter-ci.yaml",
          content: "name: build",
          commitMode: "pull_request",
        },
        auth: makeAuth(),
      });

      const apiBaseUrl = "https://github.enterprise.example/api/v3";
      expect(result).toEqual({
        mode: "pull_request",
        pullRequestUrl: "https://github.enterprise.example/enterprise/mobile/pull/12",
        pullRequestNumber: 12,
        branch: newBranchName,
      });
      expect(mockGetInstallationToken).toHaveBeenCalledWith(39413, { apiBaseUrl });
      expect(mockGithubGet).toHaveBeenNthCalledWith(
        1,
        "/repos/enterprise/mobile/git/ref/heads/main",
        "ghes-token",
        { apiBaseUrl },
      );
      expect(mockGithubGet).toHaveBeenNthCalledWith(
        2,
        "/repos/enterprise/mobile/contents/.openci/flutter-ci.yaml",
        "ghes-token",
        { queryParameters: { ref: newBranchName }, apiBaseUrl },
      );
      expect(mockGithubPut).toHaveBeenCalledWith(
        "/repos/enterprise/mobile/contents/.openci/flutter-ci.yaml",
        "ghes-token",
        {
          message: "Add workflow: flutter-ci.yaml",
          content: Buffer.from("name: build", "utf8").toString("base64"),
          branch: newBranchName,
          sha: "existing-content-sha",
        },
        { apiBaseUrl },
      );
      expect(mockGithubPost).toHaveBeenNthCalledWith(
        2,
        "/repos/enterprise/mobile/pulls",
        "ghes-token",
        expect.objectContaining({
          head: newBranchName,
          base: "main",
        }),
        { apiBaseUrl },
      );
    } finally {
      nowSpy.mockRestore();
    }
  });
});
