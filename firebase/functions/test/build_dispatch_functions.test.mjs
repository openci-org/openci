import assert from "node:assert/strict";
import { createRequire } from "node:module";
import { after, beforeEach, test } from "node:test";
import { deleteApp, getApps, initializeApp } from "firebase-admin/app";
import { getFunctions } from "firebase-admin/functions";
import { GoogleAuth } from "google-auth-library";
import {
  queueBuildJobs,
  queueBuildDispatchOnCompletion,
  dispatchBuildJob,
} from "../../lib/functions/build_dispatch_functions.js";
import {
  dispatchTaskId,
  dispatchCompletionTaskId,
  dispatchContinuationTaskId,
} from "../../lib/functions/build_dispatch.js";
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
const { declaredParams } = createRequire(import.meta.url)("firebase-functions/params");
const event = (data, errors, variables = { jobsJson: "private metadata" }) => ({
  id: "event",
  authType: "admin",
  data: { payload: { data, errors, variables } },
});
const completionEvent = (id = "dispatch-1") =>
  event({ buildJobDispatch_updateMany: 1 }, undefined, {
    id,
    jobId: "job",
    owner: "private cleanup owner",
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

test("superseded jobs are paged and reliably notified even after a partial enqueue failure", async (t) => {
  const jobs = Array.from({ length: 103 }, (_, i) => ({ id: `old-${String(i).padStart(3, "0")}` }));
  const pages = [];
  t.mock.method(DataConnectDispatchStore.prototype, "superseded", async (taskId, afterId) => {
    assert.equal(taskId, "webhook-new");
    pages.push(afterId);
    return jobs.filter((job) => job.id > afterId).slice(0, 100);
  });
  const tasks = new Map();
  let unavailable = true;
  mockQueue(t, async (data, options) => {
    assert.equal(options.id, dispatchTaskId(data.jobId, "superseded-webhook-new"));
    assert.notEqual(options.id, dispatchTaskId(data.jobId));
    assert.equal(options.scheduleTime, undefined);
    if (tasks.has(options.id)) throw { code: "functions/task-already-exists" };
    if (data.jobId === "old-101" && unavailable) throw new Error("queue outage");
    tasks.set(options.id, data);
  });
  const input = event({ jobs: [], cancelled: jobs.length }, undefined, { id: "webhook-new" });
  await assert.rejects(queueBuildJobs.run(input), /retry required/);
  assert.equal(tasks.size, 101);
  unavailable = false;
  await queueBuildJobs.run(input);
  await queueBuildJobs.run(input);
  assert.equal(tasks.size, jobs.length);
  assert.deepEqual(pages, ["", "old-099", "", "old-099", "", "old-099"]);
});

test("failed or zero-cancellation mutations do not read the cancellation source", async (t) => {
  t.mock.method(DataConnectDispatchStore.prototype, "superseded", () =>
    assert.fail("must not read"),
  );
  mockQueue(t, () => assert.fail("must not enqueue"));
  await queueBuildJobs.run(event({ jobs: [], cancelled: 0 }));
  await queueBuildJobs.run(event({ jobs: [], cancelled: 1 }, [{ message: "rolled back" }]));
  await assert.rejects(queueBuildJobs.run(event({ jobs: [], cancelled: 1 })), /retry required/);
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

test("completion wakes dispatch immediately without colliding with initial or recovery tasks", async (t) => {
  const tasks = new Map([
    [dispatchTaskId("job"), {}],
    [dispatchTaskId("job", "dispatch-1"), {}],
  ]);
  mockQueue(t, async (data, options) => {
    if (tasks.has(options.id)) throw { code: "functions/task-already-exists" };
    tasks.set(options.id, { data, options });
  });
  await queueBuildDispatchOnCompletion.run(completionEvent());
  await queueBuildDispatchOnCompletion.run({ ...completionEvent(), id: "redelivery" });
  assert.equal(tasks.size, 3);
  const notification = tasks.get(dispatchCompletionTaskId("job", "dispatch-1"));
  assert.deepEqual(notification.data, { jobId: "job" });
  assert.equal(notification.options.scheduleTime, undefined);
  assert.equal(notification.options.dispatchDeadlineSeconds, 120);
  await queueBuildDispatchOnCompletion.run(completionEvent("dispatch-2"));
  assert.equal(tasks.size, 4);
  assert.ok(tasks.has(dispatchCompletionTaskId("job", "dispatch-2")));
});

test("failed completions enqueue nothing and completion events require an admin principal", async (t) => {
  const enqueue = mockQueue(t, () => assert.fail("must not enqueue"));
  t.mock.method(logger, "error", () => {});
  await queueBuildDispatchOnCompletion.run(event(null, [{ message: "cleanup failed" }]));
  const partial = completionEvent();
  partial.data.payload.errors = [{ message: "transaction rolled back" }];
  await queueBuildDispatchOnCompletion.run(partial);
  for (const authType of [undefined, "unknown", "app_user"])
    await assert.rejects(
      queueBuildDispatchOnCompletion.run({ ...completionEvent(), authType }),
      /retry required/,
    );
  assert.equal(enqueue.mock.callCount(), 0);
});

test("malformed completion results or identities never enqueue a notification", async (t) => {
  const enqueue = mockQueue(t, () => assert.fail("must not enqueue"));
  t.mock.method(logger, "error", () => {});
  const valid = completionEvent().data.payload;
  for (const data of [
    null,
    {},
    { buildJobDispatch_updateMany: 0 },
    { buildJobDispatch_updateMany: "1" },
  ])
    await assert.rejects(
      queueBuildDispatchOnCompletion.run(event(data, undefined, valid.variables)),
      /retry required/,
    );
  for (const variables of [
    null,
    {},
    { id: "dispatch-1" },
    { id: "", jobId: "job" },
    { id: "dispatch-1", jobId: "job\n" },
  ])
    await assert.rejects(
      queueBuildDispatchOnCompletion.run(event(valid.data, undefined, variables)),
      /retry required/,
    );
  assert.equal(enqueue.mock.callCount(), 0);
});

for (const savedBeforeFailure of [false, true]) {
  test(`completion enqueue failure ${savedBeforeFailure ? "after" : "before"} saving retries without duplicating the notification`, async (t) => {
    const tasks = new Map();
    let unavailable = true;
    const errors = t.mock.method(logger, "error", () => {});
    mockQueue(t, async (data, options) => {
      if (tasks.has(options.id)) throw { code: "functions/task-already-exists" };
      if (savedBeforeFailure || !unavailable) tasks.set(options.id, data);
      if (unavailable) throw new Error("private SDK credentials");
    });
    await assert.rejects(queueBuildDispatchOnCompletion.run(completionEvent()), {
      message: "Build completion dispatch enqueue failed; retry required",
    });
    assert.equal(tasks.size, savedBeforeFailure ? 1 : 0);
    assert.deepEqual(errors.mock.calls[0].arguments, [
      "Build completion dispatch enqueue failed",
      { eventId: "event" },
    ]);
    unavailable = false;
    await queueBuildDispatchOnCompletion.run(completionEvent());
    await queueBuildDispatchOnCompletion.run(completionEvent());
    assert.deepEqual([...tasks.values()], [{ jobId: "job" }]);
  });
}

test("completion delivery waits until its notification has been enqueued", async (t) => {
  const entered = Promise.withResolvers();
  const saved = Promise.withResolvers();
  mockQueue(t, async () => {
    entered.resolve();
    await saved.promise;
  });
  let acknowledged = false;
  const delivery = queueBuildDispatchOnCompletion.run(completionEvent()).then(() => {
    acknowledged = true;
  });
  await entered.promise;
  assert.equal(acknowledged, false);
  saved.resolve();
  await delivery;
  assert.equal(acknowledged, true);
});

test("malformed task payloads are acknowledged without accessing configured services", async () => {
  for (const data of [
    null,
    {},
    { jobId: "" },
    { dispatch: false },
    { dispatch: true, jobId: "job" },
    { jobId: "job", url: "https://example.test" },
  ]) {
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
  const tracked = new Set();
  let retry;
  t.mock.method(store, "reserveRetry", async (taskId, jobId) => {
    if (jobId) tracked.add(jobId);
    retry ??= { taskId, scheduleTime: new Date(Date.now() + 60_000) };
    return retry;
  });
  t.mock.method(store, "consumeRetry", async (taskId) => {
    if (retry?.taskId === taskId) retry = undefined;
  });
  t.mock.method(store, "pendingWork", async () => ({
    queuedJob: state.job.status === "QUEUED" ? { id: state.job.id } : null,
    changedJob: tracked.has(state.job.id) && state.job.status !== "QUEUED" ? state.job : null,
  }));
  t.mock.method(store, "completeRetryJob", async (jobId) => tracked.delete(jobId));
  t.mock.method(OrchardCapacityClient.prototype, "snapshot", async () => ({
    workers: [],
    vms: [],
  }));
  const errors = t.mock.method(logger, "error", () => {});
  const info = t.mock.method(logger, "info", () => {});
  return { state, tracked, errors, info, retry: () => retry };
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
  test(`${reason} shares a delayed retry and returns HTTP 204 without ERROR logs`, async (t) => {
    const { errors, info, retry } = mockDispatcher(t, reason);
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
    const successor = tasks.get(retry().taskId);
    assert.deepEqual(successor.data, { dispatch: true });
    assert.equal(successor.options.dispatchDeadlineSeconds, 120);
    assert.ok(successor.options.scheduleTime.getTime() >= start + 60_000);
    assert.ok(successor.options.scheduleTime.getTime() <= Date.now() + 60_000);
    assert.equal(tasks.size, reason === "launch_busy" ? 2 : 1);
    if (reason === "launch_busy") assert.ok(tasks.has(dispatchTaskId("job", "reservation")));
    assert.equal(errors.mock.callCount(), 0);
    if (reason === "queue_pending") assert.equal(info.mock.callCount(), 0);
    else
      assert.deepEqual(info.mock.calls[0].arguments, [
        "Build dispatch deferred",
        { jobId: "job", reason },
      ]);
  });
}

test("recovery targets the FIFO selection while the shared retry tracks the waiting source", async (t) => {
  const { retry, tracked } = mockDispatcher(t);
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
  assert.deepEqual(tasks.get(retry().taskId).data, { dispatch: true });
  assert.ok(tracked.has("newer"));
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

test("a lost enqueue response reuses the durable reservation and subsequent polls keep moving", async (t) => {
  const { errors, retry } = mockDispatcher(t);
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
  const successorId = retry().taskId;
  assert.equal((await deliverTask(successorId, { dispatch: true })).statusCode, 204);
  assert.equal(tasks.size, 2);
  assert.notEqual(retry().taskId, successorId);
  assert.ok(tasks.has(retry().taskId));
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

test("a lost FSC reservation response retries before acknowledging or enqueueing a different task", async (t) => {
  const { retry } = mockDispatcher(t);
  const reserve = DataConnectDispatchStore.prototype.reserveRetry;
  let lostResponse = true;
  t.mock.method(DataConnectDispatchStore.prototype, "reserveRetry", async (...args) => {
    const saved = await reserve(...args);
    if (lostResponse) {
      lostResponse = false;
      throw new Error("lost database response");
    }
    return saved;
  });
  const enqueue = mockQueue(t, async () => {});
  assert.equal((await deliverTask("source")).statusCode, 500);
  assert.equal(enqueue.mock.callCount(), 0);
  const savedId = retry().taskId;
  assert.equal((await deliverTask("source")).statusCode, 204);
  assert.equal(enqueue.mock.calls[0].arguments[1].id, savedId);
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

test("100 waiting notifications share one future task and one capacity check per later poll", async (t) => {
  const { retry, tracked } = mockDispatcher(t);
  const tasks = new Map();
  mockQueue(t, async (data, options) => {
    if (tasks.has(options.id)) throw { code: "functions/task-already-exists" };
    tasks.set(options.id, { data, options });
  });
  const responses = await Promise.all(
    Array.from({ length: 100 }, (_, index) =>
      deliverTask(`source-${index}`, { jobId: `job-${index}` }),
    ),
  );
  assert.ok(responses.every((response) => response.statusCode === 204));
  assert.equal(tasks.size, 1);
  assert.equal(tracked.size, 100);
  const snapshot = OrchardCapacityClient.prototype.snapshot;
  for (let poll = 0; poll < 3; poll++) {
    const previousCalls = snapshot.mock.callCount();
    const current = retry();
    assert.equal((await deliverTask(current.taskId, { dispatch: true })).statusCode, 204);
    assert.equal(snapshot.mock.callCount() - previousCalls, 1);
    assert.notEqual(retry().taskId, current.taskId);
    assert.equal(tasks.size, poll + 2);
  }
});

test("a consumed retry still runs after a crash and does not discard its redelivery", async (t) => {
  const { retry } = mockDispatcher(t);
  mockQueue(t, async () => {});
  await deliverTask("source");
  const taskId = retry().taskId;
  const expire = t.mock.method(DataConnectDispatchStore.prototype, "expireUnstarted", async () => {
    throw new Error("database outage after consume");
  });
  assert.equal((await deliverTask(taskId, { dispatch: true })).statusCode, 500);
  assert.equal(retry(), undefined);
  expire.mock.mockImplementation(async () => {});
  assert.equal((await deliverTask(taskId, { dispatch: true })).statusCode, 204);
  assert.ok(retry());
  assert.notEqual(retry().taskId, taskId);
});

test("an empty queue ends the shared retry without reading or synchronizing a source job", async (t) => {
  const { state, retry } = mockDispatcher(t);
  state.job.status = "SUCCESS";
  const enqueue = mockQueue(t, async () => {});
  assert.equal((await deliverTask("shared", { dispatch: true })).statusCode, 204);
  assert.equal(retry(), undefined);
  assert.equal(enqueue.mock.callCount(), 0);
  assert.equal(DataConnectDispatchStore.prototype.read.mock.callCount(), 0);
  assert.equal(QueuedChecks.prototype.sync.mock.callCount(), 0);
});

test("cancellation is handed to a durable job notification before the shared retry forgets it", async (t) => {
  const { state, tracked, retry } = mockDispatcher(t);
  const tasks = new Map();
  let queueAvailable = true;
  mockQueue(t, async (data, options) => {
    if (!queueAvailable) throw new Error("queue outage");
    if (tasks.has(options.id)) throw { code: "functions/task-already-exists" };
    tasks.set(options.id, { data, options });
  });
  await deliverTask("source");
  const taskId = retry().taskId;
  state.job.status = "CANCELLED";
  queueAvailable = false;
  assert.equal((await deliverTask(taskId, { dispatch: true })).statusCode, 500);
  assert.ok(tracked.has("job"));
  queueAvailable = true;
  assert.equal((await deliverTask(taskId, { dispatch: true })).statusCode, 204);
  assert.equal(tracked.size, 0);
  const cancellationId = dispatchContinuationTaskId(taskId, "job");
  assert.deepEqual(tasks.get(cancellationId).data, { jobId: "job" });
  assert.equal(tasks.get(cancellationId).options.scheduleTime, undefined);
  assert.ok(tasks.has(dispatchContinuationTaskId(taskId)));
  const sync = QueuedChecks.prototype.sync;
  const checked = sync.mock.callCount();
  assert.equal((await deliverTask(cancellationId, { jobId: "job" })).statusCode, 204);
  assert.equal(sync.mock.callCount(), checked + 1);
  assert.deepEqual(sync.mock.calls.at(-1).arguments, ["job"]);
  assert.equal(retry(), undefined);
});

test("cancellation racing the source check sync is inherited by the shared retry", async (t) => {
  const { state, tracked, retry } = mockDispatcher(t);
  t.mock.method(QueuedChecks.prototype, "sync", async () => {
    state.job.status = "CANCELLED";
  });
  const tasks = new Map();
  mockQueue(t, async (data, options) => tasks.set(options.id, { data, options }));
  assert.equal((await deliverTask("source")).statusCode, 204);
  assert.ok(tracked.has("job"));
  const taskId = retry().taskId;
  assert.equal((await deliverTask(taskId, { dispatch: true })).statusCode, 204);
  assert.deepEqual(tasks.get(dispatchContinuationTaskId(taskId, "job")).data, { jobId: "job" });
});

test("a single wakeup fills two slots with the default CPU allocation in FIFO order", async (t) => {
  const { retry, errors } = mockDispatcher(t);
  // Firebase supplies deployment-resolved parameter defaults as environment variables.
  const cpuParam = declaredParams.find((param) => param.name === "ORCHARD_VM_CPU");
  process.env.ORCHARD_VM_CPU = String(cpuParam.toSpec().default);
  const jobs = ["oldest", "second", "newest"].map((id) => ({
    id,
    status: "QUEUED",
    runsOn: "macos-latest",
  }));
  const reservations = new Map();
  const tasks = new Map();
  const launched = [];
  const store = DataConnectDispatchStore.prototype;
  t.mock.method(store, "read", async (jobId) => ({
    job: jobs.find((job) => job.id === jobId),
    dispatch: reservations.get(jobId),
  }));
  t.mock.method(store, "active", async () => [...reservations.values()]);
  t.mock.method(
    store,
    "oldestQueued",
    async () => jobs.find((job) => !reservations.has(job.id)) ?? null,
  );
  t.mock.method(store, "reserve", async (_owner, dispatch) => {
    reservations.set(dispatch.jobId, {
      ...dispatch,
      startDeadline: new Date(Date.now() + 600_000).toISOString(),
    });
  });
  t.mock.method(store, "acquireLaunch", async () => true);
  t.mock.method(store, "recordLaunch", async (id, _owner, operationName) => {
    [...reservations.values()].find((dispatch) => dispatch.id === id).operationName = operationName;
  });
  t.mock.method(OrchardCapacityClient.prototype, "snapshot", async () => ({
    workers: [
      {
        name: "mac-1",
        last_seen: new Date().toISOString(),
        resources: {
          "org.cirruslabs.logical-cores": 8,
          "org.cirruslabs.memory-mib": 8192,
          "org.cirruslabs.tart-vms": 2,
        },
      },
    ],
    vms: [],
  }));
  t.mock.method(GoogleAuth.prototype, "request", async (request) => {
    const env = request.data.overrides.containerOverrides[0].env;
    launched.push(env.find((entry) => entry.name === "BUILD_JOB_ID").value);
    return {
      data: {
        name: `projects/demo-openci/locations/asia-northeast1/operations/launch-${launched.length}`,
      },
    };
  });
  mockQueue(t, async (data, options) => {
    if (tasks.has(options.id)) throw { code: "functions/task-already-exists" };
    tasks.set(options.id, { data, options });
  });
  let sourceId = "initial";
  assert.equal((await deliverTask(sourceId, { jobId: "newest" })).statusCode, 204);
  const delayedId = retry().taskId;
  assert.deepEqual(launched, ["oldest"]);
  for (let continuation = 0; continuation < 2; continuation++) {
    sourceId = dispatchContinuationTaskId(sourceId);
    const task = tasks.get(sourceId);
    assert.equal(task.options.scheduleTime, undefined);
    assert.equal((await deliverTask(sourceId, task.data)).statusCode, 204);
  }
  assert.deepEqual(launched, ["oldest", "second"]);
  assert.equal(reservations.size, 2);
  assert.deepEqual(
    [...reservations.values()].map((dispatch) => dispatch.cpu),
    [4, 4],
  );
  assert.equal(retry().taskId, delayedId);
  assert.equal(tasks.has(dispatchContinuationTaskId(sourceId)), false);
  assert.equal(errors.mock.callCount(), 0);
});
