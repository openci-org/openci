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
The SDK helper is not yet called by the server. Connecting it to the stored intent,
recovering uncertain results, authorization, and HTTP integration follow separately.

## Customer creation storage

When Cloud billing is enabled, startup prepares `billing_customer_creations` in Go.
The existing `billing_accounts` table must be present. A shared schema lock makes
repeated and concurrent initialization safe without replacing existing rows.

Each team can have one creation record: a unique `idempotency_key`, expected
`livemode`, `created_at` in Unix seconds, and a nullable, unique `stripe_customer_id`.
The timestamp records when the durable intent began, not Stripe's Customer creation
time. A missing Customer ID means the result has not been recorded; it does not
prove that Stripe has not created a Customer. The foreign key retains this record
with its billing account identity.

`ensureCustomerCreation` saves a new intent under the billing account lock, with a
server-generated key and current timestamp. Repeated and concurrent calls reuse
the stored key, original timestamp, and any recorded Customer ID. It requires a
current team and an initialized billing account, rejects a test/live mode mismatch,
and returns a record only after the transaction commits successfully.

This internal storage helper makes no Stripe calls and is not yet wired into the
server. Its caller must enforce Cloud billing and membership authorization, and
decide whether an existing intent needs reconciliation before a Stripe retry.
Recording the verified result and connecting the creation/recovery flow follow
separately. Disabled billing and Self-hosted do not create this table at startup.
