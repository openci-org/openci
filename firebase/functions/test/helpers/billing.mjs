import assert from "node:assert/strict";
import Stripe from "stripe";
import { StripeBilling } from "../../../lib/functions/billing/stripe.js";

export const now = Math.floor(Date.now() / 1000);
export const config = {
  enabled: true,
  livemode: false,
  origin: "https://dashboard.test",
  portalId: "bpc_test",
  prices: { light: "price_light", pro: "price_pro" },
  complimentary: new Set(),
};
export const price = {
  id: "price_light",
  active: true,
  livemode: false,
  currency: "usd",
  unit_amount: 1000,
  unit_amount_decimal: "1000",
  billing_scheme: "per_unit",
  type: "recurring",
  recurring: {
    interval: "month",
    interval_count: 1,
    usage_type: "licensed",
    trial_period_days: null,
  },
};
export function intent(teamId = "team") {
  return {
    teamId,
    idempotencyKey: "purchase-key",
    livemode: false,
    createdAt: String(now - 10),
    planId: "light",
    stripeCustomerId: "cus_test",
    stripePriceId: "price_light",
    successUrl: "https://dashboard.test/billing?teamId=" + teamId + "&result=success",
    cancelUrl: "https://dashboard.test/billing?teamId=" + teamId + "&result=cancel",
  };
}
export function session(i = intent()) {
  return {
    id: "cs_test",
    object: "checkout.session",
    mode: "subscription",
    ui_mode: "hosted_page",
    customer: i.stripeCustomerId,
    livemode: false,
    client_reference_id: i.teamId,
    metadata: { team_id: i.teamId, checkout_creation_key: i.idempotencyKey },
    success_url: i.successUrl,
    cancel_url: i.cancelUrl,
    status: "open",
    payment_status: "unpaid",
    subscription: null,
    expires_at: now + 3600,
    url: "https://checkout.stripe.com/c/pay/cs_test",
    line_items: {
      data: [{ quantity: 1, price: { ...price, id: i.stripePriceId } }],
      has_more: false,
    },
  };
}
export function subscription(teamId = "team") {
  return {
    id: "sub_test",
    object: "subscription",
    customer: "cus_test",
    livemode: false,
    status: "active",
    metadata: { team_id: teamId },
    created: now - 60,
    cancel_at_period_end: false,
    cancel_at: null,
    trial_start: null,
    trial_end: null,
    pause_collection: null,
    latest_invoice: "in_test",
    items: {
      has_more: false,
      data: [
        {
          id: "si_test",
          quantity: 1,
          current_trial: null,
          price,
          current_period_start: now - 60,
          current_period_end: now + 3600,
        },
      ],
    },
  };
}
export function invoice() {
  return {
    id: "in_test",
    object: "invoice",
    customer: "cus_test",
    livemode: false,
    parent: { subscription_details: { subscription: "sub_test" } },
    status: "paid",
    amount_remaining: 0,
    amount_paid: 1000,
    amount_paid_off_stripe: 0,
    currency: "usd",
    collection_method: "charge_automatically",
    discounts: [],
    total_discount_amounts: [],
    billing_reason: "subscription_cycle",
    lines: {
      has_more: false,
      data: [
        {
          id: "il_test",
          invoice: "in_test",
          livemode: false,
          quantity: 1,
          quantity_decimal: "1",
          amount: 1000,
          currency: "usd",
          discounts: [],
          discount_amounts: [],
          pricing: { price_details: { price: "price_light" } },
          parent: {
            subscription_item_details: {
              subscription: "sub_test",
              subscription_item: "si_test",
              proration: false,
            },
          },
          period: { start: now - 60, end: now + 3600 },
        },
      ],
    },
  };
}
export function stripeFixture(route, overrides = {}) {
  const requests = [];
  const client = new Stripe("sk_test_fake", {
    maxNetworkRetries: 0,
    telemetry: false,
    httpClient: Stripe.createFetchHttpClient(async (url, init) => {
      const request = {
        url: new URL(url),
        method: init.method,
        body: new URLSearchParams(init.body),
        headers: new Headers(init.headers),
      };
      requests.push(request);
      const body = await route(request);
      assert.ok(body, `Unexpected Stripe request: ${request.method} ${request.url.pathname}`);
      return new Response(JSON.stringify(body), {
        status: 200,
        headers: { "content-type": "application/json" },
      });
    }),
  });
  return { client, requests, stripe: new StripeBilling(client, { ...config, ...overrides }) };
}
