import assert from "node:assert/strict";
import { createRequire } from "node:module";
import { after, beforeEach, test } from "node:test";
import { deleteApp, getApps, initializeApp } from "firebase-admin/app";
import { getFunctions } from "firebase-admin/functions";
import { queueBuildJobs, dispatchBuildJob } from "../../lib/functions/build_dispatch_functions.js";
import { dispatchTaskId, dispatchRetryTaskId } from "../../lib/functions/build_dispatch.js";
import { DataConnectDispatchStore } from "../../lib/functions/dispatch_store.js";
import { OrchardCapacityClient } from "../../lib/functions/orchard_capacity.js";
import { QueuedChecks } from "../../lib/functions/queued_checks.js";

beforeEach((t) => {
  process.env.GITHUB_APP_ID = "1";
  process.env.GITHUB_APP_PRIVATE_KEY = "test-key";
  t.mock.method(QueuedChecks.prototype, "sync", async () => {});
  t.mock.method(DataConnectDispatchStore.prototype, "cancelUnstarted", async () => {});
});

const app = initializeApp({ projectId: "demo-openci" });
after(() => Promise.all(getApps().map(deleteApp)));
const logger = createRequire(import.meta.url)("firebase-functions/logger");
const event = (data, errors) => ({
  id: "event",
  authType: "admin",
  data: { payload: { data, errors, variables: { jobsJson: "private metadata" } } },
});

test("mutation retries complete a partially enqueued batch without duplicating tasks", async (t) => {
  const saved = new Map();
  let outage = true;
  t.mock.method(getFunctions(app), "taskQueue", (queue) => {
    assert.equal(queue, "locations/asia-northeast1/functions/dispatchBuildJob");
    return {
      enqueue: async (data, options) => {
        assert.deepEqual(Object.keys(data), ["jobId"]);
        assert.equal(options.id, dispatchTaskId(data.jobId));
        if (saved.has(options.id)) throw { code: "functions/task-already-exists" };
        if (data.jobId === "second" && outage) throw new Error("private SDK error");
        saved.set(options.id, data.jobId);
      },
    };
  });
  const input = event({ jobs: [{ id: "first" }, { id: "second" }, { id: "third" }] });
  await assert.rejects(queueBuildJobs.run(input), {
    message: "Build dispatch enqueue failed; retry required",
  });
  assert.deepEqual([...saved.values()], ["first"]);
  outage = false;
  await queueBuildJobs.run(input);
  await queueBuildJobs.run(input);
  assert.deepEqual([...saved.values()], ["first", "second", "third"]);
});

test("empty or failed mutations enqueue nothing and non-admin events are rejected", async (t) => {
  t.mock.method(getFunctions(app), "taskQueue", () => assert.fail("must not enqueue"));
  await queueBuildJobs.run(event({ jobs: [] }));
  await queueBuildJobs.run(event(null, [{ message: "failed" }]));
  await assert.rejects(
    queueBuildJobs.run({ ...event({ jobs: [{ id: "job" }] }), authType: "unknown" }),
  );
});

test("check publication must finish before enqueue, and failures retain mutation retry", async (t) => {
  const calls = [];
  let unavailable = true;
  t.mock.method(QueuedChecks.prototype, "sync", async (id) => {
    calls.push(`check:${id}`);
    if (unavailable) throw new Error("private check error");
  });
  t.mock.method(getFunctions(app), "taskQueue", () => ({
    enqueue: async ({ jobId }) => {
      calls.push(`enqueue:${jobId}`);
    },
  }));
  const input = event({ jobs: [{ id: "job" }] });
  await assert.rejects(queueBuildJobs.run(input), /retry required/);
  assert.deepEqual(calls, ["check:job"]);
  unavailable = false;
  await queueBuildJobs.run(input);
  assert.deepEqual(calls, ["check:job", "check:job", "enqueue:job"]);
});

test("malformed task payloads are acknowledged without accessing configured services", async () => {
  for (const data of [null, {}, { jobId: "" }, { jobId: "job", url: "https://example.test" }]) {
    await dispatchBuildJob.run({ data });
  }
});

