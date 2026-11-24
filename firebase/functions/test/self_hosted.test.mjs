import assert from "node:assert/strict";
import { test } from "node:test";
import { selfHostedMode } from "../../lib/functions/deployment_mode.js";
import { billingConfig } from "../../lib/functions/billing/config.js";
import { Billing } from "../../lib/functions/billing/service.js";
import { BillingError } from "../../lib/functions/billing/model.js";
import { ExecutionBilling } from "../../lib/functions/executor/billing.js";
import { executeBuild } from "../../lib/functions/executor/execute.js";
import { ExecutionStopped, prQrOutputReady } from "../../lib/functions/executor/model.js";
import { PullRequestCheckoutError } from "../../lib/functions/executor/checkout_error.js";
import { execFileSync } from "node:child_process";

test("self-hosted Functions bind no Stripe secrets but retain team deletion", () => {
  const script = `
    const functions = require('./firebase/lib/functions/core.js');
    console.log(JSON.stringify(Object.fromEntries(Object.entries(functions)
      .map(([name, fn]) => [name, fn.__endpoint.secretEnvironmentVariables ?? []]))));
  `;
  const manifests = JSON.parse(
    execFileSync(process.execPath, ["-e", script], {
      cwd: new URL("../../../", import.meta.url),
      env: { ...process.env, OPENCI_SELF_HOSTED: "true", BILLING_ENABLED: "false" },
      encoding: "utf8",
    }),
  );
  assert.ok(Object.hasOwn(manifests, "teamBilling"));
  assert.ok(Object.hasOwn(manifests, "cleanDeletedTeamCredentials"));
  assert.ok(!JSON.stringify(manifests).includes("STRIPE_"));
});

test("self-hosting is explicit operator configuration, distinct from paused billing", () => {
  assert.equal(selfHostedMode({}), false);
  assert.equal(selfHostedMode({ BILLING_ENABLED: "false" }), false);
  assert.equal(selfHostedMode({ OPENCI_SELF_HOSTED: "true" }), true);
  assert.throws(() => selfHostedMode({ OPENCI_SELF_HOSTED: "yes" }));
  assert.throws(() => billingConfig({ OPENCI_SELF_HOSTED: "true", BILLING_ENABLED: "true" }));
});

test("self-hosted status allows CI but still authorizes teams and rejects purchases", async () => {
  const config = billingConfig({ OPENCI_SELF_HOSTED: "true" });
  const context = { team: { id: "team" }, customer: null, stripe: null, checkout: null };
  const store = {
    async context(teamId, userId) {
      if (teamId !== "team" || userId !== "member")
        throw new BillingError("permission-denied", "forbidden");
      return context;
    },
  };
  const service = new Billing(
    store,
    new Proxy(
      {},
      {
        get() {
          throw new Error("Stripe must not be accessed");
        },
      },
    ),
    config,
  );
  const result = await service.execute("member", { action: "status", teamId: "team" });
  assert.equal(result.canStartCi, true);
  assert.equal(result.billingEnabled, false);
  assert.equal(result.canCheckout, false);
  assert.equal(result.canManageBilling, false);
  await assert.rejects(
    service.execute("outsider", { action: "status", teamId: "team" }),
    /forbidden/,
  );
  for (const action of ["checkout", "portal"]) {
    await assert.rejects(
      service.execute("member", { action, teamId: "team", planId: "pro" }),
      /billing_disabled/,
    );
  }
  context.customer = { stripeCustomerId: "existing" };
  await assert.rejects(
    service.execute("member", { action: "status", teamId: "team" }),
    /billing_unavailable/,
  );
});

