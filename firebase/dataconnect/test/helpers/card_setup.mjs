import assert from "node:assert/strict";
import { randomUUID } from "node:crypto";
import { BillingStore } from "../../../lib/functions/billing/store.js";
import { Billing } from "../../../lib/functions/billing/service.js";
import { cardTermsVersion } from "../../../lib/functions/billing/card_setup.js";
import { receiveStripeWebhook } from "../../../lib/functions/billing/webhook.js";
import { config, now, stripeFixture } from "../../../functions/test/helpers/billing.mjs";

export function cardFixture(dc, f) {
  const customerId = `cus_${f.teamId}`;
  const sessions = new Map();
  const keys = new Map();
  const state = { defaultMethod: null, appliedSession: null, writes: 0 };
  const customer = () => ({
    id: customerId,
    livemode: false,
    metadata: { team_id: f.teamId, postpaid_card_session: state.appliedSession },
    invoice_settings: { default_payment_method: state.defaultMethod },
  });
  const api = stripeFixture(({ url, method, body, headers }) => {
    if (url.pathname === "/v1/customers" && method === "POST") return customer();
    if (url.pathname === `/v1/customers/${customerId}`) {
      if (method === "POST") {
        state.writes++;
        state.defaultMethod = body.get("invoice_settings[default_payment_method]");
        state.appliedSession = body.get("metadata[postpaid_card_session]");
      }
      return customer();
    }
    if (url.pathname === "/v1/subscriptions") return { data: [], has_more: false };
    if (url.pathname === "/v1/checkout/sessions" && method === "POST") {
      assert.equal(body.get("mode"), "setup");
      assert.equal(body.get("currency"), "jpy");
      assert.equal(body.get("allowed_payment_method_types[0]"), "card");
      assert.equal(body.get("customer"), customerId);
      assert.equal(body.get("client_reference_id"), f.teamId);
      assert.equal(body.get("metadata[card_terms]"), cardTermsVersion);
      assert.equal(body.get("metadata[team_id]"), f.teamId);
      assert.equal(body.has("line_items[0][price]"), false);
      const key = headers.get("idempotency-key");
      assert.ok(key);
      if (!keys.has(key)) {
        const id = `cs_test_${randomUUID()}`;
        keys.set(key, id);
        sessions.set(id, {
          id,
          status: "open",
          mode: "setup",
          customer: customerId,
          livemode: false,
          metadata: { team_id: f.teamId, card_terms: cardTermsVersion },
          client_reference_id: f.teamId,
          url: `https://checkout.stripe.com/c/pay/${id}`,
        });
      }
      return sessions.get(keys.get(key));
    }
    if (url.pathname.endsWith("/expire") && method === "POST") {
      const session = sessions.get(url.pathname.split("/").at(-2));
      session.status = "expired";
      return session;
    }
    if (url.pathname.startsWith("/v1/checkout/sessions/"))
      return sessions.get(url.pathname.split("/").at(-1));
    if (url.pathname.startsWith("/v1/payment_methods/"))
      return {
        id: state.defaultMethod,
        livemode: false,
        customer: customerId,
        type: "card",
      };
  });
  const service = new Billing(new BillingStore(dc), api.stripe, config);
  const input = { action: "setupCard", teamId: f.teamId, termsVersion: cardTermsVersion };
  const start = () => service.execute(f.userId, input);
  const status = () => service.execute(f.userId, { action: "status", teamId: f.teamId });
  function complete(s) {
    s.status = "complete";
    s.setup_intent = {
      id: "seti_test",
      status: "succeeded",
      usage: "off_session",
      customer: customerId,
      livemode: false,
      payment_method: { id: "pm_card_visa", type: "card", customer: customerId, livemode: false },
    };
  }
  function webhook(s, type = "checkout.session.completed", eventId = "evt_card") {
    const secret = "whsec_test";
    const payload = JSON.stringify({
      id: eventId,
      type,
      created: now,
      livemode: false,
      data: {
        object:
          type === "customer.updated"
            ? customer()
            : { id: s.id, mode: "setup", customer: customerId },
      },
    });
    return receiveStripeWebhook(
      {
        method: "POST",
        rawBody: Buffer.from(payload),
        signature: api.client.webhooks.generateTestHeaderString({ payload, secret }),
      },
      service,
      secret,
    );
  }
  return { api, service, input, customerId, start, status, sessions, state, complete, webhook };
}
