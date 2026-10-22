# Stripe billing rollout

## Implementation status — 2026-10-21

The stacked PRs implement Customer and Checkout recovery, purchase guards, Portal,
verified webhook reconciliation, DB-backed status, the authenticated Dart proxy,
and Web billing screens. All current team members have the same billing access.
Cloud team deletion checks current membership, subscriptions, and pending Checkout.

The Go execution ledger stores starts, observations, completion and worker loss.
Its internal aggregate splits execution time across paid periods and adds parallel
runs. The worker now supplies its host label when claiming a job. These components
are not yet connected into complete execution accounting or quota admission.

**Production activation is blocked.** The current `canStartCi` response checks
subscription/payment eligibility and the persisted execution ledger's remaining
allowance, including live lease time. Worker accounting and claim reservations are
not connected yet. Claiming a job does not yet enforce paid eligibility or reserve
allowance. Do not treat a successful
Checkout or the local test suite as evidence that the CI billing boundary is ready.

## Service configuration

The Web client calls `openci_server`; it never receives Stripe secrets or calls
the private Go endpoints. Both servers use the same PostgreSQL database. Stripe
delivers webhooks to the Go server independently of browser navigation.

| Service | Required when Cloud billing is enabled |
| --- | --- |
| Both servers | `SERVER_ACCESS_MODE=cloud`, `BILLING_ENABLED=true`, the same `BILLING_INTERNAL_TOKEN` with at least 32 characters and no whitespace |
| `genuineci_server` | `DATABASE_URL`, `STRIPE_SECRET_KEY`, explicit `STRIPE_LIVEMODE=true` or `false`, `STRIPE_LIGHT_PRICE_ID`, `STRIPE_PRO_PRICE_ID`, `STRIPE_PORTAL_CONFIGURATION_ID`, `STRIPE_WEBHOOK_SECRET`, `BILLING_DASHBOARD_ORIGIN` |
| `openci_server` | Its existing database/authentication settings, plus `GENUINECI_SERVER_URL` containing the private Go origin without a path/query/fragment |
| `build_job_worker` | Existing worker credentials; optional `WORKER_HOST` defaults to the process hostname. Use a stable, nonblank identifier for attribution across restarts. It is not an authentication credential. |

`DATABASE_URL` is required by Go even when billing is disabled. Self-hosted does
not require Stripe configuration or use the billing proxy. Keep the deferred trial
configuration unset. The current Go listener is `:8081`; `PORT` is not implemented.

`BILLING_DASHBOARD_ORIGIN` must be an HTTPS origin, with loopback HTTP allowed for
local development. Serve `/billing` through the Web application's normal fallback
route. Server-generated return URLs include `teamId` and `result`; neither a result
query parameter nor a browser redirect grants access.

Run the Dart migrations for `billing_accounts` and `billing_periods` before enabling
Go schema initialization. Go creates Customer/Checkout intents, Stripe state/event
tables, the execution ledger, and the preserved trial-claim table at startup. Trial
API/onboarding/UI remain inactive. Existing billing history must survive rollback.