function executionFixture(selfHosted, contextChange = {}) {
  const calls = [];
  const scripts = [];
  const checkShas = [];
  const dispatch = {
    id: "dispatch",
    jobId: "job",
    teamId: "team",
    runId: "run-dispatch",
    vmName: "vm",
    cloudRunJob: "projects/demo-self-hosted/locations/asia-northeast1/jobs/executor",
    executorId: null,
    deadlineAt: new Date(Date.now() + 60000).toISOString(),
  };
  const job = {
    id: "job",
    teamId: "team",
    status: "QUEUED",
    owner: "org",
    repo: "app",
    installationId: "123",
    workflowName: "CI",
    workflowFileName: "ci.dart",
    commitSha: "a".repeat(40),
    pullRequestNumber: null,
    branch: "develop",
    latestRunId: dispatch.runId,
    // Untrusted job fields must never select deployment mode.
    selfHosted: true,
  };
  const state = { dispatch, job, run: { id: dispatch.runId, runNumber: 1 } };
  const dependencies = {
    store: {
      async read() {
        return state;
      },
      async claim(_id, executorId) {
        dispatch.executorId = executorId;
        return true;
      },
      async heartbeat() {
        return true;
      },
      async context() {
        return { team: { id: "team" }, connection: { accountId: "1" }, ...contextChange };
      },
      async configure() {
        calls.push("configure");
        return 1;
      },
      async check() {},
      async vmRequested() {},
      async result(_id, _executorId, outcome, failureSummary) {
        dispatch.outcome = outcome;
        dispatch.failureSummary = failureSummary;
        return true;
      },
      async acquireCleanup(_id, owner) {
        dispatch.cleanupOwner = owner;
        return true;
      },
      async vmDeleted() {},
      async complete() {
        calls.push("complete");
      },
    },
    billing: {
      async period() {
        calls.push("period");
        throw new ExecutionStopped("blocked");
      },
      async admit() {
        throw new Error("Unexpected admission");
      },
      async start() {
        throw new Error("Unexpected metering");
      },
      async heartbeat() {
        throw new Error("Unexpected billing heartbeat");
      },
      async close() {
        calls.push("close");
      },
    },
    github: {
      options: { appId: "1", apiBaseUrl: "https://github.example/api/v3" },
      async resolveCheckout(job) {
        calls.push("verify");
        return job.pullRequestNumber
          ? {
              event: "pull_request",
              number: Number(job.pullRequestNumber),
              headBranch: "feature/context",
              baseBranch: "develop",
              headSha: job.commitSha,
              baseSha: "b".repeat(40),
              checkoutSha: "c".repeat(40),
            }
          : {
              event: "push",
              branch: job.branch,
              commitSha: job.commitSha,
              checkoutSha: job.commitSha,
            };
      },
      async check(job) {
        checkShas.push(job.commitSha);
        return "1";
      },
      async checkout() {
        return { cloneUrl: "https://github.example/org/app.git", token: "test", async revoke() {} };
      },
    },
    orchard: {
      async create() {
        calls.push("create");
      },
      async ready() {},
      async remove() {
        calls.push("remove");
      },
      async exec(_vm, script) {
        calls.push("exec");
        scripts.push(script);
        return 0;
      },
    },
    logs: () => ({
      async start() {},
      async finish() {},
      output: () => ({ write() {}, async flush() {} }),
    }),
    async secrets() {
      return {};
    },
    async stopExecution() {},
    configuration: {
      selfHosted,
      cloudRunJob: dispatch.cloudRunJob,
      timeoutSeconds: 60,
      livemode: false,
      complimentary: new Set(),
    },
    report() {},
  };
  return {
    calls,
    scripts,
    checkShas,
    job,
    dependencies,
    dispatch,
    run: () =>
      executeBuild(
        {
          dispatchId: "dispatch",
          jobId: dispatch.jobId,
          executionName: `${dispatch.cloudRunJob}/executions/test`,
        },
        dependencies,
      ),
  };
}

test("self-hosted builds run without subscription or usage admission and still release the VM", async () => {
  const f = executionFixture(true);
  await f.run();
  assert.equal(f.dispatch.outcome, "success");
  assert.deepEqual(f.calls, [
    "verify",
    "configure",
    "create",
    "exec",
    "exec",
    "remove",
    "close",
    "complete",
  ]);
});

test("a Linux reservation checks out and runs the workflow in the same guest workspace", async () => {
  const f = executionFixture(true);
  f.job.runsOn = f.dispatch.runsOn = "linux-latest";
  f.dependencies.secrets = async () => assert.fail("The Linux pilot must not read team secrets");
  await f.run();
  assert.equal(f.dispatch.outcome, "success");
  assert.equal(f.scripts.length, 2);
  for (const script of f.scripts) {
    assert.match(script, /export HOME=\/home\/admin/);
    assert.ok(
      script.includes('cd "${HOME:?}/openci-build"') || script.includes('cd "$HOME/openci-build"'),
    );
  }
});

function postpaidLinuxFixture(contextChange) {
  const f = executionFixture(false, contextChange);
  f.job.runsOn = f.dispatch.runsOn = "linux-latest";
  f.job.githubBaseUrl = "https://github.com";
  f.job.repositoryId = "12345";
  f.dependencies.billing.period = async (_context, teamId, _livemode, complimentary) => {
    assert.equal(complimentary.has(teamId), false);
    f.calls.push("period");
    return { periodId: "postpaid-period" };
  };
  f.dependencies.billing.admit = async () => f.calls.push("admit");
  f.dependencies.billing.start = async () => f.calls.push("start");
  f.dependencies.secrets = async () => assert.fail("Linux pilot read team secrets");
  return f;
}

