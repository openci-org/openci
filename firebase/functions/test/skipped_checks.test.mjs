import assert from "node:assert/strict";
import { generateKeyPairSync } from "node:crypto";
import { test } from "node:test";
import { ExecutionGitHub } from "../../lib/functions/executor/github.js";
import {
  createdSkippedCheckIds,
  recoverSkippedChecks,
  reportSkippedCheck,
} from "../../lib/functions/skipped_checks.js";

function fixture() {
  const row = {
    id: "a".repeat(64),
    owner: "org",
    repo: "app",
    workflowName: "CI",
    workflowFileName: "ci.dart",
    commitSha: "a".repeat(40),
    comparisonBaseSha: "b".repeat(40),
    githubBaseUrl: "https://github.com",
    status: "pending",
    leaseOwner: null,
    leaseExpiresAt: null,
    checkRunId: null,
    createdAt: String(Math.floor(Date.now() / 1000)),
    connection: {
      status: "active",
      githubAppId: "1",
      githubApiBaseUrl: "https://api.github.com",
      installationId: "2",
      accountId: "10",
    },
  };
  const calls = [];
  const deps = {
    row,
    calls,
    store: {
      async claim(_id, owner) {
        if (row.status === "reported" || row.leaseOwner) return false;
        row.leaseOwner = owner;
        row.leaseExpiresAt = new Date(Date.now() + 300000).toISOString();
        return true;
      },
      async get() {
        return row;
      },
      async complete(_id, owner, checkRunId) {
        assert.equal(row.leaseOwner, owner);
        row.status = "reported";
        row.checkRunId = checkRunId;
        row.leaseOwner = null;
      },
      async retry(_id, owner) {
        calls.push("retry");
        if (row.leaseOwner === owner) row.leaseOwner = null;
      },
      async pending() {
        return [row.id];
      },
    },
    async report() {
      calls.push("report");
      return "42";
    },
  };
  return deps;
}

test("only successful committed mutation results can schedule skipped Checks", () => {
  const id = "a".repeat(64);
  assert.deepEqual(createdSkippedCheckIds({ data: { skipped: [{ id }] } }), [id]);
  assert.deepEqual(createdSkippedCheckIds({ data: { skipped: [{ id }] }, errors: [{}] }), []);
  assert.deepEqual(createdSkippedCheckIds({ data: { jobs: [{ id }] } }), []);
  assert.throws(() => createdSkippedCheckIds({ data: { skipped: [{ id: "bad" }] } }));
});

test("concurrent delivery and later redelivery report once", async () => {
  const deps = fixture();
  await Promise.all([reportSkippedCheck(deps.row.id, deps), reportSkippedCheck(deps.row.id, deps)]);
  await reportSkippedCheck(deps.row.id, deps);
  assert.deepEqual(deps.calls, ["report"]);
  assert.equal(deps.row.status, "reported");
});

test("failed reports remain retryable without creating any build work", async () => {
  const deps = fixture();
  deps.report = async () => {
    throw new Error("private HTTP data");
  };
  await assert.rejects(reportSkippedCheck(deps.row.id, deps), /retry required/);
  assert.equal(deps.row.status, "pending");
  assert.equal(deps.row.leaseOwner, null);
  deps.report = async () => "42";
  await reportSkippedCheck(deps.row.id, deps);
  assert.equal(deps.row.status, "reported");
});

test("a lost completion response does not reset an already reported outcome", async () => {
  const deps = fixture();
  const complete = deps.store.complete;
  deps.store.complete = async (...args) => {
    await complete(...args);
    throw new Error("lost");
  };
  await assert.rejects(reportSkippedCheck(deps.row.id, deps));
  await reportSkippedCheck(deps.row.id, deps);
  assert.deepEqual(deps.calls, ["report", "retry"]);
});

test("recovery continues after one report fails", async () => {
  const deps = fixture();
  deps.store.pending = async () => ["first", "second"];
  let count = 0;
  deps.report = async () => {
    if (++count === 1) throw new Error("outage");
    return "42";
  };
  const failures = [];
  await recoverSkippedChecks(deps, (id) => failures.push(id));
  assert.deepEqual(failures, ["first"]);
  assert.equal(deps.row.status, "reported");
});

test("GitHub skipped Checks reconcile lost responses and ignore other Apps' external IDs", async (t) => {
  const { privateKey } = generateKeyPairSync("rsa", {
    modulusLength: 2048,
    privateKeyEncoding: { type: "pkcs8", format: "pem" },
    publicKeyEncoding: { type: "spki", format: "pem" },
  });
  const deps = fixture();
  deps.row.leaseExpiresAt = new Date(Date.now() + 300000).toISOString();
  const externalId = "skipped-" + deps.row.id;
  const calls = [];
  let created = false;
  const original = globalThis.fetch;
  t.after(() => {
    globalThis.fetch = original;
  });
  globalThis.fetch = async (url, init) => {
    const parsed = new URL(url);
    const path = parsed.pathname;
    const body = init.body ? JSON.parse(init.body) : undefined;
    calls.push({ path, method: init.method, body });
    if (path.endsWith("/access_tokens")) {
      assert.deepEqual(body.permissions, { checks: "write" });
      assert.deepEqual(body.repositories, ["app"]);
      return Response.json({
        token: "check-token",
        expires_at: new Date(Date.now() + 3600000).toISOString(),
        permissions: body.permissions,
        repositories: [{ id: 101, name: "app" }],
        repository_selection: "selected",
      });
    }
    if (path === "/repos/org/app") return Response.json({ owner: { id: 10 } });
    if (path.includes("/commits/")) {
      const page = Number(parsed.searchParams.get("page"));
      return Response.json({
        total_count: created ? 101 : 1,
        check_runs:
          created && page === 2
            ? [{ id: 42, external_id: externalId, app: { id: 1 } }]
            : [{ id: 99, external_id: externalId, app: { id: 999 } }],
      });
    }
    if (path === "/repos/org/app/check-runs" && init.method === "POST") {
      assert.equal(body.head_sha, deps.row.commitSha);
      assert.equal(body.name, "CI");
      assert.equal(body.external_id, externalId);
      assert.equal(body.status, "completed");
      assert.equal(body.conclusion, "skipped");
      assert.equal(body.started_at, body.completed_at);
      created = true;
      throw new Error("Lost creation response");
    }
    if (path === "/repos/org/app/check-runs/42" && init.method === "PATCH")
      return Response.json({ id: 42 });
    assert.fail("Unexpected GitHub request: " + path);
  };
  const github = new ExecutionGitHub({
    appId: "1",
    privateKey,
    apiBaseUrl: "https://api.github.com",
    baseUrl: "https://github.com",
  });
  await assert.rejects(github.skippedCheck(deps.row));
  assert.equal(await github.skippedCheck(deps.row), "42");
  assert.equal(
    calls.filter((c) => c.path.endsWith("/check-runs") && c.method === "POST").length,
    1,
  );
  assert.equal(calls.filter((c) => c.method === "PATCH").length, 1);
  deps.row.leaseExpiresAt = new Date(Date.now() + 10000).toISOString();
  await assert.rejects(github.skippedCheck(deps.row), /lease expired/);
  assert.equal(calls.filter((c) => c.method === "PATCH").length, 1);
  deps.row.connection.status = "removed";
  await assert.rejects(github.skippedCheck(deps.row), /Invalid skipped Check context/);
});
