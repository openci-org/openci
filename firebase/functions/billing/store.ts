import { randomUUID } from "node:crypto";
import type { DataConnect } from "firebase-admin/data-connect";
import * as sdk from "@openci/billing-admin";
import {
  BillingError,
  type BillingContext,
  type CheckoutIntent,
  type CustomerIntent,
  type Period,
} from "./model.js";

export class BillingStore {
  constructor(readonly dc: DataConnect) {}
  async context(teamId: string, userId: string): Promise<BillingContext> {
    try {
      return (await sdk.getBillingContext(this.dc, { teamId, userId })).data;
    } catch {
      if (!(await sdk.getBillingMembership(this.dc, { teamId, userId })).data.member)
        throw new BillingError("permission-denied", "forbidden");
      throw new Error("Billing context unavailable");
    }
  }
  async createCustomer(teamId: string, userId: string, livemode: boolean, now: number) {
    await sdk.createBillingCustomerCreation(this.dc, {
      teamId,
      userId,
      livemode,
      idempotencyKey: randomUUID(),
      createdAt: String(now),
    });
  }
  async recordCustomer(intent: CustomerIntent, stripeCustomerId: string) {
    await sdk.recordBillingCustomer(this.dc, {
      teamId: intent.teamId,
      idempotencyKey: intent.idempotencyKey,
      livemode: intent.livemode,
      stripeCustomerId,
    });
  }
  async createCheckout(input: sdk.CreateBillingCheckoutCreationVariables) {
    await sdk.createBillingCheckoutCreation(this.dc, input);
  }
  async recordCheckout(intent: CheckoutIntent, stripeCheckoutSessionId: string) {
    const {
      idempotencyKey,
      teamId,
      planId,
      stripeCustomerId,
      stripePriceId,
      successUrl,
      cancelUrl,
      livemode,
      createdAt,
    } = intent;
    await sdk.recordBillingCheckoutSession(this.dc, {
      idempotencyKey,
      teamId,
      planId,
      stripeCustomerId,
      stripePriceId,
      successUrl,
      cancelUrl,
      livemode,
      createdAt,
      stripeCheckoutSessionId,
    });
  }
  async closeCheckout(intent: CheckoutIntent, stripeCheckoutSessionId: string, now: number) {
    await sdk.closeBillingCheckoutCreation(this.dc, {
      teamId: intent.teamId,
      idempotencyKey: intent.idempotencyKey,
      stripeCustomerId: intent.stripeCustomerId,
      livemode: intent.livemode,
      stripeCheckoutSessionId,
      closedAt: String(now),
    });
  }
  async checkout(teamId: string, idempotencyKey: string, livemode: boolean) {
    return (await sdk.getBillingCheckoutCreation(this.dc, { teamId, idempotencyKey, livemode }))
      .data.checkout;
  }
  async customer(stripeCustomerId: string, livemode: boolean) {
    return (await sdk.getBillingCustomerByStripeId(this.dc, { stripeCustomerId, livemode })).data
      .customer;
  }
  async state(teamId: string, livemode: boolean) {
    return (await sdk.getBillingStripeState(this.dc, { teamId, livemode })).data.billingStripeState;
  }
  async initialize(teamId: string, stripeCustomerId: string, livemode: boolean) {
    await sdk.initializeBillingStripeState(this.dc, { teamId, stripeCustomerId, livemode });
  }
  async event(eventId: string) {
    return (await sdk.getBillingStripeEvent(this.dc, { eventId })).data.billingStripeEvent;
  }
  async recordEvent(input: sdk.RecordBillingStripeEventVariables) {
    await sdk.recordBillingStripeEvent(this.dc, input);
  }
  async ensurePeriod(period: Period) {
    let stored = (await sdk.getBillingPeriod(this.dc, { teamId: period.teamId, id: period.id }))
      .data.period;
    if (!stored) {
      try {
        await sdk.createBillingPeriod(this.dc, period);
      } catch {
        /* Resolve duplicate/lost response by reading. */
      }
      stored = (await sdk.getBillingPeriod(this.dc, { teamId: period.teamId, id: period.id })).data
        .period;
    }
    if (
      !stored ||
      Object.entries(period).some(([key, value]) => stored![key as keyof Period] !== value)
    )
      throw new Error("Billing period does not match verified purchase");
  }
  async available(teamId: string, periodId: string, atMs: number): Promise<bigint> {
    const usage = (
      await sdk.getBillingPeriodUsage(this.dc, { teamId, periodId, atMs: String(atMs) })
    ).data.usage;
    if (
      !usage ||
      typeof usage !== "object" ||
      !("availableMillis" in usage) ||
      !/^-?\d+$/.test(String(usage.availableMillis))
    )
      throw new Error("Billing usage unavailable");
    return BigInt(String(usage.availableMillis));
  }
  async deleted(teamId: string, userId: string) {
    return !!(await sdk.getBillingTeamDeletion(this.dc, { teamId, userId })).data.receipt;
  }
  async deleteTeam(teamId: string, userId: string, livemode: boolean, context: BillingContext) {
    await sdk.deleteBillingTeam(this.dc, {
      teamId,
      userId,
      livemode,
      expectedCustomerCreationKey: context.customer?.idempotencyKey ?? null,
      expectedStripeCustomerId: context.customer?.stripeCustomerId ?? null,
      expectedStripeRevision: context.stripe?.revision ?? null,
    });
  }
}
