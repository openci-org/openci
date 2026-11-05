import { test } from "node:test";
import assert from "node:assert/strict";
import { join } from "node:path";
import { randomUUID } from "node:crypto";
import { GitRepository } from "../lib/git.js";
import { ApiException } from "../lib/github.js";
import { Reporter } from "../lib/report.js";
import { Service } from "../lib/service.js";
import { config, modify } from "../test/support/fixtures.mjs";
import { MemoryMergeStops } from "../test/support/merge_stops.mjs";
import { Harness, repo } from "./support/service_harness.mjs";

async function fixture(t) {
  const h = await Harness.create(t),
    f = h.f;
  const comments = new Map(),
    checks = [],
    jobs = [],
    seen = new Set();
  const merges = [],
    pushes = [];
  const owner = {
    user: { login: "stacked-pr[bot]", type: "Bot" },
    performed_via_github_app: { id: 7 },
  };
  let serial = 0;
  const state = {
    h,
    f,
    comments,
    checks,
    jobs,
    merges,
    pushes,
    lostMerge: false,
    permission: true,
  };
  const list = h.api.list,
    request = h.api.request;
  const ci = (head) => checks.filter((c) => c.head_sha === head && c.name === "tests");
  state.pass = (head) => {
    checks.push({
      id: ++serial,
      head_sha: head,
      name: "tests",
      app: { id: 42 },
      status: "completed",
      conclusion: "success",
    });
  };
  h.records.forEach((p) => state.pass(p.head));
  h.api.canWrite = async () => state.permission;
  h.api.list = async (i, path, ...rest) => {
    if (path.includes("/issues/")) return comments.get(Number(path.split("/").at(-2))) ?? [];
    if (path.includes("/check-runs")) {
      const head = path.split("/commits/")[1].split("/")[0];
      return checks.filter(
        (c) => c.head_sha === head && (!path.includes("check_name=") || c.name === "Stacked PR"),
      );
    }
    if (path.endsWith("/statuses")) return [];
    if (path.endsWith("/reviews")) {
      assert.fail("Squash stack must leave review requirements to GitHub merge conditions");
    }
    return list(i, path, ...rest);
  };
  h.api.request = async (i, method, path, body) => {
    if (path === repo.apiPath)
      return {
        ...repo.toJson(),
        default_branch: state.defaultBranch ?? "main",
        allow_squash_merge: true,
      };
    if (path.includes("/branches/")) return { protected: state.protected ?? false };
    if (path.includes("/git/ref/heads/")) {
      await state.beforeBaseCheck?.();
      return { object: { sha: await f.git(["--git-dir", f.remote, "rev-parse", "main"]) } };
    }
    if (path.includes("/compare/")) {
      const [base, head] = path.split("/compare/")[1].split("...");
      const mergeBase = await f
        .git(["--git-dir", f.remote, "merge-base", base, head])
        .catch(() => "");
      if (!mergeBase) throw new ApiException(method, path, 404);
      return {
        status: base === head ? "identical" : mergeBase === base ? "ahead" : "diverged",
        base_commit: { sha: base },
        merge_base_commit: { sha: mergeBase },
      };
    }
    if (path.includes("/git/commits/")) {
      const sha = path.split("/").at(-1);
      const [tree, parents] = (
        await f.git(["--git-dir", f.remote, "show", "-s", "--format=%T%n%P", sha])
      ).split("\n");
      return {
        tree: { sha: state.landedTree ?? tree },
        parents: parents.split(" ").map((sha) => ({ sha })),
      };
    }
    if (path === "/graphql") {
      if (body.query.includes("StackSquashStatuses"))
        return {
          data: {
            repository: {
              object: {
                oid: body.variables.head,
                statusCheckRollup: {
                  contexts: { nodes: [], pageInfo: { hasNextPage: false } },
                },
              },
            },
          },
        };
      const pr = h.records.find((p) => p.number === body.variables.number),
        live = await h.raw(pr);
      return {
        data: {
          repository: {
            pullRequest: {
              state: pr.isOpen ? "OPEN" : "CLOSED",
              isDraft: pr.draft,
              headRefOid: live.head.sha,
              baseRefName: pr.baseRef,
              mergeStateStatus: state.mergeStateStatus ?? "CLEAN",
              mergeable: "MERGEABLE",
              reviewDecision: state.reviewDecision ?? null,
              commits: {
                nodes: [
                  {
                    commit: {
                      oid: live.head.sha,
                      statusCheckRollup: {
                        state: ci(live.head.sha).length ? "SUCCESS" : "PENDING",
                      },
                    },
                  },
                ],
              },
            },
          },
        },
      };
    }
    if (path.endsWith("/comments") && method === "POST") {
      const number = Number(path.split("/").at(-2)),
        comment = { id: ++serial, ...owner, ...body };
      comments.set(number, [...(comments.get(number) ?? []), comment]);
      return comment;
    }
    if (path.includes("/issues/comments/"))
      return Object.assign(
        [...comments.values()].flat().find((c) => c.id === Number(path.split("/").at(-1))),
        body,
      );
    if (path.endsWith("/check-runs") && method === "POST") {
      const check = { id: ++serial, app: { id: 7 }, ...body };
      checks.push(check);
      return check;
    }
    if (path.includes("/check-runs/") && method === "PATCH")
      return Object.assign(
        checks.find((c) => c.id === Number(path.split("/").at(-1))),
        body,
      );
    if (method === "PUT") {
      await state.beforeMerge?.();
      const number = Number(path.split("/").at(-2)),
        pr = h.records.find((p) => p.number === number),
        live = await h.raw(pr);
      if (live.head.sha !== body.sha) throw new ApiException(method, path, 409);
      if (state.denied) throw new ApiException(method, path, 403);
      assert.equal(number, 3, "only the selected PR is merged");
      assert.equal(pr.baseRef, "main");
      assert.equal(body.merge_method, "squash");
      assert.ok(ci(body.sha).length, "final integration head must be tested");
      assert.ok(
        state.reviewDecision == null || state.reviewDecision === "APPROVED",
        "GitHub review requirements must be satisfied before merging",
      );
      assert.ok(h.locks.held.size);
      await f.git(["fetch", "origin"]);
      await f.git(["checkout", "main"]);
      await f.git(["reset", "--hard", "origin/main"]);
      await f.git(["merge", "--squash", `origin/${pr.headRef}`]);
      await f.git(["commit", "-m", body.commit_title]);
      const mergeCommit = await f.git(["rev-parse", "HEAD"]);
      await f.git(["push", "origin", "main"]);
      Object.assign(pr, { state: "closed", merged: true, head: body.sha, mergeCommit });
      merges.push(number);
      if (state.lostMerge) {
        state.lostMerge = false;
        throw new Error("lost merge response");
      }
      return { merged: true };
    }
    if (method === "PATCH" && body.state === "closed") {
      h.records.find((p) => p.number === Number(path.split("/").at(-1))).state = "closed";
      return {};
    }
    const result = await request(i, method, path, body);
    if (method === "PATCH" && body.base && state.lostBaseChange) {
      state.lostBaseChange = false;
      throw new Error("lost base change response");
    }
    return result;
  };
  const stops = new MemoryMergeStops();
  state.worker = () =>
    new Service({
      config: config({ dataDir: f.root }),
      api: h.api,
      reporter: new Reporter(h.api),
      locks: h.locks,
      mergeStops: stops,
      enqueue: async (job) => {
        if (seen.has(job.id)) return false;
        seen.add(job.id);
        jobs.push(structuredClone(job));
        return true;
      },
      gitFactory: () => {
        const git = new GitRepository({
          directory: join(f.root, `squash-${randomUUID()}.git`),
          remote: f.remote,
          allowLocal: true,
        });
        const push = git.push.bind(git);
        git.push = async (changes) => {
          assert.ok(
            changes.every((c) => c.headRef !== "main"),
            "the app must not push to the default branch",
          );
          await push(changes);
          pushes.push(...changes);
          if (state.lostPreparePush) {
            state.lostPreparePush = false;
            throw new Error("lost prepare push response");
          }
        };
        return git;
      },
    });
  state.button = (identifier = "squash-stack") => ({
    id: `button-${identifier}`,
    event: "check_run",
    payload: {
      action: "requested_action",
      installation: { id: 10 },
      repository: repo.toJson(),
      sender: { type: "User", login: "maintainer" },
      check_run: { app: { id: 7 }, external_id: "stacked-pr:20:3", head_sha: f.grandchild },
      requested_action: { identifier },
    },
  });
  state.step = async () => {
    const job = jobs.shift();
    assert.ok(job, "expected a durable task");
    await state.worker().handle(structuredClone(job));
    return job;
  };
  state.prepare = async () => {
    await state.worker().handle(state.button());
    await state.step();
    await state.step();
  };
  state.drain = async () => {
    for (let n = 0; jobs.length && n < 20; n++) await state.step();
    assert.equal(jobs.length, 0);
  };
  state.head = async () => (await h.raw(h.records[2])).head.sha;
  return state;
}

