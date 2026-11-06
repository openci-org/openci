import { test } from "node:test";
import assert from "node:assert/strict";
import { setImmediate } from "node:timers/promises";
import { Repository, RestackException } from "../lib/models.js";
import { Reporter, render, marker, stackActions } from "../lib/report.js";
import { chain, modify, fakeApi } from "./support/fixtures.mjs";

const repo = new Repository(1, "org/repo"),
  conflict = new RestackException("Conflict", 2, ["lib/conflict.dart"]);
function sample() {
  const unrelated = modify(chain()[0], { number: 200, headRef: "unrelated", head: "d".repeat(40) });
  return { unrelated, pulls: [...chain(), unrelated] };
}
for (const merged of [false, true])
  test(`a stack rooted outside the default branch requires attention (merged parent=${merged})`, () => {
    const pulls = chain();
    pulls[0] = modify(pulls[0], {
      baseRef: "integration-base",
      state: merged ? "closed" : "open",
      merged,
    });
    for (const pr of pulls.filter((p) => p.isOpen)) {
      const view = render(pulls, pr, { defaultBranch: "main" });
      assert.equal(view.conclusion, "action_required");
      assert.match(view.body, /integration-base/);
      assert.match(view.body, /main.*つながっていません/);
      assert.doesNotMatch(view.body, /依存する未mergeの親PRはありません/);
      assert.doesNotMatch(view.body, /Checkの \*\*Merge stack\*\*/);
    }
  });
