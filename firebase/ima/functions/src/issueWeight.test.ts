/// <reference types="node" />

import assert from "node:assert/strict";
import { describe, it } from "node:test";

import { issueWeightInputHash, parseWeightEstimateResponse } from "./issueWeightHelpers.js";

describe("issue weight helpers", () => {
  it("parses a valid LLM JSON response", () => {
    assert.deepEqual(
      parseWeightEstimateResponse(
        '{"value":3,"confidence":0.82,"reason":"既存UIへの小さな変更"}',
      ),
      {
        value: 3,
        confidence: 0.82,
        reason: "既存UIへの小さな変更",
      },
    );
  });

  it("rejects out-of-range weight values", () => {
    assert.throws(
      () => parseWeightEstimateResponse('{"value":13,"confidence":0.5,"reason":"large"}'),
      /integer from 1 to 8/u,
    );
  });

  it("keeps input hashes stable for unchanged issue fields", () => {
    const issue = {
      title: "Add weight badge",
      body: "Show estimated issue weight on cards.",
      repo: "openci/ima",
      labels: ["ui", "ai"],
      comments: 2,
      priority: "medium",
      statusId: "triage",
    };

    assert.equal(issueWeightInputHash(issue), issueWeightInputHash({ ...issue }));
  });
});
