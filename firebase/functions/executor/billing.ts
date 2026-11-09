import type { DataConnect } from "firebase-admin/data-connect";
import { randomInt } from "node:crypto";
import { setTimeout as delay } from "node:timers/promises";
import * as sdk from "@openci/billing-admin";
import { BillingStore } from "../billing/store.js";
import { ExecutionStopped, identity, type Context, type Dispatch } from "./model.js";

interface AdmissionPeriod {
  periodId: string;
  endsAt: number;
  cardSessionId?: string;
  livemode?: boolean;
}

export class ExecutionBilling {
  private readonly store: BillingStore;
  constructor(
    private readonly dc: DataConnect,
    private readonly now = Date.now,
    private readonly wait: (milliseconds: number) => Promise<void> = delay,
  ) {
    this.store = new BillingStore(dc);
  }

  private async waitBeforeRetry(attempt: number): Promise<void> {
    // All runs on a team share one usage revision. Spread concurrent starts and
    // heartbeats instead of exhausting immediate retries against the same burst.
    if (attempt > 0) await this.wait(randomInt(50, 251));
  }

  async period(
    context: Context,
    teamId: string,
    livemode: boolean,
    complimentary: Set<string>,
    verifyCard: (teamId: string, livemode: boolean) => Promise<string | null>,
  ): Promise<AdmissionPeriod> {
    if (context.team?.id !== teamId) throw new Error("Billing team mismatch");
    const free = complimentary.has(teamId);
    let session: string | null = null;
    if (!free) {
      if (context.customer?.stripeCustomerId) {
        if (context.customer.livemode !== livemode)
          throw new Error("Billing customer mode mismatch");
        session = await verifyCard(teamId, livemode);
      }
      if (!session) throw new ExecutionStopped("card_required");
    }
    // Complimentary periods retain UTC. Postpaid usage follows the Japanese calendar.
    const offset = free ? 0 : 9 * 3600_000;
    const date = new Date(this.now() + offset);
    const start = Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), 1);
    const end = Date.UTC(date.getUTCFullYear(), date.getUTCMonth() + 1, 1);
    const periodId = `${free ? "complimentary-pro" : "postpaid"}:${teamId}:${new Date(start).toISOString().slice(0, 7)}`;
    await this.store.ensurePeriod({
      id: periodId,
      teamId,
      planId: free ? "pro" : "postpaid",
      periodType: free ? "paid" : "postpaid",
      startsAt: String((start - offset) / 1000),
      endsAt: String((end - offset) / 1000),
      allowanceSeconds: free ? "360000" : null,
    });
    const period = { periodId, endsAt: end - offset };
    return session ? { ...period, cardSessionId: session, livemode } : period;
  }

  async admit(dispatch: Dispatch, period: AdmissionPeriod): Promise<void> {
    const { periodId, cardSessionId, livemode } = period;
    const { admissionId: id, ...attempt } = identity(dispatch);
    for (let retry = 0; retry < 12; retry++) {
      await this.waitBeforeRetry(retry);
      const state = (await sdk.getBillingAdmission(this.dc, { id, teamId: attempt.teamId })).data;
      const admission = state.billingAdmission;
      if (admission) {
        if (
          admission.jobId !== attempt.jobId ||
          admission.workerHost !== attempt.workerHost ||
          admission.periodId !== periodId ||
          admission.closedAtMs ||
          Number(admission.startByMs) <= this.now()
        )
          throw new Error("Billing admission is not active");
        if (admission.runId === attempt.runId) return;
        if (admission.runId) throw new Error("Billing admission belongs to another run");
        try {
          await sdk.bindBillingAdmissionRun(this.dc, {
            id,
            ...attempt,
            expectedUsageRevision: state.billingAccount!.usageRevision,
            atMs: String(this.now()),
          });
          return;
        } catch {
          continue;
        }
      }
      if (this.now() >= period.endsAt) throw new ExecutionStopped("blocked");
      if (
        !cardSessionId &&
        (await this.store.available(attempt.teamId, periodId, this.now())) <= 0n
      )
        throw new ExecutionStopped("blocked");
      try {
        await sdk.createBillingAdmission(this.dc, {
          id,
          teamId: attempt.teamId,
          jobId: attempt.jobId,
          workerHost: attempt.workerHost,
          periodId,
          cardSessionId,
          livemode,
          atMs: String(this.now()),
          vmName: dispatch.vmName,
        });
      } catch {
        /* Re-read the admission and budget before retrying. */
      }
    }
    throw new Error("Billing admission could not be confirmed");
  }

  async start(dispatch: Dispatch): Promise<void> {
    const attempt = identity(dispatch);
    for (let retry = 0; retry < 12; retry++) {
      await this.waitBeforeRetry(retry);
      const state = (
        await sdk.getBillingExecution(this.dc, { teamId: attempt.teamId, runId: attempt.runId })
      ).data;
      if (state.billingExecution) {
        this.validate(state.billingExecution, dispatch);
        if (
          state.billingExecution.finishedAtMs ||
          Number(state.billingExecution.leaseUntilMs) <= this.now()
        )
          throw new Error("Billing execution expired");
        return;
      }
      try {
        await sdk.startBillingExecution(this.dc, {
          ...attempt,
          expectedUsageRevision: state.billingAccount!.usageRevision,
          atMs: String(this.now()),
        });
        return;
      } catch {
        /* CAS conflicts and ambiguous responses require a new read. */
      }
    }
    throw new Error("Billing start could not be confirmed");
  }

  async heartbeat(dispatch: Dispatch): Promise<void> {
    const { admissionId: _admissionId, ...attempt } = identity(dispatch);
    const observedAt = this.now();
    for (let retry = 0; retry < 12; retry++) {
      await this.waitBeforeRetry(retry);
      const state = (
        await sdk.getBillingExecution(this.dc, { teamId: attempt.teamId, runId: attempt.runId })
      ).data;
      const execution = state.billingExecution;
      if (!execution) throw new Error("Billing execution missing");
      this.validate(execution, dispatch);
      if (execution.finishedAtMs || Number(execution.leaseUntilMs) <= this.now())
        throw new Error("Billing execution expired");
      if (Number(execution.observedAtMs) >= observedAt) return;
      try {
        await sdk.heartbeatBillingExecution(this.dc, {
          ...attempt,
          expectedUsageRevision: state.billingAccount!.usageRevision,
          atMs: String(observedAt),
        });
        return;
      } catch {
        /* Reconcile monotonic observations before retrying. */
      }
    }
    throw new Error("Billing heartbeat failed");
  }

  async close(dispatch: Dispatch): Promise<void> {
    const { admissionId: id, ...attempt } = identity(dispatch);
    for (let retry = 0; retry < 12; retry++) {
      await this.waitBeforeRetry(retry);
      const state = (
        await sdk.getBillingExecution(this.dc, { teamId: attempt.teamId, runId: attempt.runId })
      ).data;
      const execution = state.billingExecution;
      if (execution) {
        this.validate(execution, dispatch);
        if (execution.finishedAtMs) return;
        const at = dispatch.resultAt ? Date.parse(dispatch.resultAt) : undefined;
        const job = (await sdk.getBillingJob(this.dc, { id: attempt.jobId })).data.job;
        const current =
          job?.latestRunId === attempt.runId &&
          job?.workerHost === attempt.workerHost &&
          job?.teamId === attempt.teamId;
        try {
          if (
            current &&
            at !== undefined &&
            at >= Number(execution.startedAtMs) &&
            at < Number(execution.leaseUntilMs)
          ) {
            await sdk.finishBillingExecution(this.dc, {
              ...attempt,
              expectedUsageRevision: state.billingAccount!.usageRevision,
              atMs: String(at),
              outcome: dispatch.outcome === "blocked" ? "failure" : dispatch.outcome!,
            });
          } else {
            await sdk.expireBillingExecution(this.dc, {
              teamId: attempt.teamId,
              runId: attempt.runId,
              expectedUsageRevision: state.billingAccount!.usageRevision,
              atMs: String(this.now()),
            });
          }
          return;
        } catch {
          continue;
        }
      }
      const admission = (await sdk.getBillingAdmission(this.dc, { id, teamId: attempt.teamId }))
        .data;
      if (!admission.billingAdmission || admission.billingAdmission.closedAtMs) return;
      if (
        admission.billingAdmission.workerHost !== attempt.workerHost ||
        admission.billingAdmission.jobId !== attempt.jobId
      )
        throw new Error("Billing identity mismatch");
      // A crash before metering has no execution to finish. Expiry safely
      // releases the admission; until then cleanup keeps the VM slot reserved.
      try {
        await sdk.expireBillingAdmission(this.dc, {
          id,
          teamId: attempt.teamId,
          runId: admission.billingAdmission.runId,
          expectedUsageRevision: admission.billingAccount!.usageRevision,
          atMs: String(this.now()),
        });
        return;
      } catch {
        /* The recovery sweep retries after expiry or a CAS conflict. */
      }
    }
    throw new Error("Billing closure pending");
  }

  private validate(
    execution: NonNullable<sdk.GetBillingExecutionData["billingExecution"]>,
    dispatch: Dispatch,
  ) {
    const attempt = identity(dispatch);
    if (
      execution.teamId !== attempt.teamId ||
      execution.jobId !== attempt.jobId ||
      execution.workerHost !== attempt.workerHost ||
      execution.runId !== attempt.runId
    )
      throw new Error("Billing identity mismatch");
  }
}
