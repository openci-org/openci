import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";
import { after, test } from "node:test";
import { deleteApp, getApps, initializeApp } from "firebase-admin/app";
import * as dispatchSdk from "@openci/dispatch-admin";
import * as billingSdk from "@openci/billing-admin";
import * as logsSdk from "@openci/logs-admin";
import { ExecutionStore, isolatedConnector } from "../../lib/functions/executor/store.js";
import { ExecutionBilling } from "../../lib/functions/executor/billing.js";
import { ExecutionLogs } from "../../lib/functions/executor/logs.js";
import {
  executeBuild,
  recoverExecutions,
  cleanupExecution,
} from "../../lib/functions/executor/execute.js";
import { identity } from "../../lib/functions/executor/model.js";

const host = process.env.DATA_CONNECT_EMULATOR_HOST;
assert.match(host ?? "", /^(127\.0\.0\.1|localhost):\d+$/, "Start the SQL Connect emulator first");
const service = `http://${host}/v1/projects/demo-openci/locations/asia-northeast1/services/openci-b1b91-service`;
const app = initializeApp({ projectId: "demo-openci" });
const dc = isolatedConnector(dispatchSdk.connectorConfig, app);
const billingDc = isolatedConnector(billingSdk.connectorConfig, app);
const logsDc = isolatedConnector(logsSdk.connectorConfig, app);
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

async function fixture(t) {
  const teamId = randomUUID(),
    jobId = randomUUID(),
    id = randomUUID();
  const installationId = String(Math.floor(Math.random() * 1000000000) + 1);
  await graphql(
    `
      mutation Seed(
        $teamId: String!
        $jobId: String!
        $installationId: Int64!
        $installationText: String!
      ) @transaction {
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
    { teamId, jobId, installationId, installationText: installationId },
  );
  t.after(() =>
    graphql(
      `
        mutation Cleanup($teamId: String!, $jobId: String!) @transaction {
          buildJobDispatch_deleteMany(where: { jobId: { eq: $jobId } })
          buildJob_delete(id: $jobId)
          billingAccount_deleteMany(where: { teamId: { eq: $teamId } })
          team_delete(id: $teamId)
        }
      `,
      { teamId, jobId },
    ),
  );
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
  let commands = 0;
  const dependencies = {
    store,
    billing,
    configuration,
    github: {
      options: { appId: "1", apiBaseUrl: "https://api.github.com", baseUrl: "https://github.com" },
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
      exec: async (_vm, _script, output) => {
        commands++;
        calls.push(commands === 1 ? "checkout" : "workflow");
        await output(
          "stdout",
          Buffer.from(commands === 1 ? "checkout-token\n" : "workflow-secret\n"),
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

test("Cloud Run executor completes checkout, workflow, FSC logs, billing, checks and VM cleanup", async (t) => {
  const f = await fixture(t);
  await f.run();
  const state = await f.state();
  assert.equal(state.job.status, "SUCCESS", JSON.stringify(f.reports));
  assert.equal(state.job.runCount, "1");
  assert.equal(state.run.runNumber, "1");
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
    ["[REDACTED]\n", "[REDACTED]\n"],
  );
  assert.deepEqual(
    logs.buildRun.steps.map((step) => step.status),
    ["SUCCESS", "SUCCESS", "SUCCESS"],
  );
  assert.ok(Date.parse(logs.buildRun.logsExpireAt) > Date.now());
  await f.run();
  assert.equal(f.calls.filter((call) => call === "create").length, 1);
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

test("nonzero exit and cancellation finish the exact run and release its VM", async (t) => {
  for (const cancelled of [false, true]) {
    const f = await fixture(t);
    const shutdown = new AbortController();
    f.dependencies.orchard.exec = async () => {
      if (cancelled) {
        await alterJob(f.jobId, { status: "CANCELLED" });
        shutdown.abort();
      }
      return 42;
    };
    await f.run(shutdown.signal);
    assert.equal((await f.state()).job.status, cancelled ? "CANCELLED" : "FAILURE");
    assert.equal((await f.billingState()).outcome, cancelled ? "cancelled" : "failure");
    assert.ok((await f.state()).dispatch.finishedAt);
    assert.equal(f.calls.at(-1), "remove");
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

test("lack of paid entitlement leaves the build queued without allocating a VM", async (t) => {
  const f = await fixture(t);
  f.dependencies.configuration.complimentary.clear();
  await f.run();
  assert.equal((await f.state()).job.status, "QUEUED");
  assert.equal((await f.state()).dispatch.outcome, "blocked");
  assert.equal((await f.state()).dispatch.activeJobId, null);
  assert.equal(f.calls.includes("create"), false);
  assert.equal(await f.billingState(), null);
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

test(
  "FSC cancellation is observed by the heartbeat and interrupts an open command",
  { timeout: 25000 },
  async (t) => {
    const f = await fixture(t);
    f.dependencies.orchard.exec = async (_vm, _script, _output, signal) => {
      await alterJob(f.jobId, { status: "CANCELLED" });
      return new Promise((_resolve, reject) => {
        signal.addEventListener("abort", () => reject(new Error("Interrupted")), { once: true });
      });
    };
    await f.run();
    assert.equal((await f.state()).job.status, "CANCELLED");
    assert.equal((await f.billingState()).outcome, "cancelled");
    assert.equal(f.calls.at(-1), "remove");
  },
);

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
