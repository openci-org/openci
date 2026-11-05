import { test } from "node:test";
import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";
import { Firestore, Timestamp } from "firebase-admin/firestore";
import { FirestoreStackLocks, lockCollection } from "../../lib/locks.js";
import { FirestoreMergeStops, mergeStopCollection } from "../../lib/merge-stops.js";
import { RetryException } from "../../lib/models.js";
import {
  executionBudgetMs,
  workerTimeoutSeconds,
  taskDeadlineSeconds,
  stackLeaseMs,
} from "../../lib/limits.js";

assert.match(
  process.env.FIRESTORE_EMULATOR_HOST ?? "",
  /^(127\.0\.0\.1|localhost):\d+$/,
  "Run these tests only against a local Firestore emulator",
);
const projectId = "demo-stacked-pr-locks";
async function clients(t, now = Date.now) {
  const db = [new Firestore({ projectId }), new Firestore({ projectId })];
  t.after(async () => {
    const documents = await db[0].collection(lockCollection).get();
    if (documents.size) {
      const batch = db[0].batch();
      documents.docs.forEach((doc) => batch.delete(doc.ref));
      await batch.commit();
    }
    await Promise.all(db.map((client) => client.terminate()));
  });
  return {
    db,
    locks: db.map((client) => new FirestoreStackLocks(client, now)),
    scope: randomUUID(),
  };
}

test("two Firestore clients cannot acquire overlapping stacks", async (t) => {
  const { locks, scope } = await clients(t);
  const results = await Promise.allSettled([
    locks[0].acquire(scope, ["pr:1", "pr:2"]),
    locks[1].acquire(scope, ["pr:2", "pr:3"]),
  ]);
  assert.equal(results.filter((r) => r.status === "fulfilled").length, 1);
  assert.ok(results.find((r) => r.status === "rejected").reason instanceof RetryException);
  await results.find((r) => r.status === "fulfilled").value.release();
  const retry = await locks[1].acquire(scope, ["pr:1", "pr:2", "pr:3"]);
  await retry.release();
});

test("different stacks and repositories can hold leases at the same time", async (t) => {
  const { locks, scope, db } = await clients(t);
  const leases = await Promise.all([
    locks[0].acquire(scope, ["pr:1", "pr:2"]),
    locks[1].acquire(scope, ["pr:3", "pr:4"]),
    locks[1].acquire(scope + "-other-repository", ["pr:1", "pr:2"]),
  ]);
  leases.forEach((lease) => lease.assertActive());
  const records = await db[0].collection(lockCollection).get();
  assert.equal(records.size, 6);
  for (const doc of records.docs) {
    assert.match(doc.id, /^[a-f0-9]{64}$/);
    assert.deepEqual(Object.keys(doc.data()).sort(), ["expiresAt", "owner"]);
  }
  await Promise.all(leases.map((lease) => lease.release()));
});

test("acquiring two stacks is atomic and does not leave partial locks on contention", async (t) => {
  const { locks, scope } = await clients(t);
  const held = await locks[0].acquire(scope, ["pr:3"]);
  await assert.rejects(locks[1].acquire(scope, ["pr:1", "pr:2", "pr:3"]), RetryException);
  const unrelated = await locks[0].acquire(scope, ["pr:1", "pr:2"]);
  await unrelated.release();
  await held.release();
});

test("expired leases recover without TTL deletion and old release preserves the new owner", async (t) => {
  let now = Date.now();
  const { locks, scope } = await clients(t, () => now);
  const old = await locks[0].acquire(scope, ["pr:1"]);
  now += stackLeaseMs - 1;
  await assert.rejects(locks[1].acquire(scope, ["pr:1"]), RetryException);
  now++;
  const next = await locks[1].acquire(scope, ["pr:1"]);
  assert.throws(() => old.assertActive(), RetryException);
  await old.release();
  await assert.rejects(locks[0].acquire(scope, ["pr:1"]), RetryException);
  next.assertActive();
  await next.release();
  await next.release();
  const final = await locks[0].acquire(scope, ["pr:1"]);
  await final.release();
});

test("malformed existing locks fail closed instead of being overwritten", async (t) => {
  const { locks, scope, db } = await clients(t);
  const held = await locks[0].acquire(scope, ["pr:1"]);
  const [doc] = (await db[0].collection(lockCollection).get()).docs;
  await doc.ref.update({ expiresAt: "invalid" });
  await assert.rejects(locks[1].acquire(scope, ["pr:1"]), /Invalid stack lock/);
  await doc.ref.update({ expiresAt: Timestamp.fromMillis(Date.now() + stackLeaseMs) });
  await held.release();
});

test("crash recovery expires only after execution, function and task deadlines", () => {
  assert.ok(executionBudgetMs < workerTimeoutSeconds * 1000);
  assert.ok(workerTimeoutSeconds < taskDeadlineSeconds);
  assert.ok(taskDeadlineSeconds * 1000 < stackLeaseMs);
});
test("a terminal merge decision survives concurrent writers and fresh workers", async (t) => {
  const { db, scope } = await clients(t);
  const stores = db.map((client) => new FirestoreMergeStops(client));
  assert.equal(await stores[0].get(scope), undefined);
  const decisions = await Promise.all([
    stores[0].close(scope, "cancelled"),
    stores[1].close(scope, "complete"),
  ]);
  assert.equal(decisions[0], decisions[1]);
  assert.equal(await new FirestoreMergeStops(db[1]).get(scope), decisions[0]);
  assert.equal(await stores[0].close(scope, "stopped"), decisions[0]);
  const records = await db[0].collection(mergeStopCollection).get();
  for (const doc of records.docs) {
    assert.deepEqual(Object.keys(doc.data()).sort(), ["expiresAt", "state"]);
    assert.ok(doc.data().expiresAt.toMillis() > Date.now() + 24 * 3600000);
    await doc.ref.delete();
  }
});
