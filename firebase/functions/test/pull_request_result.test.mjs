import assert from "node:assert/strict";
import { test } from "node:test";
import { ExecutionGitHub } from "../../lib/functions/executor/github.js";
import { failedPullRequestComment } from "../../lib/functions/pull_request_failure.js";
import {
  reportCompletedPullRequest,
  reportPullRequestBuildResult,
} from "../../lib/functions/pull_request_result_function.js";

const sha = "a".repeat(40);
const job = {
  id: "job",
  teamId: "team",
  owner: "org",
  repo: "app",
  repositoryId: "10",
  installationId: "40",
  githubBaseUrl: "https://git.example",
  commitSha: sha,
  pullRequestNumber: "3",
  workflowFileName: "analysis.dart",
  workflowName: "Static Analysis",
  status: "FAILURE",
};
const attempt = {
  id: "dispatch",
  teamId: "team",
  runId: "run-dispatch",
  checkRunId: "42",
  outcome: "failure",
  createdAt: "2026-01-02T00:00:00.123456Z",
  finishedAt: "2026-01-02T00:01:00Z",
};
const log = (messages) => ({
  failed: [{ stepId: "run_workflow" }],
  tail: messages
    .map((message) => ({ message: message + "\n", stepId: "run_workflow", stream: "stdout" }))
    .reverse(),
});
const sample = log([
  "[STDOUT] error • From a passing command • other.dart:1:1 • old",
  '[OK] command "earlier" executed successfully',
  "[STDOUT]   error • Undefined name 'counter'. Try correcting the name • lib/menu.dart:12:3 • undefined_identifier",
  "[STDOUT]   error • Too many positional arguments: 1 expected, but 2 found. • lib/menu.dart:23:7 • extra_positional_arguments",
  "[STDOUT]   error • Undefined name 'label'. • lib/menu.dart:30:2 • undefined_identifier",
  '[ERROR] command "flutter analyze --suppress-analytics" failed with exit code 1',
  "Failed to update packages.",
]);

function fixture(t) {
  const current = { job: { ...job }, latest: { ...attempt } };
  const pr = {
    number: 3,
    state: "open",
    base: { repo: { id: 10 }, ref: "main", sha: "b".repeat(40) },
    head: { repo: { id: 10 }, ref: "feature", sha },
  };
  const comments = [],
    writes = [];
  const flags = {
    baseTip: pr.base.sha,
    loseResponse: false,
    deleteBeforeEdit: false,
    files: ["apps/client/lib/menu.dart"],
  };
  let tail = Promise.resolve(),
    logsRead = 0,
    tokens = 0,
    revoked = 0;
  const store = {
    pullRequestCommentExecution: async () => structuredClone(current),
    pullRequestFailureLog: async () => {
      logsRead++;
      return sample;
    },
    context: async () => ({ connection: { accountId: "4" } }),
    withPullRequestCommentLease: (_id, _signal, work) => {
      const pending = tail.then(() => work(async () => {}));
      tail = pending.catch(() => {});
      return pending;
    },
  };
  const github = new ExecutionGitHub({
    appId: "7",
    privateKey: "fixture",
    apiBaseUrl: "https://git.example/api/v3",
    baseUrl: job.githubBaseUrl,
    dashboardOrigin: "https://dash.example",
  });
  // Use the production REST routes and publication/ownership checks; only the
  // transport and the isolated repository are in memory.
  const request = async (route, args = {}) => {
    if (route.startsWith("DELETE /installation/token")) {
      revoked++;
      return {};
    }
    assert.equal(args.repo, "app");
    if (route === "GET /repos/{owner}/{repo}")
      return { data: { id: 10, owner: { id: 4 }, full_name: "org/app" } };
    if (route.includes("/pulls/")) return { data: pr };
    if (route === "GET /repos/{owner}/{repo}/git/ref/{ref}") {
      assert.equal(args.ref, "heads/" + pr.base.ref);
      return { data: { ref: "refs/" + args.ref, object: { type: "commit", sha: flags.baseTip } } };
    }
    if (route.includes("/git/trees/")) {
      assert.equal(args.tree_sha, current.job.commitSha);
      return {
        data: { truncated: false, tree: flags.files.map((path) => ({ type: "blob", path })) },
      };
    }
    if (route.startsWith("GET") && route.endsWith("/comments"))
      return { data: comments.slice((args.page - 1) * args.per_page, args.page * args.per_page) };
    if (route.startsWith("POST") && route.endsWith("/comments")) {
      assert.equal(args.issue_number, Number(current.job.pullRequestNumber));
      comments.push({
        id: comments.length + 1,
        user: { type: "Bot" },
        performed_via_github_app: { id: 7 },
        body: args.body,
      });
      writes.push("create");
    } else if (route.startsWith("PATCH") && route.includes("/issues/comments/")) {
      const comment = comments.find((c) => c.id === args.comment_id);
      assert.ok(comment);
      if (flags.deleteBeforeEdit) {
        comments.splice(comments.indexOf(comment), 1);
        throw Object.assign(new Error("Comment removed"), { status: 404 });
      }
      comment.body = args.body;
      writes.push("edit");
    } else assert.fail(route);
    if (flags.loseResponse) throw Object.assign(new Error("response lost"), { status: 502 });
    return {};
  };
  request.defaults = () => request;
  t.mock.method(github, "client", async (_job, purpose) => {
    assert.ok(["pr_comment", "pull_request"].includes(purpose));
    tokens++;
    return { request, token: "fixture" };
  });
  const deliveries = [];
  const report = (enqueue = async (delivery) => deliveries.push(delivery)) =>
    reportCompletedPullRequest(job.id, current.latest.id, store, github, enqueue);
  function next(outcome, commit = current.job.commitSha) {
    current.latest = {
      ...current.latest,
      id: current.latest.id + "x",
      outcome,
      createdAt: new Date(Date.parse(current.latest.createdAt) + 1000).toISOString(),
    };
    current.job = { ...current.job, status: outcome.toUpperCase(), commitSha: commit };
    pr.head.sha = commit;
  }
  t.after(() => assert.equal(tokens, revoked));
  return {
    current,
    pr,
    comments,
    writes,
    flags,
    store,
    github,
    deliveries,
    report,
    next,
    logsRead: () => logsRead,
  };
}

