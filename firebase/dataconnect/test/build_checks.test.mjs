import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";
import { after, test } from "node:test";
import { deleteApp, getApps, initializeApp } from "firebase-admin/app";
import * as sdk from "@openci/dispatch-admin";
import { isolatedConnector } from "../../lib/functions/executor/store.js";
import { QueuedChecks, QueuedCheckStore } from "../../lib/functions/queued_checks.js";

const host = process.env.DATA_CONNECT_EMULATOR_HOST;
assert.match(host ?? "", /^(127\.0\.0\.1|localhost):\d+$/);
const service = `http://${host}/v1/projects/demo-openci/locations/asia-northeast1/services/openci-b1b91-service`;
const dc = isolatedConnector(sdk.connectorConfig, initializeApp({ projectId: "demo-openci" }));
const store = new QueuedCheckStore(dc);
after(() => Promise.all(getApps().map(deleteApp)));

async function graphql(query, variables) {
  const response = await fetch(`${service}:executeGraphql`, {
    method: "POST",
    headers: { "content-type": "application/json" },
    body: JSON.stringify({ query, variables }),
    signal: AbortSignal.timeout(15000),
  });
  const result = await response.json();
  assert.ok(response.ok && !result.errors?.length, JSON.stringify(result));
  return result.data;
}

async function fixture(t) {
  const jobId = randomUUID(),
    teamId = randomUUID();
  await graphql(
    `
      mutation Seed($jobId: String!, $teamId: String!) @transaction {
        team_insert(data: { id: $teamId, name: "Check test", createdAt: 1, updatedAt: 1 })
        gitHubConnection_insert(
          data: {
            id: $teamId
            teamId: $teamId
            githubApiBaseUrl: "https://api.github.com"
            githubAppId: 1
            installationId: 2
            accountId: 10
            accountType: "Organization"
            accountLogin: "org"
            verifiedByUserId: "user"
            verifiedByGitHubUserId: 11
            verifiedAt: 1
            status: "active"
          }
        )
        buildJob_insert(
          data: {
            id: $jobId
            teamId: $teamId
            status: "QUEUED"
            runsOn: "macos-latest"
            owner: "org"
            repo: "app"
            workflowName: "CI"
            workflowFileName: "ci.dart"
            commitSha: "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa"
            installationId: "2"
            githubBaseUrl: "https://github.com"
            runCount: 0
            createdAt: 1
            updatedAt: 1
          }
        )
      }
    `,
    { jobId, teamId },
  );
  t.after(() =>
    graphql(
      `
        mutation Cleanup($jobId: String!, $teamId: String!) @transaction {
          buildJobDispatch_deleteMany(where: { jobId: { eq: $jobId } })
          buildJob_delete(id: $jobId)
          team_delete(id: $teamId)
        }
      `,
      { jobId, teamId },
    ),
  );
  const remote = new Map(),
    calls = [];
  let afterWrite = async () => {};
  const github = {
    options: { appId: "1", apiBaseUrl: "https://api.github.com" },
    queuedCheck: async (job, externalId, savedId, accountId) => {
      assert.equal(accountId, "10");
      const id = savedId ?? remote.get(externalId) ?? String(remote.size + 100);
      remote.set(externalId, id);
      calls.push({ status: job.status, id, externalId });
      await afterWrite();
      return id;
    },
  };
  const checks = new QueuedChecks(store, github);
  const alter = (data) =>
    graphql(
      "mutation Alter($jobId: String!, $data: BuildJob_Data!) { buildJob_update(id: $jobId, data: $data) }",
      { jobId, data },
    );
  const reserve = async () => {
    const id = randomUUID();
    await sdk.initializeBuildDispatchScheduler(dc);
    assert.equal((await sdk.acquireBuildDispatchScheduler(dc, { owner: id })).data.acquired, 1);
    try {
      await sdk.reserveBuildJobDispatch(dc, {
        owner: id,
        id,
        jobId,
        vmName: `openci-${id}`,
        cpu: 2,
        memoryMiB: 4096,
        image: "base-macos",
        cloudRunJob: "projects/demo-openci/locations/asia-northeast1/jobs/executor",
      });
      return (await sdk.getBuildDispatchState(dc, { jobId })).data.dispatch;
    } finally {
      await sdk.releaseBuildDispatchScheduler(dc, { owner: id });
    }
  };
  return {
    jobId,
    checks,
    alter,
    reserve,
    remote,
    calls,
    afterWrite: (fn) => {
      afterWrite = fn;
    },
  };
}