test("only the approved first Linux run can use its existing postpaid billing", async () => {
  for (const [approvedId, retryCount, runCount, allowed] of [
    ["job", 0, "0", true],
    ["another", 0, "0", false],
    ["job", 1, "0", false],
    ["job", 0, "1", false],
  ]) {
    const f = postpaidLinuxFixture();
    f.job.retryCount = retryCount;
    f.job.runCount = runCount;
    f.dependencies.configuration.linuxPostpaidPilotJobId = approvedId;
    await f.run();
    assert.equal(f.dispatch.outcome, allowed ? "success" : "failure");
    assert.equal(f.calls.includes("period"), allowed);
    assert.equal(f.calls.includes("admit"), allowed);
    assert.equal(f.calls.includes("start"), allowed);
    assert.equal(f.calls.includes("create"), allowed);
  }
});

test("an approved team and repository can run successive and retried postpaid Linux jobs", async () => {
  for (const [jobId, retryCount, runCount] of [
    ["first", 0, "0"],
    ["second", 0, "0"],
    ["second", 1, "1"],
  ]) {
    const f = postpaidLinuxFixture();
    f.dependencies.configuration.linuxPostpaidPilotTeamId = "team";
    f.dependencies.configuration.linuxPilotRepositoryId = "12345";
    f.job.id = f.dispatch.jobId = jobId;
    f.job.retryCount = retryCount;
    f.job.runCount = runCount;
    await f.run();
    assert.equal(f.dispatch.outcome, "success");
    assert.deepEqual(f.calls, [
      "verify",
      "period",
      "admit",
      "configure",
      "start",
      "create",
      "exec",
      "exec",
      "remove",
      "close",
      "complete",
    ]);
    assert.deepEqual(f.checkShas, [f.job.commitSha, f.job.commitSha]);
  }
});

test("recurring Linux admission requires both IDs and the saved GitHub.com host", async () => {
  for (const [teamId, repositoryId, jobHost] of [
    [undefined, undefined, "https://github.com"],
    [undefined, "12345", "https://github.com"],
    ["team", "", "https://github.com"],
    ["other-team", "12345", "https://github.com"],
    ["team", "67890", "https://github.com"],
    ["team", "12345", "https://github.example"],
    ["team", "12345", null],
  ]) {
    const f = postpaidLinuxFixture();
    f.dependencies.configuration.linuxPostpaidPilotTeamId = teamId;
    f.dependencies.configuration.linuxPilotRepositoryId = repositoryId;
    f.job.githubBaseUrl = jobHost;
    await f.run();
    assert.equal(f.dispatch.outcome, "failure");
    assert.ok(!f.calls.includes("period"));
    assert.ok(!f.calls.includes("create"));
  }
});

test("recurring Linux admission still requires a confirmed card before requesting a VM", async () => {
  const f = postpaidLinuxFixture({ customer: { stripeCustomerId: "cus_1", livemode: false } });
  f.dependencies.configuration.linuxPostpaidPilotTeamId = "team";
  f.dependencies.configuration.linuxPilotRepositoryId = "12345";
  const billing = new ExecutionBilling({});
  f.dependencies.billing.period = billing.period.bind(billing);
  f.dependencies.verifyCard = async (teamId, livemode) => {
    assert.equal(teamId, "team");
    assert.equal(livemode, false);
    f.calls.push("verifyCard");
    return null;
  };
  await f.run();
  assert.equal(f.dispatch.outcome, "card_required");
  assert.deepEqual(f.calls, ["verify", "verifyCard", "close", "complete"]);
});

test("PR builds check out the resolved merge SHA and report checks on the saved head SHA", async () => {
  const f = executionFixture(true);
  f.job.pullRequestNumber = "7";
  const mergeSha = "c".repeat(40);
  f.dependencies.github.resolveCheckout = async (job, accountId, signal) => {
    assert.equal(job.pullRequestNumber, "7");
    assert.equal(accountId, "1");
    assert.equal(signal.aborted, false);
    return {
      event: "pull_request",
      number: 7,
      headBranch: "feature/context",
      baseBranch: "develop",
      headSha: job.commitSha,
      baseSha: "b".repeat(40),
      checkoutSha: mergeSha,
    };
  };

  await f.run();

  assert.equal(f.dispatch.outcome, "success");
  assert.equal(f.scripts.length, 2);
  assert.ok(f.scripts[0].includes(`git checkout --detach '${mergeSha}'`));
  assert.ok(f.scripts[1].includes("flutter pub run 'openci/ci.dart'"));
  const context = JSON.parse(f.scripts[1].match(/export OPENCI_CONTEXT='([^']+)'/)[1]);
  assert.equal(context.event, "pull_request");
  assert.equal(context.headSha, f.job.commitSha);
  assert.equal(context.checkoutSha, mergeSha);
  assert.deepEqual(f.checkShas, [f.job.commitSha, f.job.commitSha]);
});

