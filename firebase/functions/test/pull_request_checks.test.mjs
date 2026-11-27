import assert from "node:assert/strict";
import { test } from "node:test";
import { ExecutionGitHub } from "../../lib/functions/executor/github.js";

const head = "a".repeat(40);
const repo = { id: 10, owner: { id: 4 }, full_name: "org/app" };
const signal = new AbortController().signal;

function fixture(t) {
  const github = new ExecutionGitHub({
    appId: "1",
    privateKey: "fixture",
    baseUrl: "https://git.example",
    apiBaseUrl: "https://git.example/api/v3",
  });
  const pulls = new Map();
  const runs = [];
  const patches = [];
  function pull(number, branch, base, merge) {
    const pr = {
      number,
      state: "open",
      merged: false,
      mergeable: true,
      merge_commit_sha: merge.repeat(40),
      base: { repo, ref: branch, sha: base.repeat(40) },
      head: { repo, ref: "feature", sha: head },
    };
    pulls.set(number, pr);
    const job = {
      id: `job-${number}`,
      owner: "org",
      repo: "app",
      repositoryId: "10",
      installationId: "2",
      pullRequestNumber: String(number),
      commitSha: head,
      workflowName: "CI",
      workflowFileName: "ci.dart",
      runCount: "0",
      retryCount: 0,
      status: "QUEUED",
      branch: "feature",
    };
    const dispatch = {
      runId: `run-${number}`,
      updatedAt: new Date().toISOString(),
      pullRequestBaseSha: pr.base.sha,
      pullRequestBaseBranch: branch,
      checkRunId: null,
    };
    return { job, pr, dispatch };
  }
  const request = async (route, args) => {
    if (route === "DELETE /installation/token") return {};
    assert.equal(args.owner, "org");
    assert.equal(args.repo, "app");
    switch (route) {
      case "GET /repos/{owner}/{repo}":
        return { data: repo };
      case "GET /repos/{owner}/{repo}/commits/{commit_sha}/pulls":
        assert.equal(args.commit_sha, head);
        return { data: [...pulls.values()].filter((pr) => pr.state === "open") };
      case "GET /repos/{owner}/{repo}/pulls":
        return { data: [...pulls.values()].filter((pr) => pr.state === "open") };
      case "GET /repos/{owner}/{repo}/pulls/{pull_number}":
        return { data: pulls.get(args.pull_number), headers: {} };
      case "GET /repos/{owner}/{repo}/git/ref/{ref}": {
        const refs = [...pulls.values()].flatMap((pr) => [pr.base, pr.head]);
        const ref = refs.find((ref) => args.ref === "heads/" + ref.ref);
        return { data: { ref: "refs/" + args.ref, object: { type: "commit", sha: ref.sha } } };
      }
      case "GET /repos/{owner}/{repo}/git/commits/{commit_sha}": {
        const pr = [...pulls.values()].find((pr) => pr.merge_commit_sha === args.commit_sha);
        return { data: { sha: args.commit_sha, parents: [pr.base, pr.head] } };
      }
      case "GET /repos/{owner}/{repo}/commits/{ref}/check-runs": {
        assert.notEqual(args.ref, head);
        const matching = runs.filter(
          (run) => run.head_sha === args.ref && run.name === args.check_name,
        );
        return { data: { total_count: matching.length, check_runs: matching } };
      }
      case "POST /repos/{owner}/{repo}/check-runs": {
        assert.notEqual(args.head_sha, head);
        const run = { ...args, id: runs.length + 1, app: { id: 1 } };
        runs.push(run);
        return { data: run };
      }
      case "GET /repos/{owner}/{repo}/check-runs/{check_run_id}":
        return { data: runs.find((run) => run.id === Number(args.check_run_id)) };
      case "PATCH /repos/{owner}/{repo}/check-runs/{check_run_id}": {
        const run = runs.find((run) => run.id === Number(args.check_run_id));
        assert.notEqual(run.head_sha, head);
        patches.push(run.id);
        return { data: Object.assign(run, args) };
      }
      default:
        assert.fail(route);
    }
  };
  t.mock.method(github, "client", async () => ({ request }));
  async function queue({ job, dispatch }) {
    dispatch.checkRunId = await github.queuedCheck(
      job,
      `queued-${job.id}-${job.retryCount}`,
      null,
      "4",
      signal,
    );
    return dispatch.checkRunId;
  }
  const result = ({ job, dispatch }, outcome) =>
    github.check(job, dispatch, outcome, { accountId: "4" });
  return { github, pull, runs, patches, queue, result };
}

