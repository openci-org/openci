import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";
import { after, beforeEach, test } from "node:test";
import { deleteApp, initializeApp } from "firebase-admin/app";
import { getDataConnect } from "firebase-admin/data-connect";
import * as sdk from "@openci/dispatch-admin";
import { DataConnectDispatchStore } from "../../lib/functions/dispatch_store.js";

const host = process.env.DATA_CONNECT_EMULATOR_HOST;
assert.match(host ?? "", /^(127\.0\.0\.1|localhost):\d+$/, "Start the SQL Connect emulator first");
const service = `http://${host}/v1/projects/demo-openci/locations/asia-northeast1/services/openci-b1b91-service`;
const app = initializeApp({ projectId: "demo-openci" });
const dc = getDataConnect(sdk.connectorConfig, app);
const store = new DataConnectDispatchStore(dc);
after(() => deleteApp(app));

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
  await graphql(`
    mutation Reset {
      buildDispatchScheduler_upsert(
        data: {
          id: "orchard"
          owner: null
          leaseUntil: null
          retryTaskId: null
          retryScheduleTime: null
        }
      )
    }
  `);
});

async function jobs(t, count = 1) {
  const rows = Array.from({ length: count }, (_, index) => ({
    id: randomUUID(),
    status: "QUEUED",
    runsOn: "macos-latest",
    owner: "org",
    repo: "app",
    workflowName: "Test",
    workflowFileName: "test.dart",
    createdAt: String(index + 1),
    updatedAt: "1",
  }));
  const ids = rows.map((job) => job.id);
  t.after(() =>
    graphql(
      `
        mutation Cleanup($ids: [String!]!) {
          buildJobDispatch_deleteMany(where: { jobId: { in: $ids } })
          buildJob_deleteMany(where: { id: { in: $ids } })
        }
      `,
      { ids },
    ),
  );
  await graphql(
    `
      mutation Seed($rows: [BuildJob_Data!]!) {
        buildJob_insertMany(data: $rows)
      }
    `,
    { rows },
  );
  return ids;
}

async function updateJob(id, data) {
  await graphql(
    `
      mutation Alter($id: String!, $data: BuildJob_Data!) {
        buildJob_update(id: $id, data: $data)
      }
    `,
    { id, data },
  );
}

async function trackedJobs(ids) {
  return (
    await graphql(
      `
        query Tracked($ids: [String!]!) {
          jobs: buildJobs(where: { id: { in: $ids } }, limit: null) {
            id
            dispatchRetryPending
          }
        }
      `,
      { ids },
    )
  ).jobs;
}

test("100 concurrent waiting jobs reserve one retry without changing the allocation lease", async (t) => {
  const ids = await jobs(t, 100);
  assert.equal(await store.acquireScheduler("allocator"), true);
  const start = Date.now();
  const retries = await Promise.all(ids.map((jobId) => store.reserveRetry(randomUUID(), jobId)));
  assert.equal(new Set(retries.map((retry) => retry.taskId)).size, 1);
  assert.equal(new Set(retries.map((retry) => retry.scheduleTime.getTime())).size, 1);
  assert.ok(retries[0].scheduleTime.getTime() >= start + 60_000);
  assert.ok(retries[0].scheduleTime.getTime() <= Date.now() + 60_000);
  assert.ok((await trackedJobs(ids)).every((job) => job.dispatchRetryPending));
  await sdk.initializeBuildDispatchScheduler(dc);
  assert.deepEqual(await store.reserveRetry("another-producer"), retries[0]);
  assert.equal(await store.acquireScheduler("competitor"), false);
  await store.releaseScheduler("allocator");
  assert.equal(await store.acquireScheduler("competitor"), true);
});

