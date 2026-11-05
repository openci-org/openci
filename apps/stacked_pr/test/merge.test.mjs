import { test } from "node:test";
import assert from "node:assert/strict";
import { StackMerge } from "../lib/merge.js";
import { Repository } from "../lib/models.js";
import { Service } from "../lib/service.js";
import { chain, config, fakeApi, modify, raw } from "./support/fixtures.mjs";
import { MemoryStackLocks } from "./support/memory_locks.mjs";
import { MemoryMergeStops } from "./support/merge_stops.mjs";

const repo = new Repository(20, "org/repo", "main");
function fixture() {
  const pulls = chain(),
    queue = [],
    comments = [],
    merged = [],
    history = new Map(),
    seen = new Set(),
    locks = new MemoryStackLocks();
  const app = { id: 7, slug: "stacked-pr" },
    owner = {
      user: { login: "stacked-pr[bot]", type: "Bot" },
      performed_via_github_app: { id: 7 },
    };
  const f = {
    pulls,
    comments,
    merged,
    history,
    queue,
    locks,
    permission: true,
    now: Date.now(),
    ready: {},
    lost: false,
  };
  let serial = 0;
  const api = fakeApi({
    canWrite: async (_i, _path, login) => login === "maintainer" && f.permission,
    timeline: async (_i, _repo, n, withActor) => {
      assert.equal(withActor, true);
      return history.get(n) ?? [];
    },
    list: async (_i, path) => {
      if (path.includes("/comments")) return comments;
      const pr = pulls.find((pr) => path.includes(pr.head));
      assert.ok(pr);
      return [
        { id: 1, app, external_id: `stacked-pr:20:${pr.number}`, conclusion: f.check ?? "success" },
      ];
    },
    request: async (_i, method, path, body) => {
      if (path === repo.apiPath) return { ...repo.toJson(), allow_squash_merge: true };
      if (path === "/graphql") {
        const pr = pulls.find((p) => p.number === body.variables.number);
        return {
          data: {
            repository: {
              pullRequest: {
                state: "OPEN",
                isDraft: false,
                headRefOid: pr.head,
                baseRefName: pr.baseRef,
                mergeStateStatus: "CLEAN",
                mergeable: "MERGEABLE",
                reviewDecision: "APPROVED",
                commits: {
                  nodes: [{ commit: { oid: pr.head, statusCheckRollup: { state: "SUCCESS" } } }],
                },
                ...f.ready,
              },
            },
          },
        };
      }
      if (path.endsWith("/comments") && method === "POST") {
        const c = { id: ++serial, ...owner, ...body };
        comments.push(c);
        return c;
      }
      if (path.includes("/issues/comments/") && method === "PATCH") {
        const c = comments.find((c) => c.id === Number(path.split("/").at(-1)));
        Object.assign(c, body);
        return c;
      }
      const number = Number(path.split("/pulls/")[1]?.split("/")[0]),
        pr = pulls.find((p) => p.number === number);
      assert.ok(pr, path);
      if (method === "PUT") {
        assert.equal(path, `${repo.apiPath}/pulls/${number}/merge`);
        assert.equal(pr.baseRef, "main");
        assert.equal(pr.isOpen, true);
        assert.ok(locks.held.size);
        assert.deepEqual(body, { sha: pr.head, merge_method: "squash" });
        merged.push(number);
        pr.merged = true;
        pr.state = "closed";
        if (f.lost) {
          f.lost = false;
          throw new Error("lost response after merge");
        }
        return { merged: true };
      }
      return raw(pr);
    },
  });
  f.merger = new StackMerge({
    api,
    locks,
    stops: new MemoryMergeStops(),
    host: "https://git.example.com",
    now: () => f.now,
    discover: async () => ({ repo, pulls, errors: new Map() }),
    enqueue: async (job, date) => {
      if (seen.has(job.id)) return false;
      seen.add(job.id);
      if (job.event === "merge_stack") queue.push({ job: structuredClone(job), date });
      return true;
    },
    sync: async () => {
      assert.equal(locks.held.size, 0, "normal restack takes its own lease");
      for (const pr of pulls.filter((p) => p.isOpen)) {
        const parent = pulls.find((p) => p.number === pr.parent);
        if (parent?.merged && pr.baseRef !== repo.defaultBranch) {
          const old = pr.head;
          pr.baseRef = "main";
          pr.head = String(pr.number).padStart(40, "0");
          history.set(pr.number, [
            ...(history.get(pr.number) ?? []),
            {
              __typename: "HeadRefForcePushedEvent",
              actor: { __typename: "Bot", login: "stacked-pr" },
              beforeCommit: { oid: old },
              afterCommit: { oid: pr.head },
            },
          ]);
        }
      }
    },
  });
  f.start = (head = pulls[2].head) => f.merger.start(10, repo, 3, "delivery", "maintainer", head);
  f.step = async () => {
    const item = queue.shift();
    assert.ok(item, "expected a durable continuation");
    const tick = item.job.payload.tick;
    if (item.date) f.now = Math.max(f.now, item.date.getTime());
    await f.merger.tick(10, repo, structuredClone(tick));
    return tick;
  };
  f.drain = async () => {
    for (let n = 0; queue.length && n < 18; n++) await f.step();
    assert.equal(queue.length, 0);
  };
  return f;
}

