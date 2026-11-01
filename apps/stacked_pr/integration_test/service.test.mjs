import { test } from "node:test";
import assert from "node:assert/strict";
import { GitException } from "../lib/git.js";
import { PullRequest } from "../lib/models.js";
import { modify } from "../test/support/fixtures.mjs";
import { Harness, repo } from "./support/service_harness.mjs";

test("fresh invocation discovers a stack without changing aligned branches", async (t) => {
  const h = await Harness.create(t),
    before = await h.heads();
  await h.service.reconcile(10, repo);
  assert.deepEqual(await h.heads(), before);
  assert.equal(h.reports[0].error, undefined);
  assert.deepEqual(
    h.reports[0].pulls.map((p) => p.parent),
    [undefined, 1, 2],
  );
});
test("normal parent push discovers the earlier fork point from Git", async (t) => {
  const h = await Harness.create(t),
    parent = await h.f.advanceParent();
  await h.restart();
  await h.service.reconcile(10, repo);
  const heads = await h.heads();
  assert.equal(await h.f.output(["rev-parse", `${heads.get("child")}^`]), parent);
  assert.equal(await h.f.output(["rev-parse", `${heads.get("grandchild")}^`]), heads.get("child"));
  assert.equal(await h.f.output(["diff", "--name-only", parent, heads.get("child")]), "child.txt");
});
test("force-pushed parent is recovered from GitHub history with a fresh clone", async (t) => {
  const h = await Harness.create(t),
    parent = await h.rewriteParent();
  await h.restart();
  await h.service.reconcile(10, repo);
  const heads = await h.heads();
  assert.equal(h.reports[0].error, undefined);
  assert.equal(await h.f.output(["rev-parse", `${heads.get("child")}^`]), parent);
  assert.equal(await h.f.output(["rev-list", "--count", `${parent}..${heads.get("child")}`]), "1");
  assert.equal(await h.f.output(["diff", "--name-only", parent, heads.get("child")]), "child.txt");
});
test("missing force-push history blocks only the affected stack", async (t) => {
  const h = await Harness.create(t),
    independent = await h.addStack(4, "independent");
  await h.rewriteParent(false);
  const unchanged = await h.heads();
  await h.f.git(["checkout", independent[0].headRef]);
  const updated = await h.f.commit("new-independent.txt", "new\n", "advance");
  await h.f.git(["push", "origin", independent[0].headRef]);
  await h.service.reconcile(10, repo);
  assert.equal((await h.heads()).get("child"), unchanged.get("child"));
  const other = await h.f.worker.remoteHeads([independent[1].headRef]);
  assert.equal(await h.f.output(["rev-parse", `${other.get(independent[1].headRef)}^`]), updated);
  assert.equal(h.reports.filter((r) => r.error)[0].error.number, 2);
  assert.equal(h.reports.find((r) => r.pulls.some((p) => p.number === 5)).error, undefined);
});
for (const retarget of [false, true])
  test(`squash merge and deleted parent restack without saved state (retarget=${retarget})`, async (t) => {
    const h = await Harness.create(t),
      main = await h.merge(retarget);
    await h.restart();
    await h.service.reconcile(10, repo);
    const heads = await h.heads();
    assert.equal(h.reports[0].error, undefined);
    assert.equal(await h.f.output(["rev-parse", `${heads.get("child")}^`]), main);
    assert.equal(await h.f.output(["diff", "--name-only", main, heads.get("child")]), "child.txt");
    assert.equal(h.records[1].baseRef, "main");
  });