function mockDispatcher(t, reason = "capacity_unavailable") {
  const env = {
    FUNCTIONS_EMULATOR: "true",
    GCLOUD_PROJECT: "demo-openci",
    ORCHARD_API_URL: "https://orchard.test",
    ORCHARD_SERVICE_ACCOUNT_NAME: "test",
    ORCHARD_SERVICE_ACCOUNT_TOKEN: "test-token",
    ORCHARD_VM_CPU: "2",
    ORCHARD_VM_MEMORY_MIB: "4096",
    BASE_VM_NAME: "test-image",
    BUILD_EXECUTOR_JOB: "projects/demo-openci/locations/asia-northeast1/jobs/build-executor",
  };
  for (const [key, value] of Object.entries(env)) {
    const original = process.env[key];
    process.env[key] = value;
    t.after(() => {
      if (original === undefined) delete process.env[key];
      else process.env[key] = original;
    });
  }
  const state = { job: { id: "job", status: "QUEUED", runsOn: "macos-latest" } };
  if (reason === "launch_busy")
    state.dispatch = {
      id: "reservation",
      jobId: "job",
      startDeadline: new Date(Date.now() + 600_000).toISOString(),
    };
  const store = DataConnectDispatchStore.prototype;
  t.mock.method(store, "expireUnstarted", async () => {});
  t.mock.method(store, "read", async () => state);
  t.mock.method(store, "active", async () => (state.dispatch ? [state.dispatch] : []));
  t.mock.method(store, "oldestQueued", async () =>
    reason !== "queue_pending" && state.job.status === "QUEUED" && !state.dispatch
      ? { id: state.job.id }
      : null,
  );
  t.mock.method(store, "acquireScheduler", async () => reason !== "scheduler_busy");
  t.mock.method(store, "releaseScheduler", async () => {});
  t.mock.method(store, "acquireLaunch", async () => false);
  t.mock.method(OrchardCapacityClient.prototype, "snapshot", async () => ({
    workers: [],
    vms: [],
  }));
  const errors = t.mock.method(logger, "error", () => {});
  const info = t.mock.method(logger, "info", () => {});
  return { state, errors, info };
}

function mockQueue(t, enqueue) {
  const enqueueMock = t.mock.fn(enqueue);
  t.mock.method(getFunctions(app), "taskQueue", () => ({ enqueue: enqueueMock }));
  return enqueueMock;
}

// Exercise the Firebase HTTP wrapper as well as the handler: an unhandled
// exception becomes both an ERROR log and an HTTP 500, even after an INFO log.
async function deliverTask(id, data = { jobId: "job" }) {
  const headers = { "content-type": "application/json", "x-cloudtasks-taskname": id };
  const response = {
    status(code) {
      this.statusCode = code;
      return this;
    },
    end() {},
    send(body) {
      this.body = body;
    },
  };
  await dispatchBuildJob(
    { method: "POST", body: { data }, headers, header: (name) => headers[name.toLowerCase()] },
    response,
  );
  return response;
}

for (const reason of ["capacity_unavailable", "scheduler_busy", "launch_busy", "queue_pending"]) {
  test(`${reason} queues a delayed successor and returns HTTP 204 without ERROR logs`, async (t) => {
    const { errors, info } = mockDispatcher(t, reason);
    const tasks = new Map();
    mockQueue(t, async (data, options) => {
      tasks.set(options.id, { data, options });
    });
    const start = Date.now();
    assert.equal(
      (await deliverTask("source")).statusCode,
      204,
      JSON.stringify(errors.mock.calls.map((call) => call.arguments)),
    );
    const successor = tasks.get(dispatchRetryTaskId("job", "source"));
    assert.deepEqual(successor.data, { jobId: "job" });
    assert.equal(successor.options.dispatchDeadlineSeconds, 120);
    assert.ok(successor.options.scheduleTime.getTime() >= start + 60_000);
    assert.ok(successor.options.scheduleTime.getTime() <= Date.now() + 60_000);
    assert.equal(tasks.size, reason === "launch_busy" ? 2 : 1);
    if (reason === "launch_busy") assert.ok(tasks.has(dispatchTaskId("job", "reservation")));
    assert.equal(errors.mock.callCount(), 0);
    assert.deepEqual(info.mock.calls[0].arguments, [
      "Build dispatch deferred",
      { jobId: "job", reason },
    ]);
  });
}

