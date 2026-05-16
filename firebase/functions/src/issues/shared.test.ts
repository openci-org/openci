import { describe, expect, it } from "vitest";

import {
  githubMergePreconditionMessage,
  githubRestErrorResponseMessage,
  githubRestErrorStatus,
} from "./shared.js";

describe("GitHub REST error helpers", () => {
  it("extracts the status and response message from GitHub request errors", () => {
    const error = new Error(
      'GitHub request failed: 405 {"message":"Pull Request has merge conflicts","status":"405"}',
    );

    expect(githubRestErrorStatus(error)).toBe(405);
    expect(githubRestErrorResponseMessage(error)).toBe("Pull Request has merge conflicts");
  });

  it("maps merge conflict responses to failed-precondition messages", () => {
    const error = new Error(
      'GitHub request failed: 405 {"message":"Pull Request has merge conflicts","status":"405"}',
    );

    expect(githubMergePreconditionMessage(error)).toBe(
      "Pull request has merge conflicts. Resolve the conflicts and try again.",
    );
  });

  it("does not map unrelated GitHub failures to merge preconditions", () => {
    const error = new Error('GitHub request failed: 500 {"message":"Server Error"}');

    expect(githubMergePreconditionMessage(error)).toBeNull();
  });
});
