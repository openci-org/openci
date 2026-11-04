import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";
import { after, beforeEach, test } from "node:test";
import { deleteApp, initializeApp } from "firebase-admin/app";
import { getDataConnect } from "firebase-admin/data-connect";
import { getFunctions } from "firebase-admin/functions";
import * as sdk from "@openci/dispatch-admin";
import { dispatchBuildJob, DispatchRetry } from "../../lib/functions/build_dispatch.js";
import { DataConnectDispatchStore } from "../../lib/functions/dispatch_store.js";
import { queueBuildDispatchOnCompletion } from "../../lib/functions/build_dispatch_functions.js";

const host = process.env.DATA_CONNECT_EMULATOR_HOST;
assert.match(host ?? "", /^(127\.0\.0\.1|localhost):\d+$/, "Start the SQL Connect emulator first");
const service = `http://${host}/v1/projects/demo-openci/locations/asia-northeast1/services/openci-b1b91-service`;
const app = initializeApp({ projectId: "demo-openci" });
const dc = getDataConnect(sdk.connectorConfig, app);
const store = new DataConnectDispatchStore(dc);
const configuration = {
  cpu: 2,
  memoryMiB: 4096,
  image: "base-macos",
  cloudRunJob: "projects/demo-openci/locations/asia-northeast1/jobs/build-executor",
};
const operation = "projects/demo-openci/locations/asia-northeast1/operations/test-operation";

async function graphql(query, variables) {
  const response = await fetch(`${service}:executeGraphql`, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ query, variables }),
  });
  const result = await response.json();
  assert.ok(response.ok && !result.errors?.length, JSON.stringify(result));
  return result.data;
}

beforeEach(async () => {
  await sdk.initializeBuildDispatchScheduler(dc);
  await graphql(`
    mutation ResetScheduler {
      buildDispatchScheduler_update(id: "orchard", data: { owner: null, leaseUntil: null })
    }
  `);
});
after(() => deleteApp(app));

async function fixture(t, { status = "QUEUED", runsOn = "macos-latest", createdAt = "1" } = {}) {
  const jobId = randomUUID();
  await graphql(
    `
      mutation Seed($id: String!, $status: String!, $runsOn: String!, $createdAt: Int64!) {
        buildJob_insert(
          data: {
            id: $id
            status: $status
            runsOn: $runsOn
            owner: "org"
            repo: "app"
            workflowName: "Test"
            workflowFileName: "test.dart"
            createdAt: $createdAt
            updatedAt: 1
          }
        )
      }
    `,
    { id: jobId, status, runsOn, createdAt },
  );
  t.after(() =>
    graphql(
      `
        mutation Cleanup($id: String!) {
          buildJobDispatch_deleteMany(where: { jobId: { eq: $id } })
          buildJob_delete(id: $id)
        }
      `,
      { id: jobId },
    ),
  );
  const launched = [],
    recoveries = [],
    order = [];
  const dependencies = {
    store,
    configuration,
    syncQueuedCheck: async () => {},
    snapshot: async () => ({
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
    }),
    enqueueRecovery: async (dispatch) => {
      recoveries.push(dispatch);
      order.push("recovery");
    },
    launch: async (dispatch) => {
      launched.push(dispatch);
      order.push("launch");
      return operation;
    },
  };
  return {
    jobId,
    dependencies,
    launched,
    recoveries,
    order,
    run: () => dispatchBuildJob(dependencies),
    state: () => store.read(jobId),
  };
}

function overrideStore(methods) {
  return Object.assign(Object.create(store), methods);
}
async function updateDispatch(id, data) {
  return graphql(
    `
      mutation Alter($id: String!, $data: BuildJobDispatch_Data!) {
        buildJobDispatch_update(id: $id, data: $data)
      }
    `,
    { id, data },
  );
}
async function updateJob(id, status) {
  return graphql(
    `
      mutation Alter($id: String!, $status: String!) {
        buildJob_update(id: $id, data: { status: $status })
      }
    `,
    { id, status },
  );
}
const claim = (id, executorId = randomUUID()) =>
  sdk.claimBuildJobExecution(dc, { id, executorId, executionName: "test-execution" });
