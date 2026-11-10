import assert from "node:assert/strict";
import { test } from "node:test";
import { mkdtemp, rm } from "node:fs/promises";
import { spawnSync } from "node:child_process";
import { tmpdir } from "node:os";
import { join } from "node:path";
import {
  fadPrOutputPath,
  fadPrOutputReady,
  workflowScript,
} from "../../lib/functions/executor/model.js";
import { publishFadPullRequest, readFadTesterLinks } from "../../lib/functions/executor/fad_pr.js";

const job = {
  id: "job",
  owner: "org",
  repo: "app",
  pullRequestNumber: "3",
  commitSha: "a".repeat(40),
  workflowFileName: "cd.dart",
};
const dispatch = {
  id: "test",
  runId: "run-test",
  teamId: "team",
  createdAt: "2026-01-01T00:00:00Z",
};
const link = "https://appdistribution.firebase.google.com/testerapps/1:123:ios:abc/releases/demo";
const signal = new AbortController().signal;

test("only a successful PR workflow with output requests publication", async (t) => {
  const dir = await mkdtemp(join(tmpdir(), "openci-fad-script-"));
  t.after(() => rm(dir, { recursive: true, force: true }));
  const script = workflowScript(job, dispatch, 1, {}).replaceAll(
    fadPrOutputPath,
    join(dir, "output"),
  );
  for (const [write, status, expected] of [
    [false, 0, 0],
    [true, 0, fadPrOutputReady],
    [true, fadPrOutputReady, 1],
    [true, 3, 1],
  ]) {
    const stub = `cd() { :; }\nflutter() { if [ "$2" = run ]; then ${write ? 'echo test > "$OPENCI_FAD_PR_OUTPUT";' : ""} return ${status}; fi; }\n`;
    const result = spawnSync("/bin/bash", ["-s"], { input: stub + script, encoding: "utf8" });
    assert.equal(result.status, expected, result.stderr);
  }
  assert.match(
    workflowScript({ ...job, pullRequestNumber: null }, dispatch, 1, {}),
    /OPENCI_FAD_PR_OUTPUT=''/,
  );
});

test("VM output only accepts a bounded list of release-specific iOS tester links", async () => {
  const read = (data, code = 0) =>
    readFadTesterLinks(
      {
        async exec(_vm, _script, output) {
          await output("stderr", Buffer.from("diagnostic"));
          for (const chunk of data) await output("stdout", Buffer.from(chunk));
          return code;
        },
      },
      "vm",
      signal,
    );
  assert.deepEqual(await read([link.slice(0, 4), link.slice(4) + "\n", link + "\n"]), [link]);
  for (const data of [
    link,
    link + "?token=private\n",
    link.replace(".com/", ".com.evil/") + "\n",
    "a".repeat(4097),
    (link + "\n").repeat(9),
  ]) {
    await assert.rejects(read([data]));
  }
  await assert.rejects(read([link + "\n"], 1));
});

function githubFixture() {
  const pr = {
    number: 3,
    state: "open",
    base: { repo: { id: 10 } },
    head: { repo: { id: 10 }, sha: job.commitSha },
  };
  const comments = [];
  const treeInputs = [];
  let tip = null;
  const trees = new Map();
  let counter = 0;
  const otherError = (status) => Object.assign(new Error("GitHub error"), { status });
  const state = { conflict: false, lostResponse: false, pr, comments, treeInputs };
  const request = async (route, args) => {
    assert.equal(args.owner, job.owner);
    assert.equal(args.repo, job.repo);
    let data;
    if (route === "GET /repos/{owner}/{repo}")
      data = { id: 10, full_name: "org/app", owner: { id: 4 } };
    else if (route.includes("/pulls/")) data = pr;
    else if (route.startsWith("GET") && route.endsWith("/comments")) data = comments;
    else if (route.includes("git/ref/")) {
      assert.equal(args.ref, "heads/genuineci/fad-qr");
      if (!tip) throw otherError(404);
      data = { object: { sha: tip } };
    } else if (route.startsWith("GET") && route.includes("git/commits/"))
      data = { tree: { sha: trees.get(tip) } };
    else if (route.endsWith("/git/trees")) {
      treeInputs.push(args);
      data = { sha: "qr-tree" };
    } else if (route.endsWith("/git/commits")) {
      assert.deepEqual(args.parents, tip ? [tip] : []);
      const sha = (++counter).toString(16).padStart(40, "0");
      trees.set(sha, args.tree);
      data = { sha };
    } else if (route.includes("/git/refs")) {
      if (state.conflict) {
        state.conflict = false;
        tip = "b".repeat(40);
        trees.set(tip, "concurrent-tree");
        throw otherError(422);
      }
      if (tip) assert.equal(args.force, false);
      tip = args.sha;
      data = {};
    } else if (route.startsWith("POST") && route.endsWith("/comments")) {
      assert.equal(args.issue_number, 3);
      comments.push({ performed_via_github_app: { id: 7 }, body: args.body });
      if (state.lostResponse) throw otherError(500);
      data = {};
    } else assert.fail(route);
    return { data };
  };
  return {
    ...state,
    state,
    publish: (account = "4", links = [link]) =>
      publishFadPullRequest(request, "7", job, account, dispatch, 17, links),
  };
}

test("publishes a pinned, repository-local QR and reconciles a raced branch or lost comment response", async () => {
  const f = githubFixture();
  f.state.conflict = true;
  f.state.lostResponse = true;
  f.comments.push({ performed_via_github_app: { id: 9 }, body: "<!-- openci-fad-pr:run-test -->" });
  await f.publish();
  assert.equal(f.treeInputs.length, 2);
  assert.equal(f.treeInputs[1].base_tree, "concurrent-tree");
  const [file] = f.treeInputs[1].tree;
  assert.match(file.content, /^<svg /);
  assert.match(file.content, /fill="white"/);
  assert.equal(f.comments.length, 2);
  assert.ok(f.comments[1].body.includes(link));
  assert.ok(f.comments[1].body.includes(`../blob/${"2".padStart(40, "0")}/${file.path}?raw=true`));
  assert.match(f.comments[1].body, /Run #17/);
  await f.publish();
  assert.equal(f.comments.length, 2);
  assert.equal(f.treeInputs.length, 2);
});

test("rejects another owner or a signed URL and skips changed, closed, or fork PRs", async () => {
  const f = githubFixture();
  await assert.rejects(f.publish("999"));
  await assert.rejects(f.publish("4", ["https://example.com/signed"]));
  f.pr.head.sha = "new";
  await f.publish();
  f.pr.head.sha = job.commitSha;
  f.pr.state = "closed";
  await f.publish();
  f.pr.state = "open";
  f.pr.head.repo.id = 11;
  await f.publish();
  assert.equal(f.treeInputs.length, 0);
  assert.equal(f.comments.length, 0);
});
