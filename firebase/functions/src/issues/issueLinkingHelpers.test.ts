import { describe, expect, it } from "vitest";

import {
  removeLinkedIssueBlocks,
  replaceLinkedIssueBlocks,
  upsertLinkedIssueBlock,
  upsertLinkedIssueBlocks,
} from "./issueLinkingHelpers.js";

describe("upsertLinkedIssueBlocks", () => {
  it("adds multiple issue links to a single managed block", () => {
    expect(
      upsertLinkedIssueBlocks("Implementation details", [
        { githubIssueNumber: 1841, imaIssueKey: "IMA-316" },
        { githubIssueNumber: 1845, imaIssueKey: "IMA-317" },
        { githubIssueNumber: 1846, imaIssueKey: "IMA-318" },
      ]),
    ).toBe(
      [
        "Implementation details",
        "",
        "<!-- ima-linked-issue:start -->",
        "Fixes #1841",
        "Ima: IMA-316",
        "Fixes #1845",
        "Ima: IMA-317",
        "Fixes #1846",
        "Ima: IMA-318",
        "<!-- ima-linked-issue:end -->",
      ].join("\n"),
    );
  });

  it("preserves existing links when adding another link", () => {
    const body = upsertLinkedIssueBlock("", 1841, "IMA-316");

    expect(
      upsertLinkedIssueBlocks(body, [{ githubIssueNumber: 1845, imaIssueKey: "IMA-317" }]),
    ).toBe(
      [
        "<!-- ima-linked-issue:start -->",
        "Fixes #1841",
        "Ima: IMA-316",
        "Fixes #1845",
        "Ima: IMA-317",
        "<!-- ima-linked-issue:end -->",
      ].join("\n"),
    );
  });
});

describe("removeLinkedIssueBlocks", () => {
  it("removes one issue from a managed block and preserves the others", () => {
    const body = upsertLinkedIssueBlocks("Implementation details", [
      { githubIssueNumber: 1841, imaIssueKey: "IMA-316" },
      { githubIssueNumber: 1845, imaIssueKey: "IMA-317" },
    ]);

    expect(removeLinkedIssueBlocks(body, [1841])).toBe(
      [
        "Implementation details",
        "",
        "<!-- ima-linked-issue:start -->",
        "Fixes #1845",
        "Ima: IMA-317",
        "<!-- ima-linked-issue:end -->",
      ].join("\n"),
    );
  });

  it("removes the managed block when the last issue is removed", () => {
    const body = upsertLinkedIssueBlock("Implementation details", 1841, "IMA-316");

    expect(removeLinkedIssueBlocks(body, [1841])).toBe("Implementation details");
  });
});

describe("replaceLinkedIssueBlocks", () => {
  it("replaces the managed block with the exact linked issues", () => {
    const body = upsertLinkedIssueBlocks("Implementation details", [
      { githubIssueNumber: 1841, imaIssueKey: "IMA-316" },
      { githubIssueNumber: 1845, imaIssueKey: "IMA-317" },
    ]);

    expect(
      replaceLinkedIssueBlocks(body, [{ githubIssueNumber: 1845, imaIssueKey: "IMA-317" }]),
    ).toBe(
      [
        "Implementation details",
        "",
        "<!-- ima-linked-issue:start -->",
        "Fixes #1845",
        "Ima: IMA-317",
        "<!-- ima-linked-issue:end -->",
      ].join("\n"),
    );
  });

  it("removes the managed block when there are no linked issues", () => {
    const body = upsertLinkedIssueBlock("Implementation details", 1841, "IMA-316");

    expect(replaceLinkedIssueBlocks(body, [])).toBe("Implementation details");
  });
});