test("one request lands only the chosen ancestors, waits for review/CI, and accepts bot restacks", async () => {
  const f = fixture();
  f.pulls.push(
    modify(f.pulls[1], { number: 4, headRef: "sibling" }),
    modify(f.pulls[2], { number: 5, headRef: "later", baseRef: "ui", parent: 3 }),
  );
  await f.start();
  await f.step();
  await f.step();
  assert.deepEqual(f.merged, [1]);
  f.ready = { reviewDecision: "REVIEW_REQUIRED" };
  await f.step();
  await f.step();
  assert.deepEqual(f.merged, [1]);
  assert.match(f.comments[0].body, /承認・CI/);
  f.ready = { mergeStateStatus: "UNSTABLE" };
  await f.step();
  assert.deepEqual(f.merged, [1]);
  f.ready = {};
  await f.drain();
  assert.deepEqual(f.merged, [1, 2, 3]);
  assert.match(f.comments[0].body, /:complete/);
  assert.ok(f.pulls[3].isOpen && f.pulls[4].isOpen);
  assert.equal(f.locks.held.size, 0);
});
test("a lost successful merge response resumes from GitHub without merging a PR twice", async () => {
  const f = fixture();
  await f.start();
  await f.step();
  const { job } = f.queue.shift();
  f.lost = true;
  await assert.rejects(f.merger.tick(10, repo, structuredClone(job.payload.tick)), /lost response/);
  await f.merger.tick(10, repo, structuredClone(job.payload.tick));
  await f.drain();
  assert.deepEqual(f.merged, [1, 2, 3]);
});
test("cancelling while waiting preserves already merged parents and rejects delayed deliveries", async () => {
  const f = fixture();
  await f.start();
  await f.step();
  await f.step();
  await f.step();
  f.ready = { mergeStateStatus: "BLOCKED" };
  await f.step();
  await f.merger.cancel(10, repo, 3, "maintainer");
  // Even someone editing the bot's comment back to active cannot revive a cancelled task.
  f.comments[0].body = f.comments[0].body.replace(":cancelled", ":active");
  await f.drain();
  assert.deepEqual(f.merged, [1]);
  assert.match(f.comments[0].body, /:cancelled/);
});
for (const [name, change] of [
  [
    "new user commit",
    (f) => {
      f.pulls[2].head = "d".repeat(40);
    },
  ],
  [
    "force push by a human with the same login",
    (f) => {
      const pr = f.pulls[2],
        old = pr.head;
      pr.head = "d".repeat(40);
      f.history.set(3, [
        {
          __typename: "HeadRefForcePushedEvent",
          actor: { __typename: "User", login: "stacked-pr" },
          beforeCommit: { oid: old },
          afterCommit: { oid: pr.head },
        },
      ]);
    },
  ],
  [
    "bot rewrite after an intervening user push",
    (f) => {
      const pr = f.pulls[2];
      pr.head = "d".repeat(40);
      f.history.set(3, [
        {
          __typename: "HeadRefForcePushedEvent",
          actor: { __typename: "Bot", login: "stacked-pr" },
          beforeCommit: { oid: "e".repeat(40) },
          afterCommit: { oid: pr.head },
        },
      ]);
    },
  ],
  [
    "retargeted child",
    (f) => {
      f.pulls[2].baseRef = "unrelated";
    },
  ],
  [
    "closed unmerged ancestor",
    (f) => {
      f.pulls[0].state = "closed";
    },
  ],
  [
    "revoked permission",
    (f) => {
      f.permission = false;
    },
  ],
  [
    "draft after starting",
    (f) => {
      f.pulls[1].draft = true;
    },
  ],
  [
    "expired request",
    (f) => {
      f.now += 25 * 3600000;
    },
  ],
  [
    "Stacked PR failure",
    (f) => {
      f.check = "failure";
    },
  ],
])
  test(`${name} stops the request without merging anything`, async () => {
    const f = fixture();
    await f.start();
    await f.step();
    change(f);
    await f.drain();
    assert.deepEqual(f.merged, []);
    assert.match(f.comments[0].body, /:stopped/);
  });
