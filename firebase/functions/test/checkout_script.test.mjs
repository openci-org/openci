import assert from "node:assert/strict";
import { test } from "node:test";
import { checkoutScript } from "../../lib/functions/executor/model.js";
import { checkoutFixture } from "./helpers/checkout.mjs";

test("a push build checks out its queued commit after the branch advances", (t) => {
  const repo = checkoutFixture(t);
  const commitSha = repo.commit("version.txt", "queued");
  repo.commit("version.txt", "newer");
  const job = { commitSha, pullRequestNumber: null };
  const result = repo.exec(checkoutScript(job, repo.source, "test-token"));
  assert.equal(result.status, 0, result.stderr);
  assert.equal(repo.git("-C", repo.checkoutDir, "rev-parse", "HEAD"), commitSha);
});