test("consumption permits a fresh retry and a stale redelivery cannot clear its successor", async () => {
  const first = await store.reserveRetry("first");
  await store.consumeRetry("unrelated-notification");
  assert.deepEqual(await store.reserveRetry("ignored"), first);
  await store.consumeRetry("first");
  const second = await store.reserveRetry("second");
  assert.equal(second.taskId, "second");
  await store.consumeRetry("first");
  assert.deepEqual(await store.reserveRetry("ignored-again"), second);
  await store.consumeRetry("second");
  assert.equal((await store.reserveRetry("third")).taskId, "third");
});

test("generic retries do not mark every job and invalid task identities roll back registration", async (t) => {
  const ids = await jobs(t, 2);
  const retry = await store.reserveRetry("shared");
  assert.ok((await trackedJobs(ids)).every((job) => !job.dispatchRetryPending));
  await assert.rejects(store.reserveRetry("invalid/id", ids[0]));
  assert.ok((await trackedJobs(ids)).every((job) => !job.dispatchRetryPending));
  assert.deepEqual(await store.reserveRetry("another"), retry);
  assert.ok(ids.includes((await store.pendingWork()).queuedJob.id));
});

test("pending work retains a leased last job and only hands off tracked status changes", async (t) => {
  const [waiting, historical] = await jobs(t, 2);
  await updateJob(historical, { status: "CANCELLED" });
  await updateJob(waiting, { checkLeaseUntil: "2099-01-01T00:00:00Z" });
  assert.equal(await store.oldestQueued(), null);
  assert.deepEqual(await store.pendingWork(), { queuedJob: { id: waiting }, changedJob: null });
  await store.reserveRetry("shared", waiting);
  await updateJob(waiting, { status: "CANCELLED" });
  assert.deepEqual(await store.pendingWork(), {
    queuedJob: null,
    changedJob: { id: waiting, status: "CANCELLED" },
  });
  // If the job is queued again during handoff, its cancellation marker must stay.
  await updateJob(waiting, { status: "QUEUED" });
  await store.completeRetryJob(waiting);
  assert.equal((await trackedJobs([waiting]))[0].dispatchRetryPending, true);
  await updateJob(waiting, { status: "CANCELLED" });
  await store.completeRetryJob(waiting);
  assert.deepEqual(await store.pendingWork(), { queuedJob: null, changedJob: null });
});

test("a cancellation racing retry registration is still tracked for check completion", async (t) => {
  const [jobId] = await jobs(t);
  await updateJob(jobId, { status: "CANCELLED" });
  await store.reserveRetry("shared", jobId);
  assert.equal((await store.pendingWork()).changedJob.id, jobId);
});

test("reserving execution transfers responsibility from the shared retry to startup recovery", async (t) => {
  const [jobId] = await jobs(t);
  await store.reserveRetry("shared", jobId);
  assert.equal(await store.acquireScheduler("allocator"), true);
  await store.reserve("allocator", {
    id: randomUUID(),
    jobId,
    vmName: randomUUID(),
    cpu: 2,
    memoryMiB: 4096,
    image: "base-macos",
    cloudRunJob: "projects/demo-openci/locations/asia-northeast1/jobs/build-executor",
  });
  assert.equal((await trackedJobs([jobId]))[0].dispatchRetryPending, false);
  // A queued startup still keeps a shared fallback alive if it is the last job.
  assert.equal((await store.pendingWork()).queuedJob.id, jobId);
});

test("end users cannot inspect pending jobs or alter the shared retry", async (t) => {
  const [jobId] = await jobs(t);
  for (const impersonate of [
    { unauthenticated: true },
    { authClaims: { sub: "user", firebase: { sign_in_provider: "password" } } },
  ]) {
    const options = { impersonate };
    await assert.rejects(sdk.reserveBuildDispatchRetry(dc, { taskId: "user", jobId }, options));
    await assert.rejects(sdk.consumeBuildDispatchRetry(dc, { taskId: "user" }, options));
    await assert.rejects(sdk.getPendingBuildDispatchWork(dc, options));
    await assert.rejects(sdk.completeBuildDispatchRetryJob(dc, { jobId }, options));
  }
});
