import assert from "node:assert/strict";
import { test } from "node:test";
import { billingConfig } from "../../lib/functions/billing/config.js";
import { Billing, retainPaidPeriod } from "../../lib/functions/billing/service.js";
import { BillingError, UnverifiedPurchase } from "../../lib/functions/billing/model.js";
import { observePurchase, paidPeriod } from "../../lib/functions/billing/purchase.js";
import { validatePrice, stripeRedirect } from "../../lib/functions/billing/stripe.js";
import { receiveStripeWebhook } from "../../lib/functions/billing/webhook.js";
import {
  config,
  now,
  price,
  intent,
  session,
  subscription,
  invoice,
  stripeFixture,
} from "./helpers/billing.mjs";

const denied = new BillingError("permission-denied", "forbidden");
const state = () => ({
  teamId: "team",
  stripeCustomerId: "cus_test",
  livemode: false,
  subscriptionStatus: "none",
  cancelAtPeriodEnd: false,
  syncedAt: "0",
  revision: "0",
});

test("only the Cloud executor is a declared invoker of the card eligibility endpoint", async () => {
  const { ciCardEligibility } = await import("../../lib/functions/billing_functions.js");
  assert.deepEqual(ciCardEligibility.__endpoint.httpsTrigger.invoker, ["openci-executor@"]);
});

test("billing configuration is disabled by default and rejects mismatched modes and redirects", () => {
  assert.equal(billingConfig({}).enabled, false);
  const env = {
    BILLING_ENABLED: "true",
    STRIPE_LIVEMODE: "false",
    STRIPE_SECRET_KEY: "sk_test_fake",
    BILLING_DASHBOARD_ORIGIN: config.origin,
    STRIPE_PORTAL_CONFIGURATION_ID: config.portalId,
  };
  assert.equal(billingConfig(env).enabled, true);
  for (const change of [
    { STRIPE_SECRET_KEY: "sk_live_fake" },
    { STRIPE_LIVEMODE: "yes" },
    { STRIPE_PORTAL_CONFIGURATION_ID: "" },
    { BILLING_DASHBOARD_ORIGIN: "https://dashboard.test/path" },
    { BILLING_DASHBOARD_ORIGIN: "http://evil.test" },
  ])
    assert.throws(() => billingConfig({ ...env, ...change }));
});

test("only the configured fixed monthly USD plan without trial grants a purchase", () => {
  validatePrice(price, "light", false);
  for (const changed of [
    { unit_amount: 1 },
    { unit_amount_decimal: "1000.01" },
    { currency: "jpy" },
    { livemode: true },
    { active: false },
    { custom_unit_amount: {} },
    { transform_quantity: {} },
    { recurring: { ...price.recurring, interval: "year" } },
    { recurring: { ...price.recurring, trial_period_days: 7 } },
    { recurring: { ...price.recurring, usage_type: "metered" } },
  ])
    assert.throws(
      () => validatePrice({ ...price, ...changed }, "light", false),
      UnverifiedPurchase,
    );
});

test("Customer retries preserve their durable key; old intents search without another creation", async () => {
  const owner = {
    teamId: "team",
    idempotencyKey: "customer-key",
    createdAt: String(now - 10),
    livemode: false,
  };
  const customer = { id: "cus_test", metadata: { team_id: "team" }, livemode: false };
  const f = stripeFixture((r) =>
    r.url.pathname.endsWith("/search") ? { data: [customer], has_more: false } : customer,
  );
  await f.stripe.createCustomer(owner, now);
  await f.stripe.createCustomer(owner, now);
  assert.equal(f.requests[0].headers.get("idempotency-key"), "customer-key");
  assert.equal(f.requests[1].body.toString(), f.requests[0].body.toString());
  await f.stripe.createCustomer({ ...owner, createdAt: String(now - 24 * 3600) }, now);
  assert.equal(f.requests[2].method, "GET");
  assert.equal(f.requests[2].url.pathname, "/v1/customers/search");
  const missing = stripeFixture(() => ({ data: [], has_more: false }));
  await assert.rejects(
    missing.stripe.createCustomer({ ...owner, createdAt: "0" }, now),
    /payment_pending/,
  );
  assert.equal(missing.requests.length, 1);
});

