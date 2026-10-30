import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";
import { after, beforeEach, test } from "node:test";
import { deleteApp, initializeApp } from "firebase-admin/app";
import { getDataConnect } from "firebase-admin/data-connect";
import * as sdk from "@openci/dispatch-admin";
import { dispatchBuildJob, DispatchRetry } from "../../lib/functions/build_dispatch.js";
import { DataConnectDispatchStore } from "../../lib/functions/dispatch_store.js";

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

async function fixture(t, { status = "QUEUED", runsOn = "macos-latest" } = {}) {
  const jobId = randomUUID();
  await graphql(
    `
      mutation Seed($id: String!, $status: String!, $runsOn: String!) {
        buildJob_insert(
          data: {
            id: $id
            status: $status
            runsOn: $runsOn
            owner: "org"
            repo: "app"
            workflowName: "Test"
            workflowFileName: "test.dart"
            createdAt: 1
            updatedAt: 1
          }
        )
      }
    `,
    { id: jobId, status, runsOn },
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
    run: () => dispatchBuildJob(jobId, dependencies),
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

test("concurrent jobs cannot reserve the same final slot", async (t) => {
  const first = await fixture(t),
    second = await fixture(t);
  const results = await Promise.allSettled([first.run(), second.run()]);
  assert.equal(results.filter((result) => result.status === "fulfilled").length, 1);
  const rejected = results.find((result) => result.status === "rejected");
  assert.ok(rejected.reason instanceof DispatchRetry);
  assert.equal(first.launched.length + second.launched.length, 1);
  assert.equal((await store.active()).length, 1);
  const waiting = first.launched.length ? second : first;
  await assert.rejects(waiting.run(), (error) => error.reason === "capacity_unavailable");
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
  assert.equal((await sdk.getBuildJobDispatch(dc, { id: old.id })).data.dispatch.state, "expired");
  assert.equal((await claim(current.id)).data.acquired, 1);
  assert.equal((await store.active()).length, 1);
});

test("claimed work never expires and only its owner can release a finalized build", async (t) => {
  const f = await fixture(t);
  await f.run();
  const { dispatch } = await f.state();
  const executorId = randomUUID();
  assert.equal((await claim(dispatch.id, executorId)).data.acquired, 1);
  await updateDispatch(dispatch.id, { startDeadline: past });
  await store.expireUnstarted();
  assert.equal((await f.state()).dispatch.id, dispatch.id);
  const finish = { id: dispatch.id, jobId: f.jobId, executorId };
  await assert.rejects(sdk.finishBuildJobDispatch(dc, finish));
  await updateJob(f.jobId, "IN_PROGRESS");
  await assert.rejects(sdk.finishBuildJobDispatch(dc, finish));
  await updateJob(f.jobId, "WAITING");
  await assert.rejects(sdk.finishBuildJobDispatch(dc, finish));
  await updateJob(f.jobId, "SUCCESS");
  await assert.rejects(sdk.finishBuildJobDispatch(dc, { ...finish, executorId: "other" }));
  await assert.rejects(sdk.finishBuildJobDispatch(dc, { ...finish, jobId: "other" }));
  await sdk.finishBuildJobDispatch(dc, finish);
  await sdk.finishBuildJobDispatch(dc, finish);
  assert.equal((await f.state()).dispatch, null);
  const next = await fixture(t);
  await next.run();
  assert.equal(next.launched.length, 1);
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
  await dispatchBuildJob(randomUUID(), f.dependencies);
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
    await assert.rejects(sdk.getBuildJobDispatch(dc, { id: dispatch.id }, options));
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
      sdk.finishBuildJobDispatch(
        dc,
        { id: dispatch.id, jobId: f.jobId, executorId: "user" },
        options,
      ),
    );
    await assert.rejects(sdk.expireUnstartedBuildDispatches(dc, options));
    await assert.rejects(sdk.cancelUnstartedBuildDispatch(dc, { jobId: f.jobId }, options));
  }
});