test("Squash stack without approvals integrates current main once, waits for final CI, and closes included parents across fresh workers", async (t) => {
  const s = await fixture(t),
    { f, h } = s;
  await f.git(["checkout", "main"]);
  const baseline = await f.commit("upstream.txt", "upstream\n", "new main change");
  await f.git(["push", "origin", "main"]);
  await s.prepare();
  const prepared = await s.head();
  assert.notEqual(prepared, f.grandchild);
  assert.deepEqual(
    s.pushes.map((p) => p.number),
    [3],
  );
  assert.equal(await f.git(["--git-dir", f.remote, "rev-parse", "parent"]), f.parent);
  assert.equal(await f.git(["--git-dir", f.remote, "rev-parse", "child"]), f.child);
  assert.equal(
    await f.git(["--git-dir", f.remote, "rev-list", "--count", `${baseline}..${prepared}`]),
    "1",
  );
  await s.step();
  assert.deepEqual(s.merges, []);
  s.pass(prepared);
  await s.drain();
  assert.deepEqual(s.merges, [3]);
  assert.ok(h.records[0].state === "closed" && !h.records[0].merged);
  assert.ok(h.records[1].state === "closed" && !h.records[1].merged);
  assert.equal(
    await f.git(["--git-dir", f.remote, "rev-list", "--count", `${baseline}..main`]),
    "1",
  );
  assert.equal(
    await f.git(["--git-dir", f.remote, "ls-tree", "-r", "--name-only", "main"]),
    "base.txt\nchild.txt\ngrandchild.txt\nparent.txt\nupstream.txt",
  );
  assert.ok(s.comments.get(1).some((c) => c.body.includes("取り込み済み")));
  assert.ok(s.comments.get(3).some((c) => c.body.includes(":complete")));
  assert.equal(h.locks.held.size, 0);
});

