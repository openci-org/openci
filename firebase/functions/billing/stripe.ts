import Stripe from "stripe";
import {
  BillingError,
  id,
  pending,
  plan,
  plans,
  terminal,
  UnverifiedPurchase,
  type CheckoutIntent,
  type CustomerIntent,
} from "./model.js";
import { returnUrl, type BillingConfig } from "./config.js";

const retryWindow = 23 * 60 * 60;
function verify(condition: unknown): asserts condition {
  if (!condition) throw new UnverifiedPurchase();
}
export function validatePrice(
  price: Stripe.Price,
  planId: string,
  livemode: boolean,
  active = true,
) {
  const expected = plans[plan(planId)];
  verify(
    price.id &&
      (!active || price.active) &&
      price.livemode === livemode &&
      price.currency === "usd" &&
      price.unit_amount === expected.cents &&
      (price.unit_amount_decimal == null ||
        String(price.unit_amount_decimal) === String(expected.cents)) &&
      price.billing_scheme === "per_unit" &&
      !price.custom_unit_amount &&
      !price.transform_quantity &&
      price.type === "recurring" &&
      price.recurring?.interval === "month" &&
      price.recurring.interval_count === 1 &&
      price.recurring.usage_type === "licensed" &&
      !price.recurring.trial_period_days,
  );
}

export function validateSession(intent: CheckoutIntent, session: Stripe.Checkout.Session) {
  verify(
    session.id &&
      session.mode === "subscription" &&
      session.ui_mode === "hosted_page" &&
      session.livemode === intent.livemode &&
      id(session.customer) === intent.stripeCustomerId &&
      session.client_reference_id === intent.teamId &&
      session.metadata?.team_id === intent.teamId &&
      session.metadata?.checkout_creation_key === intent.idempotencyKey &&
      session.success_url === intent.successUrl &&
      session.cancel_url === intent.cancelUrl &&
      (!intent.stripeCheckoutSessionId || session.id === intent.stripeCheckoutSessionId),
  );
}

function validateItems(intent: CheckoutIntent, session: Stripe.Checkout.Session) {
  const items = session.line_items;
  verify(
    items &&
      !items.has_more &&
      items.data.length === 1 &&
      items.data[0].quantity === 1 &&
      items.data[0].price?.id === intent.stripePriceId,
  );
}

export function stripeRedirect(value: string | null, portal = false): string {
  if (!value) throw pending();
  const url = new URL(value);
  if (
    url.protocol !== "https:" ||
    url.username ||
    url.password ||
    url.port ||
    url.hostname !== (portal ? "billing.stripe.com" : "checkout.stripe.com") ||
    (portal
      ? !(
          (url.pathname.startsWith("/p/session/") && url.pathname.length > 11) ||
          (url.pathname === "/p/session" && url.searchParams.get("secret")?.trim())
        )
      : !(url.pathname.startsWith("/c/pay/") && url.pathname.length > 7))
  )
    throw pending();
  return value;
}

export class StripeBilling {
  constructor(
    readonly client: Stripe,
    readonly config: BillingConfig,
  ) {}

  async ownedCustomer(teamId: string, customerId: string) {
    const customer = await this.client.customers.retrieve(customerId);
    verify(
      !customer.deleted &&
        customer.id === customerId &&
        customer.livemode === this.config.livemode &&
        customer.metadata.team_id === teamId,
    );
    return customer;
  }

  async price(planId: "light" | "pro") {
    const priceId = this.config.prices[planId];
    const price = await this.client.prices.retrieve(priceId);
    verify(price.id === priceId);
    validatePrice(price, planId, this.config.livemode);
    return priceId;
  }