test("opted-in PRs publish only after a successful workflow and report publication failures", async () => {
  const url = "https://preview.example.org/build?r=1#install";
  for (const scenario of ["success", "workflow failure", "publication failure"]) {
    const f = executionFixture(true);
    f.job.pullRequestNumber = "7";
    const phases = [];
    f.dependencies.orchard.exec = async (_vm, script, output) => {
      if (script.includes("flutter pub run")) {
        phases.push("workflow");
        return scenario === "workflow failure" ? 1 : prQrOutputReady;
      }
      if (script.includes("/usr/bin/head")) {
        phases.push("read");
        await output("stdout", Buffer.from("ja\t120x120\t" + url + "\n"));
      }
      return 0;
    };
    f.dependencies.store.withPullRequestCommentLease = async (key, signal, work) => {
      assert.equal(key, "test");
      signal.throwIfAborted();
      return work(async () => {});
    };
    f.dependencies.github.postPullRequestQrCodes = async (
      job,
      account,
      runNumber,
      links,
      signal,
      withLease,
    ) => {
      phases.push("publish");
      assert.equal(job, f.job);
      assert.equal(account, "1");
      assert.equal(runNumber, 1);
      assert.deepEqual(links, [{ url, lang: "ja", width: 120, height: 120 }]);
      signal.throwIfAborted();
      await withLease("test", async (renew) => renew());
      if (scenario === "publication failure") throw new Error("private transport failure");
    };
    await f.run();
    assert.deepEqual(
      phases,
      scenario === "workflow failure" ? ["workflow"] : ["workflow", "read", "publish"],
    );
    assert.equal(f.dispatch.outcome, scenario === "success" ? "success" : "failure");
    if (scenario === "publication failure") {
      assert.match(f.dispatch.failureSummary, /could not publish the QR code/);
      assert.doesNotMatch(f.dispatch.failureSummary, /private transport/);
    }
  }
});

test("merge resolution failure completes the check before any build commands run", async () => {
  const f = executionFixture(true);
  f.job.pullRequestNumber = "7";
  f.dependencies.github.resolveCheckout = async () => {
    throw new PullRequestCheckoutError("conflicts");
  };

  await f.run();

  assert.equal(f.dispatch.outcome, "failure");
  assert.match(f.dispatch.failureSummary, /Resolve the conflicts and push/);
  assert.deepEqual(f.scripts, []);
  assert.ok(!f.calls.includes("create"));
  assert.deepEqual(f.checkShas, [f.job.commitSha]);
});

test("unexpected API errors are not published as a failure summary", async () => {
  const f = executionFixture(true);
  f.dependencies.github.resolveCheckout = async () => {
    throw new Error("Authorization: token private-token; request body contains private data");
  };

  await f.run();

  assert.equal(f.dispatch.outcome, "failure");
  assert.equal(f.dispatch.failureSummary, null);
});

for (const selfHosted of [true, false]) {
  test(`stale merge diagnostics stay in operator logs before billing or workflow (selfHosted=${selfHosted})`, async () => {
    const f = executionFixture(selfHosted);
    const diagnostics = {
      attempts: 24,
      elapsedMs: 600000,
      requestId: "ABCD:1234",
      headSha: f.job.commitSha,
      baseSha: "b".repeat(40),
      mergeSha: "c".repeat(40),
      mergeBaseSha: "d".repeat(40),
    };
    const error = new PullRequestCheckoutError("stale_merge", diagnostics);
    f.job.pullRequestNumber = "7";
    f.dependencies.github.resolveCheckout = async () => {
      throw error;
    };
    f.dependencies.secrets = async () => {
      throw new Error("Secrets must not be loaded");
    };
    const reports = [];
    f.dependencies.report = (...args) => reports.push(args);

    await f.run();

    assert.equal(f.dispatch.outcome, "failure");
    assert.equal(f.dispatch.failureSummary, error.message);
    assert.ok(!f.dispatch.failureSummary.includes(diagnostics.requestId));
    assert.deepEqual(reports, [
      ["pull_request_checkout_stale_merge", f.dispatch.id, diagnostics],
      ["execution_failure", f.dispatch.id],
    ]);
    assert.deepEqual(f.scripts, []);
    assert.ok(!f.calls.includes("create"));
    assert.ok(!f.calls.includes("period"));
    assert.deepEqual(f.checkShas, [f.job.commitSha]);
  });
}

test("cloud builds cannot bypass billing with a job field", async () => {
  const f = executionFixture(undefined);
  await f.run();
  assert.equal(f.dispatch.outcome, "blocked");
  assert.ok(f.calls.includes("period"));
  assert.ok(!f.calls.includes("create"));
});

test("self-hosting does not bypass connection validation or existing Stripe accounts", async () => {
  for (const change of [{ connection: null }, { customer: { stripeCustomerId: "existing" } }]) {
    const f = executionFixture(true, change);
    await f.run();
    assert.equal(f.dispatch.outcome, "failure");
    assert.ok(!f.calls.includes("create"));
  }
});
