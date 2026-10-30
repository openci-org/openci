import assert from "node:assert/strict";
import { createHmac } from "node:crypto";
import { setImmediate } from "node:timers/promises";
import { test } from "node:test";
import { receiveGitHubWebhook } from "../../lib/functions/github_webhook.js";
import { ConflictingWebhookDeliveryError } from "../../lib/functions/webhook_queue.js";

const secret = "local-webhook-test-secret";

function request(payload = '{"ref":"refs/heads/main"}', overrides = {}) {
  const rawBody = Buffer.isBuffer(payload) ? payload : Buffer.from(payload);
  const headers = {
    signature: `sha256=${createHmac("sha256", secret).update(rawBody).digest("hex")}`,
    deliveryId: "test-delivery",
    eventType: "push",
    ...overrides,
  };
  let body;
  try {
    body = JSON.parse(rawBody.toString("utf8"));
  } catch {
    // Firebase rejects malformed JSON before invoking the handler.
  }
  return {
    method: "POST",
    rawBody,
    body,
    get: (name) =>
      ({
        "x-github-delivery": headers.deliveryId,
        "x-github-event": headers.eventType,
        "x-hub-signature-256": headers.signature,
      })[name],
    ...overrides,
  };
}

function dependencies(overrides = {}) {
  const deliveries = [];
  const errors = [];
  return {
    deliveries,
    errors,
    options: {
      secret,
      enqueue: async (delivery) => {
        deliveries.push(delivery);
        return "created";
      },
      reportError: (context) => errors.push(context),
      ...overrides,
    },
  };
}

test("verifies signatures even for ignored events", async () => {
  const d = dependencies();
  const signed = request('{"zen":"Keep it simple"}', { eventType: "ping" });
  assert.equal(await receiveGitHubWebhook(signed, d.options), 200);
  assert.equal(
    await receiveGitHubWebhook({ ...signed, rawBody: Buffer.from('{"tampered":true}') }, d.options),
    400,
  );
  assert.deepEqual(d.deliveries, []);
});

test("only POST can enqueue a delivery", async () => {
  const d = dependencies();
  for (const method of ["GET", "PUT", "DELETE", "OPTIONS"]) {
    assert.equal(await receiveGitHubWebhook(request("{}", { method }), d.options), 405);
  }
  assert.deepEqual(d.deliveries, []);
});

test("rejects missing, malformed, and incorrect signatures before persistence", async () => {
  const d = dependencies();
  for (const signature of [
    undefined,
    "",
    "sha1=abc",
    "sha256=",
    `sha256=${"0".repeat(64)}`,
    `sha256=${"z".repeat(64)}`,
    `${request().get("x-hub-signature-256")}00`,
  ]) {
    assert.equal(await receiveGitHubWebhook(request("{}", { signature }), d.options), 400);
  }
  assert.equal(
    await receiveGitHubWebhook(
      { ...request(), rawBody: Buffer.from('{"tampered":true}') },
      d.options,
    ),
    400,
  );
  assert.equal(await receiveGitHubWebhook({ ...request(), rawBody: undefined }, d.options), 400);
  assert.deepEqual(d.deliveries, []);
});

test("fails closed when the webhook secret is not configured", async () => {
  const d = dependencies({ secret: "" });
  assert.equal(await receiveGitHubWebhook(request(), d.options), 503);
  assert.deepEqual(d.deliveries, []);
  assert.deepEqual(d.errors, [{ reason: "webhook_secret_missing" }]);
});

test("rejects missing event headers and missing or malformed delivery IDs", async () => {
  const d = dependencies();
  for (const deliveryId of [undefined, "", " ", "a\nb", "x".repeat(256)]) {
    assert.equal(await receiveGitHubWebhook(request("{}", { deliveryId }), d.options), 400);
  }
  for (const eventType of [undefined, ""]) {
    assert.equal(await receiveGitHubWebhook(request("{}", { eventType }), d.options), 400);
  }
  assert.deepEqual(d.deliveries, []);
});

test("acknowledges unsupported events without enqueuing", async () => {
  const d = dependencies();
  for (const eventType of ["ping", "issues", "installation"]) {
    assert.equal(await receiveGitHubWebhook(request("{}", { eventType }), d.options), 200);
  }
  assert.deepEqual(d.deliveries, []);
});

