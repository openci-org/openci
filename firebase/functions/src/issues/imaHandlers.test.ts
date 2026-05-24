import { beforeEach, describe, expect, it, vi } from "vitest";
import { getFirestore } from "firebase-admin/firestore";

// mock functions
const mockGet = vi.fn();
const mockWhere = vi.fn().mockReturnThis();
const mockLimit = vi.fn().mockReturnThis();
const mockCollection = vi.fn(() => ({
  where: mockWhere,
  limit: mockLimit,
  get: mockGet,
}));
const mockDoc = vi.fn().mockReturnThis();
const mockRunTransaction = vi.fn();

class MockTimestamp {
  static now() {
    return new MockTimestamp();
  }
  toMillis() {
    return Date.now();
  }
}

vi.mock("firebase-admin/firestore", () => {
  return {
    getFirestore: () => ({
      collection: mockCollection,
      doc: mockDoc,
      runTransaction: mockRunTransaction,
    }),
    FieldValue: {
      serverTimestamp: vi.fn(),
    },
    Timestamp: MockTimestamp,
  };
});

// getTeamById mock (from ../firestoreData.js)
const mockGetTeamById = vi.fn();
vi.mock("../firestoreData.js", () => ({
  firestoreCollectionPaths: {
    workspaces: "workspaces",
  },
  getTeamById: (...args: any[]) => mockGetTeamById(...args),
}));

// getInstallationToken mock (from ../github/githubApp.js)
const mockGetInstallationToken = vi.fn();
vi.mock("../github/githubApp.js", () => ({
  githubAppId: "mock-app-id",
  githubPrivateKey: "mock-key",
  getInstallationToken: (...args: any[]) => mockGetInstallationToken(...args),
}));

// fetch spy
const mockFetch = vi.spyOn(global, "fetch");

// Import target
const { autoCreatePullRequest } = await import("./imaHandlers.js");

describe("autoCreatePullRequest", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    mockGetTeamById.mockResolvedValue({
      data: {
        team: {
          installationIds: [12345],
        },
      },
    });
    mockGetInstallationToken.mockResolvedValue({ token: "mock-token" });
    
    // reset collection mock structure
    mockCollection.mockImplementation(() => ({
      where: mockWhere,
      limit: mockLimit,
      get: mockGet,
    }));
  });

  it("should do nothing if no issue key is in the branch name", async () => {
    await autoCreatePullRequest({
      repository: "openci-org/openci",
      branch: "feature/no-issue-key",
    });

    expect(mockCollection).not.toHaveBeenCalled();
  });

  it("should create a PR and link it when matching issue is found", async () => {
    // 1. Workspace Query mock
    const mockWorkspaceDoc = {
      id: "workspace-1",
      ref: {
        collection: mockCollection,
      },
    };
    mockGet.mockResolvedValueOnce({
      docs: [mockWorkspaceDoc],
    });

    // 2. Issue Query mock
    const mockIssueDoc = {
      id: "issue-1",
      data: () => ({
        issueKey: "OPENCI-123",
        title: "Fix issue 123",
        repo: "openci-org/openci",
        statusId: "triage",
      }),
    };
    mockGet.mockResolvedValueOnce({
      docs: [mockIssueDoc],
    });

    // mock fetch (GitHub API calls)
    mockFetch
      .mockResolvedValueOnce({
        ok: true,
        json: async () => ({ default_branch: "main" }),
      } as any)
      .mockResolvedValueOnce({
        ok: true,
        json: async () => [], // No duplicate PR
      } as any)
      .mockResolvedValueOnce({
        ok: true,
        json: async () => ({ number: 100, html_url: "https://github.com/openci-org/openci/pull/100" }),
      } as any);

    // mock runTransaction for upsertPullRequestLink
    const mockTransaction = {
      get: vi.fn().mockResolvedValue({
        get: (field: string) => {
          if (field === "pullRequests") return [];
          if (field === "statusId") return "triage";
          return null;
        },
      }),
      update: vi.fn(),
      set: vi.fn(),
    };
    mockRunTransaction.mockImplementation(async (cb: any) => {
      return cb(mockTransaction);
    });

    await autoCreatePullRequest({
      repository: "openci-org/openci",
      branch: "feature/OPENCI-123-fix-it",
    });

    // Verify workspace query was run
    expect(mockCollection).toHaveBeenCalledWith("workspaces");
    expect(mockWhere).toHaveBeenCalledWith("syncedGitHubRepoFullNames", "array-contains", "openci-org/openci");

    // Verify issue query was run
    expect(mockCollection).toHaveBeenCalledWith("issues");
    expect(mockWhere).toHaveBeenCalledWith("issueKey", "==", "OPENCI-123");

    // Verify GitHub API called
    expect(mockFetch).toHaveBeenCalledTimes(3);
    const postCall = mockFetch.mock.calls[2];
    expect(postCall[0]?.toString()).toContain("/repos/openci-org/openci/pulls");
    expect(postCall[1]?.method).toBe("POST");
    const body = JSON.parse(postCall[1]?.body as string);
    expect(body.draft).toBe(false);
    expect(body.head).toBe("feature/OPENCI-123-fix-it");
  });
});
