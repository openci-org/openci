import { randomUUID } from "node:crypto";
import type { DataConnect } from "firebase-admin/data-connect";
import * as sdk from "@openci/dispatch-admin";
import { ExecutionGitHub } from "./executor/github.js";

export class QueuedCheckStore {
  constructor(readonly dc: DataConnect) {}
  async read(jobId: string) {
    return (await sdk.getQueuedBuildCheck(this.dc, { jobId })).data;
  }
  async acquire(jobId: string, owner: string, runNumber: string) {
    await sdk.acquireQueuedBuildCheck(this.dc, { jobId, owner, runNumber });
  }
  async record(jobId: string, owner: string, runNumber: string, checkRunId: string) {
    await sdk.recordQueuedBuildCheck(this.dc, { jobId, owner, runNumber, checkRunId });
  }
  async release(jobId: string, owner: string) {
    await sdk.releaseQueuedBuildCheck(this.dc, { jobId, owner });
  }
  async context(teamId: string, installationId: string, appId: string, apiBaseUrl: string) {
    return (
      await sdk.getBuildExecutorContext(this.dc, { teamId, installationId, appId, apiBaseUrl })
    ).data;
  }
}

export class QueuedChecks {
  constructor(
    readonly store: Pick<QueuedCheckStore, "read" | "acquire" | "record" | "release" | "context">,
    readonly github: Pick<ExecutionGitHub, "options" | "queuedCheck">,
  ) {}

  async sync(jobId: string): Promise<void> {
    const initial = await this.store.read(jobId);
    const job = initial.job;
    // An active reservation owns its check. Late mutation deliveries must never
    // regress running/completed checks, including executors deployed before this change.
    if (
      !job ||
      initial.dispatch ||
      job.runsOn !== "macos-latest" ||
      !["QUEUED", "CANCELLED"].includes(job.status)
    )
      return;
    const count = BigInt(job.runCount ?? "0");
    if (count < 0n) throw new Error("Invalid run count");
    const runNumber = String(count + 1n);
    const savedId = job.checkRunNumber === runNumber ? job.checkRunId : null;
    if (job.status === "CANCELLED" && !savedId) return;
    // This includes a lost release acknowledgement: let the dispatcher retry
    // until the persisted lease expires rather than issuing another GitHub call.
    if (job.status === "QUEUED" && savedId) return;

    const owner = randomUUID();
    await this.store.acquire(jobId, owner, runNumber);
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
    );
    if (!context.team || !context.connection) throw new Error("GitHub connection is inactive");
    if (Date.parse(current.checkLeaseUntil) - Date.now() < 60_000)
      throw new Error("Check publication lease is expiring");
    const externalId = `build-job:${jobId}:run:${runNumber}`;
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
