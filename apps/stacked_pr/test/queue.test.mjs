import { test } from "node:test";
import assert from "node:assert/strict";
import { getApps, deleteApp } from "firebase-admin/app";
import { TaskQueue } from "../lib/queue.js";
import { processTask } from "../lib/runtime.js";
import { RetryException } from "../lib/models.js";
import { ApiException } from "../lib/github.js";
import { GitException } from "../lib/git.js";

const job = { id: "delivery", event: "pull_request", payload: { installation: { id: 1 } } };
test("task IDs are stable, namespaced and bounded; duplicate registration succeeds", async () => {
  const requests = [],
    queue = new TaskQueue(
      {
        enqueue: async (data, options) => {
          requests.push({ data, options });
          if (requests.length === 2)
            throw Object.assign(new Error("duplicate"), { code: "functions/task-already-exists" });
        },
      },
      "https://github.example.com:7",
    );
  assert.equal(await queue.enqueue(job), true);
  assert.equal(await queue.enqueue(job), false);
  assert.deepEqual(requests[0], requests[1]);
  assert.match(requests[0].options.id, /^[a-f0-9]{64}$/);
  assert.equal(requests[0].options.dispatchDeadlineSeconds, 600);
  assert.deepEqual(requests[0].data, job);
  const second = new TaskQueue(
    { enqueue: async (_data, options) => assert.notEqual(options.id, requests[0].options.id) },
    "https://github.example.com:8",
  );
  await second.enqueue(job);
});
test("failed or timed-out enqueue cannot acknowledge accepted delivery or expose credentials", async () => {
  const queue = new TaskQueue(
    {
      enqueue: async () => {
        throw new Error("private credentials");
      },
    },
    "app",
  );
  await assert.rejects(queue.enqueue(job), (error) => {
    assert.ok(error instanceof RetryException);
    assert.doesNotMatch(String(error), /private/);
    return true;
  });
  const stalled = new TaskQueue({ enqueue: () => new Promise(() => {}) }, "app");
  await assert.rejects(stalled.enqueue(job, 10), RetryException);
  await assert.rejects(
    queue.enqueue({ ...job, payload: { body: "x".repeat(128 * 1024) } }),
    /Task too large/,
  );
});
test("cutover accepts tasks now but schedules them after old tokens expire", async () => {
  for (const delay of [65 * 60_000, -60_000]) {
    const notBefore = new Date(Date.now() + delay);
    const queue = new TaskQueue(
      {
        enqueue: async (_data, options) =>
          assert.deepEqual(options.scheduleTime, delay > 0 ? notBefore : undefined),
      },
      "app",
      notBefore,
    );
    assert.equal(await queue.enqueue(job), true);
  }
  assert.throws(() => new TaskQueue({}, "app", new Date("bad")), /Invalid/);
});
test("Admin SDK uses the configured task identity for OIDC without changing the ADC enqueuer", async (t) => {
  const env = {
    GCLOUD_PROJECT: "demo-stacked-pr",
    STACKED_PR_TASK_SERVICE_ACCOUNT: "stacked-pr-tasks@demo-stacked-pr.iam.gserviceaccount.com",
    GITHUB_URL: "https://github.com",
    GITHUB_APP_ID: "7",
  };
  const queue = TaskQueue.fromEnvironment(env),
    app = getApps().find((a) => a.name === "stacked-pr-queue");
  t.after(() => deleteApp(app));
  assert.equal(app.options.projectId, env.GCLOUD_PROJECT);
  assert.equal(app.options.serviceAccountId, env.STACKED_PR_TASK_SERVICE_ACCOUNT);
  assert.equal(queue.namespace, "https://github.com:7");
});

test("deferred work honors both the future coalescing window and cutover time", async () => {
  const scheduled = new Date(Date.now() + 60_000);
  for (const cutover of [undefined, new Date(Date.now() + 120_000)]) {
    let received;
    const queue = new TaskQueue(
      {
        enqueue: async (_data, options) => {
          received = options;
        },
      },
      "app",
      cutover,
    );
    await queue.enqueue(job, 8000, scheduled);
    assert.deepEqual(received.scheduleTime, cutover ?? scheduled);
  }
});
test("worker awaits completion, requests retry on failures, and rejects malformed jobs", async () => {
  let calls = 0;
  await processTask(job, async (received) => {
    assert.deepEqual(received, job);
    calls++;
  });
  assert.equal(calls, 1);
  await assert.rejects(
    processTask(job, async () => {
      throw new Error("secret");
    }),
    (error) => {
      assert.equal(error.code, "unavailable");
      assert.doesNotMatch(String(error), /secret/);
      return true;
    },
  );
  for (const value of [
    {},
    null,
    { ...job, id: "!bad" },
    { ...job, payload: [] },
    { ...job, payload: { body: "x".repeat(128 * 1024) } },
  ]) {
    await assert.rejects(
      processTask(value, async () => {
        calls++;
      }),
      (error) => error.code === "invalid-argument",
    );
  }
  assert.equal(calls, 1);
});
test("worker diagnostics identify safe failures without logging transport secrets", async (t) => {
  const logs = [];
  t.mock.method(console, "error", (line) => logs.push(JSON.parse(line)));
  for (const error of [
    new GitException("push", "128"),
    new ApiException("POST", "/private-repository?token=secret", 403),
    new RetryException("PR changed during restack"),
    Object.assign(new Error("secret"), { request: { headers: { authorization: "secret" } } }),
  ]) {
    await assert.rejects(
      processTask(job, async () => {
        throw error;
      }),
      (failure) => failure.code === "unavailable",
    );
  }
  assert.deepEqual(
    logs.map(({ event, delivery, ...failure }) => {
      assert.equal(event, "stack_task_failed");
      assert.equal(delivery, job.id);
      return failure;
    }),
    [
      { source: "git", command: "push", reason: "128" },
      { source: "github", method: "POST", status: 403 },
      { source: "retry", reason: "PR changed during restack" },
      { source: "runtime" },
    ],
  );
  assert.doesNotMatch(JSON.stringify(logs), /secret|private-repository|authorization/);
});
test("Firebase discovers a public webhook and four private independently locked workers", async () => {
  process.env.STACKED_PR_TASK_SERVICE_ACCOUNT =
    "stacked-pr-tasks@demo-stacked-pr.iam.gserviceaccount.com";
  const { stackedPrWebhook, stackedPrWorker } = await import("../lib/index.js");
  assert.deepEqual(stackedPrWebhook.__endpoint.httpsTrigger.invoker, ["public"]);
  assert.deepEqual(stackedPrWorker.__endpoint.taskQueueTrigger.invoker, [
    process.env.STACKED_PR_TASK_SERVICE_ACCOUNT,
  ]);
  assert.equal(stackedPrWorker.__endpoint.concurrency, 1);
  assert.equal(stackedPrWorker.__endpoint.maxInstances, 4);
  assert.equal(stackedPrWorker.__endpoint.timeoutSeconds, 540);
  assert.equal(stackedPrWorker.__endpoint.taskQueueTrigger.rateLimits.maxConcurrentDispatches, 4);
  assert.equal(stackedPrWorker.__endpoint.taskQueueTrigger.retryConfig.maxAttempts, 8);
  assert.deepEqual(stackedPrWorker.__endpoint.region, ["asia-northeast1"]);
});
