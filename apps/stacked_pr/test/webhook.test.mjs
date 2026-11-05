import { test } from "node:test";
import assert from "node:assert/strict";
import { createHmac } from "node:crypto";
import { createWebhookHandler, compactPayload } from "../lib/webhook.js";
import { secret } from "./support/fixtures.mjs";

function invoke(
  handler,
  body,
  {
    signed = true,
    id = "delivery",
    method = "POST",
    event = "pull_request",
    signature,
    rawBody,
    url = "/",
    contentType = "application/json",
    parsedBody,
  } = {},
) {
  const bytes = rawBody ?? Buffer.from(body);
  const headers = {
    "content-type": contentType,
    "x-github-event": event,
    "x-github-delivery": id,
    ...(signed
      ? {
          "x-hub-signature-256":
            signature ?? `sha256=${createHmac("sha256", secret).update(bytes).digest("hex")}`,
        }
      : {}),
  };
  const result = { status: 0, body: undefined, headers: {} };
  const response = {
    set(name, value) {
      result.headers[name] = value;
      return this;
    },
    writeHead(status, values) {
      result.status = status;
      Object.assign(result.headers, values);
      return this;
    },
    end(value) {
      result.body = value;
    },
    sendStatus(status) {
      result.status = status;
    },
  };
  let decoded;
  try {
    decoded = JSON.parse(body);
  } catch {
    decoded = {}; // Malformed JSON normally fails in Functions Framework before our handler.
  }
  return handler(
    { method, url, rawBody: bytes, body: parsedBody ?? decoded, headers },
    response,
  ).then(() => result);
}
const payload = JSON.stringify({
  action: "opened",
  installation: { id: 1 },
  pull_request: { number: 2, body: "こんにちは private text" },
});
test("signature authenticates raw UTF-8 bytes and rejects malformed or changed signatures", async () => {
  assert.throws(() => createWebhookHandler(async () => true, "short"), /at least 32/);
  let calls = 0;
  const handler = createWebhookHandler(async () => {
    calls++;
    return true;
  }, secret);
  assert.equal((await invoke(handler, payload)).status, 200);
  // Firebase has already parsed JSON; verification must still use the original bytes.
  assert.equal(
    (await invoke(handler, `  ${payload}\n`, { parsedBody: { different: true } })).status,
    200,
  );
  const signature = `sha256=${createHmac("sha256", secret).update("{}").digest("hex")}`;
  for (const invalid of ["", "sha256=ff", "sha1=abc", signature])
    assert.equal((await invoke(handler, payload, { signature: invalid })).status, 400);
  assert.equal((await invoke(handler, payload, { signed: false })).status, 400);
  assert.equal(calls, 2);
  assert.equal((await invoke(handler, "", { rawBody: Buffer.from([0xff]) })).status, 400);
});
test("SDK event subscriptions ignore unrelated notifications and bot updates", async () => {
  const jobs = [];
  const handler = createWebhookHandler(async (job) => {
    jobs.push(job);
    return true;
  }, secret);
  for (const [event, body] of [
    ["check_run", { action: "completed" }],
    ["push", { ref: "refs/tags/release" }],
    ["issue_comment", { action: "created", comment: { body: "/stack sync" } }],
    ["pull_request", { action: "labeled" }],
    ["check_run", { action: "requested_action", requested_action: { identifier: "other" } }],
  ]) {
    assert.equal((await invoke(handler, JSON.stringify(body), { event })).status, 200);
  }
  assert.equal(jobs.length, 0);
  const body = JSON.stringify({ action: "synchronize", installation: { id: 1 } });
  assert.equal((await invoke(handler, body)).status, 200);
  assert.equal(jobs.length, 1);
  assert.equal(jobs[0].event, "pull_request");
});
test("compaction keeps the old base and strips PR bodies and commit lists", () => {
  const compact = compactPayload({
    changes: {
      body: { from: "private body" },
      base: { ref: { from: "parent" }, sha: { from: "a".repeat(40) } },
    },
    pull_request: { number: 3, body: "private body" },
    commits: ["private commit"],
  });
  assert.equal(compact.previous_base, "parent");
  assert.deepEqual(compact.pull_request, { number: 3 });
  assert.doesNotMatch(JSON.stringify(compact), /private/);
});
test("signed merge and cancel buttons retain the selected Check head and actor", async () => {
  const jobs = [];
  const handler = createWebhookHandler(async (job) => {
    jobs.push(job);
    return true;
  }, secret);
  for (const identifier of ["merge-stack", "squash-stack", "cancel-merge"]) {
    const body = JSON.stringify({
      action: "requested_action",
      installation: { id: 10 },
      repository: { id: 20, full_name: "org/repo" },
      sender: { login: "maintainer", type: "User" },
      requested_action: { identifier },
      check_run: {
        app: { id: 7 },
        external_id: "stacked-pr:20:3",
        head_sha: "c".repeat(40),
        output: { summary: "private data" },
      },
    });
    assert.equal((await invoke(handler, body, { event: "check_run", signed: false })).status, 400);
    assert.equal((await invoke(handler, body, { event: "check_run" })).status, 200);
    const { payload } = jobs.at(-1);
    assert.deepEqual(payload.check_run, {
      app: { id: 7 },
      external_id: "stacked-pr:20:3",
      head_sha: "c".repeat(40),
    });
    assert.equal(payload.requested_action.identifier, identifier);
    assert.equal(payload.sender.login, "maintainer");
  }
  assert.equal(jobs.length, 3);
});

