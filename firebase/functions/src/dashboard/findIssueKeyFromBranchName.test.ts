import { describe, expect, it } from "vitest";

import { findIssueKeyFromBranchName } from "./findIssueKeyFromBranchName.js";

describe("findIssueKeyFromBranchName", () => {
  it("extracts a Dashboard issue key from the branch name", () => {
    expect(findIssueKeyFromBranchName("feature/MASA-123-review-status")).toBe("MASA-123");
    expect(findIssueKeyFromBranchName("feature/MASA-123-2")).toBe("MASA-123");
    expect(findIssueKeyFromBranchName("feature/masa-123")).toBe("MASA-123");
    expect(findIssueKeyFromBranchName("feature/masa_123")).toBe("MASA-123");
    expect(findIssueKeyFromBranchName("bugfix/openci-456")).toBe("OPENCI-456");
  });

  it("does not extract keys from surrounding words", () => {
    expect(findIssueKeyFromBranchName("feature/NOTIMA-123abc")).toBeNull();
  });

  it("returns null when the branch does not contain an issue key", () => {
    expect(findIssueKeyFromBranchName("feature/review-status")).toBeNull();
  });
});
