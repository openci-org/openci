import type Stripe from "stripe";
import type { Billing } from "./service.js";
import { id } from "./model.js";

const supported = new Set([
  "checkout.session.completed",
  "checkout.session.expired",
  "customer.subscription.created",
  "customer.subscription.updated",
  "customer.subscription.deleted",
  "customer.subscription.paused",
  "customer.subscription.resumed",
  "invoice.paid",
  "invoice.payment_failed",
  "invoice.payment_action_required",
  "invoice.marked_uncollectible",
  "invoice.voided",
  "customer.deleted",
]);

export async function receiveStripeWebhook(
  request: { method: string; rawBody: Buffer; signature?: string },
  billing: Billing,
  secret: string,
): Promise<number> {
  if (request.method !== "POST") return 405;
  if (!billing.config.enabled || !secret.startsWith("whsec_")) return 503;
  if (request.rawBody.length > 1024 * 1024) return 413;
  if (!request.signature) return 400;
  let event: Stripe.Event;
  try {
    event = billing.stripe.client.webhooks.constructEvent(
      request.rawBody,
      request.signature,
      secret,
    );
  } catch {
    return 400;
  }
  if (
    !event.id ||
    event.livemode !== billing.config.livemode ||
    event.account ||
    event.context ||
    !Number.isSafeInteger(event.created) ||
    event.created < 0
  )
    return 400;
  if (!supported.has(event.type)) return 204;
  const object = event.data.object as { id?: string; customer?: string | { id: string } | null };
  const customerId = event.type === "customer.deleted" ? object.id : id(object.customer);
  if (!customerId) return 400;
  const customer = await billing.store.customer(customerId, billing.config.livemode);
  if (!customer) return 204;
  await billing.reconcile(customer.teamId, customerId, event.id, event.type, event.created);
  return 204;
}
