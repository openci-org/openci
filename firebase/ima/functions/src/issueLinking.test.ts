/// <reference types="node" />

import assert from "node:assert/strict";
import { describe, it } from "node:test";

import {
  extractIssueKey,
  imaLinkedIssueBlockEnd,
  imaLinkedIssueBlockStart,
  issueKey,
  issueStatusForPullRequest,
  upsertLinkedIssueBlock,
} from "./issueLinkingHelpers.js";

describe("issue linking helpers", () => {
  it("normalizes issue keys from branch names", () => {
    assert.equal(extractIssueKey("feature/ima-1423-fix-login"), "IMA-1423");
    assert.equal(extractIssueKey("bugfix/OPN-8"), "OPN-8");
  });

  it("falls back across branch, title, and body sources", () => {
    assert.equal(extractIssueKey("feature/no-ticket", "Fix auth (IMA-42)", undefined), "IMA-42");
  });

  it("builds issue keys from prefixes and counters", () => {
    assert.equal(issueKey("ima", 7), "IMA-7");
    assert.equal(issueKey("ima-mobile", 8), "IMAMOBILE-8");
  });

  it("upserts a managed PR body block", () => {
    const first = upsertLinkedIssueBlock("Existing body", 57, "IMA-1423");
    assert.equal(
      first,
      [
        "Existing body",
        "",
        imaLinkedIssueBlockStart,
        "Fixes #57",
        "Ima: IMA-1423",
        imaLinkedIssueBlockEnd,
      ].join("\n"),
    );

    const second = upsertLinkedIssueBlock(first, 58, "IMA-1424");
    assert.equal(second.match(/ima-linked-issue:start/gu)?.length, 1);
    assert.match(second, /Fixes #58/u);
    assert.doesNotMatch(second, /Fixes #57/u);
  });

  it("moves linked pull requests into review", () => {
    assert.equal(
      issueStatusForPullRequest({
        action: "opened",
        merged: false,
        currentStatusId: "doing",
      }),
      "review",
    );
    assert.equal(
      issueStatusForPullRequest({
        action: "synchronize",
        merged: false,
        currentStatusId: "review",
      }),
      null,
    );
  });

  it("moves merged pull requests into done", () => {
    assert.equal(
      issueStatusForPullRequest({
        action: "closed",
        merged: true,
        currentStatusId: "review",
      }),
      "done",
    );
    assert.equal(
      issueStatusForPullRequest({
        action: "closed",
        merged: false,
        currentStatusId: "review",
      }),
      null,
    );
  });

  it("does not regress done issues except for reopened pull requests", () => {
    assert.equal(
      issueStatusForPullRequest({
        action: "edited",
        merged: false,
        currentStatusId: "done",
      }),
      null,
    );
    assert.equal(
      issueStatusForPullRequest({
        action: "reopened",
        merged: false,
        currentStatusId: "done",
      }),
      "review",
    );
  });
});
