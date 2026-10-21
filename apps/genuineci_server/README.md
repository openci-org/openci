# GenuineCI server

## Stripe client

The server uses the official [Stripe Go SDK](https://github.com/stripe/stripe-go),
pinned to `v87.0.0`. Its default API version is `2026-09-30.endive`
(`stripe.APIVersion`). Configure future snapshot webhook endpoints with this
version and review compatibility when upgrading the SDK.

`billing.NewStripeClient()` creates a client only when `SERVER_ACCESS_MODE=cloud`
and `BILLING_ENABLED=true`. It requires a nonblank `STRIPE_SECRET_KEY`; disabled
billing and Self-hosted require no Stripe key and return no client.

Client construction makes no Stripe requests and does not verify the key against
Stripe. It is not yet wired into server startup or HTTP routes.

`getStripeCheckoutSession`, `getStripeSubscription`, and `getStripePrice` each
retrieve one object by ID using the SDK, with a ten-second deadline including
retries. Earlier caller deadlines and cancellation are preserved. Request
failures return a generic error, and SDK logging is disabled to keep raw upstream
errors and response bodies out of logs. Ownership/payment validation and HTTP
route integration follow separately.

## Checkout Price configuration and validation

`stripeCheckoutPriceID` selects a server-configured Price ID from the plan ID:

| Plan | Environment variable |
| --- | --- |
| `light` | `STRIPE_LIGHT_PRICE_ID` |
| `pro` | `STRIPE_PRO_PRICE_ID` |

When Cloud billing is enabled, the selected plan requires a nonblank value;
surrounding whitespace is trimmed and unknown plans are rejected. Disabled
billing and Self-hosted return an empty ID without requiring Price configuration.
This configuration lookup makes no Stripe requests.

`validateStripeCheckoutPrice` checks a retrieved Stripe Price against the
server-selected Light or Pro plan and expected test/live mode. New purchases
require an active, fixed USD monthly Price: Light costs 1,000 cents and Pro costs
10,000 cents. Metered/tiered billing, customer-chosen amounts, quantity
transformations, and trials are rejected.

`getStripeCheckoutPrice` connects configuration, bounded retrieval, and validation.
It accepts a plan ID and the expected test/live mode from its server caller, and
returns only a valid Price whose ID matches the configured ID. Disabled billing,
missing configuration, retrieval failures, and validation failures return no Price
and an error. It preserves the retrieval helper's sanitized errors and cancellation.

Checkout session creation with quantity one and HTTP route integration follow
separately. These helpers validate new-purchase pricing; they do not decide access
for an existing subscription or paid period.

## Customer creation

`createStripeCustomer` uses the SDK's [Customer creation API](https://docs.stripe.com/api/customers/create?lang=go)
with server-owned `team_id` metadata and a required caller-provided idempotency key.
It forwards the key unchanged and bounds the call to ten seconds, preserving
earlier deadlines and cancellation. Failures return no Customer and a sanitized
error; this helper does not generate a new key or perform application-level retries.

The caller must persist the creation intent and key before invoking this helper.
Stripe can [remove API v1 idempotency keys after 24 hours](https://docs.stripe.com/api/idempotent_requests?lang=go),
so older uncertain outcomes need reconciliation before another creation attempt.
Durable intent/Customer storage, team locking and authorization, recovery, and
HTTP integration follow separately; this helper alone does not ensure one Customer
per team. It is not yet called by the server.
