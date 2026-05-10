import { describe, expect, it } from "vitest";

import {
  findIssueKeyFromPullRequestBranch,
  findRepoFullNameFromPullRequestPayload,
  isOpenedPullRequestPayload,
} from "./dashboardPullRequestPayloadHelpers.js";

describe("dashboardPullRequestPayloadHelpers", () => {
  it("checks whether the pull request was opened", () => {
    expect(isOpenedPullRequestPayload({ action: "opened" })).toBe(true);
    expect(isOpenedPullRequestPayload({ action: "synchronize" })).toBe(false);
  });

  it("finds the repository full name", () => {
    expect(
      findRepoFullNameFromPullRequestPayload({
        repository: { full_name: "openci-org/openci" },
      }),
    ).toBe("openci-org/openci");
  });

  it("returns null when the repository full name is missing", () => {
    expect(findRepoFullNameFromPullRequestPayload({})).toBeNull();
    expect(findRepoFullNameFromPullRequestPayload({ repository: { full_name: "" } })).toBeNull();
  });

  it("finds an issue key from the pull request branch", () => {
    expect(
      findIssueKeyFromPullRequestBranch({
        pull_request: { head: { ref: "feature/masa_123-review" } },
      }),
    ).toBe("MASA-123");
  });

  it("returns null when the pull request branch is missing or has no issue key", () => {
    expect(findIssueKeyFromPullRequestBranch({})).toBeNull();
    expect(
      findIssueKeyFromPullRequestBranch({
        pull_request: { head: { ref: "feature/review-status" } },
      }),
    ).toBeNull();
  });
});
