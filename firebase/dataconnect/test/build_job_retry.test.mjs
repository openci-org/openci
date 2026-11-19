import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";
import { after, test } from "node:test";
import { deleteApp, getApps, initializeApp } from "firebase-admin/app";
import * as builds from "@openci/builds-admin";
import * as dispatch from "@openci/dispatch-admin";
import * as github from "@openci/github-admin";
import { ExecutionStore, isolatedConnector } from "../../lib/functions/executor/store.js";
import { QueuedChecks, QueuedCheckStore } from "../../lib/functions/queued_checks.js";

const host = process.env.DATA_CONNECT_EMULATOR_HOST;
assert.match(host ?? "", /^(127\.0\.0\.1|localhost):\d+$/, "Start the SQL Connect emulator first");
const service = `http://${host}/v1/projects/demo-openci/locations/asia-northeast1/services/openci-b1b91-service`;
const app = initializeApp({ projectId: "demo-openci" });
const dc = isolatedConnector(builds.connectorConfig, app);
const dispatchDc = isolatedConnector(dispatch.connectorConfig, app);
const githubDc = isolatedConnector(github.connectorConfig, app);
after(() => Promise.all(getApps().map(deleteApp)));
const asUser = (uid, provider = "password") => ({
  impersonate: { authClaims: { uid, sub: uid, firebase: { sign_in_provider: provider } } },
});

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

test("a comment retry uses the verified GitHub member and the same atomic retry as the dashboard", async (t) => {
  const f = await fixture(t);
  const store = new ExecutionStore(dispatchDc);
  const host = "https://api.github.com",
    appId = "1";
  const member = (actor, api = host) => store.retryMember(f.teamId, api, appId, actor);
  assert.equal(await member("11"), f.userId); // existing connection verifier
  assert.equal(await member("12"), null);
  assert.equal(await member("11", "https://example.test/api/v3"), null);
  await github.createGitHubConnectionSession(githubDc, {
    id: randomUUID(),
    teamId: f.teamId,
    userId: f.userId,
    githubUserId: "12",
    githubIssuer: host + ":1",
    referenceHash: randomUUID().replaceAll("-", "").repeat(2),
    accessTokenSecretVersionPath: "projects/demo-openci/secrets/test/versions/1",
  });
  assert.equal(await member("11"), null);
  assert.equal(await member("12"), f.userId);
  // A callback from the previous deployment has no host/App issuer.
  await github.createGitHubConnectionSession(githubDc, {
    id: randomUUID(),
    teamId: f.teamId,
    userId: f.userId,
    githubUserId: "13",
    referenceHash: randomUUID().replaceAll("-", "").repeat(2),
    accessTokenSecretVersionPath: "projects/demo-openci/secrets/test/versions/2",
  });
  assert.equal(await member("12"), f.userId);
  assert.equal(await member("13"), null);
  await assert.rejects(store.retryAsMember(f.id, 0, "not-a-member"));
  await store.retryAsMember(f.id, 0, f.userId);
  assert.equal((await f.state()).job.status, "QUEUED");
  await f.alter({ status: "FAILURE" });
  const race = await Promise.allSettled([store.retryAsMember(f.id, 1, f.userId), f.retry(1)]);
  assert.equal(race.filter((r) => r.status === "fulfilled").length, 1);
  assert.equal((await f.state()).job.retryCount, 2);
  await graphql("mutation($id: String!) { teamMember_deleteMany(where:{teamId:{eq:$id}}) }", {
    id: f.teamId,
  });
  assert.equal(await member("12"), null);
});

