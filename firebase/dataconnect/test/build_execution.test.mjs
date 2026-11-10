import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";
import { after, test } from "node:test";
import { deleteApp, getApps, initializeApp } from "firebase-admin/app";
import * as dispatchSdk from "@openci/dispatch-admin";
import * as billingSdk from "@openci/billing-admin";
import * as logsSdk from "@openci/logs-admin";
import * as webhookSdk from "@openci/webhooks-admin";
import { ExecutionStore, isolatedConnector } from "../../lib/functions/executor/store.js";
import { ExecutionBilling } from "../../lib/functions/executor/billing.js";
import { ExecutionLogs } from "../../lib/functions/executor/logs.js";
import {
  executeBuild,
  recoverExecutions,
  cleanupExecution,
} from "../../lib/functions/executor/execute.js";
import { DataConnectDispatchStore } from "../../lib/functions/dispatch_store.js";
import { QueuedChecks, QueuedCheckStore } from "../../lib/functions/queued_checks.js";
import { cardFixture } from "./helpers/card_setup.mjs";
import { identity } from "../../lib/functions/executor/model.js";
import { PullRequestCheckoutError } from "../../lib/functions/executor/checkout_error.js";

const host = process.env.DATA_CONNECT_EMULATOR_HOST;
assert.match(host ?? "", /^(127\.0\.0\.1|localhost):\d+$/, "Start the SQL Connect emulator first");
const service = `http://${host}/v1/projects/demo-openci/locations/asia-northeast1/services/openci-b1b91-service`;
const app = initializeApp({ projectId: "demo-openci" });
const dc = isolatedConnector(dispatchSdk.connectorConfig, app);
const billingDc = isolatedConnector(billingSdk.connectorConfig, app);
const logsDc = isolatedConnector(logsSdk.connectorConfig, app);
const webhookDc = isolatedConnector(webhookSdk.connectorConfig, app);
const store = new ExecutionStore(dc);
const billing = new ExecutionBilling(billingDc);
after(async () => {
  await Promise.all(getApps().map(deleteApp));
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
test("QR comment publishers hold an exclusive, recoverable lease per workflow", async (t) => {
  const id = randomUUID();
  const a = { id, owner: randomUUID() },
    b = { id, owner: randomUUID() };
  t.after(() =>
    graphql(
      "mutation Cleanup($id: String!) { pullRequestQrCommentLease_deleteMany(where: {id: {eq: $id}}) }",
      { id },
    ),
  );
  const claimed = await Promise.all(
    [a, b].map((who) => dispatchSdk.claimPullRequestQrComment(dc, who)),
  );
  assert.deepEqual(claimed.map((r) => r.data.acquired).sort(), [0, 1]);
  const [holder, waiter] = claimed[0].data.acquired === 1 ? [a, b] : [b, a];
  assert.equal((await dispatchSdk.renewPullRequestQrComment(dc, holder)).data.renewed, 1);
  assert.equal((await dispatchSdk.releasePullRequestQrComment(dc, waiter)).data.released, 0);
  assert.equal((await dispatchSdk.claimPullRequestQrComment(dc, waiter)).data.acquired, 0);
  await graphql(
    'mutation Expire($id: String!) { pullRequestQrCommentLease_update(id: $id, data: {leaseUntil: "2000-01-01T00:00:00Z"}) }',
    { id },
  );
  assert.equal((await dispatchSdk.renewPullRequestQrComment(dc, holder)).data.renewed, 0);
  assert.equal((await dispatchSdk.claimPullRequestQrComment(dc, waiter)).data.acquired, 1);
  assert.equal((await dispatchSdk.releasePullRequestQrComment(dc, holder)).data.released, 0);
  assert.equal((await dispatchSdk.releasePullRequestQrComment(dc, waiter)).data.released, 1);
});
test("overlapping Cloud Run writers wait for each other and release the QR slot", async () => {
  const id = randomUUID();
  let writers = 0,
    completed = 0;
  const write = async (renew) => {
    assert.equal(++writers, 1);
    await renew();
    await new Promise((resolve) => setTimeout(resolve, 30));
    writers--;
    completed++;
  };
  const signal = AbortSignal.timeout(10000);
  await Promise.all([
    store.withQrCommentLease(id, signal, write),
    store.withQrCommentLease(id, signal, write),
  ]);
  assert.equal(completed, 2);
  const data = await graphql(
    "query Lease($id: String!) { pullRequestQrCommentLease(id: $id) { id } }",
    { id },
  );
  assert.equal(data.pullRequestQrCommentLease ?? null, null);
});

async function alterDispatch(id, data) {
  await graphql(
    "mutation Alter($id: String!, $data: BuildJobDispatch_Data!) { buildJobDispatch_update(id: $id, data: $data) }",
    { id, data },
  );
}
async function alterJob(id, data) {
  await graphql(
    "mutation Alter($id: String!, $data: BuildJob_Data!) { buildJob_update(id: $id, data: $data) }",
    { id, data },
  );
}

async function seedTeam(t) {
  const teamId = randomUUID();
  const installationId = String(Math.floor(Math.random() * 1000000000) + 1);
  await graphql(
    `
      mutation SeedTeam($teamId: String!, $installationId: Int64!) @transaction {
        team_insert(data: { id: $teamId, name: "Executor test", createdAt: 1, updatedAt: 1 })
        gitHubConnection_insert(
          data: {
            id: $teamId
            teamId: $teamId
            githubApiBaseUrl: "https://api.github.com"
            githubAppId: 1
            installationId: $installationId
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
    { teamId, installationId },
  );
  t.after(() =>
    graphql(
      `
        mutation CleanupTeam($teamId: String!) @transaction {
          billingAccount_deleteMany(where: { teamId: { eq: $teamId } })
          team_delete(id: $teamId)
        }
      `,
      { teamId },
    ),
  );
  return { teamId, installationId };
}

async function fixture(t, queuedCheck = false, team) {
  const { teamId, installationId } = team ?? (await seedTeam(t));
  const jobId = randomUUID(),
    id = randomUUID();
  await graphql(
    `
      mutation SeedJob($teamId: String!, $jobId: String!, $installationText: String!) {
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
            installationId: $installationText
            githubBaseUrl: "https://github.com"
            runCount: 0
            createdAt: 1
            updatedAt: 1
          }
        )
      }
    `,
    { teamId, jobId, installationText: installationId },
  );
  t.after(() =>
    graphql(
      `
        mutation CleanupJob($jobId: String!) @transaction {
          buildJobDispatch_deleteMany(where: { jobId: { eq: $jobId } })
          buildJob_delete(id: $jobId)
        }
      `,
      { jobId },
    ),
  );
  if (queuedCheck) await alterJob(jobId, { checkRunId: "123", checkRunNumber: "1" });
  await dispatchSdk.initializeBuildDispatchScheduler(dc);
  assert.equal(
    (await dispatchSdk.acquireBuildDispatchScheduler(dc, { owner: id })).data.acquired,
    1,
  );
  const cloudRunJob = "projects/demo-openci/locations/asia-northeast1/jobs/build-executor";
  await dispatchSdk.reserveBuildJobDispatch(dc, {
    owner: id,
    id,
    jobId,
    vmName: `openci-${id}`,
    cpu: 2,
    memoryMiB: 4096,
    image: "base-macos",
    cloudRunJob,
  });
  await dispatchSdk.releaseBuildDispatchScheduler(dc, { owner: id });
  const calls = [],
    checks = [],
    reports = [];
  const configuration = {
    cloudRunJob,
    timeoutSeconds: 3600,
    livemode: false,
    complimentary: new Set([teamId]),
  };
  const input = {
    dispatchId: id,
    jobId,
    executionName: `${cloudRunJob}/executions/build-executor-test`,
  };
  const scripts = [];
  const dependencies = {
    store,
    billing,
    configuration,
    github: {
      options: { appId: "1", apiBaseUrl: "https://api.github.com", baseUrl: "https://github.com" },
      resolveCheckoutCommit: async (job) => job.commitSha,
      checkout: async () => ({
        token: "checkout-token",
        cloneUrl: "https://github.com/org/app.git",
        revoke: async () => {
          calls.push("revoke");
        },
      }),
      check: async (_job, _dispatch, outcome) => {
        checks.push(outcome ?? "in_progress");
        return "123";
      },
    },
    orchard: {
      vmNames: async () => [],
      create: async () => {
        calls.push("create");
      },
      ready: async () => {
        calls.push("ready");
      },
      remove: async () => {
        calls.push("remove");
      },
      exec: async (_vm, script, output) => {
        scripts.push(script);
        calls.push(scripts.length === 1 ? "checkout" : "workflow");
        await output(
          "stdout",
          Buffer.from(
            scripts.length === 1 ? "checkout-token\nchecked out\n" : "workflow-secret\nfinished\n",
          ),
        );
        return 0;
      },
    },
    logs: (dispatch) => new ExecutionLogs(logsDc, teamId, dispatch.runId),
    secrets: async () => ({ TOKEN: "workflow-secret" }),
    stopExecution: async () => {
      calls.push("stop-cloud-run");
    },
    report: (reason) => {
      reports.push(reason);
    },
  };
  return {
    id,
    jobId,
    teamId,
    input,
    dependencies,
    calls,
    scripts,
    checks,
    reports,
    run: (signal) => executeBuild(input, dependencies, signal),
    state: () => store.read(id, jobId),
    billingState: () =>
      billingSdk
        .getBillingExecution(billingDc, { teamId, runId: `run-${id}` })
        .then((r) => r.data.billingExecution),
    claim: async () => {
      const executorId = randomUUID();
      assert.equal(await store.claim(id, executorId, input.executionName, 3600), true);
      return executorId;
    },
  };
}

async function started(f) {
  const executorId = await f.claim();
  const dispatch = (await f.state()).dispatch;
  const context = await store.context(
    f.teamId,
    (await f.state()).job.installationId,
    "1",
    "https://api.github.com",
  );
  const periodId = await billing.period(context, f.teamId, false, new Set([f.teamId]));
  await billing.admit(dispatch, periodId);
  await store.configure(dispatch, executorId);
  await billing.start(dispatch);
  return { dispatch, executorId };
}

async function prepareSupersedingRevision(t, f, closed = false) {
  const taskId = randomUUID(),
    planningId = randomUUID(),
    token = randomUUID(),
    newJobId = randomUUID();
  await alterJob(f.jobId, { cancelPreviousRuns: !closed, pullRequestNumber: "7" });
  await graphql(
    `
      mutation SeedTask($id: String!) {
        webhookTask_insert(
          data: {
            id: $id
            deliveryId: $id
            eventType: "pull_request"
            payload: "{}"
            status: "pending"
            createdAt: 1
            updatedAt: 1
          }
        )
      }
    `,
    { id: taskId },
  );
  t.after(() =>
    graphql(
      `
        mutation CleanupNew($jobId: String!, $taskId: String!) {
          buildJob_delete(id: $jobId)
          webhookTask_delete(id: $taskId)
        }
      `,
      { jobId: newJobId, taskId },
    ),
  );
  await webhookSdk.beginPullRequestPlanning(webhookDc, {
    id: planningId,
    taskId,
    connectionId: f.teamId,
    repositoryId: "10",
    pullRequestNumber: "7",
    token,
  });
  return () =>
    webhookSdk.completeWebhookTask(webhookDc, {
      id: taskId,
      planningId,
      planningToken: token,
      connectionId: f.teamId,
      owner: "org",
      repo: "app",
      branch: "feature",
      pullRequestNumber: "7",
      githubBaseUrl: "https://github.com",
      commitSha: "b".repeat(40),
      cancelClosedPullRequest: closed,
      jobCount: closed ? 0 : 1,
      jobsJson: JSON.stringify(
        closed ? [] : [{ id: newJobId, name: "CI", file: "ci.dart", cancelPreviousRuns: true }],
      ),
    });
}

test("Cloud Run executor completes checkout, workflow, FSC logs, billing, checks and VM cleanup", async (t) => {
  const f = await fixture(t);
  await graphql(
    "mutation SeedCounter($id: String!) { team_update(id: $id, data: { runNumber: 41 }) }",
    { id: f.teamId },
  );
  await f.run();
  const state = await f.state();
  assert.equal(state.job.status, "SUCCESS", JSON.stringify(f.reports));
  assert.equal(state.job.pullRequestNumber, null, "Push jobs return explicit null provenance");
  assert.equal(state.job.runCount, "1");
  assert.equal(state.run.runNumber, "41");
  assert.match(f.scripts[1], /^export OPENCI_RUN_NUMBER='41'$/m);
  assert.equal(state.run.conclusion, "success");
  assert.equal(state.dispatch.activeJobId, null);
  assert.ok(state.dispatch.vmDeletedAt && state.dispatch.finishedAt);
  assert.deepEqual(f.calls, ["create", "ready", "checkout", "revoke", "workflow", "remove"]);
  assert.deepEqual(f.checks, ["in_progress", "success"]);
  const billingState = await f.billingState();
  assert.equal(billingState.outcome, "success");
  assert.equal(billingState.measurementIncomplete, false);
  const logs = await graphql(
    `
      query Read($id: String!) {
        buildRun(id: $id) {
          logsExpireAt
          lastLogSequence
          logs: buildLogs_on_run(orderBy: { sequence: ASC }) {
            message
          }
          steps: buildSteps_on_run(orderBy: { stepOrder: ASC }) {
            status
          }
        }
      }
    `,
    { id: state.run.id },
  );
  assert.equal(logs.buildRun.lastLogSequence, "2");
  assert.deepEqual(
    logs.buildRun.logs.map((log) => log.message),
    ["[REDACTED]\nchecked out\n", "[REDACTED]\nfinished\n"],
  );
  assert.deepEqual(
    logs.buildRun.steps.map((step) => step.status),
    ["SUCCESS", "SUCCESS", "SUCCESS"],
  );
  assert.ok(Date.parse(logs.buildRun.logsExpireAt) > Date.now());
  await f.run();
  assert.equal(f.calls.filter((call) => call === "create").length, 1);
});

test("concurrent jobs share the team's run sequence and retrying an allocation reuses its number", async (t) => {
  const team = await seedTeam(t);
  const retry = await fixture(t, false, team);
  const fresh = await fixture(t, false, team);
  const otherTeam = await fixture(t);
  const previousRunId = randomUUID();
  await graphql(
    `
      mutation SeedHistory($runId: String!, $jobId: String!) @transaction {
        buildRun_insert(
          data: {
            id: $runId
            buildJobId: $jobId
            runNumber: 7
            status: "completed"
            createdAt: 1
            updatedAt: 1
          }
        )
        buildJob_update(id: $jobId, data: { latestRunId: $runId, runCount: 1 })
      }
    `,
    { runId: previousRunId, jobId: retry.jobId },
  );

  const [retryRun, freshRun, independentRun] = await Promise.all(
    [retry, fresh, otherTeam].map(async (job) => {
      const executorId = await job.claim();
      const { dispatch } = await job.state();
      const number = await store.configure(dispatch, executorId, true);
      return { dispatch, executorId, number };
    }),
  );
  assert.deepEqual(
    [retryRun.number, freshRun.number].sort((left, right) => left - right),
    [8, 9],
  );
  assert.equal(independentRun.number, 1);
  assert.equal(
    await store.configure(retryRun.dispatch, retryRun.executorId, true),
    retryRun.number,
  );
  assert.equal((await retry.state()).job.runCount, "2");
  assert.equal((await fresh.state()).job.runCount, "1");

  const saved = await graphql(
    `
      query ReadCounters($team: String!, $other: String!, $previousRun: String!) {
        team(id: $team) {
          runNumber
        }
        other: team(id: $other) {
          runNumber
        }
        previous: buildRun(id: $previousRun) {
          runNumber
        }
      }
    `,
    { team: team.teamId, other: otherTeam.teamId, previousRun: previousRunId },
  );
  assert.equal(saved.team.runNumber, "10");
  assert.equal(saved.other.runNumber, "2");
  assert.equal(saved.previous.runNumber, "7");
});

test("self-hosted executor creates a real run, logs and checks without a billing ledger", async (t) => {
  const f = await fixture(t, true);
  const check = f.dependencies.github.check;
  f.dependencies.github.check = async (job, dispatch, outcome) => {
    assert.equal(dispatch.checkRunId, "123", "Keep the queued check throughout execution");
    return check(job, dispatch, outcome);
  };
  f.dependencies.configuration.selfHosted = true;
  f.dependencies.configuration.complimentary.clear();
  await f.run();
  const state = await f.state();
  assert.equal(state.job.status, "SUCCESS", JSON.stringify(f.reports));
  assert.equal(state.job.runCount, "1");
  assert.equal(state.job.latestRunId, state.run.id);
  assert.equal(state.run.runNumber, "1");
  assert.equal(state.run.conclusion, "success");
  assert.ok(state.dispatch.vmDeletedAt && state.dispatch.finishedAt);
  assert.deepEqual(f.checks, ["in_progress", "success"]);
  assert.deepEqual(f.calls, ["create", "ready", "checkout", "revoke", "workflow", "remove"]);
  assert.equal(await f.billingState(), null);
  const saved = await graphql(
    `
      query Read($teamId: String!, $runId: String!) {
        billingAdmissions(where: { teamId: { eq: $teamId } }) {
          id
        }
        buildRun(id: $runId) {
          lastLogSequence
          logsExpireAt
        }
      }
    `,
    { teamId: f.teamId, runId: state.run.id },
  );
  assert.deepEqual(saved.billingAdmissions, []);
  assert.equal(saved.buildRun.lastLogSequence, "2");
  assert.ok(Date.parse(saved.buildRun.logsExpireAt) > Date.now());
  await f.run();
  assert.equal(f.calls.filter((call) => call === "create").length, 1);
});

test("self-hosted run initialization reconciles a lost response without duplicating runs", async (t) => {
  const f = await fixture(t);
  f.dependencies.configuration.selfHosted = true;
  let lost = false;
  const original = dc.executeMutation;
  dc.executeMutation = async function (name, ...args) {
    const response = await original.call(this, name, ...args);
    if (name === "StartSelfHostedBuildExecution" && !lost) {
      lost = true;
      throw new Error("Simulated lost acknowledgement");
    }
    return response;
  };
  t.after(() => {
    dc.executeMutation = original;
  });
  await f.run();
  assert.equal(lost, true);
  const state = await f.state();
  assert.equal(state.job.status, "SUCCESS", JSON.stringify(f.reports));
  assert.equal(state.job.runCount, "1");
  assert.equal(state.run.runNumber, "1");
  assert.equal(await f.billingState(), null);
});

test("self-hosted initialization rejects stale executors, cancelled jobs, foreign teams, Stripe accounts and client calls atomically", async (t) => {
  for (const scenario of [
    "wrong-executor",
    "cancelled",
    "expired",
    "team-mismatch",
    "stripe-customer",
    "client",
    "anonymous",
  ]) {
    const f = await fixture(t);
    const executorId = await f.claim();
    if (scenario === "cancelled") await alterJob(f.jobId, { status: "CANCELLED" });
    if (scenario === "expired") await alterDispatch(f.id, { deadlineAt: "2000-01-01T00:00:00Z" });
    if (scenario === "stripe-customer") {
      await graphql(
        `
          mutation SeedCustomer($teamId: String!) @transaction {
            billingAccount_insert(data: { teamId: $teamId })
            billingCustomerCreation_insert(
              data: { teamId: $teamId, idempotencyKey: $teamId, livemode: false, createdAt: 1 }
            )
          }
        `,
        { teamId: f.teamId },
      );
    }
    await assert.rejects(
      dispatchSdk.startSelfHostedBuildExecution(
        dc,
        {
          id: f.id,
          jobId: f.jobId,
          teamId: scenario === "team-mismatch" ? randomUUID() : f.teamId,
          executorId: scenario === "wrong-executor" ? randomUUID() : executorId,
        },
        scenario === "client"
          ? { impersonate: { authClaims: { sub: "user" } } }
          : scenario === "anonymous"
            ? { impersonate: { unauthenticated: true } }
            : undefined,
      ),
    );
    const state = await f.state();
    assert.equal(state.run, null);
    assert.equal(state.job.runCount, "0");
    assert.equal(state.job.latestRunId, null);
    assert.equal(state.job.status, scenario === "cancelled" ? "CANCELLED" : "QUEUED");
  }
});

test("persisted PR jobs and reruns fail before billing, VM creation, checkout and secrets when source verification fails", async (t) => {
  for (const runCount of [0, 3]) {
    const f = await fixture(t);
    await alterJob(f.jobId, {
      pullRequestNumber: "7",
      runCount: String(runCount),
      latestRunId: runCount ? "previous-run" : null,
      workerHost: runCount ? "previous-worker" : null,
    });
    let verified = 0;
    f.dependencies.github.resolveCheckoutCommit = async (job, accountId) => {
      assert.equal(job.pullRequestNumber, "7", "FSC must expose the saved PR number to the guard");
      assert.equal(accountId, "10");
      verified++;
      throw new Error("Untrusted pull request source");
    };
    const denied = [];
    const forbid = (operation) => async () => {
      denied.push(operation);
      throw new Error(`Unexpected ${operation}`);
    };
    f.dependencies.billing = {
      ...f.dependencies.billing,
      period: forbid("billing"),
      close: billing.close.bind(billing),
    };
    f.dependencies.github.checkout = forbid("checkout");
    f.dependencies.secrets = forbid("secrets");
    await f.run();
    const state = await f.state();
    assert.equal(verified, 1);
    assert.deepEqual(denied, []);
    assert.equal(state.job.status, "FAILURE");
    assert.equal(state.job.runCount, String(runCount));
    assert.equal(state.run, null);
    assert.equal(state.dispatch.outcome, "failure");
    assert.equal(state.dispatch.activeJobId, null);
    assert.ok(state.dispatch.finishedAt);
    assert.equal(await f.billingState(), null);
    assert.deepEqual(f.calls, ["remove"]);
    assert.deepEqual(f.checks, []);
    await f.run();
    assert.equal(verified, 1, "A rejected attempt must not be replayed");
  }
});

test("rejected old attempts cannot fail a queued job after losing their active reservation", async (t) => {
  const f = await fixture(t);
  const executorId = await f.claim();
  await store.result(
    f.id,
    executorId,
    "failure",
    new PullRequestCheckoutError("conflicts").message,
  );
  await alterDispatch(f.id, { activeJobId: null });
  await alterJob(f.jobId, {
    status: "QUEUED",
    latestRunId: "newer-run",
    workerHost: "newer-worker",
    failureSummary: "Newer attempt's summary",
  });
  await cleanupExecution(f.id, f.jobId, f.dependencies, false);
  const state = await f.state();
  assert.equal(state.job.status, "QUEUED");
  assert.equal(state.job.latestRunId, "newer-run");
  assert.equal(state.job.workerHost, "newer-worker");
  assert.equal((await jobFailure(f.jobId)).failureSummary, "Newer attempt's summary");
  assert.ok(state.dispatch.finishedAt);
});

async function jobFailure(jobId) {
  return (
    await graphql(
      "query Failure($id: String!) { buildJob(id: $id) { failureSummary failureSummaryStatus } }",
      { id: jobId },
    )
  ).buildJob;
}

test("merge failure survives cleanup recovery and is published before any run exists", async (t) => {
  const f = await fixture(t, true);
  const error = new PullRequestCheckoutError("conflicts");
  f.dependencies.github.resolveCheckoutCommit = async () => {
    throw error;
  };
  f.dependencies.github.check = async (_job, dispatch, outcome) => {
    assert.equal(dispatch.failureSummary, error.message);
    assert.equal(outcome, "failure");
    f.checks.push(outcome);
    return "123";
  };
  const remove = f.dependencies.orchard.remove;
  f.dependencies.orchard.remove = async () => {
    throw new Error("Temporary controller failure");
  };

  await assert.rejects(f.run(), /Temporary controller failure/);
  assert.equal((await f.state()).dispatch.failureSummary, error.message);
  f.dependencies.orchard.remove = remove;
  await alterDispatch(f.id, { cleanupLeaseUntil: "2000-01-01T00:00:00Z" });
  await recoverExecutions(f.dependencies);

  const state = await f.state();
  assert.equal(state.run, null);
  assert.equal(state.job.status, "FAILURE");
  assert.equal((await jobFailure(f.jobId)).failureSummary, error.message);
  assert.deepEqual(f.checks, ["failure"]);
  assert.deepEqual(f.calls, ["stop-cloud-run", "remove"]);
  assert.equal(await f.billingState(), null);
});

test("cancellation clears a recorded merge failure from the current job", async (t) => {
  const f = await fixture(t, true);
  const executorId = await f.claim();
  const summary = new PullRequestCheckoutError("not_ready").message;
  await store.result(f.id, executorId, "failure", summary);
  await alterJob(f.jobId, { status: "CANCELLED", failureSummary: summary });

  await cleanupExecution(f.id, f.jobId, f.dependencies, false);

  assert.equal((await f.state()).job.status, "CANCELLED");
  assert.equal((await jobFailure(f.jobId)).failureSummary, null);
  assert.deepEqual(f.checks, ["cancelled"]);
});

test("a new successful attempt clears the previous job failure summary", async (t) => {
  const f = await fixture(t, true);
  await alterJob(f.jobId, { failureSummary: new PullRequestCheckoutError("not_ready").message });

  await f.run();

  assert.equal((await f.state()).job.status, "SUCCESS");
  assert.equal((await jobFailure(f.jobId)).failureSummary, null);
  assert.equal((await f.state()).dispatch.failureSummary, null);
});

test("source rejection before a run exists completes the queued check", async (t) => {
  const f = await fixture(t, true);
  f.dependencies.github.resolveCheckoutCommit = async () => {
    throw new Error("superseded head");
  };
  f.dependencies.github.check = async (_job, dispatch, outcome) => {
    assert.equal(dispatch.checkRunId, "123");
    assert.equal(outcome, "failure");
    f.checks.push(outcome);
    return "123";
  };
  await f.run();
  const state = await f.state();
  assert.equal(state.run, null);
  assert.equal(state.job.status, "FAILURE");
  assert.deepEqual(f.checks, ["failure"]);
  assert.ok(state.dispatch.finishedAt);
});

test("lost acknowledgements do not duplicate admissions, runs, or log entries", async (t) => {
  const f = await fixture(t);
  const lost = new Set([
    "CreateBillingAdmission",
    "BindBillingAdmissionRun",
    "StartBillingExecution",
    "FinishBillingExecution",
    "ConfigureBuildExecutionRun",
    "AppendBuildLog",
    "CreateBuildStep",
    "UpdateBuildStep",
  ]);
  for (const connector of [dc, billingDc, logsDc]) {
    const original = connector.executeMutation;
    connector.executeMutation = async function (name, ...args) {
      const response = await original.call(this, name, ...args);
      if (lost.delete(name)) throw new Error("Simulated lost acknowledgement");
      return response;
    };
    t.after(() => {
      connector.executeMutation = original;
    });
  }
  await f.run();
  assert.deepEqual([...lost], []);
  assert.equal(
    (await f.state()).job.status,
    "SUCCESS",
    JSON.stringify({ calls: f.calls, reports: f.reports }),
  );
  assert.equal((await f.state()).job.runCount, "1");
  assert.equal((await f.billingState()).outcome, "success");
});

test("nonzero exit and cancellation flush the final log, finish the exact run and release its VM", async (t) => {
  for (const cancelled of [false, true]) {
    const f = await fixture(t);
    const shutdown = new AbortController();
    f.dependencies.orchard.exec = async (_vm, _script, output) => {
      await output("stderr", Buffer.from("checkout-token final output"));
      if (cancelled) {
        await alterJob(f.jobId, { status: "CANCELLED" });
        shutdown.abort();
      }
      return 42;
    };
    await f.run(shutdown.signal);
    const state = await f.state();
    assert.equal(state.job.status, cancelled ? "CANCELLED" : "FAILURE");
    assert.equal((await f.billingState()).outcome, cancelled ? "cancelled" : "failure");
    assert.ok(state.dispatch.finishedAt);
    assert.equal(f.calls.at(-1), "remove");
    const saved = await graphql(
      `
        query Read($id: String!) {
          buildRun(id: $id) {
            logs: buildLogs_on_run(orderBy: { sequence: ASC }) {
              stream
              message
            }
          }
        }
      `,
      { id: state.run.id },
    );
    assert.deepEqual(saved.buildRun.logs, [
      { stream: "stderr", message: "[REDACTED] final output" },
    ]);
  }
});

test("VM delete failure retains capacity and recovery stops the old Cloud Run first", async (t) => {
  const f = await fixture(t);
  f.dependencies.orchard.remove = async () => {
    throw new Error("Controller unavailable");
  };
  await assert.rejects(f.run());
  assert.equal((await f.state()).dispatch.activeJobId, f.jobId);
  assert.equal((await f.billingState()).finishedAtMs, null);
  await alterDispatch(f.id, { cleanupLeaseUntil: "2000-01-01T00:00:00Z" });
  f.dependencies.orchard.remove = async () => {
    f.calls.push("remove");
  };
  f.dependencies.stopExecution = async () => {
    throw new Error("Cancellation pending");
  };
  await recoverExecutions(f.dependencies);
  assert.equal(f.calls.includes("remove"), false);
  await alterDispatch(f.id, { cleanupLeaseUntil: "2000-01-01T00:00:00Z" });
  f.dependencies.stopExecution = async () => {
    f.calls.push("stop-cloud-run");
  };
  await recoverExecutions(f.dependencies);
  assert.deepEqual(f.calls.slice(-2), ["stop-cloud-run", "remove"]);
  assert.ok((await f.state()).dispatch.finishedAt);
  assert.equal((await f.billingState()).outcome, "success");
});

test("crashed executor is fenced, expired billing preserves last observation, and steps close", async (t) => {
  const f = await fixture(t);
  const { dispatch, executorId } = await started(f);
  await new ExecutionLogs(logsDc, f.teamId, dispatch.runId).start("run_workflow", "Workflow", 2);
  const observed = String(Date.now() - 120000);
  await graphql(
    "mutation Stale($id: String!, $at: Int64!, $lease: Int64!) { billingExecution_update(key: { runId: $id }, data: { startedAtMs: $at, observedAtMs: $at, leaseUntilMs: $lease }) }",
    { id: dispatch.runId, at: observed, lease: String(Date.now() - 60000) },
  );
  await alterDispatch(f.id, { heartbeatAt: "2000-01-01T00:00:00Z" });
  await recoverExecutions(f.dependencies);
  assert.equal(await store.heartbeat(f.id, executorId), false);
  assert.equal((await f.state()).job.status, "FAILURE");
  assert.equal((await f.billingState()).finishedAtMs, observed);
  assert.equal((await f.billingState()).measurementIncomplete, true);
  assert.equal(
    (
      await logsSdk.getBuildStepWriteState(logsDc, {
        teamId: f.teamId,
        runId: dispatch.runId,
        stepId: "run_workflow",
      })
    ).data.run.steps[0].status,
    "FAILURE",
  );
});

test("deadline recovery marks the build timed out; another executor cannot acquire the attempt", async (t) => {
  const f = await fixture(t);
  await f.claim();
  assert.equal(await store.claim(f.id, randomUUID(), f.input.executionName, 3600), false);
  await alterDispatch(f.id, { deadlineAt: "2000-01-01T00:00:00Z" });
  await recoverExecutions(f.dependencies);
  assert.equal((await f.state()).job.status, "TIMED_OUT");
  assert.equal((await f.state()).dispatch.activeJobId, null);
});

test("a missing billing card parks this job and publishes a missing queued check without allocating a VM", async (t) => {
  const f = await fixture(t);
  f.dependencies.configuration.complimentary.clear();
  await f.run();
  assert.equal((await f.state()).job.status, "QUEUED");
  assert.equal((await f.state()).dispatch.outcome, "card_required");
  assert.equal((await f.state()).dispatch.activeJobId, null);
  assert.equal(f.calls.includes("create"), false);
  assert.equal(await f.billingState(), null);
  assert.deepEqual(f.checks, ["card_required"]);
  assert.deepEqual(f.calls, []);
  assert.equal(await new DataConnectDispatchStore(dc).oldestQueued(), null);
  assert.equal((await f.state()).dispatch.checkRunId, "123");
  const saved = await graphql("query Check($id:String!) { buildJob(id:$id){ checkRunNumber } }", {
    id: f.jobId,
  });
  assert.equal(saved.buildJob.checkRunNumber, "1");
});

test("a parked Cloud job resumes once after card confirmation and writes one postpaid run", async (t) => {
  const f = await fixture(t, true);
  const userId = randomUUID();
  await graphql(
    "mutation Add($teamId: String!, $userId: String!) { teamMember_insert(data: {teamId:$teamId, userId:$userId}) }",
    { teamId: f.teamId, userId },
  );
  const card = cardFixture(billingDc, { teamId: f.teamId, userId });
  const queue = new DataConnectDispatchStore(dc);
  f.dependencies.configuration.complimentary.clear();
  f.dependencies.verifyCard = (teamId, mode) => card.service.cardSessionForCi(teamId, mode);
  await card.start();
  await f.run();
  assert.equal((await f.state()).dispatch.outcome, "card_required");
  assert.equal(await queue.oldestQueued(), null);
  assert.ok(!f.calls.includes("create"));
  const [session] = card.sessions.values();
  card.complete(session);
  assert.equal(await card.webhook(session), 204);
  assert.equal((await queue.oldestQueued()).id, f.jobId);

  async function retry() {
    const id = randomUUID();
    await queue.acquireScheduler(id);
    await queue.reserve(id, {
      id,
      jobId: f.jobId,
      vmName: `openci-${id}`,
      cpu: 2,
      memoryMiB: 4096,
      image: "base-macos",
      cloudRunJob: f.dependencies.configuration.cloudRunJob,
    });
    await queue.releaseScheduler(id);
    await executeBuild({ ...f.input, dispatchId: id }, f.dependencies);
    return store.read(id, f.jobId);
  }

  // Removal before dispatch wins even when the checkout ledger says registered.
  card.state.defaultMethod = null;
  assert.equal((await retry()).dispatch.outcome, "card_required");
  assert.equal(await queue.oldestQueued(), null);
  assert.ok(!f.calls.includes("create"));
  card.state.defaultMethod = "pm_replacement";
  await card.webhook(session, "customer.updated");
  assert.equal((await queue.oldestQueued()).id, f.jobId);
  const state = await retry();
  assert.equal(state.job.status, "SUCCESS");
  assert.equal(state.job.runCount, "1");
  assert.equal(state.dispatch.checkRunId, "123");
  assert.deepEqual(f.checks, ["card_required", "card_required", "in_progress", "success"]);
  assert.equal(f.calls.filter((call) => call === "create").length, 1);
  const admission = (
    await billingSdk.getBillingAdmission(billingDc, {
      teamId: f.teamId,
      id: identity(state.dispatch).admissionId,
    })
  ).data.billingAdmission;
  assert.equal(admission.reservedMillis, "0");
  const run = (
    await billingSdk.getBillingExecution(billingDc, { teamId: f.teamId, runId: state.run.id })
  ).data.billingExecution;
  assert.equal(run.outcome, "success");
  assert.match(run.periodId, /^postpaid:/);
  const period = (
    await billingSdk.getBillingPeriod(billingDc, { teamId: f.teamId, id: run.periodId })
  ).data.period;
  assert.equal(period.periodType, "postpaid");
  assert.equal(period.allowanceSeconds ?? null, null);
  assert.equal(new Date(Number(period.startsAt) * 1000).getUTCHours(), 15);
  const steps = await graphql(
    "query Steps($id:String!) {buildRun(id:$id){steps:buildSteps_on_run(orderBy:{stepOrder:ASC}){stepId status}}}",
    { id: state.run.id },
  );
  assert.deepEqual(steps.buildRun.steps[0], { stepId: "prepare_vm", status: "SUCCESS" });
});

test("partial admission expires before cleanup releases the reservation", async (t) => {
  const f = await fixture(t);
  const executorId = await f.claim();
  const dispatch = (await f.state()).dispatch;
  const periodId = await billing.period(
    { team: { id: f.teamId } },
    f.teamId,
    false,
    new Set([f.teamId]),
  );
  await billing.admit(dispatch, periodId);
  await store.result(f.id, executorId, "failure");
  await assert.rejects(cleanupExecution(f.id, f.jobId, f.dependencies, false), /closure pending/);
  assert.equal((await f.state()).dispatch.activeJobId, f.jobId);
  await graphql(
    "mutation Expire($id: String!, $at: Int64!) { billingAdmission_update(id: $id, data: { startByMs: $at }) }",
    { id: identity(dispatch).admissionId, at: String(Date.now() - 1) },
  );
  await alterDispatch(f.id, { cleanupLeaseUntil: "2000-01-01T00:00:00Z" });
  await recoverExecutions(f.dependencies);
  assert.ok((await f.state()).dispatch.finishedAt);
  assert.equal((await f.state()).job.status, "FAILURE");
});

test("cleanup cannot finish while billing or the VM remains, and client identities cannot invoke executor APIs", async (t) => {
  const f = await fixture(t);
  const { executorId } = await started(f);
  await store.result(f.id, executorId, "success");
  assert.equal(await store.acquireCleanup(f.id, "cleanup"), true);
  await assert.rejects(store.complete(f.id, f.jobId, "cleanup"));
  await store.vmDeleted(f.id, "cleanup");
  await assert.rejects(store.complete(f.id, f.jobId, "cleanup"));
  for (const impersonate of [{ unauthenticated: true }, { authClaims: { sub: "user" } }]) {
    const options = { impersonate };
    await assert.rejects(
      dispatchSdk.getBuildExecution(
        dc,
        { id: f.id, jobId: f.jobId, runId: `run-${f.id}` },
        options,
      ),
    );
    await assert.rejects(dispatchSdk.getBuildExecutionSecrets(dc, { teamId: f.teamId }, options));
    await assert.rejects(
      dispatchSdk.heartbeatBuildExecution(dc, { id: f.id, executorId }, options),
    );
    await assert.rejects(
      dispatchSdk.acquireBuildExecutionCleanup(dc, { id: f.id, owner: "client" }, options),
    );
    await assert.rejects(
      dispatchSdk.completeBuildExecution(
        dc,
        { id: f.id, jobId: f.jobId, owner: "client" },
        options,
      ),
    );
  }
});

for (const closed of [false, true]) {
  test(
    "PR auto cancellation interrupts an open command and closes VM, billing and GitHub Check",
    { timeout: 25000 },
    async (t) => {
      const f = await fixture(t);
      const supersede = await prepareSupersedingRevision(t, f, closed);
      f.dependencies.orchard.exec = async (_vm, _script, _output, signal) => {
        assert.equal((await supersede()).data.cancelled, 1);
        return new Promise((_resolve, reject) => {
          signal.addEventListener("abort", () => reject(new Error("Interrupted")), { once: true });
        });
      };
      await f.run();
      assert.equal((await f.state()).job.status, "CANCELLED");
      assert.equal((await f.billingState()).outcome, "cancelled");
      assert.equal(f.calls.at(-1), "remove");
      assert.equal(f.checks.at(-1), "cancelled");
      assert.equal((await f.state()).run.conclusion, "cancelled");
      assert.equal((await f.state()).dispatch.activeJobId, null);
    },
  );

  test("execution startup cannot revive a PR job cancelled concurrently with admission", async (t) => {
    const f = await fixture(t);
    const supersede = await prepareSupersedingRevision(t, f, closed);
    const executorId = await f.claim();
    const start = () =>
      dispatchSdk.startSelfHostedBuildExecution(dc, {
        id: f.id,
        jobId: f.jobId,
        teamId: f.teamId,
        executorId,
      });
    const [cancellation] = await Promise.allSettled([supersede(), start()]);
    assert.equal(cancellation.status, "fulfilled");
    assert.equal(cancellation.value.data.cancelled, 1);
    assert.equal((await f.state()).job.status, "CANCELLED");
    await assert.rejects(start());
    assert.equal((await f.state()).job.status, "CANCELLED");
  });
}

test("a lost claim acknowledgement never starts a VM or resumes the claimed attempt", async (t) => {
  const f = await fixture(t);
  f.dependencies.store = Object.assign(Object.create(store), {
    claim: async (...args) => {
      await store.claim(...args);
      throw new Error("Lost claim response");
    },
  });
  await assert.rejects(f.run());
  assert.ok((await f.state()).dispatch.executorId);
  assert.deepEqual(f.calls, []);
  await f.run();
  assert.deepEqual(f.calls, []);
});

test("another executor cannot change the reserved VM or finish the attempt", async (t) => {
  const f = await fixture(t);
  await f.claim();
  const state = await f.state();
  assert.equal(state.dispatch.vmName, `openci-${f.id}`);
  assert.equal(await store.heartbeat(f.id, "different-executor"), false);
  await assert.rejects(store.vmRequested(f.id, "different-executor"));
  await assert.rejects(store.complete(f.id, f.jobId, "different-cleaner"));
});

test("recovering an old attempt does not overwrite a newer run or its billing identity", async (t) => {
  const f = await fixture(t);
  const { dispatch, executorId } = await started(f);
  await store.result(f.id, executorId, "success");
  await alterJob(f.jobId, {
    status: "IN_PROGRESS",
    latestRunId: "new-run",
    workerHost: "new-worker",
    checkRunId: "456",
    completedAt: null,
  });
  await graphql(
    "mutation Expire($id: String!, $at: Int64!) { billingExecution_update(key: { runId: $id }, data: { leaseUntilMs: $at }) }",
    { id: dispatch.runId, at: String(Date.now() - 1) },
  );
  await recoverExecutions(f.dependencies);
  const state = await f.state();
  assert.equal(state.job.status, "IN_PROGRESS");
  assert.equal(state.job.latestRunId, "new-run");
  assert.equal(state.job.workerHost, "new-worker");
  assert.ok(state.dispatch.finishedAt);
  assert.equal((await f.billingState()).measurementIncomplete, true);
});

test("the sweep removes a VM that appears after its attempt already finished", async (t) => {
  const f = await fixture(t);
  await f.run();
  const active = await fixture(t);
  f.dependencies.orchard.vmNames = async () => [
    `openci-${f.id}`,
    `openci-${active.id}`,
    "legacy-vm",
  ];
  const removed = [];
  f.dependencies.orchard.remove = async (name) => {
    removed.push(name);
  };
  await recoverExecutions(f.dependencies);
  assert.deepEqual(removed, [`openci-${f.id}`]);
  assert.equal((await active.state()).dispatch.activeJobId, active.jobId);
});

for (const closed of [false, true]) {
  test("a terminal execution already publishing its Check retains a consistent result", async (t) => {
    const f = await fixture(t);
    const supersede = await prepareSupersedingRevision(t, f, closed);
    const check = f.dependencies.github.check;
    f.dependencies.github.check = async (job, dispatch, outcome) => {
      if (outcome === "success") assert.equal((await supersede()).data.cancelled, 0);
      return check(job, dispatch, outcome);
    };
    await f.run();
    assert.equal((await f.state()).job.status, "SUCCESS");
    assert.equal((await f.state()).run.conclusion, "success");
    assert.equal((await f.billingState()).outcome, "success");
    assert.equal(f.checks.at(-1), "success");
  });

  test("concurrent result recording and auto cancellation agree on billing and the final Check", async (t) => {
    const f = await fixture(t);
    const supersede = await prepareSupersedingRevision(t, f, closed);
    const { executorId } = await started(f);
    const [cancellation] = await Promise.all([
      supersede(),
      store.result(f.id, executorId, "success"),
    ]);
    await cleanupExecution(f.id, f.jobId, f.dependencies, false);
    const expected = cancellation.data.cancelled === 1 ? "cancelled" : "success";
    assert.equal((await f.state()).job.status, expected.toUpperCase());
    assert.equal((await f.state()).run.conclusion, expected);
    assert.equal((await f.billingState()).outcome, expected);
    assert.equal(f.checks.at(-1), expected);
  });
}

test("PR closure releases an unclaimed reservation and finalizes its queued Check", async (t) => {
  const f = await fixture(t, true);
  const close = await prepareSupersedingRevision(t, f, true);
  assert.equal((await close()).data.cancelled, 1);
  await new DataConnectDispatchStore(dc).cancelUnstarted(f.jobId);
  const reports = [];
  const checks = new QueuedChecks(new QueuedCheckStore(dc), {
    options: { appId: "1", apiBaseUrl: "https://api.github.com" },
    queuedCheck: async (job, externalId, checkRunId) => {
      reports.push({ status: job.status, externalId, checkRunId });
      return "123";
    },
  });
  await checks.sync(f.jobId);
  assert.deepEqual(reports, [
    { status: "CANCELLED", externalId: `build-job:${f.jobId}:run:1`, checkRunId: "123" },
  ]);
  const state = await f.state();
  assert.equal(state.dispatch.activeJobId, null);
  assert.ok(state.dispatch.finishedAt);
  assert.equal(state.job.status, "CANCELLED");
  assert.deepEqual(f.calls, []);
  assert.equal(await f.billingState(), null);
});
