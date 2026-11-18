import assert from "node:assert/strict";
import { createRequire } from "node:module";
import { after, test } from "node:test";
import { deleteApp, getApps, initializeApp } from "firebase-admin/app";
import { SecretManagerServiceClient } from "@google-cloud/secret-manager";
import { connectorConfig } from "@openci/secrets-admin";
import { isolatedConnector } from "../../lib/functions/executor/store.js";
import { cleanSecretVersions } from "../../lib/functions/secret_functions.js";

const app = initializeApp({ projectId: "demo-openci" });
const dc = isolatedConnector(connectorConfig, app);
const logger = createRequire(import.meta.url)("firebase-functions/logger");
process.env.SECRET_MANAGER_PROJECT = "demo-openci";
after(() => Promise.all(getApps().map(deleteApp)));

async function invoke() {
  let status;
  await cleanSecretVersions(
    { headers: {}, header: () => undefined },
    {
      status(value) {
        status = value;
        return this;
      },
      send() {},
    },
  );
  return status;
}

test("cleanup retries cold-start failures promptly and finishes retries before the next hour", () => {
  const { scheduleTrigger, timeoutSeconds } = cleanSecretVersions.__endpoint;
  assert.equal(scheduleTrigger.schedule, "every 60 minutes");
  const retry = scheduleTrigger.retryConfig;
  assert.ok(retry.retryCount >= 1 && retry.retryCount <= 5);
  // A duration limit can extend retries beyond retryCount in Cloud Scheduler.
  assert.equal(retry.maxRetrySeconds, 0);
  assert.ok(retry.minBackoffSeconds >= 10 && retry.minBackoffSeconds <= 60);
  assert.ok(retry.maxBackoffSeconds >= retry.minBackoffSeconds);
  assert.ok(retry.maxDoublings >= 1);
  assert.ok(
    (retry.retryCount + 1) * timeoutSeconds + retry.retryCount * retry.maxBackoffSeconds < 3600,
  );
});

test("an unavailable cleanup query returns 500 so Scheduler can retry it successfully", async (t) => {
  t.mock.method(logger, "error", () => {});
  let attempts = 0;
  t.mock.method(dc, "executeQuery", async (name) => {
    assert.equal(name, "GetDueSecretVersions");
    if (++attempts === 1) throw new Error("Storage temporarily unavailable");
    return { data: { versions: [] } };
  });
  assert.equal(await invoke(), 500);
  assert.equal(await invoke(), 200);
  assert.equal(attempts, 2);
});

test("retry after a lost cleanup acknowledgement preserves live secrets and avoids repeated destruction", async (t) => {
  t.mock.method(logger, "error", () => {});
  const expired = "projects/demo-openci/secrets/openci-expired/versions/1";
  const live = "projects/demo-openci/secrets/openci-live/versions/1";
  const due = new Set([expired, live]);
  const destroyed = [];
  const deferred = [];
  let storageUnavailable = true;
  t.mock.method(dc, "executeQuery", async (name, variables) => {
    if (name === "GetDueSecretVersions")
      return { data: { versions: [...due].map((path) => ({ path })) } };
    assert.equal(name, "GetSecretVersionReferences");
    return { data: { references: variables.path === live ? [{ name: "TOKEN" }] : [] } };
  });
  t.mock.method(dc, "executeMutation", async (name, { path }) => {
    if (storageUnavailable) throw new Error("Storage temporarily unavailable");
    if (name === "QueueSecretVersionCleanup") deferred.push(path);
    else assert.equal(name, "CompleteSecretVersionCleanup");
    due.delete(path);
    return { data: {} };
  });
  t.mock.method(SecretManagerServiceClient.prototype, "getSecret", async () => [
    { labels: { "openci-managed": "true" } },
  ]);
  t.mock.method(SecretManagerServiceClient.prototype, "getSecretVersion", async ({ name }) => [
    {
      state: "ENABLED",
      ...(destroyed.includes(name) ? { scheduledDestroyTime: { seconds: 1 } } : {}),
    },
  ]);
  t.mock.method(SecretManagerServiceClient.prototype, "destroySecretVersion", async ({ name }) => {
    destroyed.push(name);
    return [{}];
  });

  assert.equal(await invoke(), 500);
  assert.deepEqual(destroyed, [expired]);
  assert.equal(due.size, 2);
  storageUnavailable = false;
  assert.equal(await invoke(), 200);
  assert.deepEqual(destroyed, [expired]);
  assert.deepEqual(deferred, [live]);
  assert.equal(due.size, 0);
  assert.equal(await invoke(), 200);
  assert.deepEqual(destroyed, [expired]);
});
