import { test } from "node:test";
import assert from "node:assert/strict";
import { GitException } from "../lib/git.js";
import { PullRequest, RestackException } from "../lib/models.js";
import { planRestack } from "../lib/stack.js";
import { modify, raw } from "../test/support/fixtures.mjs";
import { GitFixture } from "./support/git_fixture.mjs";

test("squash merge preserves only child changes and cascades to grandchild", async (t) => {
  const f = await GitFixture.create(t),
    squash = await f.squash(true);
  f.pulls[1].baseRef = "main";
  const plan = await planRestack(f.pulls, f.worker);
  assert.equal(plan.pulls[1].baseRef, "main");
  assert.equal(plan.pulls[1].parent, undefined);
  assert.equal(plan.pulls[1].boundary, squash);
  assert.equal(await f.output(["rev-list", "--count", `${squash}..${plan.pulls[1].head}`]), "1");
  assert.equal(await f.output(["diff", "--name-only", squash, plan.pulls[1].head]), "child.txt");
  assert.equal(
    await f.output(["diff", "--name-only", plan.pulls[1].head, plan.pulls[2].head]),
    "grandchild.txt",
  );
  await f.worker.push(plan.changes);
  assert.equal((await f.worker.remoteHeads(["child"])).get("child"), plan.pulls[1].head);
});
test("amended parent uses recorded boundary rather than merge-base", async (t) => {
  const f = await GitFixture.create(t);
  await f.git(["checkout", "parent"]);
  await f.commit("parent.txt", "parent revised\n", "fix");
  await f.git(["reset", "--soft", f.main]);
  await f.git(["commit", "-m", "rewritten parent"]);
  f.pulls[0].head = await f.git(["rev-parse", "HEAD"]);
  await f.git(["push", "--force", "origin", "parent"]);
  await f.worker.prepare();
  const plan = await planRestack(f.pulls, f.worker);
  assert.equal(await f.output(["show", `${plan.pulls[2].head}:parent.txt`]), "parent revised");
  assert.equal(
    await f.output(["rev-list", "--count", `${f.pulls[0].head}..${plan.pulls[1].head}`]),
    "1",
  );
});
test("conflict in last layer pushes no earlier successful layer", async (t) => {
  const f = await GitFixture.create(t);
  await f.git(["checkout", "grandchild"]);
  f.pulls[2].head = await f.commit("parent.txt", "grandchild conflicting edit\n", "conflict");
  await f.git(["push", "origin", "grandchild"]);
  await f.git(["checkout", "parent"]);
  f.pulls[0].head = await f.commit("parent.txt", "parent conflicting edit\n", "fix");
  await f.git(["push", "origin", "parent"]);
  await f.worker.prepare();
  await assert.rejects(planRestack(f.pulls, f.worker), (error) => {
    assert.ok(error instanceof RestackException);
    assert.equal(error.number, 3);
    assert.deepEqual(error.files, ["parent.txt"]);
    return true;
  });
  const heads = await f.worker.remoteHeads(["child", "grandchild"]);
  assert.equal(heads.get("child"), f.child);
  assert.equal(heads.get("grandchild"), f.pulls[2].head);
});
test("atomic lease rejects all refs when one branch has a concurrent push", async (t) => {
  const f = await GitFixture.create(t);
  await f.advanceParent();
  const plan = await planRestack(f.pulls, f.worker);
  await f.git(["checkout", "grandchild"]);
  const human = await f.commit("human.txt", "human\n", "concurrent human");
  await f.git(["push", "origin", "grandchild"]);
  await assert.rejects(f.worker.push(plan.changes), GitException);
  const heads = await f.worker.remoteHeads(["child", "grandchild"]);
  assert.equal(heads.get("child"), f.child);
  assert.equal(heads.get("grandchild"), human);
});
test("already synchronized or manually restacked children are unchanged", async (t) => {
  const f = await GitFixture.create(t);
  f.pulls[1].boundary = f.main;
  const plan = await planRestack(f.pulls, f.worker);
  assert.equal(plan.pulls[1].head, f.child);
  assert.equal(plan.pulls[2].head, f.grandchild);
  assert.equal(plan.pulls[1].boundary, f.parent);
});
test("two merged ancestors retarget to surviving trunk", async (t) => {
  const f = await GitFixture.create(t);
  await f.git(["checkout", "main"]);
  await f.git(["merge", "--squash", "child"]);
  await f.git(["commit", "-m", "land both"]);
  const main = await f.git(["rev-parse", "HEAD"]);
  await f.git(["push", "origin", "main"]);
  await f.worker.prepare();
  for (let i = 0; i < 2; i++) f.pulls[i] = modify(f.pulls[i], { state: "closed", merged: true });
  const plan = await planRestack(f.pulls, f.worker);
  assert.equal(plan.pulls[2].baseRef, "main");
  assert.equal(await f.output(["diff", "--name-only", main, plan.pulls[2].head]), "grandchild.txt");
});
test("fetch removes deleted target refs while keeping pinned boundary", async (t) => {
  const f = await GitFixture.create(t);
  await f.worker.pin(f.parent);
  await f.git(["push", "origin", ":parent"]);
  await f.worker.prepare();
  await assert.rejects(f.worker.branch("parent"), GitException);
  assert.equal(await f.worker.has(f.parent), true);
});
test("missing boundary after child rewrite stops without overwriting", async (t) => {
  const f = await GitFixture.create(t),
    target = await f.advanceParent();
  await assert.rejects(
    f.worker.rebase({ number: 2, head: f.child, boundary: target, target }),
    /変更境界/,
  );
});
test("a null GitHub merge SHA cannot be used to guess a missing child boundary", async (t) => {
  const f = await GitFixture.create(t);
  await f.squash();
  f.pulls[0] = PullRequest.fromApi({ ...raw(f.pulls[0]), merge_commit_sha: null }, 20);
  f.pulls[1].boundary = f.grandchild;
  const before = await f.worker.remoteHeads(["parent", "child", "grandchild"]);
  await assert.rejects(planRestack(f.pulls, f.worker), (error) => {
    assert.ok(error instanceof RestackException);
    assert.equal(error.number, 2);
    assert.match(error.message, /変更境界/);
    return true;
  });
  assert.deepEqual(await f.worker.remoteHeads(["parent", "child", "grandchild"]), before);
});
test("merged boundary recovery rejects multiple merge bases", async (t) => {
  const f = await GitFixture.create(t),
    squash = await f.squash();
  await f.git(["checkout", "-b", "left", squash]);
  const left = await f.commit("left.txt", "left\n", "left side");
  await f.git(["checkout", "-b", "right", squash]);
  const right = await f.commit("right.txt", "right\n", "right side");
  await f.git(["merge", "--no-ff", "left", "-m", "join from right"]);
  const target = await f.git(["rev-parse", "HEAD"]),
    tree = await f.git(["rev-parse", "HEAD^{tree}"]);
  const head = await f.git(["commit-tree", tree, "-p", left, "-p", right, "-m", "join from left"]);
  await f.git(["branch", "other-join", head]);
  await f.git(["push", "origin", "right", "other-join"]);
  await f.worker.prepare();
  assert.equal(
    await f.worker.findMergedBoundary({ head, target, mergeCommits: [squash] }),
    undefined,
  );
});
