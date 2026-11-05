import { createHash } from "node:crypto";
import { type DocumentData, type Firestore, Timestamp } from "firebase-admin/firestore";
import { RetryException } from "./models.js";

export type Terminal = "stopped" | "cancelled" | "complete";
export interface MergeStops {
  get(key: string): Promise<Terminal | undefined>;
  close(key: string, state: Terminal): Promise<Terminal>;
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
    if (!["stopped", "cancelled", "complete"].includes(data.state))
      throw new RetryException("Invalid merge stop record");
    return data.state as Terminal;
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
      tx.create(ref, { state, expiresAt: Timestamp.fromMillis(Date.now() + 2 * 24 * 60 * 60_000) });
      return state;
    });
  }
}
