import { randomUUID } from "node:crypto";
import type { BillingConfig } from "./config.js";
import {
  BillingError,
  emptyObservation,
  pending,
  terminal,
  UnverifiedPurchase,
  type BillingContext,
  type Observation,
  type StripeState,
} from "./model.js";
import { observePurchase } from "./purchase.js";
import { BillingStore } from "./store.js";
import { StripeBilling } from "./stripe.js";
import {
  cardSetupStatus,
  cardTermsVersion,
  reconcileCardSession,
  startCardSetup,
} from "./card_setup.js";

export class Billing {
  constructor(
    readonly store: BillingStore,
    readonly stripe: StripeBilling,
    readonly config: BillingConfig,
    readonly now = Date.now,
  ) {}
  private seconds() {
    return Math.floor(this.now() / 1000);
  }

  async execute(userId: string, input: unknown) {
    if (!input || typeof input !== "object" || Array.isArray(input))
      throw new BillingError("invalid-argument", "invalid_request");
    const { action, teamId, termsVersion } = input as Record<string, unknown>;
    if (
      typeof action !== "string" ||
      !["status", "checkout", "setupCard", "portal", "deleteTeam"].includes(action) ||
      typeof teamId !== "string" ||
      !teamId.trim() ||
      teamId.length > 255
    )
      throw new BillingError("invalid-argument", "invalid_request");
    if (action === "deleteTeam" && (await this.store.deleted(teamId, userId)))
      return { success: true };
    const context = await this.store.context(teamId, userId);
    if (action === "deleteTeam") return this.deleteTeam(teamId, userId, context);
    if (action === "status") return this.status(teamId, userId, context);
    if (!this.config.enabled) throw new BillingError("failed-precondition", "billing_disabled");
    this.compatible(context);
    if (action === "setupCard") {
      if (termsVersion !== cardTermsVersion)
        throw new BillingError("invalid-argument", "card_consent_required");
      if (this.config.selfHosted || this.config.complimentary.has(teamId))
        throw new BillingError("failed-precondition", "billing_disabled");
      const customerId = await this.ensureCustomer(teamId, userId, context);
      return startCardSetup(this.store, this.stripe, teamId, userId, customerId);
    }
    if (action === "checkout")
      throw new BillingError("failed-precondition", "monthly_plans_closed");
    const customerId = context.customer?.stripeCustomerId;
    if (!customerId) throw new BillingError("failed-precondition", "customer_missing");
    await this.stripe.ownedCustomer(teamId, customerId);
    await this.store.context(teamId, userId);
    const url = await this.stripe.portal(teamId, customerId);
    await this.store.context(teamId, userId);
    return { url };
  }

  private compatible(context: BillingContext) {
    if (
      (context.customer && context.customer.livemode !== this.config.livemode) ||
      (context.stripe &&
        (context.stripe.livemode !== this.config.livemode ||
          context.stripe.stripeCustomerId !== context.customer?.stripeCustomerId)) ||
      (context.cardSetup &&
        (context.cardSetup.livemode !== this.config.livemode ||
          context.cardSetup.stripeCustomerId !== context.customer?.stripeCustomerId)) ||
      (context.checkout &&
        (context.checkout.livemode !== this.config.livemode ||
          context.checkout.stripeCustomerId !== context.customer?.stripeCustomerId))
    )
      throw new BillingError("unavailable", "billing_unavailable");
  }