for (const decision of ["REVIEW_REQUIRED", "CHANGES_REQUESTED"])
  test(`GitHub ${decision} waits after final CI until GitHub approves the merge`, async (t) => {
    const s = await fixture(t);
    s.reviewDecision = decision;
    await s.prepare();
    s.pass(await s.head());
    await s.step();
    assert.deepEqual(s.merges, []);
    assert.ok(s.comments.get(3).some((c) => c.body.includes("承認・CI・ブランチ保護の条件待ち")));
    s.reviewDecision = "APPROVED";
    await s.drain();
    assert.deepEqual(s.merges, [3]);
  });

test("a delayed preparation task cannot stop or rewrite the newer final-CI stage", async (t) => {
  const s = await fixture(t);
  await s.worker().handle(s.button());
  const old = await s.step();
  await s.step();
  const prepared = await s.head();
  await s.worker().handle(old);
  assert.equal(await s.head(), prepared);
  s.pass(prepared);
  await s.drain();
  assert.deepEqual(s.merges, [3]);
});

test("cancel during final CI restores the selected branch and base without merging or closing parents", async (t) => {
  const s = await fixture(t);
  await s.prepare();
  await s.worker().handle(s.button("cancel-merge"));
  assert.equal(
    await s.head(),
    s.f.grandchild,
    "cancel restores immediately, before any queued continuation",
  );
  assert.equal(s.h.records[2].baseRef, "child");
  await s.drain();
  assert.equal(await s.head(), s.f.grandchild);
  assert.equal(s.h.records[2].baseRef, "child");
  assert.ok(s.h.records.every((p) => p.isOpen));
  assert.deepEqual(s.merges, []);
});