const past = "2000-01-01T00:00:00Z";

test("reserves capacity, schedules recovery before launch, and deduplicates redelivery", async (t) => {
  const f = await fixture(t);
  await f.run();
  const { job, dispatch } = await f.state();
  assert.equal(job.status, "QUEUED");
  assert.equal(dispatch.jobId, f.jobId);
  assert.equal(dispatch.operationName, operation);
  assert.equal(dispatch.vmName, `openci-${dispatch.id}`);
  assert.ok(Date.parse(dispatch.startDeadline) > Date.now());
  assert.deepEqual(f.order, ["recovery", "launch"]);
  await f.run();
  assert.equal(f.launched.length, 1);
  assert.equal((await f.state()).dispatch.id, dispatch.id);
});

test("full capacity keeps the job queued without a reservation or launch", async (t) => {
  const f = await fixture(t);
  f.dependencies.snapshot = async () => ({ workers: [], vms: [] });
  await assert.rejects(
    f.run(),
    (error) => error instanceof DispatchRetry && error.reason === "capacity_unavailable",
  );
  assert.deepEqual(await f.state(), {
    job: { id: f.jobId, status: "QUEUED", runsOn: "macos-latest" },
    dispatch: null,
  });
  assert.equal(f.launched.length, 0);
  assert.equal(f.recoveries.length, 0);
});

test("any notification reserves the oldest job and reports a launch for immediate continuation", async (t) => {
  const oldest = await fixture(t, { createdAt: "1" });
  const newer = await fixture(t, { createdAt: "2" });
  assert.equal(await newer.run(), true);
  assert.equal(newer.launched[0].jobId, oldest.jobId);
  assert.equal(newer.recoveries[0].jobId, oldest.jobId);
  const firstDispatch = (await oldest.state()).dispatch;
  assert.ok(firstDispatch);
  assert.equal((await newer.state()).dispatch, null);
  await updateJob(oldest.jobId, "SUCCESS");
  await updateDispatch(firstDispatch.id, {
    activeJobId: null,
    state: "finished",
    finishedAt: new Date().toISOString(),
  });
  await newer.run();
  assert.deepEqual(
    newer.launched.map((dispatch) => dispatch.jobId),
    [oldest.jobId, newer.jobId],
  );
});

test("a completed job notification can start the oldest waiting job", async (t) => {
  const waiting = await fixture(t);
  const completed = await fixture(t, { status: "SUCCESS" });
  await completed.run();
  assert.equal(completed.launched[0]?.jobId, waiting.jobId);
  assert.ok((await waiting.state()).dispatch);
});

test("a completed notification reports a capacity wait when other jobs remain queued", async (t) => {
  const waiting = await fixture(t);
  const completed = await fixture(t, { status: "SUCCESS" });
  completed.dependencies.snapshot = async () => ({ workers: [], vms: [] });
  await assert.rejects(completed.run(), (failure) => failure.reason === "capacity_unavailable");
  assert.equal(completed.launched.length, 0);
  assert.equal((await waiting.state()).dispatch, null);
});