test("historical subscription checkout lookup requires its saved session id and is read-only", async () => {
  const i = intent();
  const f = stripeFixture(() => session(i));
  await assert.rejects(f.stripe.existingSession(i), /payment_pending/);
  assert.equal(f.requests.length, 0);
  const saved = session(i);
  await f.stripe.existingSession({ ...i, stripeCheckoutSessionId: saved.id });
  assert.deepEqual(
    f.requests.map((r) => [r.method, r.url.pathname]),
    [["GET", `/v1/checkout/sessions/${saved.id}`]],
  );
});

test("an active or racing completed Checkout prevents team deletion", async () => {
  const i = intent();
  const f = stripeFixture(() => ({ ...subscription(), status: "active" }));
  await assert.rejects(f.stripe.ended(i, session(i)), /payment_pending/);
  assert.equal(f.requests.length, 0);
  await assert.rejects(
    f.stripe.ended(i, { ...session(i), status: "complete", subscription: "sub_test" }),
    /subscription_exists/,
  );
  await f.stripe.ended(i, { ...session(i), status: "expired" });
});

test("paid entitlement requires matching invoice, price, subscription, full payment and period", () => {
  assert.equal(paidPeriod(intent(), subscription(), invoice()).allowanceSeconds, "36000");
  for (const change of [
    { amount_paid: 999 },
    { amount_paid_off_stripe: 1000 },
    { customer: "cus_other" },
    { status: "open" },
    { collection_method: "send_invoice" },
    { billing_reason: "subscription_update" },
    { discounts: ["coupon"] },
    { lines: { ...invoice().lines, has_more: true } },
  ])
    assert.throws(
      () => paidPeriod(intent(), subscription(), { ...invoice(), ...change }),
      UnverifiedPurchase,
    );
  for (const change of [
    { amount: 999 },
    { quantity_decimal: "1.5" },
    { invoice: "in_other" },
    { period: { start: now - 60, end: now + 7200 } },
    {
      parent: {
        subscription_item_details: {
          subscription: "sub_test",
          subscription_item: "si_test",
          proration: true,
        },
      },
    },
  ]) {
    const copy = invoice();
    copy.lines.data[0] = { ...copy.lines.data[0], ...change };
    assert.throws(() => paidPeriod(intent(), subscription(), copy), UnverifiedPurchase);
  }
});

function purchaseStripe() {
  return stripeFixture((r) => {
    if (r.url.pathname === "/v1/customers/cus_test")
      return { id: "cus_test", livemode: false, metadata: { team_id: "team" } };
    if (r.url.pathname === "/v1/subscriptions") return { data: [subscription()], has_more: false };
    if (r.url.pathname === "/v1/checkout/sessions")
      return {
        data: [{ ...session(), status: "complete", subscription: "sub_test" }],
        has_more: false,
      };
    if (r.url.pathname === "/v1/invoices/in_test") return invoice();
  });
}
test("Stripe observation uses a persisted purchase and never trusts webhook amounts", async () => {
  const f = purchaseStripe();
  const result = await observePurchase(
    { checkout: async () => intent() },
    f.stripe,
    "team",
    "cus_test",
  );
  assert.equal(result.paidPeriodId, "stripe:in_test");
  await assert.rejects(
    observePurchase({ checkout: async () => null }, f.stripe, "team", "cus_test"),
    UnverifiedPurchase,
  );
});

test("reconciliation refetches Stripe on revision conflict and resolves a lost commit response", async () => {
  const f = purchaseStripe();
  let revision = 0;
  let saved;
  let writes = 0;
  const store = {
    event: async () => saved,
    state: async () => ({ ...state(), revision: String(revision) }),
    checkout: async () => intent(),
    ensurePeriod: async () => {},
    recordEvent: async (value) => {
      assert.equal(value.expectedRevision, String(revision));
      if (++writes === 1) {
        revision++;
        throw Error("race");
      }
      saved = value;
      throw Error("response lost after commit");
    },
  };
  const service = new Billing(store, f.stripe, config, () => now * 1000);
  await service.reconcile("team", "cus_test", "evt_test", "invoice.paid", now);
  assert.equal(f.requests.filter((r) => r.url.pathname === "/v1/invoices/in_test").length, 2);
  const count = f.requests.length;
  await service.reconcile("team", "cus_test", "evt_test", "invoice.paid", now);
  assert.equal(f.requests.length, count);
  assert.equal(saved.paidPeriodId, "stripe:in_test");
});