  async createCustomer(intent: CustomerIntent, now: number) {
    if (intent.livemode !== this.config.livemode || now < Number(intent.createdAt)) throw pending();
    let customer: Stripe.Customer;
    if (now + 10 < Number(intent.createdAt) + retryWindow) {
      customer = await this.client.customers.create(
        { metadata: { team_id: intent.teamId } },
        { idempotencyKey: intent.idempotencyKey },
      );
    } else {
      // Never issue a new POST after Stripe can forget an idempotency key.
      const escaped = intent.teamId.replace(/\\/g, "\\\\").replace(/"/g, '\\"');
      const found = await this.client.customers.search({
        query: `metadata["team_id"]:"${escaped}"`,
        limit: 2,
      });
      if (found.has_more || found.data.length !== 1) throw pending();
      customer = found.data[0];
    }
    verify(
      customer.id &&
        customer.livemode === intent.livemode &&
        customer.metadata.team_id === intent.teamId,
    );
    return customer;
  }

  async session(intent: CheckoutIntent, now: number) {
    let session: Stripe.Checkout.Session;
    if (intent.livemode !== this.config.livemode || now < Number(intent.createdAt)) throw pending();
    if (intent.stripeCheckoutSessionId) {
      session = await this.client.checkout.sessions.retrieve(intent.stripeCheckoutSessionId, {
        expand: ["line_items"],
      });
    } else if (now + 10 < Number(intent.createdAt) + retryWindow) {
      session = await this.client.checkout.sessions.create(
        {
          mode: "subscription",
          ui_mode: "hosted_page",
          customer: intent.stripeCustomerId,
          client_reference_id: intent.teamId,
          success_url: intent.successUrl,
          cancel_url: intent.cancelUrl,
          allowed_payment_method_types: ["card"],
          adaptive_pricing: { enabled: false },
          line_items: [{ price: intent.stripePriceId, quantity: 1 }],
          metadata: { team_id: intent.teamId, checkout_creation_key: intent.idempotencyKey },
          subscription_data: { metadata: { team_id: intent.teamId } },
        },
        { idempotencyKey: intent.idempotencyKey },
      );
      // Keep creation parameters identical to the legacy server for imported
      // in-flight intents; expand the item on a separate read.
      session = await this.client.checkout.sessions.retrieve(session.id, {
        expand: ["line_items"],
      });
    } else {
      let match: Stripe.Checkout.Session | undefined;
      let count = 0;
      for await (const candidate of this.client.checkout.sessions.list({
        customer: intent.stripeCustomerId,
        created: { gte: Number(intent.createdAt) - 300 },
        limit: 100,
        expand: ["data.line_items"],
      })) {
        if (++count > 1000) throw pending();
        if (candidate.metadata?.checkout_creation_key !== intent.idempotencyKey) continue;
        if (match) throw pending();
        match = candidate;
      }
      if (!match) throw pending();
      session = match;
    }
    validateSession(intent, session);
    validateItems(intent, session);
    verify(session.status && ["open", "complete", "expired"].includes(session.status));
    return session;
  }

  async subscriptions(customerId: string): Promise<Stripe.Subscription[]> {
    const result: Stripe.Subscription[] = [];
    for await (const subscription of this.client.subscriptions.list({
      customer: customerId,
      status: "all",
      limit: 100,
    })) {
      verify(
        result.length < 1000 &&
          subscription.id &&
          id(subscription.customer) === customerId &&
          subscription.livemode === this.config.livemode,
      );
      result.push(subscription);
    }
    return result;
  }

  async noSubscription(customerId: string) {
    if ((await this.subscriptions(customerId)).some((s) => !terminal(s.status)))
      throw new BillingError("failed-precondition", "subscription_exists");
  }

  async ended(intent: CheckoutIntent, session: Stripe.Checkout.Session, expire: boolean) {
    validateSession(intent, session);
    if (session.status === "open" && expire && !session.subscription) {
      try {
        await this.client.checkout.sessions.expire(
          session.id,
          {},
          { idempotencyKey: intent.idempotencyKey + ":expire" },
        );
      } catch {
        /* Confirm remote state after an ambiguous response. */
      }
      session = await this.client.checkout.sessions.retrieve(session.id);
      validateSession(intent, session);
    }
    if (
      session.status === "expired" &&
      session.payment_status === "unpaid" &&
      !session.subscription
    )
      return;
    const subscriptionId = id(session.subscription);
    if (session.status === "complete" && subscriptionId) {
      const subscription = await this.client.subscriptions.retrieve(subscriptionId);
      verify(
        subscription.id === subscriptionId &&
          id(subscription.customer) === intent.stripeCustomerId &&
          subscription.livemode === intent.livemode &&
          subscription.metadata.team_id === intent.teamId,
      );
      if (!terminal(subscription.status))
        throw new BillingError("failed-precondition", "subscription_exists");
      return;
    }
    throw pending();
  }

  async portal(teamId: string, customerId: string) {
    const config = await this.client.billingPortal.configurations.retrieve(this.config.portalId);
    const features = config.features;
    verify(
      config.id === this.config.portalId &&
        config.active &&
        config.livemode === this.config.livemode &&
        features.invoice_history.enabled &&
        features.payment_method_update.enabled &&
        !features.subscription_update.enabled &&
        !config.login_page?.enabled &&
        features.subscription_cancel.enabled &&
        features.subscription_cancel.mode === "at_period_end" &&
        features.subscription_cancel.proration_behavior === "none",
    );
    const return_url = returnUrl(this.config, teamId, "portal");
    const session = await this.client.billingPortal.sessions.create({
      customer: customerId,
      configuration: config.id,
      return_url,
    });
    verify(
      session.id &&
        session.customer === customerId &&
        id(session.configuration) === config.id &&
        session.return_url === return_url &&
        session.livemode === this.config.livemode,
    );
    return stripeRedirect(session.url, true);
  }
}
