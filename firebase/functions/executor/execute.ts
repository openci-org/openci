import { randomUUID } from "node:crypto";
import { setTimeout as delay } from "node:timers/promises";
import {
  checkoutScript,
  ExecutionStopped,
  identity,
  validateJob,
  workflowScript,
  type Dispatch,
  type Outcome,
} from "./model.js";
import type { ExecutionStore } from "./store.js";
import type { ExecutionBilling } from "./billing.js";
import type { ExecutionGitHub } from "./github.js";
import type { ExecutionLogs } from "./logs.js";
import type { OrchardExecutor } from "./orchard.js";

export interface ExecutorDependencies {
  store: Pick<ExecutionStore, keyof ExecutionStore>;
  billing: Pick<ExecutionBilling, "period" | "admit" | "start" | "heartbeat" | "close">;
  github: Pick<ExecutionGitHub, "options" | "checkout" | "check">;
  orchard: Pick<OrchardExecutor, "create" | "ready" | "remove" | "exec" | "vmNames">;
  logs: (dispatch: Dispatch) => Pick<ExecutionLogs, "start" | "finish" | "output">;
  secrets: (teamId: string, signal: AbortSignal) => Promise<Record<string, string>>;
  stopExecution: (dispatch: Dispatch) => Promise<void>;
  configuration: {
    cloudRunJob: string;
    timeoutSeconds: number;
    livemode: boolean;
    complimentary: Set<string>;
  };
  report: (reason: string, dispatchId: string) => void;
}

export async function cleanupExecution(
  id: string,
  jobId: string,
  dependencies: ExecutorDependencies,
  recovery = true,
): Promise<void> {
  const { store, orchard, billing, github } = dependencies;
  const owner = randomUUID();
  if (!(await store.acquireCleanup(id, owner))) return;
  const state = await store.read(id, jobId);
  const dispatch = state.dispatch;
  if (!dispatch || dispatch.cleanupOwner !== owner || dispatch.jobId !== jobId)
    throw new Error("Cleanup ownership lost");
  identity(dispatch);
  if (recovery) await dependencies.stopExecution(dispatch);
  // A DELETE acknowledgement alone is insufficient; remove also confirms GET 404.
  await orchard.remove(dispatch.vmName);
  await store.vmDeleted(id, owner);
  const current =
    state.job?.latestRunId === dispatch.runId ||
    (!state.job?.latestRunId &&
      (!state.job?.workerHost || state.job.workerHost === identity(dispatch).workerHost));
  if (current && state.job?.status === "CANCELLED") dispatch.outcome = "cancelled";
  await billing.close(dispatch);
  if (state.job && state.run && dispatch.outcome !== "blocked") {
    validateJob(state.job, dispatch);
    const checkRunId = await github.check(state.job, dispatch, dispatch.outcome as Outcome);
    await store.check(id, checkRunId);
  }
  await store.complete(id, jobId, owner);
}

