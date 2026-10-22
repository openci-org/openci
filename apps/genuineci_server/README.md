# GenuineCI server

See [ROLLOUT.md](ROLLOUT.md) for service configuration, release gates, and the
Stripe verification plan. Local Stripe Sandbox and real-worker verification results
are recorded in [G-1360](https://linear.app/genuineci/issue/G-1360). The next deployment
target is production; a separate staging environment is not required. Follow
[G-1361](https://linear.app/genuineci/issue/G-1361) for live configuration, the existing-team
transition and the published refund contact before enabling billing.

## Go package layout

```text
cmd/server/                 Server entry point and startup tests
internal/
  billing/                  Billing workflows, authorization, storage, and HTTP handlers
    config/                 Environment validation and server-owned return URLs
    schema/                 PostgreSQL table and index initialization
    stripeapi/              Bounded Stripe SDK calls and sanitized upstream errors
  testutil/                 Shared database fixtures and fake Stripe transport
integration_test/
  worker_bridge/            Server used by the Dart worker bridge integration test
```

Tests live beside the code they exercise. Billing workflows own purchase
eligibility, payment verification, and transaction boundaries; `stripeapi` does
not import them. Schema initialization depends only on PostgreSQL. `testutil`
is imported only by tests.

Run these commands from `apps/genuineci_server`:

```sh
go run ./cmd/server
go build -o /tmp/genuineci-server ./cmd/server
go vet ./...
go test -race ./...
```

Startup requires `DATABASE_URL`. Set `OPENCI_TEST_DATABASE_URL` to a disposable
local PostgreSQL database to include database tests; otherwise they are skipped.
The Dockerfile builds the same `./cmd/server` entry point from the repository root.

## Billing service

Billing authorization treats every current team member equally. `withBillingMemberLock`
locks the current team and billing account, then checks membership before performing
an operation. Account initialization rolls back for rejected users. The UID must
come from verified authentication; a request body is not an identity source.

`config.Load` requires explicit `STRIPE_LIVEMODE`, distinct Light/Pro Price
IDs, `STRIPE_PORTAL_CONFIGURATION_ID`, `STRIPE_WEBHOOK_SECRET`, and a shared
`BILLING_INTERNAL_TOKEN` of at least 32 characters when billing is enabled.
`BILLING_DASHBOARD_ORIGIN` must be HTTPS (loopback HTTP is allowed locally).
Return URLs are generated on the server as `/billing?teamId=...&result=...`;
clients cannot supply a return origin. Disabled billing needs none of these settings.

## Complimentary Pro

Operators can set `BILLING_COMPLIMENTARY_PRO_TEAM_IDS` to a comma-separated list of
exact team IDs. Listed teams receive Pro without a charge, with 6,000 minutes per
UTC calendar month, renewed on the first day at 00:00 UTC. The grant continues
until the operator removes the team ID and restarts the service. The default is empty.

The first authorized status read or worker claim creates that month's immutable
`complimentary-pro:<team-id>:YYYY-MM` allowance. These use the existing `paid`
period type to share paid-plan accounting; they are operator grants, not payment
records. No Stripe Customer, Subscription, invoice or payment state is created.
The Web page shows Pro without a paid-through date or purchase/Portal actions;
direct Checkout requests are also blocked. Configure grants before purchases begin;
granting Pro does not cancel or refund an existing Stripe subscription.

Membership, worker capacity, metering and atomic allowance reservations remain
enforced. Exhaustion or removing a grant blocks new starts, while admitted/running
jobs finish and their history is retained. Unlisted teams still require a verified
Stripe subscription and paid period. Old grant periods alone never authorize CI.

## Cloud deployment with Compose

From the repository root, apply `docker-compose.billing.yml` after the base file:

```sh
BILLING_ENABLED=false docker compose -f docker-compose.yml -f docker-compose.billing.yml up -d --build --wait server genuineci-server
```

The overlay sets both servers to Cloud mode and shares their database and billing
token. Billing defaults to disabled, so Stripe credentials are not required for
this initial deployment. The Dart server connects to `http://genuineci-server:8081`
and waits for the Go health check. Go is reachable from the host only at
`127.0.0.1:8081`; the base Compose configuration remains available for Self-hosted.

Keep using both Compose files for subsequent updates. Before setting
`BILLING_ENABLED=true`, complete the Dart database migrations, configure the billing
variables listed in [ROLLOUT.md](ROLLOUT.md#service-configuration), and route only
`POST /stripe/webhook` through the public HTTPS proxy. Keep `/internal/` private.
While billing is disabled, Go serves `/healthz`; billing and webhook routes are inactive.

## Stripe client

The server uses the official [Stripe Go SDK](https://github.com/stripe/stripe-go),
pinned to `v87.0.0`. Its default API version is `2026-09-30.endive`
(`stripe.APIVersion`). Configure snapshot webhook endpoints with this
version and review compatibility when upgrading the SDK.

`stripeapi.NewClient()` creates a client only when `SERVER_ACCESS_MODE=cloud`
and `BILLING_ENABLED=true`. It requires a nonblank `STRIPE_SECRET_KEY`; disabled
billing and Self-hosted require no Stripe key and return no client.

Client construction makes no Stripe requests and does not verify the key against
Stripe. Startup validates configuration, initializes the billing tables, and registers
the routes only when Cloud billing is enabled.

`stripeapi.GetCheckoutSession`, `stripeapi.GetSubscription`, and `stripeapi.GetPrice` each
retrieve one object by ID using the SDK, with a ten-second deadline including
retries. Earlier caller deadlines and cancellation are preserved. Request
failures return a generic error, and SDK logging is disabled to keep raw upstream
errors and response bodies out of logs. The billing workflows validate ownership
and payment before returning actions or committing access state.

## Checkout Price configuration and validation

`config.CheckoutPriceID` selects a server-configured Price ID from the plan ID:

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

These helpers validate new-purchase pricing; they do not decide access for an
existing subscription or paid period. Paid access uses the verified invoice period.

## Checkout Session creation

`stripeapi.CreateCheckoutSession` uses the SDK's [Checkout Session creation API](https://docs.stripe.com/api/checkout/sessions/create?lang=go)
with an existing Customer, one Price at quantity one, and server-owned return URLs.
It creates a hosted subscription checkout, restricts eligible payment methods to
cards, disables Adaptive Pricing, and adds no trial or promotion settings. Both
the Session and resulting Subscription carry `team_id` metadata; the Session also
uses the team ID as its client reference. It returns the Session, including its ID
and payment URL, with a ten-second deadline, sanitized failures, and preserved
cancellation and earlier deadlines.

The caller must validate Customer ownership, the configured Price, and allowed
return URLs, then persist all parameters and a Checkout-specific idempotency key
before calling this helper. Retries forward the same parameters and key unchanged;
a timeout does not prove that Stripe failed to create the Session. Membership
authorization is enforced by the Checkout workflow.

`ensureStripeCheckoutSession` connects committed intents to creation and result
storage. It sends only the original stored parameters, with the durable key also
in Session metadata, and returns a result only after recording it. A known Session
is retrieved instead of creating another one. Unrecorded outcomes may replay the
same key within 23 hours. Older unknown outcomes are recovered through a bounded,
paginated Customer-scoped Session lookup. Recovery requires exactly one match for
the creation key, matching identity/return URLs, and the original Price at quantity
one. Open, completed, and expired results are recorded without creating a replacement.
Missing, ambiguous, truncated, or mismatched results remain blocked; future-dated
intents also remain blocked. Lookup scans at most 1,000 Sessions within ten seconds.
This internal helper does not authorize a purchase, close intents, or grant access.

`expireCheckoutCreation` retrieves and validates a recorded Session before expiry.
It closes the durable intent only after Stripe confirms `expired` and unpaid.
Lost expiry responses trigger a fresh read; completed or uncertain purchases keep
the intent blocking a replacement. Repeated closure preserves its original time.
This is the prerequisite for pre-payment plan reselection, not subscription changes.

Purchase guards retrieve the stored Customer and verify its ID, team metadata,
mode, and availability. A Customer-scoped, paginated subscription lookup blocks
new purchases for every nonterminal or unknown status. Only canceled and
incomplete-expired contracts permit another purchase; failed reads fail closed.

## Customer Portal

`stripeapi.CreatePortalSession` uses an explicit server-owned Portal configuration.
Before issuing a Session it verifies active/test-live mode, invoice history,
payment-method updates, period-end cancellation without proration, disabled
subscription updates, and disabled public Portal login. The returned Customer,
configuration, mode, and return URL must match. Configuration reads and Session
creation share a ten-second deadline. Membership and Customer ownership are
the responsibility of the higher-level billing workflow.

## Checkout creation storage

When Cloud billing is enabled, startup prepares `billing_checkout_creations` in Go.
It requires `billing_accounts` and uses the shared billing schema lock. Table and
index creation run in one transaction; repeated initialization preserves records.

Each record stores a unique idempotency key, team and plan IDs, the exact Customer
and Price IDs, success/cancel URLs, test/live mode, and creation time. A nullable
Session ID records the verified Stripe result and cannot belong to two records.
Its absence means that the result is not recorded, not that no Session exists.

`closed_at` is null while an intent is unresolved or its Session remains open. A
partial unique index allows only one such record per team, across all plans and
modes. Historical closed records retain their keys and Session IDs. Timestamps are
Unix seconds. The Checkout workflow establishes that an intent is safe to close
before setting `closed_at`; closing an intent alone does not authorize another
purchase when an existing subscription is present. Billing account deletion is
blocked while these records exist.

`ensureCheckoutCreation` saves a new intent under the team and billing account
locks, with a server-generated key and creation time, and returns it only after
commit. It requires a current team, an initialized billing account, a supported
plan, and nonblank Customer/Price IDs and return URLs.

An unfinished intent for the same plan, Customer, and mode is reused, including
its original key, timestamp, exact parameters, and any recorded Session ID. Price
or return URL configuration changes do not rewrite it. A different plan, Customer,
or mode returns `errCheckoutCreationConflict` without changing the record. Closed
history is retained when a new intent is saved.

`recordStripeCheckoutSession` records the ID from a server-obtained Stripe Session
after matching its subscription/hosted mode, test/live mode, Customer, team
metadata, client reference, and return URLs against the intent. Under the team
and billing account locks, it requires the stored key, creation time, and every
original request parameter to remain unchanged. Missing, closed, changed, or
already differently linked intents are rejected. The same Session ID can be
saved again after reconnecting, but cannot belong to another intent, including
closed history. The write succeeds only after commit.

This result helper stores the Session identity; it does not establish paid access
or close the intent. It also accepts completed or expired Sessions without a
payment URL so an obtained result can still be recorded. The caller must supply
the response for this exact creation request. It is not a validator for arbitrary
recovered Sessions: [line items are not returned by default](https://docs.stripe.com/api/checkout/sessions/object?lang=go),
and this helper does not retrieve or validate their Price or quantity. Recovery
and payment validation must perform those checks separately.

This storage helper makes no Stripe calls and does not close intents. Its caller
must validate Customer ownership, Price eligibility, allowed return URLs, current
membership, and existing subscriptions before authorizing a purchase. An old
unfinished intent still requires reconciliation before retrying Stripe outside
the safe idempotency window. The Checkout workflow coordinates these checks.

## Customer creation

`stripeapi.CreateCustomer` uses the SDK's [Customer creation API](https://docs.stripe.com/api/customers/create?lang=go)
with server-owned `team_id` metadata and a required caller-provided idempotency key.
It forwards the key unchanged and bounds the call to ten seconds, preserving
earlier deadlines and cancellation. Failures return no Customer and a sanitized
error; this helper does not generate a new key or perform application-level retries.

The caller must persist the creation intent and key before invoking this helper.
Stripe can [remove API v1 idempotency keys after 24 hours](https://docs.stripe.com/api/idempotent_requests?lang=go),
so older uncertain outcomes need reconciliation before another creation attempt.
The SDK helper is used by the authorized Checkout flow through the internal
creation flow below.

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

This internal storage helper makes no Stripe calls. The creation flow below uses
it before calling Stripe. HTTP callers must enforce membership authorization.
Disabled billing and Self-hosted do not create this table at startup.

`recordStripeCustomer` accepts a Customer obtained by the server through the Stripe
SDK, checks its ID, deletion flag, team metadata, and test/live mode, then saves its
ID under the billing account lock. It requires a current team and a stored intent
with the same key and mode. Repeating the same result is safe; a different Customer
cannot replace an existing link or be shared with another team's intent. The
original key, mode, and intent timestamp are preserved, and success is returned
only after commit.

This helper must not receive a Customer object supplied by an HTTP client.

## Customer creation flow

`ensureStripeCustomer` requires enabled Cloud billing and a configured SDK client.
It commits the team's creation intent first, calls Stripe with the saved key
outside the database transaction, and returns the Customer ID only after the
verified result is committed. An existing recorded ID is returned without a
Stripe request. A lost response or failed result save leaves the original intent
available for a later call to retry with the same key.

Pending intents can be retried for 23 hours from their original timestamp, leaving
a margin before Stripe's 24-hour minimum key retention. The request deadline also
ends at this boundary. Once the window expires, the flow searches Stripe for an
existing Customer and commits a verified match before returning its ID. It retains
the original key and intent timestamp throughout recovery. Failed searches or
result commits leave the intent available for another recovery attempt.

Empty or ambiguous searches remain unresolved and never trigger a new creation
or key. Future-dated pending intents return
`errStripeCustomerReconciliationRequired` without contacting Stripe.

The Checkout route calls this flow after verifying current team membership.
The team and expected mode come from trusted server state. Recovery runs on the
next Checkout request. Ambiguous or absent recovery results remain blocked for
operator investigation; operators must not clear an intent merely because a
request timed out.

## Customer recovery lookup

`findStripeCustomer` uses the SDK's [Customer search API](https://docs.stripe.com/api/customers/search?lang=go)
to find a candidate by server-owned `team_id` metadata, with a ten-second deadline
and sanitized failures. It checks only the first page, requesting at most two
results to detect ambiguity. It returns a Customer only when the page contains
exactly one result, has no further pages, and its ID, deletion flag, exact team ID,
and expected test/live mode are valid.

Stripe search is eventually consistent. Empty, multiple, incomplete, or mismatched
results return `errStripeCustomerReconciliationRequired`; an empty search is not
proof that no Customer exists. This helper only reads Stripe; the creation flow
handles result persistence after this lookup succeeds.

## HTTP integration and webhooks

The authenticated `openci_server` billing proxy must supply a
verified Firebase UID in `X-GenuineCI-User-ID` and the shared
`Authorization: Bearer <BILLING_INTERNAL_TOKEN>` to these private Go routes:

| Method | Path | Request |
| --- | --- | --- |
| GET | `/internal/billing/teams/{teamID}` | No body |
| DELETE | `/internal/billing/teams/{teamID}` | Empty body or `{}` |
| POST | `/internal/billing/teams/{teamID}/checkout` | `{"planId":"light"}` or `{"planId":"pro"}` |
| POST | `/internal/billing/teams/{teamID}/portal` | Empty body or `{}` |

Keep `/internal/` behind the service network or reverse-proxy access rules; never
expose the shared token to a browser. Go rechecks current team membership for all
routes. Responses are not cached and never expose raw Stripe errors. Team deletion
blocks active subscriptions and unresolved Checkout, then retains billing history.

Expose `POST /stripe/webhook` to Stripe using HTTPS and the snapshot API version
above. The official SDK verifies the unmodified body and signature with a
five-minute tolerance. Subscribe to `checkout.session.completed`,
`checkout.session.expired`, `customer.subscription.created`,
`customer.subscription.updated`, `customer.subscription.deleted`,
`customer.subscription.paused`, `customer.subscription.resumed`, `invoice.paid`,
`invoice.payment_failed`, `invoice.payment_action_required`,
`invoice.marked_uncollectible`, `invoice.voided`, and `customer.deleted`.
See [Stripe webhook setup](https://docs.stripe.com/webhooks).

A webhook refreshes current Stripe state under the team billing lock. The verified
paid period, subscription state, and processed event ID commit together. Retries
do not reset periods, failed renewals do not extend them, and provider/commit
failures return 500 for Stripe to retry. Unverifiable purchases deny access.
Status reads only the DB and bounds access by the paid interval; it never calls
Stripe. A browser return does not grant access. Clients refresh on page open,
Stripe return, or an explicit reload, without polling.

Existing `billing_accounts` and `billing_periods` migrations in `openci_server`
must run first. Go owns Customer/Checkout intents, Stripe state, and event tables.
Initial trial routes remain disabled. Authenticated worker claim, start and report
routes enforce allowance admission and record execution time independently of
Stripe calls. See [the worker lifecycle](ROLLOUT.md#worker-lifecycle-and-recovery)
for reservations, lease expiry and recovery. Do not enable production billing
before the remaining rollout gates are complete.
