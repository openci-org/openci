import assert from "node:assert/strict";
import { test } from "node:test";
import {
  BuildQueueEnqueueError,
  buildQueueFailureReason,
} from "../../lib/functions/build_queue_error.js";
import { dispatchFailureReason } from "../../lib/functions/build_dispatch.js";

test("queue diagnostics keep allowlisted reasons without retaining SDK secrets", () => {
  const original = Object.assign(new Error("private payload"), {
    code: "functions/permission-denied",
    request: { authorization: "private token" },
    response: { body: "private source" },
    cause: new Error("private cause"),
  });
  const wrapped = new BuildQueueEnqueueError(original);
  assert.equal(wrapped.message, "Build dispatch could not be queued");
  assert.equal(buildQueueFailureReason(wrapped), "functions/permission-denied");
  assert.equal(wrapped.cause, undefined);
  assert.equal(JSON.stringify(wrapped), '{"reason":"functions/permission-denied"}');
  assert.doesNotMatch(wrapped.stack, /private/);
  assert.equal(dispatchFailureReason(wrapped), "recovery_enqueue_failed");

  for (const [failure, reason] of [
    [{ code: "data-connect/query-error" }, "data-connect/query-error"],
    [{ code: "functions/failed-precondition" }, "functions/failed-precondition"],
    [{ code: "app/network-timeout" }, "app/network-timeout"],
    [{ code: "ECONNRESET" }, "ECONNRESET"],
    [{ status: 403, response: { body: "private" } }, "http_403"],
    [{ status: 429 }, "http_429"],
    [new Error("Check publication lease lost"), "check_lease_lost"],
    [new Error("GitHub connection is inactive"), "github_connection_inactive"],
    [new DOMException("private URL", "TimeoutError"), "request_timeout"],
    [new DOMException("private URL", "AbortError"), "request_aborted"],
  ]) {
    assert.equal(buildQueueFailureReason(failure), reason);
    assert.equal(buildQueueFailureReason(new BuildQueueEnqueueError(failure)), reason);
  }
});

test("unknown queue failures cannot inject arbitrary text into diagnostics", () => {
  for (const failure of [
    null,
    "private value",
    new Error("private payload"),
    new Error("constructor"),
    new Error("Check publication lease lost: private details"),
    { code: "functions/private-token", status: "403" },
    { status: 123456 },
    { message: "Check publication lease lost", cause: { code: "private" } },
  ]) {
    assert.equal(buildQueueFailureReason(failure), "unknown");
    assert.equal(buildQueueFailureReason(new BuildQueueEnqueueError(failure)), "unknown");
  }
});