test("a conflicting sibling cannot publish a failed check on the successful PR's head or test merge", async (t) => {
  const f = fixture(t);
  const clean = f.pull(1, "base-one", "b", "c");
  const conflicting = f.pull(2, "base-two", "d", "e");
  conflicting.pr.mergeable = false;
  delete conflicting.dispatch.pullRequestBaseSha;
  await f.queue(clean);
  assert.equal(await f.queue(conflicting), null);
  await f.result(clean, "success");
  assert.equal(await f.result(conflicting, "failure"), null);
  assert.deepEqual(
    f.runs.map((r) => [r.head_sha, r.conclusion]),
    [[clean.pr.merge_commit_sha, "success"]],
  );
});

test("identically named checks keep opposite results and retries on their respective test merges", async (t) => {
  const f = fixture(t);
  const first = f.pull(1, "base-one", "b", "c");
  const second = f.pull(2, "base-two", "d", "e");
  await Promise.all([f.queue(first), f.queue(second)]);
  await Promise.all([f.result(second, "failure"), f.result(first, "success")]);
  const firstRun = f.runs.find((r) => r.head_sha === first.pr.merge_commit_sha);
  const secondRun = f.runs.find((r) => r.head_sha === second.pr.merge_commit_sha);
  assert.equal(firstRun.conclusion, "success");
  assert.equal(secondRun.conclusion, "failure");
  assert.equal(firstRun.name, secondRun.name);
  second.job.retryCount++;
  await f.queue(second);
  await f.result(second, "success");
  assert.equal(f.runs.length, 3);
  assert.equal(f.runs.at(-1).head_sha, second.pr.merge_commit_sha);
  assert.equal(firstRun.conclusion, "success");
  assert.equal(secondRun.conclusion, "failure");
});

test("a saved legacy head check is replaced on the test merge; an unready or retargeted merge never receives a past result", async (t) => {
  const f = fixture(t);
  const p = f.pull(1, "base-one", "b", "c");
  f.runs.push({ id: 1, name: "CI", app: { id: 1 }, head_sha: head, status: "queued" });
  p.dispatch.checkRunId = "1";
  assert.equal(await f.result(p, "success"), "2");
  assert.deepEqual(f.patches, []);
  const correct = p.pr.merge_commit_sha;
  p.pr.mergeable = null;
  assert.equal(await f.result(p, "success"), null);
  await assert.rejects(
    f.github.check(p.job, p.dispatch, "success", { accountId: "4", retryPending: true }),
    /pending/,
  );
  p.pr.mergeable = true;
  p.pr.base.sha = "f".repeat(40);
  assert.equal(await f.result(p, "success"), null);
  await assert.rejects(
    f.github.check(p.job, p.dispatch, "success", { accountId: "4", retryPending: true }),
    /base changed during check publication/,
  );
  p.pr.base.sha = p.dispatch.pullRequestBaseSha;
  p.pr.base.ref = "retargeted";
  assert.equal(await f.result(p, "success"), null);
  p.pr.base.ref = p.dispatch.pullRequestBaseBranch;
  assert.equal(await f.result(p, "success"), "2");
  assert.equal(f.runs[1].head_sha, correct);
});

test("a replacement validation publishes success on the new test merge and leaves the obsolete check cancelled", async (t) => {
  const f = fixture(t);
  const first = f.pull(1, "main", "b", "c");
  await f.queue(first);
  const replacement = f.pull(1, "main", "d", "e");
  assert.equal(await f.result(first, "success"), null);
  assert.equal(f.runs[0].conclusion, "cancelled");
  replacement.job.id = "replacement";
  replacement.dispatch.runId = "replacement-run";
  await f.queue(replacement);
  await f.result(replacement, "success");
  assert.deepEqual(
    f.runs.map((r) => [r.head_sha, r.conclusion]),
    [
      [first.pr.merge_commit_sha, "cancelled"],
      [replacement.pr.merge_commit_sha, "success"],
    ],
  );
});