for (const [name, change] of [
  [
    "stale button",
    (f) => {
      f.pulls[2].head = "d".repeat(40);
    },
  ],
  [
    "cycle",
    (f) => {
      f.pulls[0].parent = 3;
    },
  ],
  [
    "a non-default destination",
    (f) => {
      f.pulls[0].baseRef = "release";
    },
  ],
  [
    "fork ancestor",
    (f) => {
      f.pulls[0].sameRepo = false;
    },
  ],
])
  test(`${name} never registers a merge plan`, async () => {
    const f = fixture(),
      head = f.pulls[2].head;
    change(f);
    await f.start(head);
    assert.equal(f.queue.length, 0);
    assert.deepEqual(f.merged, []);
    assert.match(f.comments[0].body, /:stopped/);
  });
test("rollup and the exact checked head must both match even if GitHub reports clean", async () => {
  const f = fixture();
  await f.start();
  await f.step();
  f.ready = {
    commits: {
      nodes: [{ commit: { oid: f.pulls[0].head, statusCheckRollup: { state: "PENDING" } } }],
    },
  };
  await f.step();
  f.ready = { headRefOid: "f".repeat(40) };
  await f.step();
  assert.deepEqual(f.merged, []);
  f.ready = {};
  await f.drain();
  assert.deepEqual(f.merged, [1, 2, 3]);
});
test("forged progress comments cannot cancel or authorize a request", async () => {
  const f = fixture();
  f.comments.push({
    id: 99,
    user: { type: "User", login: "human" },
    body: "<!-- stacked-pr-app:merge:delivery:cancelled -->",
  });
  await f.start();
  await f.drain();
  assert.deepEqual(f.merged, [1, 2, 3]);
  assert.match(f.comments.at(-1).body, /:complete/);
});
test("another app, bot, repository, read-only actor or malformed head cannot start a merge", async () => {
  const api = fakeApi({
    request: async () => assert.fail("must not discover a stack"),
    canWrite: async (_i, _path, login) => login === "maintainer",
  });
  const service = new Service({
    config: config(),
    api,
    locks: new MemoryStackLocks(),
    mergeStops: new MemoryMergeStops(),
    reporter: {},
    enqueue: async () => assert.fail("must not enqueue"),
  });
  const payload = {
    action: "requested_action",
    installation: { id: 10 },
    repository: repo.toJson(),
    sender: { login: "maintainer", type: "User" },
    check_run: { app: { id: 7 }, external_id: "stacked-pr:20:3", head_sha: "c".repeat(40) },
    requested_action: { identifier: "merge-stack" },
  };
  for (const changes of [
    { check_run: { ...payload.check_run, app: { id: 8 } } },
    { check_run: { ...payload.check_run, external_id: "stacked-pr:21:3" } },
    { sender: { login: "maintainer", type: "Bot" } },
    { sender: { login: "reader", type: "User" } },
    { check_run: { ...payload.check_run, head_sha: "invalid" } },
  ])
    await service.handle({
      id: "delivery",
      event: "check_run",
      payload: { ...payload, ...changes },
    });
});