test("recovery targets the selected job while the successor retains the notification's job", async (t) => {
  mockDispatcher(t);
  const selected = { job: { id: "oldest", status: "QUEUED", runsOn: "macos-latest" } };
  const source = { job: { id: "newer", status: "QUEUED", runsOn: "macos-latest" } };
  const checked = [];
  const tasks = new Map();
  t.mock.method(QueuedChecks.prototype, "sync", async (jobId) => checked.push(jobId));
  const store = DataConnectDispatchStore.prototype;
  t.mock.method(store, "read", async (jobId) => (jobId === "oldest" ? selected : source));
  t.mock.method(store, "oldestQueued", async () => ({ id: "oldest" }));
  t.mock.method(store, "reserve", async (_owner, dispatch) => {
    assert.deepEqual(checked, ["newer", "oldest"]);
    selected.dispatch = {
      ...dispatch,
      startDeadline: new Date(Date.now() + 600_000).toISOString(),
    };
  });
  t.mock.method(OrchardCapacityClient.prototype, "snapshot", async () => ({
    workers: [
      {
        name: "mac-1",
        last_seen: new Date().toISOString(),
        resources: {
          "org.cirruslabs.logical-cores": 2,
          "org.cirruslabs.memory-mib": 4096,
          "org.cirruslabs.tart-vms": 1,
        },
      },
    ],
    vms: [],
  }));
  mockQueue(t, async (data, options) => tasks.set(options.id, { data, options }));
  assert.equal((await deliverTask("source", { jobId: "newer" })).statusCode, 204);
  const recovery = tasks.get(dispatchTaskId("oldest", selected.dispatch.id));
  assert.deepEqual(recovery.data, { jobId: "oldest" });
  assert.equal(
    recovery.options.scheduleTime.getTime(),
    Date.parse(selected.dispatch.startDeadline) + 1000,
  );
  assert.deepEqual(tasks.get(dispatchRetryTaskId("newer", "source")).data, { jobId: "newer" });
  assert.equal(tasks.size, 2);
});

test("the source is not acknowledged before the successor enqueue completes", async (t) => {
  mockDispatcher(t);
  const entered = Promise.withResolvers();
  const saved = Promise.withResolvers();
  mockQueue(t, async () => {
    entered.resolve();
    await saved.promise;
  });
  let completed = false;
  const delivery = deliverTask("source").then((response) => {
    completed = true;
    return response;
  });
  await entered.promise;
  assert.equal(completed, false);
  saved.resolve();
  assert.equal((await delivery).statusCode, 204);
});

test("a lost enqueue response retries safely, deduplicates redelivery, and keeps later waits moving", async (t) => {
  const { state, errors } = mockDispatcher(t);
  const tasks = new Map();
  let loseResponse = true;
  mockQueue(t, async (data, options) => {
    if (tasks.has(options.id)) throw { code: "functions/task-already-exists" };
    tasks.set(options.id, { data, options });
    if (loseResponse) {
      loseResponse = false;
      throw new Error("private queue response");
    }
  });
  assert.equal((await deliverTask("source")).statusCode, 500);
  assert.equal(tasks.size, 1);
  assert.equal((await deliverTask("source")).statusCode, 204);
  assert.equal((await deliverTask("source")).statusCode, 204);
  assert.equal(tasks.size, 1);
  const successorId = dispatchRetryTaskId("job", "source");
  assert.equal((await deliverTask(successorId)).statusCode, 204);
  assert.equal(tasks.size, 2);
  assert.ok(tasks.has(dispatchRetryTaskId("job", successorId)));
  state.job.status = "CANCELLED";
  assert.equal((await deliverTask(dispatchRetryTaskId("job", successorId))).statusCode, 204);
  assert.equal(tasks.size, 2);
  assert.ok(!JSON.stringify(errors.mock.calls).includes("private queue response"));
});

test("enqueue outages fail the current task instead of losing the queued build", async (t) => {
  const { info, errors } = mockDispatcher(t);
  mockQueue(t, async () => {
    throw new Error("private queue credentials");
  });
  assert.equal((await deliverTask("source")).statusCode, 500);
  assert.equal(info.mock.callCount(), 0);
  assert.deepEqual(errors.mock.calls[0].arguments, [
    "Build dispatch failed",
    { jobId: "job", reason: "retry_enqueue_failed" },
  ]);
  assert.ok(!JSON.stringify(errors.mock.calls).includes("private queue credentials"));
});

test("missing task identity cannot acknowledge a deferred build or create an unstable retry", async (t) => {
  mockDispatcher(t);
  const enqueue = mockQueue(t, async () => {});
  assert.equal((await deliverTask(undefined)).statusCode, 500);
  assert.equal(enqueue.mock.callCount(), 0);
});

test("actual dispatch errors retain HTTP 500, sanitized ERROR logs, and the source task retry", async (t) => {
  const { errors, info } = mockDispatcher(t);
  t.mock.method(DataConnectDispatchStore.prototype, "expireUnstarted", async () => {
    throw Object.assign(new Error("private database payload"), {
      code: "data-connect/unavailable",
    });
  });
  const enqueue = mockQueue(t, async () => {});
  assert.equal((await deliverTask("source")).statusCode, 500);
  assert.equal(enqueue.mock.callCount(), 0);
  assert.equal(info.mock.callCount(), 0);
  assert.deepEqual(errors.mock.calls[0].arguments, [
    "Build dispatch failed",
    { jobId: "job", reason: "data-connect/unavailable" },
  ]);
  assert.ok(!JSON.stringify(errors.mock.calls).includes("private database payload"));
});
