import assert from "node:assert/strict";
import { createRequire } from "node:module";
import { after, beforeEach, test } from "node:test";
import { notifyAuthUserCreated } from "../../lib/functions/auth_signup_functions.js";

const logger = createRequire(import.meta.url)("firebase-functions/logger");
const webhookUrl = "https://hooks.slack.com/services/test-workspace/test-channel/test-secret";
const originalSecret = process.env.SLACK_SIGNUP_WEBHOOK_URL;
const originalProject = process.env.GCLOUD_PROJECT;
after(() => {
  if (originalSecret === undefined) delete process.env.SLACK_SIGNUP_WEBHOOK_URL;
  else process.env.SLACK_SIGNUP_WEBHOOK_URL = originalSecret;
  if (originalProject === undefined) delete process.env.GCLOUD_PROJECT;
  else process.env.GCLOUD_PROJECT = originalProject;
});

beforeEach((t) => {
  process.env.SLACK_SIGNUP_WEBHOOK_URL = webhookUrl;
  process.env.GCLOUD_PROJECT = "demo-openci";
  t.mock.method(logger, "error", () => {});
  t.mock.method(logger, "info", () => {});
  t.mock.method(globalThis, "fetch", async () => new Response("ok"));
});

const user = (overrides = {}) => ({
  uid: "new-user-id",
  email: "new-user@example.com",
  displayName: "New User",
  metadata: { creationTime: "Mon, 16 Nov 2026 00:00:00 GMT" },
  providerData: [{ providerId: "password" }],
  ...overrides,
});
const context = (overrides = {}) => ({
  eventId: "signup-event",
  timestamp: new Date().toISOString(),
  ...overrides,
});
const request = () => globalThis.fetch.mock.calls.at(-1).arguments;
const payload = () => JSON.parse(request()[1].body);

test("deployment subscribes to user creation with the secret and retry enabled", () => {
  const endpoint = notifyAuthUserCreated.__endpoint;
  assert.equal(endpoint.platform, "gcfv1");
  assert.equal(endpoint.eventTrigger.eventType, "providers/firebase.auth/eventTypes/user.create");
  assert.equal(endpoint.eventTrigger.retry, true);
  assert.deepEqual(endpoint.secretEnvironmentVariables, [{ key: "SLACK_SIGNUP_WEBHOOK_URL" }]);
});

test("sends the account snapshot and acknowledges only Slack delivery", async () => {
  await notifyAuthUserCreated.run(
    user({
      passwordHash: "private-hash",
      customClaims: { private: "private-claim" },
      providerData: [
        { providerId: "google.com" },
        { providerId: "password" },
        { providerId: "google.com" },
      ],
    }),
    context(),
  );
  assert.equal(globalThis.fetch.mock.callCount(), 1);
  assert.equal(request()[0].toString(), webhookUrl);
  assert.equal(request()[1].method, "POST");
  assert.deepEqual(request()[1].headers, { "Content-Type": "application/json" });
  assert.equal(request()[1].redirect, "error");
  assert.ok(request()[1].signal instanceof AbortSignal);
  assert.deepEqual(
    payload().blocks[1].fields.map((f) => f.text),
    [
      "Name\nNew User",
      "Email\nnew-user@example.com",
      "Sign-in providers\ngoogle.com, password",
      "Created (UTC)\nMon, 16 Nov 2026 00:00:00 GMT",
      "Firebase UID\nnew-user-id",
    ],
  );
  assert.doesNotMatch(request()[1].body, /private-hash|private-claim/);
  assert.deepEqual(logger.info.mock.calls[0].arguments, [
    "Signup notification delivered",
    { eventId: "signup-event" },
  ]);
});

test("accounts without a name, email, or provider still generate a notification", async () => {
  await notifyAuthUserCreated.run(
    user({ displayName: undefined, email: undefined, providerData: [] }),
    context(),
  );
  assert.deepEqual(
    payload()
      .blocks[1].fields.slice(0, 3)
      .map((f) => f.text),
    ["Name\nNot provided", "Email\nNot provided", "Sign-in providers\nNot provided"],
  );
});

