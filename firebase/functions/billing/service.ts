import { randomUUID } from "node:crypto";
import type { BillingConfig } from "./config.js";
import { returnUrl } from "./config.js";
import {
  BillingError,
  emptyObservation,
  pending,
  plan,
  terminal,
  UnverifiedPurchase,
  type BillingContext,
  type CheckoutIntent,
  type Observation,
  type StripeState,
} from "./model.js";
import { observePurchase } from "./purchase.js";
import { BillingStore } from "./store.js";
import { StripeBilling, stripeRedirect } from "./stripe.js";

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
    const { action, teamId, planId } = input as Record<string, unknown>;
    if (
      typeof action !== "string" ||
      !["status", "checkout", "portal", "deleteTeam"].includes(action) ||
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
    if (action === "checkout")
      return { url: await this.checkout(teamId, userId, plan(planId), context) };
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
    };
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
      if (context.customer?.stripeCustomerId) {
        // Explicit page reload also repairs a delayed or missed webhook.
        await this.reconcile(
          teamId,
          context.customer.stripeCustomerId,
          `refresh:${randomUUID()}`,
          "billing.refresh",
          this.seconds(),
        );
        context = await this.store.context(teamId, userId);
        this.compatible(context);
      }
      const state = context.stripe;
      const status = state?.subscriptionStatus ?? "none";
      const period = state?.paidPeriod;
      result.planId = state?.planId ?? null;
      result.cancelAtPeriodEnd = state?.cancelAtPeriodEnd ?? false;
      result.canManageBilling = !!context.customer?.stripeCustomerId;
      result.canCheckout = status === "none" || terminal(status);
      // Retrying Checkout must remain possible after a lost customer-creation
      // response: ensureCustomer reuses/reconciles the existing intent.
      if (period) result.paidUntil = new Date(Number(period.endsAt) * 1000).toISOString();
      result.canStartCi = !!(
        period &&
        period.id === state?.paidPeriodId &&
        period.teamId === teamId &&
        period.planId === state?.planId &&
        period.periodType === "paid" &&
        ["active", "past_due"].includes(status) &&
        Number(period.startsAt) <= this.seconds() &&
        Number(period.endsAt) > this.seconds()
      );
      if (result.canStartCi) {
        result.canStartCi = (await this.store.available(teamId, period!.id, this.now())) > 0n;
        result.blockReason = result.canStartCi ? "" : "allowance_exhausted";
      } else if (status === "unverified") result.blockReason = "billing_unavailable";
      else if (terminal(status)) result.blockReason = "subscription_ended";
      else if (
        status === "incomplete" ||
        (status === "none" &&
          (context.checkout || (context.customer && !context.customer.stripeCustomerId)))
      )
        result.blockReason = "payment_pending";
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

  private async ensureSession(teamId: string, userId: string, intent: CheckoutIntent) {
    await this.store.context(teamId, userId);
    const session = await this.stripe.session(intent, this.seconds());
    try {
      await this.store.recordCheckout(intent, session.id);
    } catch {
      /* Confirm saved identity below. */
    }
    const current = (await this.store.context(teamId, userId)).checkout;
    if (
      !current ||
      current.idempotencyKey !== intent.idempotencyKey ||
      current.stripeCheckoutSessionId !== session.id
    )
      throw pending();
    return session;
  }

  private async checkout(
    teamId: string,
    userId: string,
    planId: "light" | "pro",
    context: BillingContext,
  ) {
    if (this.config.complimentary.has(teamId))
      throw new BillingError("failed-precondition", "subscription_exists");
    const stripePriceId = await this.stripe.price(planId);
    const stripeCustomerId = await this.ensureCustomer(teamId, userId, context);
    await this.stripe.ownedCustomer(teamId, stripeCustomerId);
    await this.stripe.noSubscription(stripeCustomerId);
    context = await this.store.context(teamId, userId);
    this.compatible(context);
    const previous = context.checkout;
    if (previous) {
      const session = await this.ensureSession(teamId, userId, previous);
      if (
        previous.planId === planId &&
        session.status === "open" &&
        !session.subscription &&
        session.expires_at > this.seconds()
      )
        return stripeRedirect(session.url);
      await this.stripe.ended(previous, session, true);
      await this.store.context(teamId, userId);
      await this.store.closeCheckout(previous, session.id, this.seconds());
    }
    await this.store.context(teamId, userId);
    await this.stripe.noSubscription(stripeCustomerId);
    const desired = {
      teamId,
      planId,
      stripeCustomerId,
      stripePriceId,
      successUrl: returnUrl(this.config, teamId, "success"),
      cancelUrl: returnUrl(this.config, teamId, "cancel"),
      livemode: this.config.livemode,
    };
    try {
      await this.store.createCheckout({
        ...desired,
        userId,
        idempotencyKey: randomUUID(),
        createdAt: String(this.seconds()),
      });
    } catch {
      /* Concurrent requests must share the persisted intent. */
    }
    const intent = (await this.store.context(teamId, userId)).checkout;
    if (
      !intent ||
      Object.entries(desired).some(([key, value]) => intent[key as keyof CheckoutIntent] !== value)
    )
      throw new BillingError("failed-precondition", "checkout_conflict");
    const session = await this.ensureSession(teamId, userId, intent);
    if (session.status !== "open" || session.subscription || session.expires_at <= this.seconds())
      throw pending();
    return stripeRedirect(session.url);
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
        const session = await this.stripe.session(intent, this.seconds());
        // A deletion request does not expire an active purchase on the user's behalf.
        await this.stripe.ended(intent, session, false);
        await this.store.context(teamId, userId);
        await this.store.closeCheckout(intent, session.id, this.seconds());
        context = await this.store.context(teamId, userId);
      }
      this.compatible(context);
      await this.stripe.ownedCustomer(teamId, customerId);
      await this.stripe.noSubscription(customerId);
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