for (const outcome of ["success", "failure", "cancelled", "timed_out", "blocked"]) {
  test(`${outcome} completion notifies dispatch and starts the oldest eligible waiting job`, async (t) => {
    const finishing = await fixture(t, { createdAt: "0" });
    await finishing.run();
    const { dispatch } = await finishing.state();
    const executorId = randomUUID();
    assert.equal((await claim(dispatch.id, executorId)).data.acquired, 1);
    const oldest = await fixture(t, { createdAt: "1" });
    const newer = await fixture(t, { createdAt: "2" });
    if (outcome === "timed_out") {
      await updateDispatch(dispatch.id, { deadlineAt: past });
    } else {
      if (outcome === "cancelled") await updateJob(finishing.jobId, "CANCELLED");
      await sdk.recordBuildExecutionResult(dc, { id: dispatch.id, executorId, outcome });
    }
    const owner = randomUUID();
    assert.equal(
      (await sdk.acquireBuildExecutionCleanup(dc, { id: dispatch.id, owner })).data.acquired,
      1,
    );
    const variables = { id: dispatch.id, jobId: finishing.jobId, owner };
    await assert.rejects(sdk.completeBuildExecution(dc, variables));
    await assert.rejects(newer.run(), (failure) => failure.reason === "capacity_unavailable");
    await sdk.confirmBuildVmDeleted(dc, { id: dispatch.id, owner });
    const { data } = await sdk.completeBuildExecution(dc, variables);

    const notifications = new Map();
    t.mock.method(getFunctions(app), "taskQueue", (queue) => {
      assert.equal(queue, "locations/asia-northeast1/functions/dispatchBuildJob");
      return {
        enqueue: async (payload, options) => {
          assert.equal(options.scheduleTime, undefined);
          if (notifications.has(options.id)) throw { code: "functions/task-already-exists" };
          notifications.set(options.id, payload);
        },
      };
    });
    // The SQL emulator returns the real mutation result; Eventarc delivery is
    // supplied here because it is not part of the local emulator boundary.
    const event = {
      id: randomUUID(),
      authType: "admin",
      data: { payload: { data, variables } },
    };
    await queueBuildDispatchOnCompletion.run(event);
    await queueBuildDispatchOnCompletion.run(event);
    assert.deepEqual([...notifications.values()], [{ jobId: finishing.jobId }]);
    assert.equal(await dispatchBuildJob(newer.dependencies), true);
    if (outcome === "blocked") {
      assert.equal((await finishing.state()).job.status, "QUEUED");
    } else {
      assert.equal((await finishing.state()).job.status, outcome.toUpperCase());
    }
    assert.equal((await finishing.state()).dispatch, null);
    assert.ok((await oldest.state()).dispatch);
    assert.equal((await newer.state()).dispatch, null);
    assert.deepEqual(
      newer.launched.map((reservation) => reservation.jobId),
      [oldest.jobId],
    );
    assert.equal((await store.active()).length, 1);
  });
}

test("capacity retries preserve the oldest job even when the newer notification arrives again", async (t) => {
  const oldest = await fixture(t, { createdAt: "1" });
  const newer = await fixture(t, { createdAt: "2" });
  const available = newer.dependencies.snapshot;
  newer.dependencies.snapshot = async () => ({ workers: [], vms: [] });
  await assert.rejects(newer.run(), (error) => error.reason === "capacity_unavailable");
  assert.equal((await oldest.state()).dispatch, null);
  newer.dependencies.snapshot = available;
  assert.equal(await newer.run(), true);
  assert.equal(newer.launched[0].jobId, oldest.jobId);
});

test("pending work includes a job that FIFO temporarily excludes during check publication", async (t) => {
  const f = await fixture(t);
  await graphql(
    `
      mutation Publishing($id: String!) {
        buildJob_update(id: $id, data: { checkLeaseUntil: "2099-01-01T00:00:00Z" })
      }
    `,
    { id: f.jobId },
  );
  assert.equal(await f.run(), false);
  assert.equal((await store.pendingWork()).queuedJob.id, f.jobId);
  assert.equal(f.launched.length, 0);
  await graphql(
    `
      mutation Published($id: String!) {
        buildJob_update(id: $id, data: { checkLeaseUntil: null })
      }
    `,
    { id: f.jobId },
  );
  await f.run();
  assert.equal(f.launched[0].jobId, f.jobId);
});

test("cancellation while preparing the selected job never reserves it and retains the newer job", async (t) => {
  const oldest = await fixture(t, { createdAt: "1" });
  const newer = await fixture(t, { createdAt: "2" });
  newer.dependencies.syncQueuedCheck = async (jobId) => {
    assert.equal(jobId, oldest.jobId);
    await updateJob(jobId, "CANCELLED");
  };
  await assert.rejects(newer.run(), (error) => error.reason === "queue_pending");
  assert.equal((await oldest.state()).dispatch, null);
  assert.equal((await newer.state()).dispatch, null);
  assert.equal(newer.launched.length, 0);
  newer.dependencies.syncQueuedCheck = async () => {};
  await newer.run();
  assert.equal(newer.launched[0].jobId, newer.jobId);
});

