import { describe, expect, it } from "vitest";

import { findDashboardIssueStatusSyncTarget } from "./dashboardIssueStatusSyncTarget.js";

describe("findDashboardIssueStatusSyncTarget", () => {
  it("returns repo and issue key for an opened pull request branch", () => {
    expect(
      findDashboardIssueStatusSyncTarget({
        action: "opened",
        repository: { full_name: "openci-org/openci" },
        pull_request: { head: { ref: "feature/masa_123-review" } },
      }),
    ).toEqual({
      repoFullName: "openci-org/openci",
      issueKey: "MASA-123",
    });
  });

  it("returns null when the pull request was not opened", () => {
    expect(
      findDashboardIssueStatusSyncTarget({
        action: "synchronize",
        repository: { full_name: "openci-org/openci" },
        pull_request: { head: { ref: "feature/MASA-123" } },
      }),
    ).toBeNull();
  });

  it("returns null when the repository is missing", () => {
    expect(
      findDashboardIssueStatusSyncTarget({
        action: "opened",
        pull_request: { head: { ref: "feature/MASA-123" } },
      }),
    ).toBeNull();
  });

  it("returns null when the branch is missing", () => {
    expect(
      findDashboardIssueStatusSyncTarget({
        action: "opened",
        repository: { full_name: "openci-org/openci" },
      }),
    ).toBeNull();
  });

  it("returns null when the branch has no issue key", () => {
    expect(
      findDashboardIssueStatusSyncTarget({
        action: "opened",
        repository: { full_name: "openci-org/openci" },
        pull_request: { head: { ref: "feature/review-status" } },
      }),
    ).toBeNull();
  });
});
