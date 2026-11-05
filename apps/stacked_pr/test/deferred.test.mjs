import { test } from "node:test";
import assert from "node:assert/strict";
import { Service } from "../lib/service.js";
import { Repository, StackBusyException } from "../lib/models.js";
import { TaskQueue } from "../lib/queue.js";
import { chain, config, fakeApi, raw, modify } from "./support/fixtures.mjs";

const repo = new Repository(20, "org/repo", "main");
function fixture() {
  const requests = new Map();
  let now = Date.now(),
    busy = true;
  const records = chain();
  const reports = [];
  const queue = new TaskQueue(
    {
      enqueue: async (data, options) => {
        if (requests.has(options.id))
          throw Object.assign(new Error("exists"), { code: "functions/task-already-exists" });
        requests.set(options.id, { data, options });
      },
    },
    "app",
  );
  const settings = {
    config: config({ autoRestack: false }),
    api: fakeApi({
      request: async () => repo.toJson(),
      list: async (_installation, path) =>
        path.includes("state=closed") ? [] : records.map((pr) => raw(pr)),
    }),
    locks: {
      acquire: async () => {
        if (busy) throw new StackBusyException("Stack is already being processed");
        return { assertActive() {}, async release() {} };
      },
    },
    reporter: { publish: async (_installation, _repo, pulls) => reports.push(pulls) },
    now: () => now,
    enqueue: (job, at) => queue.enqueue(job, 8000, at),
  };
  return {
    settings,
    requests,
    reports,
    records,
    advance: (at) => {
      now = at;
    },
    release: () => {
      busy = false;
    },
  };
}

test("contended deliveries coalesce into a future task that reads the latest state", async () => {
  const f = fixture();
  const service = new Service(f.settings);
  for (const number of [1, 2, 3, 2, 1]) await service.reconcile(10, repo, { number });
  assert.equal(f.requests.size, 1);
  const [{ data, options }] = [...f.requests.values()];
  assert.ok(options.scheduleTime.getTime() > Date.now());
  assert.equal(data.payload.pull_request.number, 1);
  f.records[1].title = "updated while first task was running";
  f.release();
  await service.handle(data);
  assert.equal(f.reports.length, 1);
  assert.equal(f.reports[0].find((pr) => pr.number === 2).title, f.records[1].title);

  // A later event must get a new ID even if Cloud Tasks still retains the old tombstone.
  f.advance(options.scheduleTime.getTime());
  const busyAgain = new Service({
    ...f.settings,
    locks: {
      acquire: async () => {
        throw new StackBusyException();
      },
    },
  });
  await busyAgain.reconcile(10, repo, { number: 3 });
  assert.equal(f.requests.size, 2);
  assert.ok([...f.requests.values()][1].options.scheduleTime > options.scheduleTime);
});

test("a failed deferred enqueue propagates so the original delivery is retried", async () => {
  const f = fixture();
  const service = new Service({
    ...f.settings,
    enqueue: async () => {
      throw new Error("queue unavailable");
    },
  });
  await assert.rejects(service.reconcile(10, repo, { number: 2 }), /queue unavailable/);
  assert.equal(f.reports.length, 0);
});

test("moving between stacks schedules both components and does not merge forced with automatic work", async () => {
  const f = fixture();
  f.records[2].baseRef = "main";
  const service = new Service(f.settings);
  await service.reconcile(10, repo, { number: 3, previousBase: "api" });
  assert.deepEqual(
    [...f.requests.values()].map(({ data }) => data.payload.pull_request.number).sort(),
    [1, 3],
  );
  await service.reconcile(10, repo, { number: 3, force: true });
  assert.equal(f.requests.size, 3);
  assert.equal(
    [...f.requests.values()].filter(({ data }) => data.payload.force === true).length,
    1,
  );
});

test("unrelated stacks are deferred independently", async () => {
  const f = fixture();
  f.records.push(modify(chain()[0], { number: 9, headRef: "other" }));
  const service = new Service(f.settings);
  await service.reconcile(10, repo, { number: 2 });
  await service.reconcile(10, repo, { number: 9 });
  assert.equal(f.requests.size, 2);
});