async function fixture(t, overrides = {}) {
  const id = randomUUID(),
    teamId = randomUUID(),
    userId = randomUUID();
  const runId = `previous-${id}`;
  const job = {
    id,
    teamId,
    status: "FAILURE",
    runsOn: "macos-latest",
    owner: "org",
    repo: "app",
    workflowName: "CI",
    workflowFileName: "ci.dart",
    commitSha: "a".repeat(40),
    branch: "main",
    installationId: "2",
    githubBaseUrl: "https://github.com",
    runCount: "1",
    latestRunId: runId,
    createdAt: "1",
    updatedAt: "2",
    completedAt: "2",
    failureSummary: "Previous failure",
    failureSummaryStatus: "completed",
    workerHost: "old-worker",
    vmName: "old-vm",
    checkRunId: "123",
    checkRunNumber: "1",
    supersededByTaskId: "old-webhook",
    webhookExecutionKey: id.replaceAll("-", "").repeat(2),
    ...overrides,
  };
  await graphql(
    `
      mutation Seed(
        $teamId: String!
        $userId: String!
        $job: BuildJob_Data!
        $runId: String!
        $jobId: String!
      ) @transaction {
        team_insert(data: { id: $teamId, name: "Retry test", createdAt: 1, updatedAt: 1 })
        teamMember_insert(data: { teamId: $teamId, userId: $userId })
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
            verifiedByUserId: $userId
            verifiedByGitHubUserId: 11
            verifiedAt: 1
            status: "active"
          }
        )
        buildJob_insert(data: $job)
        buildRun_insert(
          data: {
            id: $runId
            buildJobId: $jobId
            runNumber: 7
            status: "completed"
            conclusion: "failure"
            createdAt: 1
            updatedAt: 2
          }
        )
      }
    `,
    { teamId, userId, job, runId, jobId: id },
  );
  t.after(() =>
    graphql(
      `
        mutation Cleanup($id: String!, $teamId: String!) @transaction {
          buildJobDispatch_deleteMany(where: { jobId: { eq: $id } })
          buildJob_delete(id: $id)
          team_delete(id: $teamId)
        }
      `,
      { id, teamId },
    ),
  );
  return {
    id,
    teamId,
    userId,
    runId,
    original: job,
    retry: (expectedRetryCount = 0, options = asUser(userId)) =>
      builds.retryBuildJob(dc, { id, expectedRetryCount }, options),
    alter: (data) =>
      graphql(
        "mutation($id: String!, $data: BuildJob_Data!) { buildJob_update(id: $id, data: $data) }",
        { id, data },
      ),
    state: async () =>
      await graphql(
        `
          query ($id: String!, $runId: String!) {
            job: buildJob(id: $id) {
              id
              teamId
              status
              retryCount
              runCount
              latestRunId
              commitSha
              branch
              workflowFileName
              createdAt
              completedAt
              failureSummary
              failureSummaryStatus
              workerHost
              vmName
              checkRunId
              checkRunNumber
              checkOwner
              checkLeaseUntil
              supersededByTaskId
              webhookExecutionKey
            }
            run: buildRun(id: $runId) {
              id
              runNumber
              status
              conclusion
            }
          }
        `,
        { id, runId },
      ),
  };
}

for (const status of ["SUCCESS", "FAILURE", "CANCELLED", "TIMED_OUT"]) {
  test(`${status} retries preserve job identity, pinned revision and previous run`, async (t) => {
    const f = await fixture(t, { status });
    const before = await f.state();
    const result = (await f.retry()).data;
    assert.deepEqual(Object.keys(result).sort(), ["result", "retried"]);
    assert.equal(result.retried, 1);
    assert.deepEqual(result.result.job, {
      id: f.id,
      status: "QUEUED",
      retryCount: 1,
      runCount: "1",
      latestRunId: f.runId,
    });
    const after = await f.state();
    assert.deepEqual(after.run, before.run);
    for (const field of [
      "id",
      "teamId",
      "commitSha",
      "branch",
      "workflowFileName",
      "createdAt",
      "latestRunId",
      "runCount",
      "webhookExecutionKey",
    ])
      assert.equal(after.job[field], before.job[field], field);
    for (const field of [
      "completedAt",
      "failureSummary",
      "failureSummaryStatus",
      "workerHost",
      "vmName",
      "checkRunId",
      "checkRunNumber",
      "checkOwner",
      "checkLeaseUntil",
      "supersededByTaskId",
    ])
      assert.equal(after.job[field] ?? null, null, field);
    assert.equal(
      (await builds.getBuildJob(dc, { id: f.id }, asUser(f.userId))).data.job.retryCount,
      1,
    );
  });
}

test("nonmembers, anonymous callers, signed-out callers and deleted teams cannot retry", async (t) => {
  const f = await fixture(t);
  for (const options of [
    asUser("outsider"),
    asUser(f.userId, "anonymous"),
    { impersonate: { unauthenticated: true } },
  ])
    await assert.rejects(f.retry(0, options));
  await assert.rejects(
    builds.retryBuildJob(dc, { id: "missing", expectedRetryCount: 0 }, asUser(f.userId)),
  );
  assert.equal((await f.state()).job.status, "FAILURE");
  await graphql("mutation($id: String!) { team_delete(id: $id) }", { id: f.teamId });
  await assert.rejects(f.retry(), /Team access denied/);
  assert.equal((await f.state()).job.retryCount, 0);
});

test("disconnected repositories cannot re-enter the queue", async (t) => {
  const f = await fixture(t);
  await graphql(
    'mutation($id: String!) { gitHubConnection_update(id: $id, data: { status: "removed" }) }',
    { id: f.teamId },
  );
  await assert.rejects(f.retry(), /GitHub connection is inactive/);
  assert.equal((await f.state()).job.retryCount, 0);
});

test("repository-scoped connections must match and cannot bypass an explicit disconnect", async (t) => {
  const f = await fixture(t, { repositoryId: "101" });
  await graphql(
    "mutation($id: String!) { gitHubConnection_update(id: $id, data: { repositoryId: 102 }) }",
    { id: f.teamId },
  );
  await assert.rejects(f.retry(), /GitHub connection is inactive/);
  await graphql(
    "mutation($id: String!) { gitHubConnection_update(id: $id, data: { repositoryId: 101 }) }",
    { id: f.teamId },
  );
  await f.retry();
  await f.alter({ status: "FAILURE" });
  await graphql(
    `
      mutation ($id: String!, $teamId: String!) {
        gitHubConnection_update(id: $id, data: { status: "removed" })
        gitHubConnection_insert(
          data: {
            id_expr: "vars.id + '-legacy'"
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
      }
    `,
    { id: f.teamId, teamId: f.teamId },
  );
  await assert.rejects(f.retry(1), /GitHub connection is inactive/);
});