Keep `/internal/` on the private service network or explicitly blocked at the public
reverse proxy. Route only `POST /stripe/webhook` publicly to Go over HTTPS, preserving
the raw body and `Stripe-Signature`. Configure a snapshot endpoint using the pinned
SDK API version `2026-09-30.endive` and the event list in [README.md](README.md#http-integration-and-webhooks).
Its signing secret must correspond to that endpoint and mode. See the
[Stripe webhook guide](https://docs.stripe.com/webhooks).

## Stripe configuration

Create distinct, fixed-price USD monthly licensed Prices: Light USD 10 and Pro USD
100, quantity one, without trials, metering, transformations or customer-selected
amounts. Keep test and live objects separate. The application stores immutable paid
allowances of 36,000 and 360,000 seconds per period. There is no per-minute charge
or plan-specific concurrency limit.

Use an explicit Portal configuration enabling invoice history, payment-method
updates, and cancellation at period end without proration. Disable subscription
updates and public Portal login. Plan changes to an existing subscription are not
part of this release. Before payment, Checkout can close a verified expired Session
and start a different selection; uncertain outcomes continue blocking a replacement.

## Remaining release gates

| Gate | Tracking | Required result |
| --- | --- | --- |
| Worker lifecycle and usage | [G-1382](https://linear.app/genuineci/issue/G-1382) | Server-validated start/heartbeat/finish events bound to the admitted attempt; queue/dependency waiting excluded; worker-loss recovery connected |
| Atomic CI admission | [G-1358](https://linear.app/genuineci/issue/G-1358) | Paid eligibility and remaining allowance checked with reservations in the claim transaction; ineligible queue heads skipped; Self-hosted bypass preserved |
| Allowance exhaustion policy | [G-1358](https://linear.app/genuineci/issue/G-1358) | Product decision on stopping or finishing running jobs when the budget is exhausted, followed by concurrency/renewal/recovery tests |
| Minimal exhausted state | [G-1417](https://linear.app/genuineci/issue/G-1417) | Existing ledger-based status must also account for the completed claim-reservation integration |
| Refund terms and contact | [G-1443](https://linear.app/genuineci/issue/G-1443) | Approve detailed eligibility, request deadline, cancellation/access timing and a real support contact |
| Deployed sandbox verification | [G-1360](https://linear.app/genuineci/issue/G-1360) | Record results using the actual Stripe test environment and staging worker |
| Production activation | [G-1361](https://linear.app/genuineci/issue/G-1361) | Separate rollout after review, integration, sandbox evidence and operational configuration |

Jobs claimed before subscription expiry may finish. Behavior at allowance exhaustion
is a separate, unanswered decision. No fixed team-concurrency cap substitutes for
accounting or reservations. Initial trials, detailed usage API/UI, Native billing
screens and periodic client polling remain deferred.

## Sandbox verification record

The following checks are still pending against real Stripe test objects and a
deployed staging worker. Local SDK HTTP fixtures and PostgreSQL tests do not replace
these checks. Record the commit, mode, sanitized Stripe object/event IDs, timestamps,
expected result and observed result in G-1360; never attach keys or signing secrets.

| Scenario | Expected result |
| --- | --- |
| First Light/Pro purchase and Web return | One Customer/Subscription, correct amount and paid period; access changes only after verified server reconciliation and the next status fetch |
| Two members purchase concurrently; request/response loss | One unresolved Checkout per team; retries/recovery preserve original parameters and prevent duplicate subscriptions |
| Plan reselection before payment | Old Session verified expired before replacement; a completed or uncertain purchase blocks a second purchase |
| Duplicate/delayed webhooks and temporary DB/Stripe failure | No duplicate periods or stale access resurrection; failed processing is retried; unrelated or unverifiable purchases grant no access |
| Renewal, failed payment and period-end cancellation | Only verified paid invoices extend access; old allowance stays historical; Portal cancellation ends access at the confirmed end |
| Page open, Stripe return, browser Back and manual reload | A status fetch occurs at the intended boundary; no timer polling; Native/Self-hosted show no billing entry |
| Non-member, removed member and team deletion | No cross-team action; active/pending purchases prevent deletion; completed deletion retains billing history |
| CI eligibility, parallel usage, renewal and worker loss | After the gates above are implemented, verify queued jobs, atomic reservations, actual measured time and the approved exhaustion behavior |
| Manual refund and access outcome | After G-1443 is approved, verify the separate refund and cancellation/access effects in test mode |

## Manual refund operations — pending policy approval

Seven-day money-back and manual processing are approved. The exact first-payment
eligibility, cutoff, handling of renewals/re-subscriptions, cancellation timing and
support address are not yet approved; do not publish the proposed details as terms.

Once approved, an operator must match the request to the current team, Customer,
Subscription and paid invoice, check eligibility and earlier refunds, and retain a
support/audit reference. Stripe supports [manual refunds](https://docs.stripe.com/refunds)
and [subscription cancellation](https://docs.stripe.com/billing/subscriptions/cancel).
Review the intended amount and cancellation settings before executing either action.

The application does not infer access revocation from `charge.refunded`. Its current
access reconciliation follows subscription/invoice state. A refund by itself is not
evidence that cancellation or application access has changed. Verify the approved
subscription action, webhook processing and DB-backed status separately; retain
records instead of deleting or manually rewriting billing history. No refund or
production configuration change is performed by this document.