  private async status(teamId: string, userId: string, context: BillingContext) {
    const result = {
      billingEnabled: this.config.enabled,
      planId: null as string | null,
      canStartCi: false,
      blockReason: this.config.enabled ? "payment_required" : "billing_disabled",
      paidUntil: null as string | null,
      canCheckout: false,
      canManageBilling: false,
      cancelAtPeriodEnd: false,
      cardSetupStatus: null as Awaited<ReturnType<typeof cardSetupStatus>> | null,
    };
    if (this.config.selfHosted) {
      if (context.customer || context.stripe || context.checkout || context.cardSetup) {
        throw new BillingError("failed-precondition", "billing_unavailable");
      }
      return { ...result, canStartCi: true, blockReason: "" };
    }
    if (!this.config.enabled) return result;
    this.compatible(context);
    if (this.config.complimentary.has(teamId)) {
      const date = new Date(this.now());
      const start = Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), 1);
      const period = {
        id: `complimentary-pro:${teamId}:${new Date(start).toISOString().slice(0, 7)}`,
        teamId,
        planId: "pro",
        periodType: "paid",
        startsAt: String(start / 1000),
        endsAt: String(Date.UTC(date.getUTCFullYear(), date.getUTCMonth() + 1, 1) / 1000),
        allowanceSeconds: "360000",
      };
      await this.store.ensurePeriod(period);
      result.planId = "pro";
      result.canStartCi = (await this.store.available(teamId, period.id, this.now())) > 0n;
      result.blockReason = result.canStartCi ? "" : "allowance_exhausted";
    } else {
      result.cardSetupStatus = await cardSetupStatus(this.store, this.stripe, context.cardSetup);
      result.canManageBilling = !!context.customer?.stripeCustomerId;
      result.canStartCi = result.cardSetupStatus === "registered";
      result.blockReason = result.canStartCi
        ? ""
        : result.cardSetupStatus === "pending"
          ? "payment_pending"
          : "payment_required";
      if (result.canStartCi && context.cardSetup) {
        await this.store.confirmCardReady(
          teamId,
          context.cardSetup.sessionId,
          this.config.livemode,
        );
      }
    }
    await this.store.context(teamId, userId);
    return result;
  }

  private async ensureCustomer(teamId: string, userId: string, context: BillingContext) {
    if (!context.customer) {
      try {
        await this.store.createCustomer(teamId, userId, this.config.livemode, this.seconds());
      } catch {
        /* Read durable intent after conflict/timeout. */
      }
      context = await this.store.context(teamId, userId);
    }
    this.compatible(context);
    const intent = context.customer;
    if (!intent) throw pending();
    if (intent.stripeCustomerId) return intent.stripeCustomerId;
    await this.store.context(teamId, userId);
    const customer = await this.stripe.createCustomer(intent, this.seconds());
    try {
      await this.store.recordCustomer(intent, customer.id);
    } catch {
      /* Confirm saved identity below. */
    }
    const stored = (await this.store.context(teamId, userId)).customer;
    if (
      !stored ||
      stored.idempotencyKey !== intent.idempotencyKey ||
      stored.stripeCustomerId !== customer.id ||
      stored.livemode !== intent.livemode
    )
      throw pending();
    return customer.id;
  }

  // This endpoint is called by the trusted executor. A stored consent alone
  // cannot authorize a run after the customer removes their default card.
  async cardSessionForCi(teamId: string, livemode: boolean) {
    if (!this.config.enabled || this.config.selfHosted || livemode !== this.config.livemode)
      throw new BillingError("unavailable", "billing_unavailable");
    const setup = await this.store.cardSetup(teamId);
    if (!setup) return null;
    const owner = await this.store.customer(setup.stripeCustomerId, livemode);
    if (owner?.teamId !== teamId) throw new BillingError("unavailable", "billing_unavailable");
    const status = await cardSetupStatus(this.store, this.stripe, setup);
    return status === "registered" ? setup.sessionId : null;
  }

  async reconcile(
    teamId: string,
    customerId: string,
    eventId: string,
    eventType: string,
    eventCreated: number,
  ) {
    for (let attempt = 0; attempt < 4; attempt++) {
      const processed = await this.store.event(eventId);
      if (processed) {
        if (processed.eventType !== eventType || processed.eventCreated !== String(eventCreated))
          throw new Error("Conflicting Stripe event");
        return;
      }
      let state = await this.store.state(teamId, this.config.livemode);
      if (!state) {
        try {
          await this.store.initialize(teamId, customerId, this.config.livemode);
        } catch {
          /* Read after duplicate initialization. */
        }
        state = await this.store.state(teamId, this.config.livemode);
      }
      if (!state || state.stripeCustomerId !== customerId)
        throw new Error("Stripe state unavailable");
      // The CAS revision is captured BEFORE fetching Stripe. Never replay an
      // old observation with a newer revision after concurrent reconciliation.
      let observation: Observation;
      try {
        observation = await observePurchase(this.store, this.stripe, teamId, customerId);
      } catch (cause) {
        if (!(cause instanceof UnverifiedPurchase)) throw cause;
        observation = emptyObservation("unverified");
      }
      if (observation.period) await this.store.ensurePeriod(observation.period);
      observation = retainPaidPeriod(state, observation);
      const { period: _period, ...values } = observation;
      try {
        await this.store.recordEvent({
          teamId,
          stripeCustomerId: customerId,
          livemode: this.config.livemode,
          expectedRevision: state.revision,
          ...values,
          eventId,
          eventType,
          eventCreated: String(eventCreated),
          processedAt: String(Math.max(this.seconds(), Number(state.syncedAt))),
        });
        return;
      } catch {
        /* A lost response or revision conflict is resolved from the top. */
      }
    }
    // One final read covers a committed write whose last response was lost.
    const saved = await this.store.event(eventId);
    if (!saved || saved.eventType !== eventType || saved.eventCreated !== String(eventCreated))
      throw new Error("Billing synchronization needs retry");
  }

  private async deleteTeam(teamId: string, userId: string, context: BillingContext) {
    this.compatible(context);
    if (context.customer || context.stripe || context.checkout) {
      if (!this.config.enabled) throw new BillingError("failed-precondition", "billing_disabled");
      const customerId = context.customer?.stripeCustomerId;
      if (!customerId) throw pending();
      await this.reconcile(
        teamId,
        customerId,
        `delete-check:${randomUUID()}`,
        "billing.delete-check",
        this.seconds(),
      );
      context = await this.store.context(teamId, userId);
      const intent = context.checkout;
      if (intent) {
        if (!intent.stripeCheckoutSessionId) throw pending();
        const session = await this.stripe.existingSession(intent);
        // A deletion request does not expire an active purchase on the user's behalf.
        await this.stripe.ended(intent, session);
        await this.store.context(teamId, userId);
        await this.store.closeCheckout(intent, session.id, this.seconds());
        context = await this.store.context(teamId, userId);
      }
      this.compatible(context);
      await this.stripe.ownedCustomer(teamId, customerId);
      await this.stripe.noSubscription(customerId);
      const setup = context.cardSetup;
      if (setup?.status === "pending") {
        const open = await reconcileCardSession(this.store, this.stripe, setup);
        if (open) {
          await this.store.context(teamId, userId);
          try {
            await this.stripe.client.checkout.sessions.expire(
              open.id,
              {},
              { idempotencyKey: `expire-card:${open.id}` },
            );
          } catch {
            // Resolve a concurrent completion or lost expiry response from Stripe.
          }
          if (await reconcileCardSession(this.store, this.stripe, setup)) throw pending();
        }
      }
    }
    try {
      await this.store.deleteTeam(teamId, userId, this.config.livemode, context);
    } catch {
      if (!(await this.store.deleted(teamId, userId))) {
        await this.store.context(teamId, userId);
        throw pending();
      }
    }
    return { success: true };
  }
}

export function retainPaidPeriod(previous: StripeState, observation: Observation): Observation {
  const same =
    previous.stripeSubscriptionId &&
    previous.stripeSubscriptionId === observation.stripeSubscriptionId;
  if (
    terminal(previous.subscriptionStatus) &&
    (same || !observation.stripeSubscriptionId) &&
    observation.subscriptionStatus !== previous.subscriptionStatus
  )
    return {
      ...emptyObservation(previous.subscriptionStatus),
      stripeSubscriptionId: previous.stripeSubscriptionId ?? null,
      planId: previous.planId ?? null,
      paidPeriodId: previous.paidPeriodId ?? null,
      cancelAtPeriodEnd: previous.cancelAtPeriodEnd,
    };
  if (same && observation.subscriptionStatus !== "unverified") {
    observation.planId ??= previous.planId ?? null;
    if (
      previous.paidPeriodId &&
      (!observation.period ||
        Number(observation.period.endsAt) < Number(previous.paidPeriod?.endsAt))
    )
      observation.paidPeriodId = previous.paidPeriodId;
  }
  return observation;
}