test("automatic base change after squash and parent deletion preserves child changes", async (t) => {
  const h = await Harness.create(t),
    main = await h.merge(true, true);
  await h.restart();
  await h.service.reconcile(10, repo, { number: 2 });
  const heads = await h.heads();
  assert.equal(h.reports.length, 1);
  assert.equal(h.reports[0].error, undefined);
  assert.equal(await h.f.output(["rev-parse", `${heads.get("child")}^`]), main);
  assert.equal(await h.f.output(["rev-list", "--count", `${main}..${heads.get("child")}`]), "1");
  assert.equal(await h.f.output(["diff", "--name-only", main, heads.get("child")]), "child.txt");
  assert.equal(await h.f.output(["rev-parse", `${heads.get("grandchild")}^`]), heads.get("child"));
  assert.equal(h.records[1].baseRef, "main");
});
test("lost response after atomic push recovers with a new invocation and no journal", async (t) => {
  const h = await Harness.create(t);
  await h.merge();
  h.failPatch = true;
  await assert.rejects(h.service.reconcile(10, repo), /outage after push/);
  const pushed = await h.heads();
  h.failPatch = false;
  await h.restart();
  await h.service.reconcile(10, repo);
  assert.deepEqual(await h.heads(), pushed);
  assert.equal(h.records[1].baseRef, "main");
  await h.restart();
  await h.service.reconcile(10, repo);
  assert.deepEqual(await h.heads(), pushed);
});
test("two merged ancestors recover a chain of automatic base changes", async (t) => {
  const h = await Harness.create(t);
  await h.f.git(["checkout", "parent"]);
  await h.f.git(["merge", "--squash", "child"]);
  await h.f.git(["commit", "-m", "squash child into parent"]);
  const mergedChild = await h.f.git(["rev-parse", "HEAD"]);
  await h.f.git(["push", "origin", "parent", ":child"]);
  h.records[1] = modify(h.records[1], { state: "closed", merged: true, mergeCommit: mergedChild });
  h.baseChange(3, "child", "parent", true);
  await h.f.git(["checkout", "main"]);
  await h.f.git(["merge", "--squash", "parent"]);
  await h.f.git(["commit", "-m", "squash parent into main"]);
  const main = await h.f.git(["rev-parse", "HEAD"]);
  await h.f.git(["push", "origin", "main", ":parent"]);
  h.records[0] = modify(h.records[0], {
    head: mergedChild,
    state: "closed",
    merged: true,
    mergeCommit: main,
  });
  h.baseChange(3, "parent", "main", true);
  h.records[2].baseRef = "main";
  await h.restart();
  await h.service.reconcile(10, repo, { number: 3 });
  const heads = await h.heads();
  assert.equal(h.reports[0].error, undefined);
  assert.equal(await h.f.output(["rev-parse", `${heads.get("grandchild")}^`]), main);
  assert.equal(
    await h.f.output(["diff", "--name-only", main, heads.get("grandchild")]),
    "grandchild.txt",
  );
});
test("a PR notification only fetches and updates the connected stack", async (t) => {
  const h = await Harness.create(t),
    other = await h.addStack(4, "other");
  await h.f.advanceParent();
  await h.f.git(["checkout", other[0].headRef]);
  await h.f.commit("other-new.txt", "new\n", "advance other");
  await h.f.git(["push", "origin", other[0].headRef]);
  const oldHead = (await h.f.worker.remoteHeads([other[1].headRef])).get(other[1].headRef);
  await h.restart();
  await h.service.reconcile(10, repo, { number: 2 });
  assert.equal(h.reports.length, 1);
  assert.ok(h.reports[0].pulls.every((p) => p.number <= 3));
  assert.equal((await h.f.worker.remoteHeads([other[1].headRef])).get(other[1].headRef), oldHead);
  await assert.rejects(h.f.worker.branch(other[1].headRef), GitException);
});
test("changing a PR base refreshes both affected stacks, leaving others alone", async (t) => {
  const h = await Harness.create(t);
  await h.addStack(4, "unrelated");
  h.records[2].baseRef = "main";
  h.baseChange(3, "child", "main");
  await h.service.handle({
    id: "base-change",
    event: "pull_request",
    payload: {
      action: "edited",
      installation: { id: 10 },
      repository: repo.toJson(),
      pull_request: { number: 3 },
      previous_base: "child",
    },
  });
  assert.equal(h.reports.length, 2);
  assert.deepEqual(
    new Set(h.reports.flatMap((r) => r.pulls).map((p) => p.number)),
    new Set([1, 2, 3]),
  );
});
test("branching children both follow their parent", async (t) => {
  const h = await Harness.create(t);
  await h.f.git(["checkout", "-b", "sibling", h.f.parent]);
  const sibling = await h.f.commit("sibling.txt", "sibling\n", "sibling");
  await h.f.git(["push", "origin", "sibling"]);
  h.records.push(
    new PullRequest({
      number: 4,
      title: "sibling",
      head: sibling,
      headRef: "sibling",
      base: h.f.parent,
      baseRef: "parent",
    }),
  );
  const parent = await h.f.advanceParent();
  await h.service.reconcile(10, repo);
  for (const head of (await h.f.worker.remoteHeads(["child", "sibling"])).values())
    assert.equal(await h.f.output(["rev-parse", `${head}^`]), parent);
  assert.equal(h.reports[0].error, undefined);
});
test("cycle reports stay within their component", async (t) => {
  const h = await Harness.create(t);
  await h.addStack(4, "healthy");
  h.records[0].baseRef = "grandchild";
  await h.service.reconcile(10, repo);
  assert.ok(h.reports.find((r) => r.pulls.some((p) => p.number === 2)).error);
  assert.equal(h.reports.find((r) => r.pulls.some((p) => p.number === 5)).error, undefined);
});
test("conflict does not push any member of its stack", async (t) => {
  const h = await Harness.create(t);
  await h.f.git(["checkout", "child"]);
  await h.f.commit("parent.txt", "child edit\n", "child edit");
  await h.f.git(["push", "origin", "child"]);
  await h.f.git(["checkout", "parent"]);
  await h.f.commit("parent.txt", "parent edit\n", "parent edit");
  await h.f.git(["push", "origin", "parent"]);
  const before = await h.heads();
  await h.service.reconcile(10, repo);
  assert.deepEqual(await h.heads(), before);
  assert.deepEqual(h.reports[0].error.files, ["parent.txt"]);
});
test("closed unmerged parent requires a decision without prior app execution", async (t) => {
  const h = await Harness.create(t);
  h.records[0] = modify(h.records[0], { state: "closed" });
  await h.service.reconcile(10, repo);
  assert.match(h.reports[0].error.message, /mergeされず/);
});
test("observe mode does not rebase; unauthorized sync cannot enable it", async (t) => {
  const h = await Harness.create(t, false);
  await h.f.advanceParent();
  const before = await h.heads();
  await h.service.reconcile(10, repo);
  assert.deepEqual(await h.heads(), before);
  h.api.canWrite = async () => false;
  await h.service.handle({
    id: "sync",
    event: "issue_comment",
    payload: {
      action: "created",
      installation: { id: 10 },
      repository: repo.toJson(),
      issue: { pull_request: {} },
      comment: { body: "/stack sync" },
      sender: { login: "reader", type: "User" },
    },
  });
  assert.deepEqual(await h.heads(), before);
});
test("removed installations do no repository work", async (t) => {
  const h = await Harness.create(t);
  h.api.installationActive = async () => false;
  h.api.list = async () => assert.fail("removed installation must not access repository");
  await h.service.handle({
    id: "old",
    event: "reconcile",
    payload: { installation: { id: 10 }, repository: repo.toJson() },
  });
});
test("repository reconciliation fans out to one bounded task per connected stack", async (t) => {
  const h = await Harness.create(t);
  await h.addStack(4, "other");
  await h.service.handle({
    id: "installation-20",
    event: "reconcile",
    payload: { installation: { id: 10 }, repository: repo.toJson() },
  });
  assert.deepEqual(
    h.enqueued.map((j) => j.payload.pull_request.number),
    [1, 4],
  );
  assert.equal(h.reports.length, 0);
});