test("active, skipped and unsupported jobs are rejected without changes", async (t) => {
  const f = await fixture(t);
  for (const status of ["QUEUED", "IN_PROGRESS", "WAITING", "SKIPPED", "unknown"]) {
    await f.alter({ status });
    await assert.rejects(f.retry(), /not ready to retry/);
    assert.equal((await f.state()).job.status, status);
  }
  await f.alter({ status: "FAILURE", runsOn: "linux" });
  await assert.rejects(f.retry());
  await f.alter({ runsOn: "macos-latest" });
  await assert.rejects(f.retry(-1));
  await assert.rejects(f.retry(2147483647));
  assert.equal((await f.state()).job.retryCount, 0);
});

test("only one concurrent retry wins and an old request cannot retry a later failure", async (t) => {
  const f = await fixture(t, { runCount: "0", latestRunId: null });
  const results = await Promise.allSettled(Array.from({ length: 12 }, () => f.retry()));
  assert.equal(results.filter((result) => result.status === "fulfilled").length, 1);
  assert.equal((await f.state()).job.retryCount, 1);
  // A checkout rejection can finish without incrementing runCount.
  await f.alter({ status: "FAILURE" });
  await assert.rejects(f.retry(0), /not ready to retry/);
  assert.equal((await f.retry(1)).data.result.job.retryCount, 2);
  assert.equal((await f.state()).job.runCount, "0");
});

test("unfinished dispatches and active Check publication prevent requeue atomically", async (t) => {
  const f = await fixture(t, { status: "CANCELLED" });
  await graphql(
    `
      mutation ($id: String!, $teamId: String!) {
        buildJobDispatch_insert(
          data: {
            id: $id
            jobId: $id
            teamId: $teamId
            activeJobId: $id
            vmName: $id
            cpu: 2
            memoryMiB: 4096
            image: "base"
            cloudRunJob: "executor"
            state: "finishing"
            startDeadline_expr: "request.time"
            createdAt_expr: "request.time"
            updatedAt_expr: "request.time"
          }
        )
      }
    `,
    { id: f.id, teamId: f.teamId },
  );
  const before = await f.state();
  await assert.rejects(f.retry(), /still finishing/);
  assert.deepEqual(await f.state(), before);
  await graphql(
    'mutation($id: String!) { buildJobDispatch_update(id: $id, data: { activeJobId: null, finishedAt_expr: "request.time" }) }',
    { id: f.id },
  );
  await f.alter({
    checkOwner: "publisher",
    checkLeaseUntil: new Date(Date.now() + 300000).toISOString(),
  });
  await assert.rejects(f.retry(), /not ready to retry/);
  await f.alter({ checkLeaseUntil: new Date(Date.now() - 10000).toISOString() });
  await f.retry();
  assert.equal((await f.state()).job.checkOwner ?? null, null);
});

test("a retried job gets a fresh queued Check and the normal executor allocates its next run", async (t) => {
  const f = await fixture(t, { status: "CANCELLED", runCount: "0", latestRunId: null });
  await f.retry();
  const checks = new QueuedChecks(new QueuedCheckStore(dispatchDc), {
    options: { appId: "1", apiBaseUrl: "https://api.github.com" },
    queuedCheck: async (_job, externalId, savedId) => {
      assert.equal(externalId, `build-job:${f.id}:run:1:retry:1`);
      assert.equal(savedId, null);
      return "456";
    },
  });
  await checks.sync(f.id);
  const id = randomUUID(),
    executorId = randomUUID();
  const cloudRunJob = "projects/demo-openci/locations/asia-northeast1/jobs/build-executor";
  await dispatch.initializeBuildDispatchScheduler(dispatchDc);
  assert.equal(
    (await dispatch.acquireBuildDispatchScheduler(dispatchDc, { owner: id })).data.acquired,
    1,
  );
  await dispatch.reserveBuildJobDispatch(dispatchDc, {
    owner: id,
    id,
    jobId: f.id,
    vmName: id,
    cpu: 2,
    memoryMiB: 4096,
    image: "base",
    cloudRunJob,
  });
  await dispatch.releaseBuildDispatchScheduler(dispatchDc, { owner: id });
  const store = new ExecutionStore(dispatchDc);
  assert.equal(await store.claim(id, executorId, `${cloudRunJob}/executions/test`, 3600), true);
  const active = (await store.read(id, f.id)).dispatch;
  assert.equal(active.checkRunId, "456");
  assert.equal(await store.configure(active, executorId, true), 8);
  assert.equal(await store.configure(active, executorId, true), 8);
  const after = await f.state();
  assert.equal(after.job.status, "IN_PROGRESS");
  assert.equal(after.job.runCount, "1");
  assert.equal(after.job.latestRunId, `run-${id}`);
  assert.equal(after.run.conclusion, "failure");
});