test("delayed observations cannot revive an ended subscription or shorten paid entitlement", () => {
  const previous = {
    ...state(),
    stripeSubscriptionId: "sub_test",
    subscriptionStatus: "canceled",
    planId: "light",
    paidPeriodId: "old",
    paidPeriod: { endsAt: "200" },
  };
  assert.equal(
    retainPaidPeriod(previous, { stripeSubscriptionId: "sub_test", subscriptionStatus: "active" })
      .subscriptionStatus,
    "canceled",
  );
  const active = { ...previous, subscriptionStatus: "active" };
  const observation = {
    stripeSubscriptionId: "sub_test",
    subscriptionStatus: "past_due",
    planId: null,
    paidPeriodId: "older",
    period: { endsAt: "100" },
  };
  assert.equal(retainPaidPeriod(active, observation).paidPeriodId, "old");
  assert.equal(observation.planId, "light");
});

test("callables use verified UID, authorize before Stripe and reject membership revoked during lookup", async () => {
  let calls = 0;
  const f = stripeFixture(() => {
    throw Error("must not reach Stripe");
  });
  const blocked = new Billing(
    {
      context: async (team, user) => {
        assert.equal(user, "actor");
        throw denied;
      },
    },
    f.stripe,
    config,
  );
  await assert.rejects(
    blocked.execute("actor", {
      action: "checkout",
      teamId: "team",
      userId: "victim",
      planId: "light",
    }),
    denied,
  );
  const store = {
    context: async () => {
      if (++calls > 1) throw denied;
      return {};
    },
    ensurePeriod: async () => {},
    available: async () => 1n,
  };
  const service = new Billing(store, f.stripe, { ...config, complimentary: new Set(["team"]) });
  await assert.rejects(service.execute("actor", { action: "status", teamId: "team" }), denied);
});

test("complimentary monthly entitlement consumes the same FSC usage as executor", async () => {
  let remaining = 0n;
  let period;
  const store = {
    context: async () => ({}),
    ensurePeriod: async (p) => {
      period = p;
    },
    available: async () => remaining,
  };
  const service = new Billing(
    store,
    null,
    { ...config, complimentary: new Set(["team"]) },
    () => now * 1000,
  );
  assert.equal(
    (await service.execute("actor", { action: "status", teamId: "team" })).blockReason,
    "allowance_exhausted",
  );
  remaining = 1n;
  assert.equal(
    (await service.execute("actor", { action: "status", teamId: "team" })).canStartCi,
    true,
  );
  assert.equal(period.allowanceSeconds, "360000");
  assert.match(period.id, /^complimentary-pro:team:\d{4}-\d{2}$/);
});

test("a pending customer can register a card and cannot start a monthly plan", async () => {
  const store = {
    context: async () => ({
      customer: {
        teamId: "team",
        idempotencyKey: "pending-key",
        livemode: false,
        createdAt: String(now),
      },
    }),
  };
  const service = new Billing(store, null, config);
  const status = await service.execute("actor", { action: "status", teamId: "team" });
  assert.equal(status.canCheckout, false);
  assert.equal(status.canStartCi, false);
  assert.equal(status.cardSetupStatus, "unregistered");
  assert.equal(status.blockReason, "payment_required");
});

test("team deletion recovers an ambiguous transaction from its actor-scoped receipt", async () => {
  let deleted = false;
  const store = {
    deleted: async (_team, actor) => deleted && actor === "actor",
    context: async () => ({}),
    deleteTeam: async () => {
      deleted = true;
      throw Error("lost response");
    },
  };
  const service = new Billing(store, null, config);
  assert.deepEqual(await service.execute("actor", { action: "deleteTeam", teamId: "team" }), {
    success: true,
  });
  store.context = () => {
    throw Error("already gone");
  };
  assert.deepEqual(await service.execute("actor", { action: "deleteTeam", teamId: "team" }), {
    success: true,
  });
  await assert.rejects(
    service.execute("other", { action: "deleteTeam", teamId: "team" }),
    /already gone/,
  );
});