test("a PR failure posts linked diagnostics, then edits the same app comment on failure and recovery", async (t) => {
  const f = fixture(t);
  f.next("success");
  await f.report();
  assert.deepEqual(f.writes, []);
  assert.equal(f.logsRead(), 0);
  f.next("failure");
  f.flags.loseResponse = true;
  await Promise.all([f.report(), f.report()]);
  assert.deepEqual(f.writes, ["create"]);
  assert.equal(f.logsRead(), 1);
  const original = f.comments[0];
  assert.match(original.body, /### ❌ Static Analysis が失敗しました/);
  assert.match(original.body, /`flutter analyze` が 3 件のエラー/u);
  assert.ok(
    original.body.includes(
      `[12:3](https://git.example/org/app/blob/${sha}/apps/client/lib/menu.dart#L12)`,
    ),
  );
  assert.match(original.body, /https:\/\/dash.example\/runs\/job/);
  assert.doesNotMatch(original.body, /From a passing|Failed to update packages|Try correcting/);
  const copy = { ...original, id: 10, user: { type: "User" } };
  f.comments.unshift(copy);
  f.next("failure", "b".repeat(40));
  await f.report();
  assert.deepEqual(f.writes, ["create", "edit"]);
  assert.notEqual(copy.body, original.body);
  const failed = original.body;
  f.next("success", "c".repeat(40));
  await f.report();
  await f.report();
  assert.deepEqual(f.writes, ["create", "edit", "edit"]);
  assert.equal(original.id, 1);
  assert.match(original.body, /### ✅ Static Analysis のエラーが解消しました/);
  assert.match(original.body, /<summary>前回のエラーを見る（3件）<\/summary>/u);
  assert.ok(original.body.includes("b".repeat(40)));
  assert.match(original.body, /runs\/42/);
  assert.equal(f.logsRead(), 2);
  f.next("success");
  await f.report();
  assert.equal(f.writes.length, 3);
  f.next("failure");
  await f.report();
  assert.equal(f.writes.at(-1), "edit");
  assert.match(original.body, /### ❌ /);
  assert.doesNotMatch(original.body, /<details>/);
  assert.notEqual(original.body, failed);
});

test("a checkout conflict before the run posts its reason and log on the originating PR", async (t) => {
  const f = fixture(t);
  Object.assign(f.current.latest, {
    checkRunId: null,
    runId: null,
    failureSummary: "Merge conflict with the target branch.",
  });
  await f.report();
  assert.deepEqual(f.writes, ["create"]);
  assert.match(f.comments[0].body, /Merge conflict with the target branch/);
  assert.match(f.comments[0].body, /https:\/\/dash\.example\/runs\/job/);
  assert.equal(f.logsRead(), 0);
});

test("a base update requests the live revision idempotently without publishing stale results", async (t) => {
  const f = fixture(t);
  f.next("success");
  Object.assign(f.current.latest, {
    checkRunId: null,
    pullRequestBaseBranch: "main",
    pullRequestBaseSha: f.pr.base.sha,
  });
  f.flags.baseTip = "c".repeat(40);
  await assert.rejects(
    f.report(async (delivery) => {
      f.deliveries.push(delivery);
      throw new Error("acknowledgement lost");
    }),
    /acknowledgement lost/,
  );
  await Promise.all([f.report(), f.report()]);
  f.next("failure");
  f.current.job.workflowFileName = "other.dart";
  f.current.latest.checkRunId = "42";
  await f.report();
  assert.equal(f.deliveries.length, 4);
  assert.deepEqual(f.deliveries.slice(0, 3), Array(3).fill(f.deliveries[0]));
  assert.equal(f.deliveries[3].payload, f.deliveries[0].payload);
  assert.notEqual(f.deliveries[3].deliveryId, f.deliveries[0].deliveryId);
  const payload = JSON.parse(f.deliveries[0].payload);
  assert.equal(payload.openci_team_id, job.teamId);
  assert.deepEqual(payload.pull_request.base, {
    ref: "main",
    sha: f.flags.baseTip,
    repo: { id: 10 },
  });
  assert.deepEqual(payload.pull_request.head, { ref: "feature", sha, repo: { id: 10 } });
  assert.equal(f.writes.length, 0);
  assert.equal(f.logsRead(), 0);
  f.flags.baseTip = "d".repeat(40);
  await f.report();
  assert.notEqual(f.deliveries.at(-1).deliveryId, f.deliveries[0].deliveryId);
});

test("closed, retargeted, forked and superseded PRs do not request a base revalidation", async (t) => {
  const f = fixture(t);
  Object.assign(f.current.latest, {
    pullRequestBaseBranch: "main",
    pullRequestBaseSha: f.pr.base.sha,
  });
  f.flags.baseTip = "c".repeat(40);
  f.pr.state = "closed";
  await f.report();
  f.pr.state = "open";
  f.pr.base.ref = "different";
  await f.report();
  f.pr.base.ref = "main";
  f.pr.head.repo.id = 999;
  await f.report();
  f.pr.head.repo.id = 10;
  f.pr.head.sha = "d".repeat(40);
  await f.report();
  assert.deepEqual(f.deliveries, []);
  assert.deepEqual(f.writes, []);
});

test("a locally merged success is visible on its PR while its check is pending and is reconciled on redelivery", async (t) => {
  const f = fixture(t);
  f.next("success");
  const latest = f.current.latest;
  Object.assign(latest, {
    checkRunId: null,
    pullRequestBaseSha: "b".repeat(40),
    pullRequestBaseBranch: "main",
  });
  let checks = 0;
  t.mock.method(f.github, "check", async (source, dispatch, outcome, context) => {
    assert.equal(source.pullRequestNumber, "3");
    assert.equal(dispatch.pullRequestBaseSha, latest.pullRequestBaseSha);
    assert.equal(outcome, "success");
    assert.equal(context.retryPending, true);
    if (++checks === 1) throw new Error("pending");
    return "73";
  });
  f.store.completedCheck = async (id, jobId, runId, checkRunId) => {
    assert.deepEqual([id, jobId, runId, checkRunId], [latest.id, job.id, latest.runId, "73"]);
    latest.checkRunId = checkRunId;
  };
  await assert.rejects(f.report(), /pending/);
  assert.match(f.comments[0].body, /が成功しました/);
  await Promise.all([f.report(), f.report()]);
  assert.equal(checks, 2);
  assert.deepEqual(f.writes, ["create"]);
});

test("a rejected PR comment cannot prevent the matching late check from being recorded", async (t) => {
  const f = fixture(t);
  Object.assign(f.current.latest, {
    checkRunId: null,
    pullRequestBaseSha: "b".repeat(40),
    pullRequestBaseBranch: "main",
  });
  t.mock.method(f.github, "postPullRequestResult", async () => {
    throw new Error("Comment permission denied");
  });
  t.mock.method(f.github, "check", async (_job, _attempt, _outcome, context) => {
    await context.beforeWrite();
    return "90";
  });
  f.store.completedCheck = async (_dispatchId, _jobId, _runId, id) => {
    f.current.latest.checkRunId = id;
  };
  await assert.rejects(f.report(), /Comment permission denied/);
  assert.equal(f.current.latest.checkRunId, "90");
});

test("obsolete attempts, push, cancelled, forked, closed and superseded PRs stay quiet", async (t) => {
  const f = fixture(t);
  await reportCompletedPullRequest(job.id, "old", f.store, f.github);
  f.current.job.pullRequestNumber = null;
  await f.report();
  f.current.job.pullRequestNumber = "3";
  f.next("cancelled");
  await f.report();
  f.next("failure");
  f.pr.head.repo.id = 11;
  await f.report();
  f.pr.head.repo.id = 10;
  f.pr.state = "closed";
  await f.report();
  f.pr.state = "open";
  f.pr.head.sha = "b".repeat(40);
  await f.report();
  assert.deepEqual(f.writes, []);
  assert.equal(f.logsRead(), 0);
  f.pr.head.sha = sha;
  const read = f.store.pullRequestCommentExecution;
  let reads = 0;
  f.store.pullRequestCommentExecution = async () => {
    if (++reads === 2) f.next("success");
    return read();
  };
  await f.report();
  assert.deepEqual(f.writes, []);
  assert.equal(f.logsRead(), 0);
});

test("ambiguous source locations stay readable and a deleted failure is not recreated on success", async (t) => {
  const f = fixture(t);
  f.flags.files.push("apps/other/lib/menu.dart");
  await f.report();
  assert.match(f.comments[0].body, /\| 12:3 \|/);
  assert.doesNotMatch(f.comments[0].body, /#L12/);
  f.next("success");
  f.flags.deleteBeforeEdit = true;
  await f.report();
  assert.deepEqual(f.writes, ["create"]);
  assert.equal(f.comments.length, 0);
});

const noFiles = async () => new Map();
test("unstructured errors, timeout and pre-run failures retain useful fallbacks without command arguments", async () => {
  const content = await failedPullRequestComment(
    job,
    attempt,
    log([
      "[STDERR] Error: signing failed",
      "[STDERR] Error: MY_API_TOKEN=private-value",
      '[ERROR] command "custom --credential private-value" failed with exit code 27',
      "Failed to update packages.",
    ]),
    noFiles,
  );
  assert.match(content, /signing failed/);
  assert.match(content, /終了コード 27/);
  assert.doesNotMatch(content, /private-value|Failed to update packages/);
  assert.match(
    await failedPullRequestComment(job, { ...attempt, outcome: "timed_out" }, undefined, noFiles),
    /タイムアウト/u,
  );
  assert.match(
    await failedPullRequestComment(
      job,
      { ...attempt, failureSummary: "Merge conflict." },
      undefined,
      noFiles,
    ),
    /Merge conflict/,
  );
});

test("selects only failed-step diagnostics, bounds the table and omits unresolved source links", async () => {
  const data = log(
    Array.from(
      { length: 12 },
      (_, i) => `warning - lib/source.dart:${i + 1}:2 - Unused name - unused_name`,
    ),
  );
  data.tail.push({ stepId: "checkout", stream: "stderr", message: "fatal: unrelated\n" });
  const result = await failedPullRequestComment(job, attempt, data, noFiles);
  assert.match(result, /12 件の指摘/u);
  assert.match(result, /先頭 10 件/u);
  assert.match(result, /\| 10:2 \|/);
  assert.doesNotMatch(result, /11:2|#L|\/blob\/|unrelated/);
});

test("failed or superseded completion events are ignored and client principals cannot report", async () => {
  const event = {
    id: "event",
    authType: "admin",
    data: { payload: { data: { completed: 0 }, variables: { id: "attempt", jobId: "job" } } },
  };
  await reportPullRequestBuildResult.run(event);
  await reportPullRequestBuildResult.run({
    ...event,
    data: { payload: { errors: [{ message: "rolled back" }] } },
  });
  await assert.rejects(
    reportPullRequestBuildResult.run({ ...event, authType: "app_user" }),
    /requires retry/u,
  );
});