test("another notification recovers a reservation whose recovery task could not be enqueued", async (t) => {
  const oldest = await fixture(t, { createdAt: "1" });
  const newer = await fixture(t, { createdAt: "2" });
  const enqueue = newer.dependencies.enqueueRecovery;
  newer.dependencies.enqueueRecovery = async () => {
    throw new Error("queue unavailable");
  };
  await assert.rejects(newer.run(), /queue unavailable/);
  const reservation = (await oldest.state()).dispatch;
  assert.ok(reservation);
  newer.dependencies.enqueueRecovery = enqueue;
  assert.equal(await newer.run(), true);
  assert.equal(newer.launched[0].id, reservation.id);
  assert.equal((await store.active()).length, 1);
  assert.equal((await newer.state()).dispatch, null);
});

test("concurrent jobs cannot reserve the same final slot", async (t) => {
  const first = await fixture(t, { createdAt: "1" }),
    second = await fixture(t, { createdAt: "2" });
  const results = await Promise.allSettled([first.run(), second.run()]);
  for (const result of results) {
    if (result.status === "rejected") assert.ok(result.reason instanceof DispatchRetry);
  }
  assert.equal(first.launched.length + second.launched.length, 1);
  assert.equal((await store.active()).length, 1);
  assert.ok((await first.state()).dispatch);
  assert.equal((await second.state()).dispatch, null);
  await assert.rejects(second.run(), (error) => error.reason === "capacity_unavailable");
});

test("initialization preserves a live lease and a replaced owner cannot reserve or release", async (t) => {
  const f = await fixture(t);
  assert.equal(await store.acquireScheduler("first"), true);
  assert.equal(await store.acquireScheduler("second"), false);
  await graphql(`
    mutation Expire {
      buildDispatchScheduler_update(id: "orchard", data: { leaseUntil: "2000-01-01T00:00:00Z" })
    }
  `);
  assert.equal(await store.acquireScheduler("second"), true);
  await store.releaseScheduler("first");
  assert.equal(await store.acquireScheduler("third"), false);
  const dispatch = { id: randomUUID(), jobId: f.jobId, vmName: randomUUID(), ...configuration };
  await assert.rejects(store.reserve("first", dispatch));
  assert.equal((await f.state()).dispatch, null);
  await store.reserve("second", dispatch);
  await assert.rejects(
    store.reserve("second", { ...dispatch, id: randomUUID(), vmName: randomUUID() }),
  );
  assert.equal((await store.active()).length, 1);
});

test("a reservation commit with a lost response is reconciled without a second slot", async (t) => {
  const f = await fixture(t);
  f.dependencies.store = overrideStore({
    reserve: async (...args) => {
      await store.reserve(...args);
      throw new Error("lost response");
    },
  });
  await f.run();
  assert.equal(f.launched.length, 1);
  assert.equal((await store.active()).length, 1);
});

test("recovery enqueue failure prevents launch and the existing reservation is reusable", async (t) => {
  const f = await fixture(t);
  const enqueue = f.dependencies.enqueueRecovery;
  f.dependencies.enqueueRecovery = async () => {
    throw new Error("queue unavailable");
  };
  await assert.rejects(f.run());
  const first = (await f.state()).dispatch;
  assert.ok(first);
  assert.equal(f.launched.length, 0);
  f.dependencies.enqueueRecovery = enqueue;
  await f.run();
  assert.equal(f.launched[0].id, first.id);
});

test("ambiguous launch retries the same dispatch, but duplicate containers have one winner", async (t) => {
  const f = await fixture(t);
  const launch = f.dependencies.launch;
  f.dependencies.launch = async (dispatch) => {
    await launch(dispatch);
    throw new Error("lost response");
  };
  await assert.rejects(f.run());
  const { dispatch } = await f.state();
  await assert.rejects(f.run(), (error) => error.reason === "launch_busy");
  assert.equal(f.launched.length, 1);
  await updateDispatch(dispatch.id, { launchLeaseUntil: past });
  f.dependencies.launch = launch;
  await f.run();
  assert.deepEqual(
    f.launched.map((item) => item.id),
    [dispatch.id, dispatch.id],
  );
  const results = await Promise.all([claim(dispatch.id), claim(dispatch.id), claim(dispatch.id)]);
  assert.deepEqual(results.map((result) => result.data.acquired).sort(), [0, 0, 1]);
  await f.run();
  assert.equal(f.launched.length, 2);
});

