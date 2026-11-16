import { randomUUID } from "node:crypto";
import type { DataConnect } from "firebase-admin/data-connect";
import * as sdk from "@openci/dispatch-admin";
import { ExecutionGitHub } from "./executor/github.js";
import { DispatchRetry } from "./build_dispatch.js";
import { resolveExecutionContext } from "./executor/store.js";
import { queuedCheckExternalId } from "./executor/model.js";

export class QueuedCheckStore {
  constructor(readonly dc: DataConnect) {}
  async read(jobId: string) {
    return (await sdk.getQueuedBuildCheck(this.dc, { jobId })).data;
  }
  async acquire(jobId: string, owner: string, runNumber: string) {
    const result = await sdk.acquireQueuedBuildCheck(this.dc, { jobId, owner, runNumber });
    if (result.data.buildJob_updateMany === 0) throw new DispatchRetry("check_publication_busy");
  }
  async record(jobId: string, owner: string, runNumber: string, checkRunId: string) {
    await sdk.recordQueuedBuildCheck(this.dc, { jobId, owner, runNumber, checkRunId });
  }
  async release(jobId: string, owner: string) {
    await sdk.releaseQueuedBuildCheck(this.dc, { jobId, owner });
  }
  async context(
    teamId: string,
    installationId: string,
    appId: string,
    apiBaseUrl: string,
    repositoryId?: string | null,
  ) {
    return resolveExecutionContext(
      (
        await sdk.getBuildExecutorContext(this.dc, {
          teamId,
          installationId,
          appId,
          apiBaseUrl,
          repositoryId,
        })
      ).data,
    );
  }
}

type CheckState = Awaited<ReturnType<QueuedCheckStore["read"]>>;

function publicationInFlight(job: CheckState["job"]): boolean {
  return !!job?.checkOwner && Date.parse(job.checkLeaseUntil ?? "") > Date.now();
}

function publicationRun({ job, dispatch }: CheckState): string | undefined {
  // Active reservations own their Checks. Never regress running/completed work.
  if (
    !job ||
    dispatch ||
    job.runsOn !== "macos-latest" ||
    !["QUEUED", "CANCELLED"].includes(job.status)
  )
    return;
  const count = BigInt(job.runCount ?? "0");
  if (count < 0n) throw new Error("Invalid run count");
  const runNumber = String(count + 1n);
  const savedId = job.checkRunNumber === runNumber ? job.checkRunId : null;
  if (!publicationInFlight(job)) {
    // An expired owner may have created a Check before losing the response.
    // Reconcile it even if cancellation arrived before its ID was saved.
    if (job.status === "CANCELLED" && !savedId && !job.checkOwner) return;
    if (job.status === "QUEUED" && savedId) return;
  }
  return runNumber;
}

export class QueuedChecks {
  constructor(
    readonly store: Pick<QueuedCheckStore, "read" | "acquire" | "record" | "release" | "context">,
    readonly github: Pick<ExecutionGitHub, "options" | "queuedCheck">,
  ) {}

  async sync(jobId: string): Promise<void> {
    const initial = await this.store.read(jobId);
    const runNumber = publicationRun(initial);
    if (!runNumber) return;
    if (publicationInFlight(initial.job)) throw new DispatchRetry("check_publication_busy");

    const owner = randomUUID();
    try {
      await this.store.acquire(jobId, owner, runNumber);
    } catch (failure) {
      // The initial read does not lock the job. Another publisher or dispatcher
      // can win before the transaction checks its lease, run and reservation.
      const busy = failure instanceof DispatchRetry && failure.reason === "check_publication_busy";
      if (
        !busy &&
        (!failure ||
          typeof failure !== "object" ||
          !("code" in failure) ||
          failure.code !== "data-connect/query-error")
      )
        throw failure;
      const latest = await this.store.read(jobId);
      const latestRun = publicationRun(latest);
      if (!latestRun) return;
      if (busy || publicationInFlight(latest.job) || latestRun !== runNumber)
        throw new DispatchRetry("check_publication_busy");
      // No durable evidence of contention: retain the original failure/retry.
      throw failure;
    }
    const state = await this.store.read(jobId);
    const current = state.job;
    if (
      !current ||
      current.checkOwner !== owner ||
      !current.checkLeaseUntil ||
      Date.parse(current.checkLeaseUntil) - Date.now() < 60_000 ||
      state.dispatch
    )
      throw new Error("Check publication lease lost");
    if (
      !current.teamId ||
      !/^[1-9][0-9]*$/.test(current.installationId ?? "") ||
      !/^[a-f0-9]{40}([a-f0-9]{24})?$/i.test(current.commitSha ?? "")
    )
      throw new Error("Invalid queued job");
    const context = await this.store.context(
      current.teamId,
      current.installationId!,
      this.github.options.appId,
      this.github.options.apiBaseUrl,
      current.repositoryId,
    );
    if (!context.team || !context.connection) throw new Error("GitHub connection is inactive");
    if (Date.parse(current.checkLeaseUntil) - Date.now() < 60_000)
      throw new Error("Check publication lease is expiring");
    const externalId = queuedCheckExternalId(current);
    const signal = AbortSignal.timeout(20_000);
    const checkRunId = await this.github.queuedCheck(
      current,
      externalId,
      current.checkRunNumber === runNumber ? (current.checkRunId ?? null) : null,
      context.connection.accountId,
      signal,
    );
    await this.store.record(jobId, owner, runNumber, checkRunId);
    // Cancellation may race the POST. Save the ID first so a retry can finish it.
    const latest = (await this.store.read(jobId)).job;
    if (latest?.status === "CANCELLED" && current.status !== "CANCELLED")
      await this.github.queuedCheck(
        latest,
        externalId,
        checkRunId,
        context.connection.accountId,
        signal,
      );
    // Keep the lease after ambiguous failures; only successful publication releases it.
    await this.store.release(jobId, owner);
  }
}

export function queuedChecks(dc: DataConnect): QueuedChecks {
  return new QueuedChecks(
    new QueuedCheckStore(dc),
    new ExecutionGitHub({
      appId: process.env.GITHUB_APP_ID ?? "",
      privateKey: process.env.GITHUB_APP_PRIVATE_KEY ?? "",
      apiBaseUrl: process.env.GITHUB_API_BASE_URL ?? "https://api.github.com",
      baseUrl: process.env.GITHUB_BASE_URL ?? "https://github.com",
    }),
  );
}