test("concurrent event deliveries publish one queued check and reservation inherits it", async (t) => {
  const f = await fixture(t);
  await Promise.allSettled(Array.from({ length: 5 }, () => f.checks.sync(f.jobId)));
  await f.checks.sync(f.jobId);
  assert.equal(f.remote.size, 1);
  assert.equal(f.calls.length, 1);
  const saved = (await store.read(f.jobId)).job;
  assert.equal(saved.checkRunId, "100");
  assert.equal(saved.checkRunNumber, "1");
  assert.equal(saved.checkOwner, null);
  const dispatch = await f.reserve();
  assert.equal(dispatch.checkRunId, "100");
  await f.checks.sync(f.jobId);
  await f.alter({ status: "IN_PROGRESS", runCount: "1" });
  await f.checks.sync(f.jobId);
  await f.alter({ status: "SUCCESS" });
  await f.checks.sync(f.jobId);
  assert.equal(f.calls.length, 1, "late delivery must not regress the check");
});

test("publication fences reservation and a lost GitHub response reconciles after lease expiry", async (t) => {
  const f = await fixture(t);
  f.afterWrite(async () => {
    throw new Error("lost response");
  });
  await assert.rejects(f.checks.sync(f.jobId), /lost response/);
  await assert.rejects(f.reserve());
  await assert.rejects(f.checks.sync(f.jobId));
  assert.equal(f.calls.length, 1);
  await f.alter({ checkLeaseUntil: new Date(0).toISOString() });
  f.afterWrite(async () => {});
  await f.checks.sync(f.jobId);
  assert.equal(f.remote.size, 1);
  assert.equal((await f.reserve()).checkRunId, "100");
});

test("cancellation racing check creation completes the saved check without launching", async (t) => {
  const f = await fixture(t);
  f.afterWrite(async () => {
    await f.alter({ status: "CANCELLED" });
  });
  await f.checks.sync(f.jobId);
  assert.deepEqual(
    f.calls.map(({ status, id }) => [status, id]),
    [
      ["QUEUED", "100"],
      ["CANCELLED", "100"],
    ],
  );
  assert.equal((await store.read(f.jobId)).job.checkRunId, "100");
  await assert.rejects(f.reserve());
});

test("cancelled jobs without checks are ignored and a new run receives a new identity", async (t) => {
  const f = await fixture(t);
  await f.alter({ status: "CANCELLED" });
  await f.checks.sync(f.jobId);
  assert.equal(f.calls.length, 0);
  await f.alter({ status: "QUEUED" });
  await f.checks.sync(f.jobId);
  await f.alter({ runCount: "1" });
  await f.checks.sync(f.jobId);
  assert.equal(f.remote.size, 2);
  assert.equal((await store.read(f.jobId)).job.checkRunNumber, "2");
  assert.equal((await f.reserve()).checkRunId, "101");
});

test("expired owners cannot record or release another publisher's check", async (t) => {
  const f = await fixture(t);
  await store.acquire(f.jobId, "old", "1");
  await f.alter({ checkLeaseUntil: new Date(0).toISOString() });
  await store.acquire(f.jobId, "new", "1");
  await assert.rejects(store.record(f.jobId, "old", "1", "999"));
  await store.release(f.jobId, "old");
  assert.equal((await store.read(f.jobId)).job.checkOwner, "new");
  await assert.rejects(f.reserve());
  await store.release(f.jobId, "new");
  await f.checks.sync(f.jobId);
  assert.equal((await f.reserve()).checkRunId, "100");
});