test("main advancing during final CI keeps the tested head and merges with the newer main", async (t) => {
  const s = await fixture(t);
  await s.prepare();
  const prepared = await s.head();
  await s.f.git(["checkout", "main"]);
  await s.f.commit("later.txt", "later\n", "concurrent main change");
  await s.f.git(["push", "origin", "main"]);
  await s.step();
  assert.deepEqual(s.merges, []);
  assert.equal(await s.head(), prepared);
  s.pass(prepared);
  await s.drain();
  assert.deepEqual(s.merges, [3]);
  assert.equal(s.pushes.length, 1, "advancing main must not trigger another force push or CI");
  assert.equal(await s.f.git(["--git-dir", s.f.remote, "show", "main:later.txt"]), "later");
  assert.ok(s.h.records.every((p) => !p.isOpen));
});

test("GitHub requiring an up-to-date branch waits without rewriting the tested head", async (t) => {
  const s = await fixture(t);
  await s.prepare();
  const prepared = await s.head();
  s.pass(prepared);
  await s.f.git(["checkout", "main"]);
  await s.f.commit("later.txt", "later\n", "new main with strict checks");
  await s.f.git(["push", "origin", "main"]);
  s.mergeStateStatus = "BEHIND";
  await s.step();
  assert.deepEqual(s.merges, []);
  assert.equal(await s.head(), prepared);
  assert.equal(s.pushes.length, 1);
  assert.ok(s.comments.get(3).some((c) => c.body.includes("承認・CI・ブランチ保護の条件待ち")));
});

test("a human push to the prepared branch is retained and stops the batch", async (t) => {
  const s = await fixture(t);
  await s.prepare();
  await s.f.git(["fetch", "origin"]);
  await s.f.git(["checkout", "grandchild"]);
  await s.f.git(["reset", "--hard", "origin/grandchild"]);
  const human = await s.f.commit("human.txt", "human\n", "human edit");
  await s.f.git(["push", "origin", "grandchild"]);
  await s.drain();
  assert.equal(await s.head(), human);
  assert.deepEqual(s.merges, []);
});

test("a lost successful merge response resumes cleanup without a second merge", async (t) => {
  const s = await fixture(t);
  await s.prepare();
  s.pass(await s.head());
  const job = s.jobs.shift();
  s.lostMerge = true;
  await assert.rejects(s.worker().handle(structuredClone(job)), /lost merge response/);
  await s.worker().handle(structuredClone(job));
  await s.drain();
  assert.deepEqual(s.merges, [3]);
  assert.ok(s.h.records.every((p) => !p.isOpen));
});

test("a lost merge response with newer main validates the actual landing on retry", async (t) => {
  const s = await fixture(t);
  await s.prepare();
  s.pass(await s.head());
  await s.f.git(["checkout", "main"]);
  await s.f.commit("later.txt", "later\n", "new main before lost response");
  await s.f.git(["push", "origin", "main"]);
  const job = s.jobs.shift();
  s.lostMerge = true;
  await assert.rejects(s.worker().handle(structuredClone(job)), /lost merge response/);
  await s.worker().handle(structuredClone(job));
  await s.drain();
  assert.deepEqual(s.merges, [3]);
  assert.equal(s.pushes.length, 1);
  assert.equal(await s.f.git(["--git-dir", s.f.remote, "show", "main:later.txt"]), "later");
  assert.ok(s.h.records.every((p) => !p.isOpen));
});

