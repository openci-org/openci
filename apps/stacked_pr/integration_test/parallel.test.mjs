import { test } from "node:test";
import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";
import { join } from "node:path";
import { GitRepository } from "../lib/git.js";
import { Service } from "../lib/service.js";
import { RetryException } from "../lib/models.js";
import { config } from "../test/support/fixtures.mjs";
import { Harness, repo } from "./support/service_harness.mjs";

function worker(h, overrides = {}) {
  return new Service({
    config: config({ dataDir: h.f.root }),
    api: h.api,
    reporter: h.reporter,
    locks: h.locks,
    gitFactory: () =>
      new GitRepository({
        directory: join(h.f.root, `parallel-${randomUUID()}.git`),
        remote: h.f.remote,
        allowLocal: true,
      }),
    ...overrides,
  });
}

test(
  "same-stack deliveries retry while an independent stack rebases in parallel",
  { timeout: 30000 },
  async (t) => {
    const h = await Harness.create(t);
    const other = await h.addStack(4, "independent");
    await h.f.advanceParent();
    await h.f.git(["checkout", other[0].headRef]);
    const otherParent = await h.f.commit("independent-new.txt", "new\n", "advance other stack");
    await h.f.git(["push", "origin", other[0].headRef]);

    const entered = Promise.withResolvers(),
      finish = Promise.withResolvers();
    const first = worker(h, {
      reporter: {
        publish: async (...args) => {
          await h.reporter.publish(...args);
          entered.resolve();
          await finish.promise;
        },
      },
    }).reconcile(10, repo, { number: 2 });
    try {
      await Promise.race([entered.promise, first]);
      let duplicateGitStarted = false;
      await assert.rejects(
        worker(h, {
          gitFactory: () => {
            duplicateGitStarted = true;
            throw new Error("must not start Git while another stack member holds the lease");
          },
        }).reconcile(10, repo, { number: 3 }),
        RetryException,
      );
      assert.equal(duplicateGitStarted, false);

      // This completes while the first stack is still inside publish().
      await worker(h).reconcile(10, repo, { number: 5 });
      const heads = await h.f.worker.remoteHeads([other[1].headRef]);
      assert.equal(
        await h.f.git(["--git-dir", h.f.remote, "rev-parse", `${heads.get(other[1].headRef)}^`]),
        otherParent,
      );
      assert.equal(h.reports.length, 2);
      assert.ok(h.locks.held.size > 0);
    } finally {
      finish.resolve();
      await first;
    }
    const beforeRetry = await h.heads();
    await worker(h).reconcile(10, repo, { number: 3 });
    assert.deepEqual(await h.heads(), beforeRetry);
    assert.equal(h.locks.held.size, 0);
  },
);

test("joining another stack between discovery and acquisition releases and retries before Git", async (t) => {
  const h = await Harness.create(t);
  const other = await h.addStack(4, "other");
  let gitStarted = false;
  const before = await h.heads();
  const moving = worker(h, {
    locks: {
      acquire: async (...args) => {
        const lease = await h.locks.acquire(...args);
        h.records[0].baseRef = other[1].headRef;
        return lease;
      },
    },
    gitFactory: () => {
      gitStarted = true;
      throw new Error("stale scope");
    },
  });
  await assert.rejects(moving.reconcile(10, repo, { number: 2 }), /Stack membership changed/);
  assert.equal(gitStarted, false);
  assert.deepEqual(await h.heads(), before);
  assert.equal(h.reports.length, 0);
  assert.equal(h.locks.held.size, 0);
});

test("the plan uses GitHub state fetched after acquiring the lease", async (t) => {
  const h = await Harness.create(t);
  let latest;
  const updating = worker(h, {
    locks: {
      acquire: async (...args) => {
        const lease = await h.locks.acquire(...args);
        latest = await h.f.advanceParent();
        return lease;
      },
    },
  });
  await updating.reconcile(10, repo, { number: 2 });
  const heads = await h.heads();
  assert.equal(
    await h.f.git(["--git-dir", h.f.remote, "rev-parse", `${heads.get("child")}^`]),
    latest,
  );
  assert.equal(h.reports[0].error, undefined);
});

test("failed publishing releases the stack so a new delivery can recover", async (t) => {
  const h = await Harness.create(t);
  await assert.rejects(
    worker(h, {
      reporter: {
        publish: async () => {
          throw new Error("temporary report failure");
        },
      },
    }).reconcile(10, repo, { number: 2 }),
    /temporary report failure/,
  );
  assert.equal(h.locks.held.size, 0);
  await worker(h).reconcile(10, repo, { number: 2 });
  assert.equal(h.reports.length, 1);
  assert.equal(h.locks.held.size, 0);
});

test("merged ancestors remain locked after automatic retargeting and branch deletion", async (t) => {
  const h = await Harness.create(t);
  await h.merge(true, true);
  const resources = [];
  await worker(h, {
    locks: {
      acquire: async (scope, keys) => {
        resources.push(...keys);
        return h.locks.acquire(scope, keys);
      },
    },
  }).reconcile(10, repo, { number: 2, previousBase: "parent" });
  for (const key of ["pr:1", "pr:2", "pr:3", "head:parent", "head:child", "head:grandchild"])
    assert.ok(resources.includes(key), key);
  assert.equal(h.reports[0].error, undefined);
});

test("base changes acquire both the source and destination stack in one lease", async (t) => {
  const h = await Harness.create(t);
  const other = await h.addStack(4, "other");
  h.records[2].baseRef = other[0].headRef;
  h.baseChange(3, "child", other[0].headRef);
  const acquisitions = [];
  await worker(h, {
    config: config({ dataDir: h.f.root, autoRestack: false }),
    locks: {
      acquire: async (scope, keys) => {
        acquisitions.push(keys);
        return h.locks.acquire(scope, keys);
      },
    },
  }).reconcile(10, repo, { number: 3, previousBase: "child" });
  assert.equal(acquisitions.length, 1);
  for (const number of [1, 2, 3, 4, 5]) assert.ok(acquisitions[0].includes(`pr:${number}`));
  assert.equal(h.reports.length, 2);
});
