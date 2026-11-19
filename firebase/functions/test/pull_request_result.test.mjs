import assert from "node:assert/strict";
import { test } from "node:test";
import { ExecutionGitHub } from "../../lib/functions/executor/github.js";
import { failedPullRequestComment } from "../../lib/functions/pull_request_failure.js";
import { retryFromPullRequest } from "../../lib/functions/pull_request_retry.js";
import { retryCheckboxClick } from "../../lib/functions/pull_request_retry_control.js";
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
  runsOn: "macos-latest",
  retryCount: 0,
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
    base: { repo: { id: 10 } },
    head: { repo: { id: 10 }, sha },
  };
  const comments = [],
    writes = [];
  const flags = {
    loseResponse: false,
    deleteBeforeEdit: false,
    files: ["apps/client/lib/menu.dart"],
    permission: "write",
    member: "verified-member",
    actorId: 27,
    loseRetryResponse: false,
  };
  let tail = Promise.resolve(),
    logsRead = 0,
    tokens = 0,
    revoked = 0;
  const store = {
    retryMember: async () => flags.member,
    retryAsMember: async (id, count, uid) => {
      assert.deepEqual([id, count, uid], [job.id, current.job.retryCount, "verified-member"]);
      current.job.retryCount++;
      current.job.status = "QUEUED";
      if (flags.loseRetryResponse) throw new Error("Lost successful mutation response");
    },
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
    if (route.includes("/collaborators/"))
      return { data: { permission: flags.permission, user: { id: flags.actorId } } };
    if (route === "GET /repos/{owner}/{repo}/issues/comments/{comment_id}")
      return { data: { ...comments.find((c) => c.id === args.comment_id) } };
    if (route.includes("/git/trees/")) {
      assert.equal(args.tree_sha, current.job.commitSha);
      return {
        data: { truncated: false, tree: flags.files.map((path) => ({ type: "blob", path })) },
      };
    }
    if (route.startsWith("GET") && route.endsWith("/comments"))
      return { data: comments.slice((args.page - 1) * args.per_page, args.page * args.per_page) };
    if (route.startsWith("POST") && route.endsWith("/comments")) {
      comments.push({
        id: comments.length + 1,
        user: { type: "Bot" },
        performed_via_github_app: { id: 7 },
        issue_url: "https://git.example/api/v3/repos/org/app/issues/3",
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
    assert.equal(purpose, "pr_comment");
    tokens++;
    return { request, token: "fixture" };
  });
  const report = () =>
    reportCompletedPullRequest(job.id, current.latest.id, store, github, "https://dash.example");
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
  assert.match(original.body, /- \[ \] このジョブを再実行/);
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
  assert.doesNotMatch(original.body, /このジョブを再実行|openci-retry:/);
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
function checkBox(f) {
  const comment = f.comments[0];
  const from = comment.body;
  comment.body = from.replace("- [ ] このジョブを再実行", "- [x] このジョブを再実行");
  const event = {
    action: "edited",
    issue: { number: 3, state: "open", pull_request: {} },
    installation: { id: 40 },
    repository: { id: 10 },
    comment: { ...comment },
    sender: { type: "User", id: 27, login: "maintainer" },
    changes: { body: { from } },
  };
  return { event, click: retryCheckboxClick(event) };
}

test("a checked App comment retries only this attempt and acknowledges it in place after lost responses", async (t) => {
  const f = fixture(t);
  await f.report();
  const { click } = checkBox(f);
  assert.ok(click);
  f.flags.loseRetryResponse = true;
  f.flags.loseResponse = true;
  await assert.rejects(retryFromPullRequest(click, f.store, f.github), /response lost/);
  f.flags.loseResponse = false;
  await Promise.all([
    retryFromPullRequest(click, f.store, f.github),
    retryFromPullRequest(click, f.store, f.github),
  ]);
  assert.equal(f.current.job.retryCount, 1);
  assert.deepEqual(f.writes, ["create", "edit"]);
  assert.match(f.comments[0].body, /⏳ 再実行を受け付けました/);
  assert.match(f.comments[0].body, /lib\/menu.dart/);
  assert.doesNotMatch(f.comments[0].body, /このジョブを再実行/);
  f.next("failure");
  await f.report();
  assert.match(f.comments[0].body, /- \[ \] このジョブを再実行/);
  await retryFromPullRequest(click, f.store, f.github);
  assert.equal(f.current.job.retryCount, 1);
  const second = checkBox(f).click;
  await retryFromPullRequest(second, f.store, f.github);
  f.next("success");
  await f.report();
  assert.equal(f.current.job.retryCount, 2);
  assert.doesNotMatch(f.comments[0].body, /openci-retry:|このジョブを再実行|受け付けました/);
  assert.match(f.comments[0].body, /前回のエラーを見る/);
});

test("only the exact human checkbox edit on the current App comment can request a retry", async (t) => {
  const f = fixture(t);
  await f.report();
  const { event, click } = checkBox(f);
  assert.equal(retryCheckboxClick({ ...event, sender: { ...event.sender, type: "Bot" } }), null);
  assert.equal(
    retryCheckboxClick({ ...event, comment: { ...event.comment, user: { type: "User" } } }),
    null,
  );
  assert.equal(
    retryCheckboxClick({ ...event, changes: { body: { from: "copied request" } } }),
    null,
  );
  assert.equal(retryCheckboxClick({ ...event, issue: { number: 3, state: "open" } }), null);
  assert.equal(
    retryCheckboxClick({ ...event, changes: { body: { from: event.comment.body } } }),
    null,
  );
  const retry = (changes) => retryFromPullRequest({ ...click, ...changes }, f.store, f.github);
  for (const mismatch of [
    { pr: "4" },
    { installationId: "41" },
    { repositoryId: "11" },
    { scope: "0".repeat(64) },
    { team: "0".repeat(64) },
    { order: "1" },
  ])
    await retry(mismatch);
  f.pr.head.sha = "f".repeat(40);
  await retry({});
  f.pr.head.sha = sha;
  f.comments[0].performed_via_github_app.id = 8;
  await retry({});
  f.comments[0].performed_via_github_app.id = 7;
  f.comments[0].issue_url += "7";
  await retry({});
  f.comments[0].issue_url = f.comments[0].issue_url.slice(0, -1);
  f.comments[0].body = event.changes.body.from;
  await retry({});
  assert.equal(f.current.job.retryCount, 0);
  assert.deepEqual(f.writes, ["create"]);
});

test("denied clicks restore the control for a verified team member with repository write access", async (t) => {
  const f = fixture(t);
  await f.report();
  for (const [member, permission, actorId] of [
    [null, "write", 27],
    ["verified-member", "read", 27],
    ["verified-member", "write", 43],
  ]) {
    Object.assign(f.flags, { member, permission, actorId });
    await retryFromPullRequest(checkBox(f).click, f.store, f.github);
    assert.match(f.comments[0].body, /権限を確認してください。\n- \[ \] このジョブを再実行/);
    assert.equal(f.current.job.retryCount, 0);
  }
  Object.assign(f.flags, { member: "verified-member", permission: "admin", actorId: 27 });
  await retryFromPullRequest(checkBox(f).click, f.store, f.github);
  assert.match(f.comments[0].body, /⏳ 再実行を受け付けました/);
  assert.doesNotMatch(f.comments[0].body, /権限を確認/);
});
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