test("reporter warns after a parent merge leaves a stack on a comparison branch", async () => {
  const root = modify(chain()[1], { parent: undefined, baseRef: "integration-base" }),
    child = chain()[2],
    writes = [];
  const api = fakeApi({
    request: async (_installation, _method, path, body) => writes.push({ path, body }),
  });
  await new Reporter(api).publish(1, new Repository(1, "org/repo", "main"), [root, child]);
  const checks = writes.filter((w) => w.path.endsWith("/check-runs"));
  assert.equal(checks.length, 2);
  for (const { body } of checks) {
    assert.equal(body.conclusion, "action_required");
    assert.match(body.output.summary, /integration-base/);
    assert.deepEqual(
      body.actions.map((a) => a.identifier),
      ["restack"],
    );
  }
});
test("an intentional standalone release PR stays outside stack reporting", async () => {
  const pr = modify(chain()[0], { baseRef: "release/1.x" }),
    writes = [];
  const api = fakeApi({ request: async (...args) => writes.push(args) });
  await new Reporter(api).publish(1, new Repository(1, "org/repo", "main"), [pr]);
  assert.equal(writes.length, 0);
});
test("a repaired root on a non-main default branch clears the warning", () => {
  const pulls = chain();
  pulls[0].baseRef = "develop";
  const view = render(pulls, pulls[0], { defaultBranch: "develop" });
  assert.equal(view.conclusion, "success");
  assert.doesNotMatch(view.body, /つながっていません/);
});
test("an active merge can still be cancelled after its root becomes unresolved", () => {
  const pulls = chain();
  pulls[0].baseRef = "integration-base";
  const view = render(pulls, pulls[0], { defaultBranch: "main", merging: true });
  assert.match(view.body, /Cancel merge/);
  assert.deepEqual(
    stackActions(true, view.canMerge).map((a) => a.identifier),
    ["restack", "cancel-merge"],
  );
});
test("restack conflicts take precedence over an unresolved base warning", () => {
  const pulls = chain();
  pulls[0].baseRef = "integration-base";
  const view = render(pulls, pulls[1], { defaultBranch: "main", error: conflict });
  assert.equal(view.conclusion, "failure");
  assert.match(view.body, /lib\/conflict.dart/);
});
test("conflict fails only the affected stack, including its parent and descendants", () => {
  const { unrelated, pulls } = sample();
  for (const pr of pulls.slice(0, 3)) {
    const view = render(pulls, pr, { error: conflict });
    assert.equal(view.conclusion, "failure");
    assert.match(view.body, /Restack停止 · #2/);
    assert.match(view.body, /lib\/conflict.dart/);
  }
  const view = render(pulls, unrelated, { error: conflict });
  assert.equal(view.conclusion, "success");
  assert.doesNotMatch(view.body, /Restack停止|lib\/conflict.dart/);
});
test("unrelated stack retains its parent dependency status", () => {
  const { unrelated, pulls } = sample(),
    child = modify(unrelated, { number: 201, headRef: "unrelated-child", parent: 200 });
  pulls.push(child);
  const view = render(pulls, child, { error: conflict });
  assert.equal(view.conclusion, "action_required");
  assert.match(view.body, /依存先：#200/);
  assert.doesNotMatch(view.body, /Restack停止/);
});
test("errors without a PR number apply to all supplied PRs", () => {
  const { pulls } = sample(),
    error = new RestackException("GitHub API unavailable");
  for (const pr of pulls) {
    const view = render(pulls, pr, { error });
    assert.equal(view.conclusion, "failure");
    assert.ok(view.body.includes(error.message));
  }
});
test("reporter creates no comment or check for an unrelated standalone PR", async () => {
  const { pulls } = sample(),
    writes = [],
    reads = [];
  const api = fakeApi({
    list: async (_installation, path) => {
      reads.push(path);
      return [];
    },
    request: async (_installation, method, path, body) => {
      writes.push({ method, path, body });
    },
  });
  await new Reporter(api).publish(1, repo, pulls, { error: conflict });
  assert.ok(writes.every((w) => !w.path.includes("/200/")));
  assert.ok(reads.every((path) => !path.includes("d".repeat(40))));
  const checks = writes.filter((w) => w.path.endsWith("/check-runs")).map((w) => w.body);
  assert.deepEqual(
    checks.map((c) => c.external_id),
    ["stacked-pr:1:1", "stacked-pr:1:2", "stacked-pr:1:3"],
  );
  assert.ok(checks.every((c) => c.conclusion === "failure"));
});
test("independent PR reports overlap within the API limit and remain idempotent", async () => {
  const root = chain()[0];
  const pulls = [
    root,
    ...Array.from({ length: 9 }, (_, i) =>
      modify(chain()[1], {
        number: i + 2,
        headRef: `child-${i}`,
        head: (i + 2).toString(16).padStart(40, "0"),
      }),
    ),
  ];
  const comments = new Map(),
    checks = new Map();
  let active = 0,
    peak = 0,
    writes = 0;
  const api = fakeApi({
    list: async (_installation, path) => {
      peak = Math.max(peak, ++active);
      await setImmediate();
      active--;
      const number = path.includes("check-runs")
        ? pulls.find((p) => path.includes(p.head)).number
        : Number(path.split("/").at(-2));
      const value = (path.includes("check-runs") ? checks : comments).get(number);
      return value ? [value] : [];
    },
    request: async (_installation, method, path, body) => {
      writes++;
      assert.equal(method, "POST");
      peak = Math.max(peak, ++active);
      await setImmediate();
      active--;
      if (path.endsWith("/comments")) {
        const number = Number(path.split("/").at(-2));
        assert.equal(comments.has(number), false);
        comments.set(number, { id: number, ...body, performed_via_github_app: { id: 7 } });
      } else {
        const number = Number(body.external_id.split(":").at(-1));
        assert.equal(checks.has(number), false);
        checks.set(number, { id: number, ...body, app: { id: 7 } });
      }
    },
  });
  const reporter = new Reporter(api);
  await reporter.publish(1, repo, pulls);
  assert.ok(peak > 1 && peak <= 4);
  assert.equal(active, 0);
  assert.equal(writes, pulls.length * 2);
  await reporter.publish(1, repo, pulls);
  assert.equal(writes, pulls.length * 2);
});
test("reporter clears stale standalone failures and the next sync performs no writes", async () => {
  const { unrelated } = sample(),
    comment = {
      id: 100,
      body: `${marker}\nRestack停止 · #2：Conflict`,
      performed_via_github_app: { id: 7 },
    };
  const check = {
      id: 200,
      external_id: "stacked-pr:1:200",
      app: { id: 7 },
      conclusion: "failure",
      output: { summary: comment.body },
    },
    writes = [];
  const api = fakeApi({
    list: async (_installation, path) => (path.includes("check-runs") ? [check] : [comment]),
    request: async (_installation, method, path, body) => {
      writes.push({ method, path });
      Object.assign(path.includes("check-runs") ? check : comment, body);
    },
  });
  const reporter = new Reporter(api);
  await reporter.publish(1, repo, [unrelated], { error: conflict });
  assert.doesNotMatch(comment.body, /Restack停止/);
  assert.equal(check.conclusion, "success");
  assert.equal(check.output.summary, comment.body);
  assert.equal(writes.length, 2);
  await reporter.publish(1, repo, [unrelated], { error: conflict });
  assert.equal(writes.length, 2);
});
for (const error of [
  new RestackException("Standalone PR conflict", 200),
  new RestackException("GitHub API unavailable"),
])
  test(`reporter publishes standalone failure: ${error.message}`, async () => {
    const { unrelated } = sample(),
      bodies = [];
    const api = fakeApi({
      request: async (_installation, _method, _path, body) => bodies.push(body),
    });
    await new Reporter(api).publish(1, repo, [unrelated], { error });
    assert.equal(bodies.length, 2);
    assert.ok(bodies[0].body.includes(error.message));
    assert.equal(bodies[1].conclusion, "failure");
    assert.equal(bodies[1].output.summary, bodies[0].body);
  });
test("normal, observe and error reports all direct users to sync", () => {
  const pulls = chain();
  for (const options of [{}, { observeOnly: true }, { error: new RestackException("Conflict") }]) {
    assert.deepEqual(
      new Set([...render(pulls, pulls[1], options).body.matchAll(/\/stack \w+/g)].map((m) => m[0])),
      new Set(["/stack sync"]),
    );
  }
});
test("closed report updates existing comment to Merged without creating a check", async () => {
  const comment = { id: 100, body: marker, performed_via_github_app: { id: 7 } };
  let writes = 0;
  const api = fakeApi({
    list: async (_installation, path) => {
      assert.ok(!path.includes("check-runs"));
      return [comment];
    },
    request: async (_installation, method, path, body) => {
      assert.equal(method, "PATCH");
      assert.equal(path, "/repos/org/repo/issues/comments/100");
      writes++;
      Object.assign(comment, body);
    },
  });
  const pulls = [modify(chain()[0], { state: "closed", merged: true })],
    reporter = new Reporter(api);
  await reporter.publish(1, repo, pulls, { closedToUpdate: [1] });
  assert.ok(comment.body.includes("| Merged |"));
  assert.equal(writes, 1);
  await reporter.publish(1, repo, pulls, { closedToUpdate: [1] });
  assert.equal(writes, 1);
});
test("reporter reuses its own comment and check, preserving Sync while ignoring forged markers", async () => {
  const comments = [{ id: 99, body: marker, user: { type: "User", login: "human" } }],
    checks = [],
    paths = [];
  const api = fakeApi({
    list: async (_installation, path) => (path.includes("check-runs") ? checks : comments),
    request: async (_installation, method, path, body) => {
      paths.push(path);
      if (method === "POST" && path.endsWith("/comments"))
        comments.push({ id: 100, ...body, user: { type: "Bot", login: "stacked-pr[bot]" } });
      if (method === "POST" && path.endsWith("/check-runs"))
        checks.push({ id: 200, ...body, app: { id: 7 } });
    },
  });
  const pulls = chain().slice(0, 2);
  pulls[0] = modify(pulls[0], { state: "closed", merged: true, sameRepo: false });
  const reporter = new Reporter(api);
  await reporter.publish(1, repo, pulls);
  assert.equal(paths.length, 2);
  assert.deepEqual(checks[0].actions, [
    { label: "Sync", description: "Synchronize dependent pull requests", identifier: "restack" },
    {
      label: "Merge stack",
      description: "Merge ancestors through this PR",
      identifier: "merge-stack",
    },
    {
      label: "Squash stack",
      description: "Land the full stack as one squash commit",
      identifier: "squash-stack",
    },
  ]);
  // GitHub's check-run response omits actions, even after a successful update.
  delete checks[0].actions;
  await reporter.publish(1, repo, pulls);
  assert.equal(paths.length, 2);
  pulls[1].title = "Changed title";
  await reporter.publish(1, repo, pulls);
  assert.equal(paths[2], "/repos/org/repo/issues/comments/100");
  assert.equal(
    paths.some((path) => path.endsWith("/99")),
    false,
  );
});