for (const name of ["later child", "sibling"])
  test(`${name} prevents flattening or closing dependent PRs`, async (t) => {
    const s = await fixture(t);
    const parent = name === "sibling" ? s.h.records[0] : s.h.records[2];
    await s.f.git(["checkout", "-b", "outside", parent.head]);
    const head = await s.f.commit("outside.txt", "outside\n", "dependent change");
    await s.f.git(["push", "origin", "outside"]);
    s.h.records.push(
      modify(parent, {
        number: 4,
        headRef: "outside",
        head,
        baseRef: parent.headRef,
        parent: parent.number,
      }),
    );
    await s.worker().handle(s.button());
    await s.drain();
    assert.deepEqual(s.pushes, []);
    assert.deepEqual(s.merges, []);
    assert.ok(s.h.records.every((p) => p.isOpen));
  });

test("a lost preparation push response recovers the persisted candidate without rebuilding another SHA", async (t) => {
  const s = await fixture(t);
  await s.worker().handle(s.button());
  await s.step();
  const job = s.jobs.shift();
  s.lostPreparePush = true;
  await assert.rejects(s.worker().handle(structuredClone(job)), /lost prepare push response/);
  const candidate = await s.head();
  assert.equal(candidate, job.payload.tick.squash.head);
  await s.worker().handle(structuredClone(job));
  assert.equal(await s.head(), candidate);
  s.pass(candidate);
  await s.drain();
  assert.deepEqual(s.merges, [3]);
});

test("main advancing between readiness and the last base check preserves both sets of changes", async (t) => {
  const s = await fixture(t);
  await s.prepare();
  const prepared = await s.head();
  s.pass(prepared);
  let concurrent;
  s.beforeBaseCheck = async () => {
    s.beforeBaseCheck = undefined;
    await s.f.git(["checkout", "main"]);
    concurrent = await s.f.commit("raced.txt", "main\n", "concurrent main update");
    await s.f.git(["push", "origin", "main"]);
  };
  await s.drain();
  assert.deepEqual(s.merges, [3]);
  assert.equal(await s.head(), prepared);
  assert.equal(s.pushes.length, 1);
  assert.equal(await s.f.git(["--git-dir", s.f.remote, "rev-parse", "main^1"]), concurrent);
  assert.equal(await s.f.git(["--git-dir", s.f.remote, "show", "main:raced.txt"]), "main");
  assert.equal(
    await s.f.git(["--git-dir", s.f.remote, "show", "main:grandchild.txt"]),
    "grandchild",
  );
  assert.ok(s.h.records.every((p) => !p.isOpen));
});

test("main advancing after the last base check is verified against the actual merge parent", async (t) => {
  const s = await fixture(t);
  await s.prepare();
  const prepared = await s.head();
  s.pass(prepared);
  s.beforeMerge = async () => {
    s.beforeMerge = undefined;
    await s.f.git(["checkout", "main"]);
    await s.f.commit("raced.txt", "main\n", "main update during merge request");
    await s.f.git(["push", "origin", "main"]);
  };
  await s.drain();
  assert.deepEqual(s.merges, [3]);
  assert.equal(await s.head(), prepared);
  assert.equal(s.pushes.length, 1);
  assert.equal(await s.f.git(["--git-dir", s.f.remote, "show", "main:raced.txt"]), "main");
  assert.ok(s.h.records.every((p) => !p.isOpen));
});

test("a rewritten main stops without merging or losing the external change", async (t) => {
  const s = await fixture(t);
  await s.prepare();
  s.pass(await s.head());
  await s.f.git(["checkout", "--orphan", "rewritten"]);
  const rewritten = await s.f.commit("rewritten.txt", "rewrite\n", "unrelated main history");
  await s.f.git(["push", "--force", "origin", "HEAD:main"]);
  await s.drain();
  assert.deepEqual(s.merges, []);
  assert.equal(await s.f.git(["--git-dir", s.f.remote, "rev-parse", "main"]), rewritten);
  assert.equal(await s.head(), s.f.grandchild);
  assert.ok(s.h.records.every((p) => p.isOpen));
  assert.ok(s.comments.get(3).some((c) => c.body.includes("履歴を確認できません")));
});

