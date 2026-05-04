/// <reference types="node" />

import assert from "node:assert/strict";
import { describe, it } from "node:test";

import {
  isAdjacentWeight,
  isValidWeight,
  issueWeightInputHash,
  parseWeightEstimateResponse,
  validWeights,
} from "./issueWeightHelpers.js";

describe("issue weight helpers", () => {
  it("parses a valid LLM JSON response", () => {
    assert.deepEqual(
      parseWeightEstimateResponse(
        '{"value":4,"confidence":0.82,"reason":"既存UIへの小さな変更"}',
      ),
      {
        value: 4,
        confidence: 0.82,
        reason: "既存UIへの小さな変更",
      },
    );
  });

  it("accepts all valid weight values", () => {
    for (const w of validWeights) {
      const result = parseWeightEstimateResponse(
        `{"value":${w},"confidence":0.7,"reason":"テスト"}`,
      );
      assert.equal(result.value, w);
    }
  });

  it("rejects weight values not in the valid set", () => {
    assert.throws(
      () => parseWeightEstimateResponse('{"value":3,"confidence":0.5,"reason":"invalid"}'),
      /must be one of/u,
    );
    assert.throws(
      () => parseWeightEstimateResponse('{"value":5,"confidence":0.5,"reason":"invalid"}'),
      /must be one of/u,
    );
    assert.throws(
      () => parseWeightEstimateResponse('{"value":64,"confidence":0.5,"reason":"too large"}'),
      /must be one of/u,
    );
  });

  it("validates weights correctly", () => {
    assert.equal(isValidWeight(1), true);
    assert.equal(isValidWeight(2), true);
    assert.equal(isValidWeight(4), true);
    assert.equal(isValidWeight(8), true);
    assert.equal(isValidWeight(16), true);
    assert.equal(isValidWeight(32), true);
    assert.equal(isValidWeight(3), false);
    assert.equal(isValidWeight(5), false);
    assert.equal(isValidWeight(0), false);
  });

  it("detects adjacent weights correctly", () => {
    assert.equal(isAdjacentWeight(1, 1), true);
    assert.equal(isAdjacentWeight(1, 2), true);
    assert.equal(isAdjacentWeight(2, 4), true);
    assert.equal(isAdjacentWeight(4, 8), true);
    assert.equal(isAdjacentWeight(8, 16), true);
    assert.equal(isAdjacentWeight(16, 32), true);
    assert.equal(isAdjacentWeight(1, 4), false);
    assert.equal(isAdjacentWeight(2, 8), false);
    assert.equal(isAdjacentWeight(4, 16), false);
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
