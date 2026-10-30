export interface ExpiredLogStore {
  expired(): Promise<{ id: string; logs: { sequence: string }[] }[]>;
  deleteThrough(runId: string, sequence: string): Promise<void>;
}

/** Bound each invocation; the next scheduled sweep resumes unfinished runs. */
export async function deleteExpiredLogs(store: ExpiredLogStore): Promise<void> {
  for (const run of await store.expired()) {
    const last = run.logs.at(-1);
    if (last) await store.deleteThrough(run.id, last.sequence);
  }
}
