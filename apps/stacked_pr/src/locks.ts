import { createHash, randomUUID } from "node:crypto";
import { getApps, initializeApp } from "firebase-admin/app";
import { getFirestore, type Firestore, Timestamp } from "firebase-admin/firestore";
import { required, type Environment } from "./config.js";
import { stackLeaseMs } from "./limits.js";
import { RetryException, StackBusyException } from "./models.js";

export interface StackLease {
  assertActive(): void;
  release(): Promise<void>;
}
export interface StackLocks {
  acquire(scope: string, resources: string[]): Promise<StackLease>;
}
export const lockCollection = "StackedPrLocks";

/** Shared across processes/revisions; documents contain only owner and expiry. */
export class FirestoreStackLocks implements StackLocks {
  constructor(
    private readonly db: Firestore,
    private readonly now: () => number = Date.now,
  ) {}

  static fromEnvironment(env: Environment): FirestoreStackLocks {
    const projectId = env.GCLOUD_PROJECT || required(env, "GOOGLE_CLOUD_PROJECT");
    const name = "stacked-pr-locks";
    const app = getApps().find((a) => a.name === name) ?? initializeApp({ projectId }, name);
    return new FirestoreStackLocks(getFirestore(app, env.STACKED_PR_LOCK_DATABASE || "(default)"));
  }

  async acquire(scope: string, resources: string[]): Promise<StackLease> {
    if (!resources.length) throw new Error("Cannot lock an empty stack");
    const owner = randomUUID(); // A retry of the same delivery is a different owner.
    const refs = [...new Set(resources)].sort().map((resource) => {
      const id = createHash("sha256")
        .update(JSON.stringify([scope, resource]))
        .digest("hex");
      return this.db.collection(lockCollection).doc(id);
    });
    // All members are acquired atomically, including both stacks during a base
    // change. There is no partial acquisition or lock-order deadlock.
    const expiresAt = await this.db.runTransaction(async (transaction) => {
      const snapshots = await transaction.getAll(...refs);
      const now = this.now();
      for (const snapshot of snapshots) {
        if (!snapshot.exists) continue;
        const data = snapshot.data()!;
        if (typeof data.owner !== "string" || !(data.expiresAt instanceof Timestamp))
          throw new RetryException("Invalid stack lock");
        if (data.expiresAt.toMillis() > now)
          throw new StackBusyException("Stack is already being processed");
      }
      const expiresAt = Timestamp.fromMillis(now + stackLeaseMs);
      for (const ref of refs) transaction.set(ref, { owner, expiresAt });
      return expiresAt.toMillis();
    });
    let released = false;
    return {
      assertActive: () => {
        if (released || this.now() >= expiresAt) throw new RetryException("Stack lease expired");
      },
      release: async () => {
        if (released) return;
        released = true;
        await this.db.runTransaction(async (transaction) => {
          const snapshots = await transaction.getAll(...refs);
          for (const snapshot of snapshots) {
            // An expired owner must never remove a successor's lock.
            if (snapshot.data()?.owner === owner) transaction.delete(snapshot.ref);
          }
        });
      },
    };
  }
}