test("webhook verifies raw signatures, mode, connected account and processing before acknowledgment", async () => {
  const f = stripeFixture(() => {
    throw Error("unexpected Stripe call");
  });
  const secret = "whsec_test";
  const processed = [];
  const billing = {
    config,
    stripe: f.stripe,
    store: { customer: async () => ({ teamId: "team" }) },
    reconcile: async (...args) => processed.push(args),
  };
  const make = (overrides = {}) => {
    const event = {
      id: "evt_test",
      type: "invoice.paid",
      created: now,
      livemode: false,
      data: { object: { customer: "cus_test", amount_paid: 99999999 } },
      ...overrides,
    };
    const payload = JSON.stringify(event);
    return {
      method: "POST",
      rawBody: Buffer.from(payload),
      signature: f.client.webhooks.generateTestHeaderString({ payload, secret }),
    };
  };
  assert.equal(await receiveStripeWebhook(make(), billing, secret), 204);
  assert.deepEqual(processed[0], ["team", "cus_test", "evt_test", "invoice.paid", now]);
  for (const request of [
    { ...make(), signature: "wrong" },
    make({ livemode: true }),
    make({ account: "acct_elsewhere" }),
    make({ context: "acct_elsewhere" }),
    { ...make(), rawBody: Buffer.from("{}") },
  ])
    assert.equal(await receiveStripeWebhook(request, billing, secret), 400);
  assert.equal(processed.length, 1);
  assert.equal(await receiveStripeWebhook(make({ type: "unhandled.event" }), billing, secret), 204);
  billing.reconcile = async () => {
    throw Error("retry required");
  };
  await assert.rejects(receiveStripeWebhook(make(), billing, secret), /retry required/);
});

test("Stripe Checkout preserves hosted session URLs for both payment paths", () => {
  for (const path of ["/c/pay/", "/g/pay/"]) {
    const url = `https://checkout.stripe.com${path}cs_test?locale=ja#fid-example`;
    assert.equal(stripeRedirect(url), url);
  }
});

test("Stripe destinations exclude lookalike hosts, credentials and other paths", () => {
  assert.equal(
    stripeRedirect("https://billing.stripe.com/p/session?secret=test", true),
    "https://billing.stripe.com/p/session?secret=test",
  );
  for (const url of [
    "http://checkout.stripe.com/c/pay/x",
    "https://user@checkout.stripe.com/c/pay/x",
    "https://checkout.stripe.com.evil.test/c/pay/x",
    "https://checkout.stripe.com/other",
    "https://checkout.stripe.com/c/pay/",
    "https://checkout.stripe.com/g/pay/?locale=ja#fid-example",
    "https://checkout.stripe.com/g/pay//",
    "https://checkout.stripe.com/g/payment/x",
    "https://checkout.stripe.com/x/pay/x",
    "https://checkout.stripe.com.evil.test/g/pay/x",
    "https://checkout.stripe.com:8443/c/pay/x",
  ])
    assert.throws(() => stripeRedirect(url));
  assert.throws(() => stripeRedirect("https://billing.stripe.com/p/session?secret=%20", true));
  assert.throws(() => stripeRedirect("https://billing.stripe.com/g/pay/x", true));
});

test("Customer Portal must retain end-of-period cancellation without plan changes or public login", async () => {
  const settings = {
    id: config.portalId,
    active: true,
    livemode: false,
    login_page: { enabled: false },
    features: {
      invoice_history: { enabled: true },
      payment_method_update: { enabled: true },
      subscription_update: { enabled: false },
      subscription_cancel: { enabled: true, mode: "at_period_end", proration_behavior: "none" },
    },
  };
  const f = stripeFixture((r) =>
    r.method === "GET"
      ? settings
      : {
          id: "bps_test",
          customer: "cus_test",
          configuration: settings.id,
          return_url: r.body.get("return_url"),
          livemode: false,
          url: "https://billing.stripe.com/p/session/test",
        },
  );
  assert.equal(
    await f.stripe.portal("team", "cus_test"),
    "https://billing.stripe.com/p/session/test",
  );
  assert.equal(f.requests[1].body.get("configuration"), config.portalId);
  for (const change of [
    (s) => {
      s.login_page.enabled = true;
    },
    (s) => {
      s.features.subscription_update.enabled = true;
    },
    (s) => {
      s.features.subscription_cancel.mode = "immediately";
    },
    (s) => {
      s.features.subscription_cancel.proration_behavior = "create_prorations";
    },
    (s) => {
      s.livemode = true;
    },
    (s) => {
      s.active = false;
    },
  ]) {
    const invalid = structuredClone(settings);
    change(invalid);
    const other = stripeFixture(() => invalid);
    await assert.rejects(other.stripe.portal("team", "cus_test"), UnverifiedPurchase);
    assert.equal(other.requests.length, 1);
  }
});