/** A Cloud Run task owns exactly one persisted reservation and never polls for work. */
export async function executeBuild(
  input: { dispatchId: string; jobId: string; executionName: string },
  dependencies: ExecutorDependencies,
  shutdown?: AbortSignal,
): Promise<void> {
  const { store, billing, github, orchard, configuration } = dependencies;
  const initial = await store.read(input.dispatchId, input.jobId);
  if (!initial.dispatch || initial.dispatch.finishedAt || initial.dispatch.executorId) return;
  // Older reservations expire unclaimed and are replaced with team identity.
  if (!initial.dispatch.teamId) return;
  if (
    initial.dispatch.jobId !== input.jobId ||
    initial.dispatch.cloudRunJob !== configuration.cloudRunJob ||
    !input.executionName.startsWith(`${configuration.cloudRunJob}/executions/`)
  )
    throw new Error("Execution does not match reservation");
  if (!initial.job || initial.job.status !== "QUEUED") return;
  const executorId = randomUUID();
  // Even a lost successful claim response exits. Recovery owns that attempt;
  // it must never be resumed by a second process with a different executor ID.
  if (
    !(await store.claim(
      input.dispatchId,
      executorId,
      input.executionName,
      configuration.timeoutSeconds,
    ))
  )
    return;
  const state = await store.read(input.dispatchId, input.jobId);
  const dispatch = state.dispatch!;
  const job = state.job!;
  if (dispatch.executorId !== executorId) throw new Error("Execution claim lost");
  const controller = new AbortController();
  const signal = controller.signal;
  const stopHeartbeat = new AbortController();
  const shutdownListener = () => controller.abort(new ExecutionStopped("cancelled"));
  shutdown?.addEventListener("abort", shutdownListener, { once: true });
  if (shutdown?.aborted) shutdownListener();
  const timeout = setTimeout(
    () => controller.abort(new ExecutionStopped("timed_out")),
    Math.max(0, Date.parse(dispatch.deadlineAt!) - Date.now()),
  );
  let billingStarted = false;
  const heartbeat = (async () => {
    while (!stopHeartbeat.signal.aborted) {
      try {
        await delay(15000, undefined, { signal: stopHeartbeat.signal });
        const current = await store.read(dispatch.id, dispatch.jobId);
        if (current.job?.status === "CANCELLED") throw new ExecutionStopped("cancelled");
        if (!(await store.heartbeat(dispatch.id, executorId)))
          throw new ExecutionStopped("failure");
        if (billingStarted) await billing.heartbeat(dispatch);
      } catch (error) {
        if (!stopHeartbeat.signal.aborted)
          controller.abort(
            error instanceof ExecutionStopped ? error : new ExecutionStopped("failure"),
          );
        return;
      }
    }
  })();
  let outcome: Outcome = "failure";
  try {
    signal.throwIfAborted();
    validateJob(job, dispatch);
    const context = await store.context(
      job.teamId!,
      job.installationId!,
      github.options.appId,
      github.options.apiBaseUrl,
    );
    if (!context.team || !context.connection) throw new Error("GitHub connection is not active");
    const period = await billing.period(
      context,
      job.teamId!,
      configuration.livemode,
      configuration.complimentary,
    );
    signal.throwIfAborted();
    await billing.admit(dispatch, period);
    const runNumber = await store.configure(dispatch, executorId);
    await billing.start(dispatch);
    billingStarted = true;
    await store.check(dispatch.id, await github.check(job, dispatch));
    const logs = dependencies.logs(dispatch);
    const step = async (id: string, order: number, work: () => Promise<void>) => {
      signal.throwIfAborted();
      const started = Date.now();
      await logs.start(id, id, order);
      try {
        await work();
        signal.throwIfAborted();
        await logs.finish(id, "SUCCESS", Date.now() - started);
      } catch (error) {
        const stopped =
          signal.aborted && signal.reason instanceof ExecutionStopped ? signal.reason : error;
        const status =
          stopped instanceof ExecutionStopped ? stopped.outcome.toUpperCase() : "FAILURE";
        await logs.finish(id, status, Date.now() - started);
        throw error;
      }
    };
    await step("prepare_vm", 0, async () => {
      await store.vmRequested(dispatch.id, executorId);
      signal.throwIfAborted();
      await orchard.create(dispatch, signal);
      await orchard.ready(dispatch.vmName, signal);
    });
    await step("checkout", 1, async () => {
      const checkout = await github.checkout(job, context.connection!.accountId);
      const output = logs.output("checkout", [
        checkout.token,
        Buffer.from(`x-access-token:${checkout.token}`).toString("base64"),
      ]);
      try {
        signal.throwIfAborted();
        const code = await orchard.exec(
          dispatch.vmName,
          checkoutScript(job, checkout.cloneUrl, checkout.token),
          output.write,
          signal,
        );
        if (code !== 0) throw new ExecutionStopped("failure");
      } finally {
        try {
          await output.flush();
        } finally {
          await checkout.revoke();
        }
      }
    });
    await step("run_workflow", 2, async () => {
      const secrets = await dependencies.secrets(job.teamId!, signal);
      signal.throwIfAborted();
      const output = logs.output("run_workflow", Object.values(secrets));
      try {
        const code = await orchard.exec(
          dispatch.vmName,
          workflowScript(job, dispatch, runNumber, secrets),
          output.write,
          signal,
        );
        if (code !== 0) throw new ExecutionStopped("failure");
      } finally {
        await output.flush();
      }
    });
    outcome = "success";
  } catch (error) {
    const stopped = signal.aborted ? signal.reason : error;
    outcome = stopped instanceof ExecutionStopped ? stopped.outcome : "failure";
    dependencies.report(`execution_${outcome}`, dispatch.id);
  } finally {
    stopHeartbeat.abort();
    await heartbeat;
    clearTimeout(timeout);
    shutdown?.removeEventListener("abort", shutdownListener);
  }
  if (signal.aborted && signal.reason instanceof ExecutionStopped) outcome = signal.reason.outcome;
  if (await store.result(dispatch.id, executorId, outcome))
    await cleanupExecution(dispatch.id, dispatch.jobId, dependencies, false);
}

export async function recoverExecutions(
  dependencies: ExecutorDependencies,
  budgetMs = 40000,
): Promise<void> {
  const started = Date.now();
  // A timed-out POST can be committed by the controller after cleanup saw 404.
  // Only closed attempts with matching stable VM names are eligible here.
  try {
    const names = (await dependencies.orchard.vmNames()).filter((name) =>
      /^openci-[a-f0-9-]{36}$/.test(name),
    );
    const orphanBudget = Math.min(30000, budgetMs / 3);
    for (
      let offset = 0;
      offset < names.length && Date.now() - started < orphanBudget;
      offset += 100
    ) {
      for (const stale of await dependencies.store.finishedForVms(
        names.slice(offset, offset + 100),
      )) {
        if (Date.now() - started >= orphanBudget) break;
        try {
          await dependencies.orchard.remove(stale.vmName);
        } catch {
          dependencies.report("orphan_vm_cleanup_pending", stale.id);
        }
      }
    }
  } catch {
    dependencies.report("orphan_vm_scan_failed", "");
  }
  for (const dispatch of await dependencies.store.recoverable()) {
    if (Date.now() - started > budgetMs) break;
    try {
      await cleanupExecution(dispatch.id, dispatch.jobId, dependencies);
    } catch {
      dependencies.report("execution_cleanup_pending", dispatch.id);
    }
  }
}
