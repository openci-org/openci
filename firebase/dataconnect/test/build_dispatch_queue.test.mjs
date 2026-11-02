import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";
import { after, test } from "node:test";
import { deleteApp, initializeApp } from "firebase-admin/app";
import { getDataConnect } from "firebase-admin/data-connect";
import * as sdk from "@openci/dispatch-admin";

const host = process.env.DATA_CONNECT_EMULATOR_HOST;
assert.match(host ?? "", /^(127\.0\.0\.1|localhost):\d+$/, "Start the SQL Connect emulator first");
const service = `http://${host}/v1/projects/demo-openci/locations/asia-northeast1/services/openci-b1b91-service`;
const app = initializeApp({ projectId: "demo-openci" });
const dc = getDataConnect(sdk.connectorConfig, app);
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

async function seedJobs(t, overrides) {
  const prefix = randomUUID();
  const jobs = overrides.map((job) => ({
    status: "QUEUED",
    runsOn: "macos-latest",
    owner: "org",
    repo: "app",
    workflowName: "Test",
    workflowFileName: "test.dart",
    createdAt: "1",
    updatedAt: "1",
    ...job,
    id: `${prefix}-${job.id}`,
  }));
  t.after(() =>
    graphql(
      `
        mutation Cleanup($ids: [String!]!) {
          buildJobDispatch_deleteMany(where: { jobId: { in: $ids } })
          buildJob_deleteMany(where: { id: { in: $ids } })
        }
      `,
      { ids: jobs.map((job) => job.id) },
    ),
  );
  await graphql(
    `
      mutation Seed($jobs: [BuildJob_Data!]!) {
        buildJob_insertMany(data: $jobs)
      }
    `,
    { jobs },
  );
  return jobs;
}

async function seedDispatches(jobs, overrides = {}) {
  const dispatches = jobs.map((job) => {
    const id = randomUUID();
    return {
      id,
      jobId: job.id,
      activeJobId: job.id,
      vmName: `openci-${id}`,
      cpu: 2,
      memoryMiB: 4096,
      image: "base-macos",
      cloudRunJob: "projects/demo-openci/locations/asia-northeast1/jobs/build-executor",
      state: "reserved",
      startDeadline: "2099-01-01T00:00:00Z",
      createdAt: "2000-01-01T00:00:00Z",
      updatedAt: "2000-01-01T00:00:00Z",
      ...overrides,
    };
  });
  await graphql(
    `
      mutation Seed($dispatches: [BuildJobDispatch_Data!]!) {
        buildJobDispatch_insertMany(data: $dispatches)
      }
    `,
    { dispatches },
  );
  return dispatches;
}

async function oldestQueuedJob() {
  const { dispatches } = (await sdk.getBuildDispatchExclusions(dc)).data;
  return (
    await sdk.getOldestQueuedBuildJob(dc, {
      excludedJobIds: dispatches.map((dispatch) => dispatch.jobId),
    })
  ).data.job;
}

test("an empty dispatch queue returns no job", async () => {
  assert.equal(await oldestQueuedJob(), null);
});

test("the oldest creation time wins regardless of insertion order or later updates", async (t) => {
  const [, oldest] = await seedJobs(t, [
    { id: "a-newer", createdAt: "30" },
    { id: "z-oldest", createdAt: "10", updatedAt: "1000" },
    { id: "b-middle", createdAt: "20" },
  ]);
  assert.deepEqual(await oldestQueuedJob(), { id: oldest.id, createdAt: "10" });
  assert.deepEqual(await oldestQueuedJob(), { id: oldest.id, createdAt: "10" });
});

test("equal creation times use job ID order", async (t) => {
  const [, first] = await seedJobs(t, [{ id: "z" }, { id: "a" }, { id: "m" }]);
  assert.equal((await oldestQueuedJob()).id, first.id);
});

test("only queued macOS jobs without a live check publication lease are eligible", async (t) => {
  const jobs = await seedJobs(t, [
    { id: "cancelled", status: "CANCELLED" },
    { id: "running", status: "IN_PROGRESS" },
    { id: "success", status: "SUCCESS" },
    { id: "failed", status: "FAILURE" },
    { id: "timed-out", status: "TIMED_OUT" },
    { id: "linux", runsOn: "ubuntu-latest" },
    { id: "missing-runner", runsOn: null },
    { id: "publishing", checkLeaseUntil: "2099-01-01T00:00:00Z" },
    { id: "ready", createdAt: "2" },
  ]);
  const ready = jobs.at(-1);
  assert.equal((await oldestQueuedJob()).id, ready.id);
  await graphql(
    `
      mutation Cancel($id: String!) {
        buildJob_update(id: $id, data: { status: "CANCELLED" })
      }
    `,
    { id: ready.id },
  );
  assert.equal(await oldestQueuedJob(), null);
});

test("an expired check publication lease restores the original queue priority", async (t) => {
  const [oldest] = await seedJobs(t, [
    { id: "oldest", checkLeaseUntil: "2000-01-01T00:00:00Z" },
    { id: "newer", createdAt: "2" },
  ]);
  assert.equal((await oldestQueuedJob()).id, oldest.id);
});

test("reservations beyond the default query page are all excluded", async (t) => {
  const firstPage = await seedJobs(
    t,
    Array.from({ length: 100 }, (_, index) => ({ id: `reserved-${index}` })),
  );
  const lastPage = await seedJobs(t, [{ id: "last-reservation" }]);
  const reserved = [...firstPage, ...lastPage];
  const [waiting] = await seedJobs(t, [{ id: "waiting", createdAt: "2" }]);
  await seedDispatches(firstPage);
  await seedDispatches(lastPage);
  const { dispatches } = (await sdk.getBuildDispatchExclusions(dc)).data;
  assert.deepEqual(
    dispatches.map((dispatch) => dispatch.jobId).sort(),
    reserved.map((job) => job.id).sort(),
  );
  assert.equal((await oldestQueuedJob()).id, waiting.id);
});

test("recently blocked jobs defer to later jobs and regain priority after the retry interval", async (t) => {
  const [blocked, waiting] = await seedJobs(t, [
    { id: "blocked" },
    { id: "waiting", createdAt: "2" },
  ]);
  const [dispatch] = await seedDispatches([blocked], {
    state: "finished",
    activeJobId: null,
    outcome: "blocked",
    finishedAt: new Date().toISOString(),
  });
  assert.equal((await oldestQueuedJob()).id, waiting.id);
  await graphql(
    `
      mutation EndRetryInterval($id: String!) {
        buildJobDispatch_update(
          id: $id
          data: { finishedAt_expr: "request.time - duration('60s')" }
        )
      }
    `,
    { id: dispatch.id },
  );
  assert.deepEqual(await oldestQueuedJob(), { id: blocked.id, createdAt: "1" });
});

test("finished non-blocked attempts do not exclude a queued job", async (t) => {
  const [job] = await seedJobs(t, [{ id: "waiting" }]);
  await seedDispatches([job], {
    state: "finished",
    activeJobId: null,
    outcome: "success",
    finishedAt: new Date().toISOString(),
  });
  assert.equal((await oldestQueuedJob()).id, job.id);
});

test("dispatch queue reads reject unauthenticated and signed-in clients", async () => {
  for (const impersonate of [
    { unauthenticated: true },
    { authClaims: { sub: "user", firebase: { sign_in_provider: "password" } } },
  ]) {
    const options = { impersonate };
    await assert.rejects(sdk.getBuildDispatchExclusions(dc, options));
    await assert.rejects(sdk.getOldestQueuedBuildJob(dc, { excludedJobIds: [] }, options));
  }
});