test("an unexpected tree after main advances leaves included parents open", async (t) => {
  const s = await fixture(t);
  await s.prepare();
  s.pass(await s.head());
  await s.f.git(["checkout", "main"]);
  await s.f.commit("later.txt", "later\n", "new main");
  await s.f.git(["push", "origin", "main"]);
  s.landedTree = "0".repeat(40);
  await s.drain();
  assert.deepEqual(s.merges, [3]);
  assert.ok(s.h.records.slice(0, -1).every((p) => p.isOpen));
  assert.ok(s.comments.get(3).some((c) => c.body.includes("統合状態と一致しません")));
});

test("main advancing between preparation tasks retains the same candidate", async (t) => {
  const s = await fixture(t);
  await s.worker().handle(s.button());
  const preparation = await s.step();
  const candidate = s.jobs[0].payload.tick.squash.head;
  await s.f.git(["checkout", "main"]);
  await s.f.commit("later.txt", "later\n", "main update before preparation push");
  await s.f.git(["push", "origin", "main"]);
  await s.step();
  assert.equal(await s.head(), candidate);
  await s.worker().handle(preparation);
  s.pass(candidate);
  await s.drain();
  assert.deepEqual(s.merges, [3]);
  assert.equal(s.pushes.length, 1);
  assert.ok(s.h.records.every((p) => !p.isOpen));
});

test("the merge API rejects a new selected head after readiness without overwriting it", async (t) => {
  const s = await fixture(t);
  await s.prepare();
  s.pass(await s.head());
  let human;
  s.beforeMerge = async () => {
    s.beforeMerge = undefined;
    await s.f.git(["fetch", "origin"]);
    await s.f.git(["checkout", "grandchild"]);
    await s.f.git(["reset", "--hard", "origin/grandchild"]);
    human = await s.f.commit("raced.txt", "human\n", "concurrent human update");
    await s.f.git(["push", "origin", "grandchild"]);
  };
  await s.drain();
  assert.deepEqual(s.merges, []);
  assert.equal(await s.head(), human);
  assert.equal(await s.f.git(["--git-dir", s.f.remote, "rev-parse", "main"]), s.f.main);
});

test("GitHub branch protection rejection stops and restores without pushing to main", async (t) => {
  const s = await fixture(t);
  await s.prepare();
  s.pass(await s.head());
  s.denied = true;
  await s.drain();
  assert.deepEqual(s.merges, []);
  assert.equal(await s.head(), s.f.grandchild);
  assert.ok(s.h.records.every((p) => p.isOpen));
  assert.ok(s.comments.get(3).some((c) => c.body.includes("403")));
});

test("another stack's merge lease defers this merge until the destination is released", async (t) => {
  const s = await fixture(t);
  await s.prepare();
  s.pass(await s.head());
  const lease = await s.h.locks.acquire("https://git.example.com:20", ["merge-target:main"]);
  await s.step();
  assert.deepEqual(s.merges, []);
  await lease.release();
  await s.drain();
  assert.deepEqual(s.merges, [3]);
});

test("a lost base-change response resumes the same prepared candidate", async (t) => {
  const s = await fixture(t);
  await s.worker().handle(s.button());
  await s.step();
  const job = s.jobs.shift();
  s.lostBaseChange = true;
  await assert.rejects(s.worker().handle(structuredClone(job)), /lost base change response/);
  assert.equal(s.h.records[2].baseRef, "main");
  assert.equal(await s.head(), s.f.grandchild);
  await s.worker().handle(structuredClone(job));
  s.pass(await s.head());
  await s.drain();
  assert.deepEqual(s.merges, [3]);
});

test("restoration never rewrites a selected branch that became the new default branch", async (t) => {
  const s = await fixture(t);
  await s.prepare();
  const prepared = await s.head();
  s.defaultBranch = "grandchild";
  await s.step();
  assert.equal(await s.head(), prepared);
  assert.equal(s.pushes.length, 1);
  assert.deepEqual(s.merges, []);
});
