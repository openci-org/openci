import { createHash } from "node:crypto";
import { type DocumentData, type Firestore, Timestamp } from "firebase-admin/firestore";
import { RetryException } from "./models.js";

export type Terminal = "stopped" | "cancelled" | "complete";
export interface SquashRollback {
  number: number;
  ref: string;
  head: string;
  base: string;
  trunk: string;
  prepared: string;
}
export interface MergeStops {
  get(key: string): Promise<Terminal | undefined>;
  close(key: string, state: Terminal): Promise<Terminal>;
  advance(key: string, sequence: number): Promise<boolean>;
  rollback(key: string): Promise<SquashRollback | undefined>;
  saveRollback(key: string, rollback: SquashRollback): Promise<boolean>;
}
export const mergeStopCollection = "StackedPrMergeStops";
/** An edited/deleted PR comment or a delayed delivery cannot revive a finished request. */
export class FirestoreMergeStops implements MergeStops {
  constructor(private readonly db: Firestore) {}
  private ref(key: string) {
    return this.db
      .collection(mergeStopCollection)
      .doc(createHash("sha256").update(key).digest("hex"));
  }
  private state(data: DocumentData | undefined): Terminal | undefined {
    if (!data) return undefined;
    if (data.state === undefined && Number.isSafeInteger(data.sequence) && data.sequence >= 0)
      return undefined;
    if (!["stopped", "cancelled", "complete"].includes(data.state))
      throw new RetryException("Invalid merge stop record");
    return data.state as Terminal;
  }
  private rollbackData(value: unknown): SquashRollback | undefined {
    if (value === undefined) return undefined;
    const r = value as SquashRollback;
    if (
      !r ||
      !Number.isSafeInteger(r.number) ||
      r.number <= 0 ||
      ![r.ref, r.base, r.trunk].every((s) => typeof s === "string" && s.length > 0) ||
      r.ref === r.trunk ||
      ![r.head, r.prepared].every((s) => /^(?:[a-f0-9]{40}|[a-f0-9]{64})$/.test(s))
    )
      throw new RetryException("Invalid squash rollback record");
    return {
      number: r.number,
      ref: r.ref,
      head: r.head,
      base: r.base,
      trunk: r.trunk,
      prepared: r.prepared,
    };
  }
  async get(key: string) {
    return this.state((await this.ref(key).get()).data());
  }
  async close(key: string, state: Terminal) {
    const ref = this.ref(key);
    return this.db.runTransaction(async (tx) => {
      const existing = this.state((await tx.get(ref)).data());
      if (existing) return existing;
      // Retain beyond the 24-hour request deadline and the queue's retry horizon.
      tx.set(
        ref,
        { state, expiresAt: Timestamp.fromMillis(Date.now() + 2 * 24 * 60 * 60_000) },
        { merge: true },
      );
      return state;
    });
  }
  async advance(key: string, sequence: number) {
    if (!Number.isSafeInteger(sequence) || sequence < 0) throw new Error("Invalid merge sequence");
    const ref = this.ref(key);
    return this.db.runTransaction(async (tx) => {
      const data = (await tx.get(ref)).data();
      if (this.state(data) || (data?.sequence ?? -1) > sequence) return false;
      tx.set(
        ref,
        { sequence, expiresAt: Timestamp.fromMillis(Date.now() + 2 * 24 * 60 * 60_000) },
        { merge: true },
      );
      return true;
    });
  }
  async rollback(key: string) {
    return this.rollbackData((await this.ref(key).get()).data()?.rollback);
  }
  async saveRollback(key: string, rollback: SquashRollback) {
    const value = this.rollbackData(rollback)!;
    const ref = this.ref(key);
    return this.db.runTransaction(async (tx) => {
      const data = (await tx.get(ref)).data();
      if (this.state(data)) return false;
      if (!data) throw new RetryException("Missing merge progress");
      const existing = this.rollbackData(data?.rollback);
      if (existing && JSON.stringify(existing) !== JSON.stringify(value))
        throw new RetryException("Squash rollback changed");
      tx.set(ref, { rollback: value }, { merge: true });
      return true;
    });
  }
}