test("a saved operation with a lost acknowledgement does not cause another launch", async (t) => {
  const f = await fixture(t);
  f.dependencies.store = overrideStore({
    recordLaunch: async (...args) => {
      await store.recordLaunch(...args);
      throw new Error("lost response");
    },
  });
  await assert.rejects(f.run());
  assert.equal((await f.state()).dispatch.operationName, operation);
  await f.run();
  assert.equal(f.launched.length, 1);
});

test("an expired unclaimed attempt is replaced and cannot claim the new reservation", async (t) => {
  const f = await fixture(t);
  await f.run();
  const old = (await f.state()).dispatch;
  await updateDispatch(old.id, { startDeadline: past });
  await f.run();
  const current = (await f.state()).dispatch;
  assert.notEqual(current.id, old.id);
  assert.equal((await claim(old.id)).data.acquired, 0);
  assert.equal(
    (await sdk.getBuildExecution(dc, { id: old.id, jobId: f.jobId, runId: `run-${old.id}` })).data
      .dispatch.state,
    "expired",
  );
  assert.equal((await claim(current.id)).data.acquired, 1);
  assert.equal((await store.active()).length, 1);
});

test("claimed work does not expire through unstarted dispatch recovery", async (t) => {
  const f = await fixture(t);
  await f.run();
  const { dispatch } = await f.state();
  assert.equal((await claim(dispatch.id, randomUUID())).data.acquired, 1);
  await updateDispatch(dispatch.id, { startDeadline: past });
  await store.expireUnstarted();
  assert.equal((await f.state()).dispatch.id, dispatch.id);
  assert.equal((await store.active()).length, 1);
});

test("cancellation releases unstarted reservations and prevents a late executor", async (t) => {
  const f = await fixture(t);
  await f.run();
  const { dispatch } = await f.state();
  await updateJob(f.jobId, "CANCELLED");
  await f.run();
  assert.equal((await f.state()).dispatch, null);
  assert.equal(f.launched.length, 1);
  await assert.rejects(claim(dispatch.id));
  for (const input of [
    { status: "IN_PROGRESS" },
    { status: "SUCCESS" },
    { runsOn: "ubuntu-latest" },
  ]) {
    const skipped = await fixture(t, input);
    skipped.dependencies.snapshot = async () => {
      throw new Error("must not check capacity");
    };
    await skipped.run();
    assert.equal(skipped.launched.length, 0);
  }
  assert.equal(await dispatchBuildJob(f.dependencies), false);
});

test("end users cannot inspect capacity reservations, acquire execution, or release work", async (t) => {
  const f = await fixture(t);
  await f.run();
  const { dispatch } = await f.state();
  for (const impersonate of [
    { unauthenticated: true },
    { authClaims: { sub: "user", firebase: { sign_in_provider: "password" } } },
  ]) {
    const options = { impersonate };
    await assert.rejects(sdk.getBuildDispatchState(dc, { jobId: f.jobId }, options));
    await assert.rejects(sdk.getActiveBuildDispatches(dc, options));
    await assert.rejects(
      sdk.getBuildExecution(
        dc,
        { id: dispatch.id, jobId: f.jobId, runId: `run-${dispatch.id}` },
        options,
      ),
    );
    await assert.rejects(sdk.initializeBuildDispatchScheduler(dc, options));
    await assert.rejects(sdk.acquireBuildDispatchScheduler(dc, { owner: "user" }, options));
    await assert.rejects(
      sdk.acquireBuildDispatchLaunch(dc, { id: dispatch.id, owner: "user" }, options),
    );
    await assert.rejects(
      sdk.claimBuildJobExecution(
        dc,
        { id: dispatch.id, executorId: "user", executionName: "user" },
        options,
      ),
    );
    await assert.rejects(
      sdk.completeBuildExecution(dc, { id: dispatch.id, jobId: f.jobId, owner: "user" }, options),
    );
    await assert.rejects(sdk.expireUnstartedBuildDispatches(dc, options));
    await assert.rejects(sdk.cancelUnstartedBuildDispatch(dc, { jobId: f.jobId }, options));
  }
});