test("user input cannot become Slack mentions and long Unicode names fit field limits", async () => {
  const name = "<!channel> <@U123> <https://example.com|click> & *text*";
  await notifyAuthUserCreated.run(user({ displayName: name }), context());
  assert.equal(payload().text, "New OpenCI signup");
  assert.deepEqual(payload().blocks[1].fields[0], {
    type: "plain_text",
    text: `Name\n${name}`,
    emoji: false,
  });
  assert.equal(payload().unfurl_links, false);
  assert.equal(payload().unfurl_media, false);

  await notifyAuthUserCreated.run(user({ displayName: "🧑".repeat(2_000) }), context());
  const text = payload().blocks[1].fields[0].text;
  assert.ok(text.length < 2_000);
  assert.ok(text.isWellFormed());
});

test("invalid webhook configuration fails without sending account data", async () => {
  for (const invalid of [
    "",
    "not-a-url",
    "https://example.com/services/a/b/c",
    "http://hooks.slack.com/services/a/b/c",
    "https://hooks.slack.com/services/a/b",
    "https://user:password@hooks.slack.com/services/a/b/c",
    "https://hooks.slack.com/services/a/b/c?query=secret",
    "https://hooks.slack.com/services/a/b/c#fragment",
  ]) {
    process.env.SLACK_SIGNUP_WEBHOOK_URL = invalid;
    await assert.rejects(notifyAuthUserCreated.run(user(), context()), {
      message: "Signup notification failed; retry required",
    });
  }
  assert.equal(globalThis.fetch.mock.callCount(), 0);
  assert.equal(logger.info.mock.callCount(), 0);
});

for (const status of [302, 400, 429, 500]) {
  test(`HTTP ${status} is retried without exposing Slack response details`, async (t) => {
    t.mock.method(
      globalThis,
      "fetch",
      async () => new Response(`${webhookUrl} new-user@example.com`, { status }),
    );
    await assert.rejects(notifyAuthUserCreated.run(user(), context()), {
      message: "Signup notification failed; retry required",
    });
    assert.deepEqual(logger.error.mock.calls[0].arguments, [
      "Signup notification failed",
      { eventId: "signup-event", httpStatus: status },
    ]);
    assert.equal(logger.info.mock.callCount(), 0);
  });
}

test("HTTP success without Slack's acknowledgement is retried", async (t) => {
  t.mock.method(globalThis, "fetch", async () => new Response("invalid_payload"));
  await assert.rejects(notifyAuthUserCreated.run(user(), context()), /retry required/);
  assert.equal(logger.info.mock.callCount(), 0);
});

test("a failed request can be redelivered successfully without logging its secret", async (t) => {
  t.mock.method(globalThis, "fetch", async () => {
    throw new Error(`Cannot reach ${webhookUrl}`);
  });
  const event = context();
  await assert.rejects(notifyAuthUserCreated.run(user(), event), {
    message: "Signup notification failed; retry required",
  });
  assert.deepEqual(logger.error.mock.calls[0].arguments, [
    "Signup notification failed",
    { eventId: "signup-event", httpStatus: undefined },
  ]);
  t.mock.method(globalThis, "fetch", async () => new Response("ok\n"));
  await notifyAuthUserCreated.run(user(), event);
  assert.equal(logger.info.mock.callCount(), 1);
});

test("a hung request times out and retains the event for retry", async (t) => {
  const controller = new AbortController();
  t.mock.method(AbortSignal, "timeout", (ms) => {
    assert.equal(ms, 10_000);
    return controller.signal;
  });
  t.mock.method(
    globalThis,
    "fetch",
    async (_url, { signal }) =>
      new Promise((_resolve, reject) => {
        signal.addEventListener("abort", () => reject(signal.reason), { once: true });
      }),
  );
  const pending = notifyAuthUserCreated.run(user(), context());
  const rejected = assert.rejects(pending, /retry required/);
  controller.abort(new Error("private timeout detail"));
  await rejected;
  assert.equal(logger.info.mock.callCount(), 0);
});

test("events expire after 24 hours without another Slack request", async (t) => {
  const now = Date.parse("2026-11-16T12:00:00Z");
  t.mock.method(Date, "now", () => now);
  await notifyAuthUserCreated.run(user(), context({ timestamp: "2026-11-15T12:00:00Z" }));
  assert.equal(globalThis.fetch.mock.callCount(), 0);
  assert.deepEqual(logger.error.mock.calls[0].arguments, [
    "Signup notification expired without confirmed delivery",
    { eventId: "signup-event" },
  ]);
  await notifyAuthUserCreated.run(user(), context({ timestamp: "2026-11-15T12:00:00.001Z" }));
  assert.equal(globalThis.fetch.mock.callCount(), 1);
});
