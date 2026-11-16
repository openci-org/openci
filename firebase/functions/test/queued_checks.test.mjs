import assert from "node:assert/strict";
import { test } from "node:test";
import { QueuedChecks } from "../../lib/functions/queued_checks.js";
import { DispatchRetry } from "../../lib/functions/build_dispatch.js";

const queryError = () =>
  Object.assign(new Error("private database details"), { code: "data-connect/query-error" });
const busy = (error) => error instanceof DispatchRetry && error.reason === "check_publication_busy";

function fixture() {
  const state = {
    job: {
      id: "job",
      status: "QUEUED",
      runsOn: "macos-latest",
      runCount: "0",
      teamId: "team",
      installationId: "2",
      commitSha: "a".repeat(40),
    },
    dispatch: null,
  };
  const calls = [];
  const store = {
    read: async () => structuredClone(state),
    acquire: async (_, owner) => {
      calls.push("acquire");
      state.job.checkOwner = owner;
      state.job.checkLeaseUntil = new Date(Date.now() + 300_000).toISOString();
    },
    record: async (_, owner, runNumber, checkRunId) => {
      assert.equal(state.job.checkOwner, owner);
      state.job.checkRunNumber = runNumber;
      state.job.checkRunId = checkRunId;
    },
    release: async (_, owner) => {
      assert.equal(state.job.checkOwner, owner);
      state.job.checkOwner = null;
      state.job.checkLeaseUntil = null;
    },
    context: async () => ({ team: {}, connection: { accountId: "10" } }),
  };
  const github = {
    options: { appId: "1", apiBaseUrl: "https://api.github.com" },
    queuedCheck: async () => {
      calls.push("github");
      return "100";
    },
  };
  const checks = new QueuedChecks(store, github);
  const competingLease = () => {
    state.job.checkOwner = "other";
    state.job.checkLeaseUntil = new Date(Date.now() + 300_000).toISOString();
  };
  return { state, store, github, checks, calls, competingLease };
}

for (const status of ["QUEUED", "CANCELLED"]) {
  test(`a live publisher defers ${status} work before acquiring or calling GitHub`, async () => {
    const f = fixture();
    f.state.job.status = status;
    f.competingLease();
    await assert.rejects(f.checks.sync("job"), busy);
    assert.deepEqual(f.calls, []);
  });
}

test("a saved Check with a live lease defers until release acknowledgement or expiry", async () => {
  const f = fixture();
  f.competingLease();
  Object.assign(f.state.job, { checkRunId: "100", checkRunNumber: "1" });
  await assert.rejects(f.checks.sync("job"), busy);
  f.state.job.checkLeaseUntil = new Date(0).toISOString();
  await f.checks.sync("job");
  assert.deepEqual(f.calls, []);
});

test("acquisition contention rereads durable state and defers without exposing the SDK error", async () => {
  const f = fixture();
  f.store.acquire = async () => {
    f.competingLease();
    throw queryError();
  };
  await assert.rejects(f.checks.sync("job"), busy);
  assert.deepEqual(f.calls, []);
  Object.assign(f.state.job, {
    checkOwner: null,
    checkLeaseUntil: null,
    checkRunId: "100",
    checkRunNumber: "1",
  });
  await f.checks.sync("job");
  assert.deepEqual(f.calls, []);
});

for (const outcome of ["published", "reserved", "running", "cancelled", "deleted"]) {
  test(`a ${outcome} job wins acquisition and is reconciled without publishing a stale Check`, async () => {
    const f = fixture();
    f.store.acquire = async () => {
      if (outcome === "published")
        Object.assign(f.state.job, { checkRunId: "100", checkRunNumber: "1" });
      if (outcome === "reserved") f.state.dispatch = { id: "dispatch" };
      if (outcome === "running") f.state.job.status = "IN_PROGRESS";
      if (outcome === "cancelled") f.state.job.status = "CANCELLED";
      if (outcome === "deleted") f.state.job = null;
      throw queryError();
    };
    await f.checks.sync("job");
    assert.deepEqual(f.calls, []);
  });
}

test("a changed run defers to a fresh delivery instead of publishing the stale run", async () => {
  const f = fixture();
  f.store.acquire = async () => {
    f.state.job.runCount = "1";
    throw queryError();
  };
  await assert.rejects(f.checks.sync("job"), busy);
  assert.deepEqual(f.calls, []);
});

for (const code of [
  "data-connect/query-error",
  "data-connect/permission-denied",
  "data-connect/unavailable",
  "app/network-timeout",
]) {
  test(`${code} without evidence of contention retains the original failure`, async () => {
    const f = fixture();
    const failure = Object.assign(new Error("private SDK response"), { code });
    f.store.acquire = async () => {
      throw failure;
    };
    await assert.rejects(f.checks.sync("job"), (error) => error === failure);
    assert.deepEqual(f.calls, []);
  });
}

test("permission errors are not reclassified even if another publisher completes", async () => {
  const f = fixture();
  const failure = Object.assign(new Error("private permission details"), {
    code: "data-connect/permission-denied",
  });
  f.store.acquire = async () => {
    Object.assign(f.state.job, { checkRunId: "100", checkRunNumber: "1" });
    throw failure;
  };
  await assert.rejects(f.checks.sync("job"), (error) => error === failure);
});

test("a failed reconciliation read remains an error", async () => {
  const f = fixture();
  const failure = new Error("read unavailable");
  f.store.acquire = async () => {
    f.store.read = async () => {
      throw failure;
    };
    throw queryError();
  };
  await assert.rejects(f.checks.sync("job"), (error) => error === failure);
});

test("a lost acquisition acknowledgement keeps its lease and later recovers", async () => {
  const f = fixture();
  const acquire = f.store.acquire;
  const failure = Object.assign(new Error("lost response"), { code: "app/network-timeout" });
  f.store.acquire = async (...args) => {
    await acquire(...args);
    throw failure;
  };
  await assert.rejects(f.checks.sync("job"), (error) => error === failure);
  await assert.rejects(f.checks.sync("job"), busy);
  assert.deepEqual(f.calls, ["acquire"]);
  f.state.job.checkLeaseUntil = new Date(0).toISOString();
  f.store.acquire = acquire;
  await f.checks.sync("job");
  assert.deepEqual(f.calls, ["acquire", "acquire", "github"]);
  assert.equal(f.state.job.checkRunId, "100");
});

test("record failures remain errors and do not release an ambiguous publication", async () => {
  const f = fixture();
  const failure = queryError();
  f.store.record = async () => {
    throw failure;
  };
  await assert.rejects(f.checks.sync("job"), (error) => error === failure);
  assert.ok(f.state.job.checkOwner);
  await assert.rejects(f.checks.sync("job"), busy);
  assert.deepEqual(f.calls, ["acquire", "github"]);
});

test("a lost acquisition race still defers cancellation when its winner has already released", async () => {
  const f = fixture();
  Object.assign(f.state.job, { status: "CANCELLED", checkRunId: "100", checkRunNumber: "1" });
  f.store.acquire = async () => {
    throw new DispatchRetry("check_publication_busy");
  };
  await assert.rejects(f.checks.sync("job"), busy);
  assert.deepEqual(f.calls, []);
});
