import type Stripe from "stripe";
import { returnUrl } from "./config.js";
import { BillingError, id, pending, type BillingContext } from "./model.js";
import type { BillingStore } from "./store.js";
import { stripeRedirect, type StripeBilling } from "./stripe.js";

export const cardTermsVersion = "ci-jpy1-tax-included-monthly-v1";
type CardSetup = NonNullable<BillingContext["cardSetup"]>;

function verify(condition: unknown): asserts condition {
  if (!condition) throw new BillingError("unavailable", "billing_unavailable");
}

function verifySession(
  session: Stripe.Checkout.Session,
  teamId: string,
  customerId: string,
  livemode: boolean,
  termsVersion: string,
) {
  verify(
    session.id &&
      session.mode === "setup" &&
      session.livemode === livemode &&
      id(session.customer) === customerId &&
      session.client_reference_id === teamId &&
      session.metadata?.team_id === teamId &&
      session.metadata?.card_terms === termsVersion,
  );
}

// Only a stored, still-pending session can change a default. In particular,
// replaying a completed setup must never undo a later Customer Portal change.
export async function reconcileCardSession(
  store: BillingStore,
  stripe: StripeBilling,
  setup: CardSetup,
) {
  verify(setup.livemode === stripe.config.livemode);
  if (setup.status !== "pending") return null;
  const session = await stripe.client.checkout.sessions.retrieve(setup.sessionId, {
    expand: ["setup_intent.payment_method"],
  });
  verify(session.id === setup.sessionId);
  verifySession(session, setup.teamId, setup.stripeCustomerId, setup.livemode, setup.termsVersion);
  if (session.status === "open") return session;
  let paymentMethodId: string | null = null;
  if (session.status === "complete") {
    const intent = session.setup_intent;
    verify(
      intent &&
        typeof intent !== "string" &&
        intent.id &&
        intent.status === "succeeded" &&
        intent.usage === "off_session" &&
        intent.livemode === setup.livemode &&
        id(intent.customer) === setup.stripeCustomerId,
    );
    const method = intent.payment_method;
    verify(
      method &&
        typeof method !== "string" &&
        method.id &&
        method.type === "card" &&
        method.livemode === setup.livemode,
    );
    paymentMethodId = method.id;
    const customer = await stripe.ownedCustomer(setup.teamId, setup.stripeCustomerId);
    // Stripe commits the session marker and default together. If FSC is down
    // after that write, a retry can finish even after Stripe's idempotency
    // window, without reattaching a card since replaced or removed in Portal.
    if (customer.metadata.postpaid_card_session !== session.id) {
      verify(id(method.customer) === setup.stripeCustomerId);
      const updated = await stripe.client.customers.update(
        customer.id,
        {
          invoice_settings: { default_payment_method: method.id },
          metadata: { postpaid_card_session: session.id },
        },
        { idempotencyKey: `card-default:${session.id}` },
      );
      verify(
        updated.id === customer.id &&
          updated.livemode === setup.livemode &&
          updated.metadata.postpaid_card_session === session.id &&
          id(updated.invoice_settings.default_payment_method) === method.id,
      );
    }
  } else verify(session.status === "expired");
  const changed = await store.resolveCardSetup({
    teamId: setup.teamId,
    stripeCustomerId: setup.stripeCustomerId,
    livemode: setup.livemode,
    sessionId: session.id,
    paymentMethodId,
  });
  if (!changed) {
    const saved = await store.cardSetup(setup.teamId);
    verify(
      saved &&
        (saved.sessionId !== session.id ||
          (saved.status === (paymentMethodId ? "registered" : "expired") &&
            (saved.paymentMethodId ?? null) === paymentMethodId)),
    );
  }
  return null;
}

export async function startCardSetup(
  store: BillingStore,
  stripe: StripeBilling,
  teamId: string,
  userId: string,
  customerId: string,
) {
  await stripe.ownedCustomer(teamId, customerId);
  for (let retry = 0; retry < 4; retry++) {
    const { cardSetup: setup, customer } = await store.context(teamId, userId);
    verify(
      customer?.stripeCustomerId === customerId && customer.livemode === stripe.config.livemode,
    );
    if (setup) {
      verify(setup.stripeCustomerId === customerId && setup.livemode === stripe.config.livemode);
      if (setup.status === "registered") return { registered: true };
      if (setup.status === "pending") {
        const open = await reconcileCardSession(store, stripe, setup);
        if (!open) continue;
        await store.context(teamId, userId);
        return { url: stripeRedirect(open.url) };
      }
      verify(setup.status === "expired");
    }
    const session = await stripe.client.checkout.sessions.create(
      {
        mode: "setup",
        ui_mode: "hosted_page",
        currency: "jpy",
        allowed_payment_method_types: ["card"],
        customer: customerId,
        client_reference_id: teamId,
        success_url: returnUrl(stripe.config, teamId, "card_success"),
        cancel_url: returnUrl(stripe.config, teamId, "card_cancel"),
        metadata: { team_id: teamId, card_terms: cardTermsVersion },
      },
      { idempotencyKey: `card-setup:${setup?.sessionId ?? customerId}` },
    );
    verifySession(session, teamId, customerId, stripe.config.livemode, cardTermsVersion);
    try {
      await store.recordCardConsent({
        teamId,
        userId,
        stripeCustomerId: customerId,
        livemode: stripe.config.livemode,
        previousSessionId: setup?.sessionId ?? null,
        sessionId: session.id,
        termsVersion: cardTermsVersion,
      });
    } catch {
      // Recover an ambiguous write or concurrent registration from the team row.
    }
  }
  throw pending();
}

export async function cardSetupStatus(
  store: BillingStore,
  stripe: StripeBilling,
  initial: BillingContext["cardSetup"],
) {
  let setup = initial;
  if (setup?.status === "pending") {
    if (await reconcileCardSession(store, stripe, setup)) return "pending";
    setup = await store.cardSetup(setup.teamId);
  }
  if (!setup || setup.status === "expired") return "unregistered";
  if (setup.status === "pending") return "pending";
  verify(setup.status === "registered" && setup.livemode === stripe.config.livemode);
  const customer = await stripe.ownedCustomer(setup.teamId, setup.stripeCustomerId);
  const methodId = id(customer.invoice_settings.default_payment_method);
  if (!methodId) return "needs_card";
  if (methodId === setup.paymentMethodId) return "registered";
  const method = await stripe.client.paymentMethods.retrieve(methodId);
  return method.type === "card" &&
    method.livemode === setup.livemode &&
    id(method.customer) === customer.id
    ? "registered"
    : "needs_card";
}