test("signed self-generated writes are ignored without dropping other actors or lifecycle events", async () => {
  const jobs = [];
  const handler = createWebhookHandler(
    async (job) => {
      jobs.push(job);
      return true;
    },
    secret,
    undefined,
    "stacked-pr[bot]",
  );
  const body = {
    installation: { id: 1 },
    repository: { id: 20, full_name: "org/repo" },
    pull_request: { number: 2 },
    ref: "refs/heads/child",
    sender: { login: "stacked-pr[bot]", type: "Bot" },
  };
  for (const [event, action] of [
    ["push", undefined],
    ["pull_request", "synchronize"],
    ["pull_request", "edited"],
  ]) {
    const payload = JSON.stringify({ ...body, action });
    assert.equal((await invoke(handler, payload, { event })).status, 200);
    assert.equal((await invoke(handler, payload, { event, signed: false })).status, 400);
  }
  assert.equal(jobs.length, 0);
  for (const sender of [
    { login: "another[bot]", type: "Bot" },
    { login: "stacked-pr[bot]", type: "User" },
    { login: "developer", type: "User" },
  ])
    await invoke(handler, JSON.stringify({ ...body, action: "synchronize", sender }));
  for (const action of ["opened", "closed", "reopened"])
    await invoke(handler, JSON.stringify({ ...body, action }));
  assert.equal(jobs.length, 6);
});
test("only newly created sync commands on PRs enqueue work", async () => {
  const jobs = [];
  const handler = createWebhookHandler(async (job) => {
    jobs.push(job);
    return true;
  }, secret);
  const body = { action: "created", issue: { pull_request: {} }, installation: { id: 1 } };
  for (const command of [
    "/stack sync",
    "  /stack sync\n",
    "/stack rebase",
    "/stack retry",
    "/stack sync extra",
    "hello",
  ]) {
    await invoke(handler, JSON.stringify({ ...body, comment: { body: command } }), {
      event: "issue_comment",
    });
  }
  await invoke(
    handler,
    JSON.stringify({ ...body, action: "edited", comment: { body: "/stack sync" } }),
    { event: "issue_comment" },
  );
  assert.deepEqual(
    jobs.map((job) => job.payload.comment.body),
    ["/stack sync", "  /stack sync\n"],
  );
});
test("deliveries await enqueue and return safe duplicate, failure and malformed-input responses", async (t) => {
  t.mock.timers.enable({ apis: ["setTimeout"] });
  const jobs = new Map();
  let fail = false,
    release;
  const handler = createWebhookHandler(
    async (job) => {
      if (fail) throw new Error("private queue credentials");
      if (release) await release;
      const fresh = !jobs.has(job.id);
      jobs.set(job.id, job);
      return fresh;
    },
    secret,
    512,
  );
  let finish;
  release = new Promise((resolve) => {
    finish = resolve;
  });
  let replied = false;
  const pending = invoke(handler, payload).then((r) => {
    replied = true;
    return r;
  });
  await new Promise((resolve) => setImmediate(resolve));
  assert.equal(replied, false);
  // Octokit's default response timeout must not acknowledge an unregistered task.
  t.mock.timers.tick(9_001);
  await new Promise((resolve) => setImmediate(resolve));
  assert.equal(replied, false);
  finish();
  assert.equal((await pending).status, 200);
  release = undefined;
  assert.equal((await invoke(handler, payload)).status, 200);
  assert.equal(jobs.size, 1);
  assert.deepEqual(jobs.get("delivery").payload.pull_request, { number: 2 });
  for (const bad of ["{", "[]", "null", "true", "1", '"text"'])
    assert.equal((await invoke(handler, bad)).status, 400);
  assert.equal((await invoke(handler, "x".repeat(513))).status, 413);
  assert.equal((await invoke(handler, payload, { id: "!bad" })).status, 400);
  assert.equal((await invoke(handler, '{"action":"opened"}')).status, 400);
  assert.equal((await invoke(handler, "", { method: "GET" })).status, 404);
  assert.equal((await invoke(handler, payload, { url: "/unexpected" })).status, 404);
  assert.equal((await invoke(handler, payload, { contentType: "text/plain" })).status, 415);
  assert.equal((await invoke(handler, "{}", { event: "ping" })).status, 200);
  fail = true;
  const result = await invoke(handler, payload, { id: "retry" });
  assert.equal(result.status, 503);
  assert.doesNotMatch(JSON.stringify(result), /private/);
  assert.equal(jobs.has("retry"), false);
});