test("stores the original signed UTF-8 body, including whitespace", async () => {
  const d = dependencies();
  const body = '{\n "ref": "refs/heads/main", "message": "ビルド 🚀"\n}\n';
  assert.equal(await receiveGitHubWebhook(request(body), d.options), 200);
  assert.deepEqual(d.deliveries, [
    { deliveryId: "test-delivery", eventType: "push", payload: body },
  ]);
});

test("rejects malformed JSON objects and invalid UTF-8 for supported events", async () => {
  const d = dependencies();
  for (const eventType of ["push", "pull_request"]) {
    for (const body of ["", "{", "[]", "null", "42", '"text"', "\uFEFF{}", Buffer.from([0xff])]) {
      assert.equal(await receiveGitHubWebhook(request(body, { eventType }), d.options), 400);
    }
    // Exercise raw-body validation even if the framework supplied a parsed body.
    for (const body of ["", "{", "\uFEFF{}", Buffer.from([0xff])]) {
      assert.equal(
        await receiveGitHubWebhook(request(body, { eventType, body: {} }), d.options),
        400,
      );
    }
  }
  assert.deepEqual(d.deliveries, []);
});

test("accepts only the existing pull request trigger actions", async () => {
  const d = dependencies();
  for (const action of ["opened", "synchronize", "reopened", "closed", "edited", null, undefined]) {
    assert.equal(
      await receiveGitHubWebhook(
        request(JSON.stringify({ action, number: 42 }), { eventType: "pull_request" }),
        d.options,
      ),
      200,
    );
  }
  assert.deepEqual(
    d.deliveries.map((delivery) => JSON.parse(delivery.payload).action),
    ["opened", "synchronize", "reopened"],
  );
  for (const action of [42, {}, [], ["opened"]]) {
    assert.equal(
      await receiveGitHubWebhook(
        request(JSON.stringify({ action }), { eventType: "pull_request" }),
        d.options,
      ),
      400,
    );
  }
});

test("waits for durable persistence before acknowledging a delivery", async () => {
  const saved = Promise.withResolvers();
  const entered = Promise.withResolvers();
  let acknowledged = false;
  const d = dependencies({
    enqueue: () => {
      entered.resolve();
      return saved.promise;
    },
  });
  const response = receiveGitHubWebhook(request(), d.options).then((status) => {
    acknowledged = true;
    return status;
  });
  await entered.promise;
  await setImmediate();
  assert.equal(acknowledged, false);
  saved.resolve("created");
  assert.equal(await response, 200);
});

test("concurrent requests keep their raw payloads and delivery IDs separate", async () => {
  const d = dependencies();
  const bodies = ['{"ref":"refs/heads/first"}', '{"ref":"refs/heads/second"}'];
  assert.deepEqual(
    await Promise.all(
      bodies.map((body, i) =>
        receiveGitHubWebhook(request(body, { deliveryId: `delivery-${i}` }), d.options),
      ),
    ),
    [200, 200],
  );
  assert.deepEqual(
    d.deliveries.sort((a, b) => a.deliveryId.localeCompare(b.deliveryId)),
    bodies.map((payload, i) => ({ deliveryId: `delivery-${i}`, eventType: "push", payload })),
  );
});

test("acknowledges a confirmed duplicate", async () => {
  const d = dependencies({ enqueue: async () => "duplicate" });
  assert.equal(await receiveGitHubWebhook(request(), d.options), 200);
});

test("rejects a conflicting reuse of a delivery ID", async () => {
  const d = dependencies({
    enqueue: async () => {
      throw new ConflictingWebhookDeliveryError();
    },
  });
  assert.equal(await receiveGitHubWebhook(request(), d.options), 409);
});

test("persistence failures return 503 without exposing payloads, secrets, or SDK errors", async () => {
  const d = dependencies({
    enqueue: async () => {
      // An SDK error's status must not be mistaken for an invalid webhook.
      throw Object.assign(new Error(`private-payload ${secret}`), { status: 400 });
    },
  });
  const status = await receiveGitHubWebhook(request(), d.options);
  assert.equal(status, 503);
  assert.deepEqual(d.errors, [
    {
      reason: "webhook_persistence_failed",
      deliveryId: "test-delivery",
      eventType: "push",
    },
  ]);
  assert.doesNotMatch(JSON.stringify(d.errors), /private-payload|local-webhook-test-secret/);
});
