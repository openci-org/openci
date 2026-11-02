import { randomUUID } from "node:crypto";
import type { GetSkippedWorkflowCheckData } from "@openci/webhooks-admin";

export type SkippedCheck = NonNullable<GetSkippedWorkflowCheckData["check"]>;

export interface SkippedCheckStore {
  claim(id: string, leaseOwner: string): Promise<boolean>;
  get(id: string): Promise<SkippedCheck | null>;
  complete(id: string, leaseOwner: string, checkRunId: string): Promise<void>;
  retry(id: string, leaseOwner: string): Promise<void>;
  pending(): Promise<string[]>;
}

export interface SkippedCheckDependencies {
  store: SkippedCheckStore;
  report(check: SkippedCheck): Promise<string>;
}

export function createdSkippedCheckIds(payload: unknown): string[] {
  if (!payload || typeof payload !== "object") return [];
  const value = payload as { data?: { skipped?: unknown }; errors?: unknown[] };
  if (value.errors?.length || !value.data?.skipped) return [];
  if (!Array.isArray(value.data.skipped) || value.data.skipped.length > 100)
    throw new Error("Invalid skipped Check batch");
  return value.data.skipped.map((entry: unknown) => {
    if (
      !entry ||
      typeof entry !== "object" ||
      !("id" in entry) ||
      typeof entry.id !== "string" ||
      !/^[a-f0-9]{64}$/.test(entry.id)
    )
      throw new Error("Invalid skipped Check ID");
    return entry.id;
  });
}

export async function reportSkippedCheck(
  id: string,
  { store, report }: SkippedCheckDependencies,
): Promise<void> {
  const owner = randomUUID();
  if (!(await store.claim(id, owner))) return;
  try {
    const check = await store.get(id);
    if (!check || check.status !== "pending" || check.leaseOwner !== owner)
      throw new Error("Skipped Check lease is no longer active");
    const checkRunId = await report(check);
    await store.complete(id, owner, checkRunId);
  } catch {
    // A lost GitHub create response is reconciled by external_id on retry.
    // A failed retry write is recovered when the original lease expires.
    await store.retry(id, owner);
    throw new Error("Skipped Check reporting failed; retry required");
  }
}

export async function recoverSkippedChecks(
  dependencies: SkippedCheckDependencies,
  onError: (id: string) => void,
  budgetMs = 180000,
): Promise<void> {
  const deadline = Date.now() + budgetMs;
  for (const id of await dependencies.store.pending()) {
    if (Date.now() >= deadline) break;
    try {
      await reportSkippedCheck(id, dependencies);
    } catch {
      onError(id);
    }
  }
}