test("path exclusions publish a skipped check only for the originating PR and comparison base", async (t) => {
  const f = fixture(t);
  const p = f.pull(1, "base-one", "b", "c");
  const check = {
    id: "skipped",
    owner: "org",
    repo: "app",
    commitSha: head,
    workflowName: "CI",
    comparisonBaseSha: p.pr.base.sha,
    githubBaseUrl: "https://git.example",
    leaseExpiresAt: new Date(Date.now() + 300_000).toISOString(),
    createdAt: "1",
    connection: {
      status: "active",
      githubApiBaseUrl: f.github.options.apiBaseUrl,
      githubAppId: "1",
      accountId: "4",
      repositoryId: "10",
      installationId: "2",
    },
    webhookTask: {
      eventType: "pull_request",
      payload: JSON.stringify({ number: 1, pull_request: p.pr }),
    },
  };
  assert.equal(await f.github.skippedCheck(check), "1");
  p.pr.mergeable = null;
  await assert.rejects(f.github.skippedCheck(check), /pending/);
  p.pr.mergeable = false;
  assert.equal(await f.github.skippedCheck(check), null);
  assert.deepEqual(
    f.runs.map((r) => [r.head_sha, r.conclusion]),
    [[p.pr.merge_commit_sha, "skipped"]],
  );
});

test("the pinned check completes on the tested merge even after the PR closes", async (t) => {
  const f = fixture(t);
  const p = f.pull(1, "base-one", "b", "c");
  await f.queue(p);
  p.dispatch.pullRequestMergeSha = p.pr.merge_commit_sha;
  assert.equal(await f.result(p), "1");
  p.pr.state = "closed";
  assert.equal(await f.github.check(p.job, p.dispatch, "success"), "1");
  assert.equal(f.runs[0].head_sha, p.dispatch.pullRequestMergeSha);
  assert.equal(f.runs[0].conclusion, "success");
});

test("an identical synthetic commit cannot carry results for two pull requests", async (t) => {
  const f = fixture(t);
  const first = f.pull(1, "base-one", "b", "c");
  const second = f.pull(2, "base-two", "b", "c");
  assert.equal(await f.queue(first), null);
  assert.equal(await f.queue(second), null);
  assert.equal(await f.result(first, "success"), null);
  assert.equal(await f.result(second, "failure"), null);
  assert.deepEqual(
    f.runs.map((r) => [r.head_sha, r.conclusion]),
    [[first.pr.merge_commit_sha, "action_required"]],
  );
});

test("retargeting retires only the previous queued check for the same PR", async (t) => {
  const f = fixture(t);
  const p = f.pull(1, "base-one", "b", "c");
  await f.queue(p);
  p.pr.base.sha = "d".repeat(40);
  p.pr.merge_commit_sha = "e".repeat(40);
  p.dispatch.pullRequestBaseSha = p.pr.base.sha;
  p.dispatch.pullRequestMergeSha = p.pr.merge_commit_sha;
  assert.equal(await f.result(p, "failure"), "2");
  assert.deepEqual(
    f.runs.map((r) => [r.head_sha, r.conclusion]),
    [
      ["c".repeat(40), "cancelled"],
      ["e".repeat(40), "failure"],
    ],
  );
});

test("a later PR sharing an existing green check cannot use it to satisfy a required check", async (t) => {
  const f = fixture(t);
  const first = f.pull(1, "base-one", "b", "c");
  await f.queue(first);
  await f.result(first, "success");
  const second = f.pull(2, "base-two", "b", "c");
  assert.equal(await f.queue(second), null);
  assert.equal(f.runs[0].conclusion, "action_required");
  assert.equal(f.runs[0].details_url, "https://git.example/org/app/pulls");
  first.pr.state = "closed";
  assert.equal(await f.result(second, "failure"), null);
  assert.equal(f.runs.length, 1);
  assert.equal(f.runs[0].conclusion, "action_required");
});

test("cancelling a queued PR after its base moves completes only the original queued check", async (t) => {
  const f = fixture(t);
  const p = f.pull(1, "base-one", "b", "c");
  const id = await f.queue(p);
  p.pr.base.sha = "d".repeat(40);
  p.pr.merge_commit_sha = "e".repeat(40);
  p.job.status = "CANCELLED";
  await f.github.queuedCheck(p.job, "queued-retry", id, "4", signal);
  await f.github.queuedCheck(p.job, "lost-response", null, "4", signal);
  assert.deepEqual(
    f.runs.map((r) => [r.head_sha, r.conclusion]),
    [["c".repeat(40), "cancelled"]],
  );
});
