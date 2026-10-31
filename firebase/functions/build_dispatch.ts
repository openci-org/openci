import { createHash, randomUUID } from "node:crypto";
import { hasOrchardCapacity, type OrchardSnapshot, type VmSize } from "./orchard_capacity.js";

export interface BuildDispatch extends VmSize {
  id: string;
  jobId: string;
  vmName: string;
  image: string;
  cloudRunJob: string;
  startDeadline: string;
  executorId?: string | null;
  operationName?: string | null;
}
export interface DispatchState {
  job?: { id: string; status: string; runsOn?: string | null } | null;
  dispatch?: BuildDispatch | null;
}
export interface DispatchStore {
  expireUnstarted(): Promise<void>;
  cancelUnstarted(jobId: string): Promise<void>;
  read(jobId: string): Promise<DispatchState>;
  active(): Promise<BuildDispatch[]>;
  acquireScheduler(owner: string): Promise<boolean>;
  releaseScheduler(owner: string): Promise<void>;
  reserve(owner: string, dispatch: Omit<BuildDispatch, "startDeadline">): Promise<void>;
  acquireLaunch(id: string, owner: string): Promise<boolean>;
  recordLaunch(id: string, owner: string, operationName: string): Promise<void>;
}

export class DispatchRetry extends Error {
  constructor(readonly reason: "capacity_unavailable" | "scheduler_busy" | "launch_busy") {
    super(reason);
  }
}

/** Return only fixed diagnostics; SDK errors can embed private request data. */
export function dispatchFailureReason(failure: unknown): string {
  if (!failure || typeof failure !== "object") return "unknown";
  const codes = new Set([
    "data-connect/permission-denied",
    "data-connect/query-error",
    "data-connect/invalid-argument",
    "data-connect/unavailable",
    "data-connect/internal-error",
    "app/invalid-credential",
    "ETIMEDOUT",
    "ECONNREFUSED",
    "ECONNRESET",
    "ERR_TLS_CERT_ALTNAME_INVALID",
    "DEPTH_ZERO_SELF_SIGNED_CERT",
  ]);
  if ("code" in failure && typeof failure.code === "string" && codes.has(failure.code))
    return failure.code;
  const messages: Record<string, string> = {
    "Orchard request timed out": "orchard_timeout",
    "Orchard capacity unavailable": "orchard_unavailable",
    "Invalid VM size": "invalid_vm_size",
    "Unknown Orchard VM resource usage": "unknown_vm_resources",
    "Build reservation unavailable": "reservation_unavailable",
    "Missing build reservation": "reservation_missing",
    "Build dispatch could not be queued": "recovery_enqueue_failed",
    "Invalid Cloud Run operation response": "invalid_launch_response",
  };
  return failure instanceof Error && Object.hasOwn(messages, failure.message)
    ? messages[failure.message]
    : "unknown";
}

export function validJobId(value: unknown): value is string {
  return typeof value === "string" && /^[\x21-\x7e]{1,255}$/.test(value);
}

export function createdBuildJobIds(payload: { data: unknown; errors?: unknown[] }): string[] {
  if (payload.errors?.length) return [];
  if (
    !payload.data ||
    typeof payload.data !== "object" ||
    !("jobs" in payload.data) ||
    !Array.isArray(payload.data.jobs) ||
    payload.data.jobs.length > 100
  ) {
    throw new Error("Invalid completed webhook result");
  }
  const ids = payload.data.jobs.map((row: unknown) => {
    if (!row || typeof row !== "object" || !("id" in row) || !validJobId(row.id)) {
      throw new Error("Invalid created build job ID");
    }
    return row.id;
  });
  return [...new Set(ids)];
}

export function dispatchTaskId(jobId: string, dispatchId?: string): string {
  return createHash("sha256")
    .update(JSON.stringify([jobId, dispatchId ?? "initial"]))
    .digest("hex");
}

export async function dispatchBuildJob(
  jobId: string,
  dependencies: {
    store: DispatchStore;
    snapshot: () => Promise<OrchardSnapshot>;
    configuration: VmSize & { image: string; cloudRunJob: string };
    enqueueRecovery: (dispatch: BuildDispatch) => Promise<void>;
    launch: (dispatch: BuildDispatch) => Promise<string>;
  },
): Promise<void> {
  const { store, configuration } = dependencies;
  if (!validJobId(jobId)) throw new Error("Invalid build job ID");
  await store.expireUnstarted();
  let state = await store.read(jobId);
  if (!eligible(state)) {
    if (state.dispatch && !state.dispatch.executorId) await store.cancelUnstarted(jobId);
    return;
  }
  if (state.dispatch?.executorId) return;
  if (!state.dispatch) {
    const owner = randomUUID();
    if (!(await store.acquireScheduler(owner))) throw new DispatchRetry("scheduler_busy");
    try {
      // Another dispatcher may have completed while this caller was waiting.
      state = await store.read(jobId);
      if (!eligible(state)) {
        if (state.dispatch && !state.dispatch.executorId) await store.cancelUnstarted(jobId);
        return;
      }
      if (!state.dispatch) {
        const [snapshot, reservations] = await Promise.all([
          dependencies.snapshot(),
          store.active(),
        ]);
        if (!hasOrchardCapacity(snapshot, reservations, configuration)) {
          throw new DispatchRetry("capacity_unavailable");
        }
        const id = randomUUID();
        try {
          await store.reserve(owner, { id, jobId, vmName: `openci-${id}`, ...configuration });
        } catch {
          // Reconcile a commit whose response was lost, without taking a second slot.
          if (!(await store.read(jobId)).dispatch) throw new Error("Build reservation unavailable");
        }
        state = await store.read(jobId);
      }
    } finally {
      await store.releaseScheduler(owner);
    }
  }
  const dispatch = state.dispatch;
  if (!dispatch) throw new Error("Missing build reservation");
  if (dispatch.executorId) return;
  // Persist the delayed recovery before jobs.run. A cold-start failure or lost
  // launch response cannot strand a reservation after this invocation ends.
  await dependencies.enqueueRecovery(dispatch);
  if (dispatch.operationName) return;
  const owner = randomUUID();
  if (!(await store.acquireLaunch(dispatch.id, owner))) throw new DispatchRetry("launch_busy");
  // jobs.run has no idempotency key. Keep the lease on errors, then retry the
  // same dispatch ID; ClaimBuildJobExecution fences any duplicate containers.
  const operation = await dependencies.launch(dispatch);
  await store.recordLaunch(dispatch.id, owner, operation);
}

function eligible(state: DispatchState): boolean {
  return state.job?.status === "QUEUED" && state.job.runsOn === "macos-latest";
}
