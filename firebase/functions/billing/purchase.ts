import type Stripe from "stripe";
import {
  emptyObservation,
  id,
  plan,
  plans,
  terminal,
  UnverifiedPurchase,
  type CheckoutIntent,
  type Observation,
  type Period,
} from "./model.js";
import type { BillingStore } from "./store.js";
import { StripeBilling, validatePrice, validateSession } from "./stripe.js";

function verify(condition: unknown): asserts condition {
  if (!condition) throw new UnverifiedPurchase();
}

export function paidPeriod(
  intent: CheckoutIntent,
  subscription: Stripe.Subscription,
  invoice: Stripe.Invoice,
): Period {
  const expected = plans[plan(intent.planId)];
  const item = subscription.items.data[0];
  verify(
    invoice.id &&
      id(invoice.customer) === intent.stripeCustomerId &&
      invoice.livemode === intent.livemode &&
      id(invoice.parent?.subscription_details?.subscription) === subscription.id &&
      invoice.status === "paid" &&
      invoice.amount_remaining === 0 &&
      invoice.amount_paid >= expected.cents &&
      !invoice.amount_paid_off_stripe &&
      invoice.currency === "usd" &&
      invoice.collection_method === "charge_automatically" &&
      !invoice.discounts?.length &&
      !invoice.total_discount_amounts?.length &&
      ["subscription_create", "subscription_cycle"].includes(invoice.billing_reason ?? "") &&
      invoice.lines &&
      !invoice.lines.has_more &&
      invoice.lines.data.length === 1,
  );
  const line = invoice.lines.data[0];
  const parent = line.parent?.subscription_item_details;
  verify(
    line.id &&
      line.invoice === invoice.id &&
      line.livemode === intent.livemode &&
      line.quantity === 1 &&
      (line.quantity_decimal == null || String(line.quantity_decimal) === "1") &&
      line.amount === expected.cents &&
      line.currency === "usd" &&
      !line.discounts?.length &&
      !line.discount_amounts?.length &&
      id(line.pricing?.price_details?.price) === intent.stripePriceId &&
      parent &&
      !parent.proration &&
      parent.subscription === subscription.id &&
      parent.subscription_item === item.id &&
      line.period.start === item.current_period_start &&
      line.period.end === item.current_period_end,
  );
  return {
    id: `stripe:${invoice.id}`,
    teamId: intent.teamId,
    planId: intent.planId,
    periodType: "paid",
    startsAt: String(line.period.start),
    endsAt: String(line.period.end),
    allowanceSeconds: expected.seconds,
  };
}

export async function observePurchase(
  store: BillingStore,
  stripe: StripeBilling,
  teamId: string,
  customerId: string,
): Promise<Observation> {
  await stripe.ownedCustomer(teamId, customerId);
  const subscriptions = await stripe.subscriptions(customerId);
  const current = subscriptions.filter((s) => !terminal(s.status));
  verify(current.length <= 1);
  const subscription =
    current[0] ??
    subscriptions.sort((a, b) => b.created - a.created || b.id.localeCompare(a.id))[0];
  if (!subscription) return emptyObservation();
  verify(subscription.metadata.team_id === teamId);
  const observation: Observation = {
    ...emptyObservation(subscription.status),
    stripeSubscriptionId: subscription.id,
    cancelAtPeriodEnd: subscription.cancel_at_period_end,
  };
  if (!["active", "past_due"].includes(subscription.status)) return observation;
  const sessions = await stripe.client.checkout.sessions.list({
    customer: customerId,
    subscription: subscription.id,
    limit: 2,
  });
  verify(!sessions.has_more && sessions.data.length === 1);
  const session = sessions.data[0];
  verify(
    session.status === "complete" &&
      id(session.subscription) === subscription.id &&
      session.metadata?.checkout_creation_key,
  );
  const intent = await store.checkout(
    teamId,
    session.metadata.checkout_creation_key,
    stripe.config.livemode,
  );
  verify(intent);
  validateSession(intent, session);
  verify(
    !subscription.items.has_more &&
      subscription.items.data.length === 1 &&
      !subscription.pause_collection &&
      !subscription.trial_start &&
      !subscription.trial_end,
  );
  const item = subscription.items.data[0];
  verify(
    item.id &&
      !item.deleted &&
      item.quantity === 1 &&
      !item.current_trial &&
      item.price.id === intent.stripePriceId &&
      item.current_period_start > 0 &&
      item.current_period_end > item.current_period_start,
  );
  validatePrice(item.price, intent.planId, intent.livemode, false);
  observation.planId = intent.planId;
  observation.cancelAtPeriodEnd ||= subscription.cancel_at === item.current_period_end;
  const invoiceId = id(subscription.latest_invoice);
  verify(invoiceId);
  const invoice = await stripe.client.invoices.retrieve(invoiceId);
  verify(
    invoice.id === invoiceId &&
      id(invoice.customer) === customerId &&
      invoice.livemode === intent.livemode &&
      id(invoice.parent?.subscription_details?.subscription) === subscription.id,
  );
  if (invoice.status === "paid") {
    const period = paidPeriod(intent, subscription, invoice);
    return { ...observation, paidPeriodId: period.id, period };
  }
  return observation;
}
