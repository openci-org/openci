# Stripe billing rollout

The legacy polling planner and build worker have been removed from this checkout.
Their Go worker APIs remain for compatibility, but the current FSC execution
path uses the [Cloud Run executor](../../firebase/functions/BUILD_EXECUTOR.md)
for admission and metering. The rollout notes below describe the legacy
Dart-to-Go billing integration; Stripe webhook, Checkout and Portal still use
this Go server.

## Implementation status — 2026-10-21

The stacked PRs implement Customer and Checkout recovery, purchase guards, Portal,
verified webhook reconciliation, DB-backed status, the authenticated Dart proxy,
and Web billing screens. All current team members have the same billing access.
Cloud team deletion checks current membership, subscriptions, and pending Checkout.

Cloud worker claims now check paid eligibility and reserve remaining allowance
atomically. Run creation, metering and completion use the admitted attempt's
identity. The Go execution ledger splits measured time across paid periods and
adds parallel runs; DB-backed status includes live leases and pending reservations.
Self-hosted and disabled-billing workers keep the existing claim path.

The implementation is published as stacked PRs and has local PostgreSQL and
Dart-to-Go HTTP coverage. **Production activation remains blocked** on review and
integration, real Stripe/staging verification, and refund-contact configuration.
Local test fixtures do not establish that deployed Stripe billing is ready.

## Service configuration

The Web client calls `openci_server`; it never receives Stripe secrets or calls
the private Go endpoints. Both servers use the same PostgreSQL database. Stripe
delivers webhooks to the Go server independently of browser navigation.

| Service | Required when Cloud billing is enabled |
| --- | --- |
| Both servers | `SERVER_ACCESS_MODE=cloud`, `BILLING_ENABLED=true`, the same `BILLING_INTERNAL_TOKEN` with at least 32 characters and no whitespace |
| `genuineci_server` | `DATABASE_URL`, `STRIPE_SECRET_KEY`, explicit `STRIPE_LIVEMODE=true` or `false`, `STRIPE_LIGHT_PRICE_ID`, `STRIPE_PRO_PRICE_ID`, `STRIPE_PORTAL_CONFIGURATION_ID`, `STRIPE_WEBHOOK_SECRET`, `BILLING_DASHBOARD_ORIGIN` |
| `openci_server` | Its existing database/authentication settings, plus `GENUINECI_SERVER_URL` containing the private Go origin without a path/query/fragment |

`DATABASE_URL` is required by Go even when billing is disabled. Self-hosted does
not require Stripe configuration or use the billing proxy. Keep the deferred trial
configuration unset. The current Go listener is `:8081`; `PORT` is not implemented.

Optional Go-only `BILLING_COMPLIMENTARY_PRO_TEAM_IDS` grants ongoing complimentary
Pro to exact operator-selected team IDs. Each UTC calendar month grants 6,000
minutes with ordinary usage enforcement; the default is no grants. Before enabling
billing, verify the intended team's membership, Pro status and denied Checkout,
and verify an unlisted unpaid team cannot start CI. See [README.md](README.md#complimentary-pro)
for renewal, removal and history behavior. Preserve this setting in deployment
backups; do not replace real Stripe state with synthetic subscriptions.

`BILLING_DASHBOARD_ORIGIN` must be an HTTPS origin, with loopback HTTP allowed for
local development. Serve `/billing` through the Web application's normal fallback
route. Server-generated return URLs include `teamId` and `result`; neither a result
query parameter nor a browser redirect grants access.

Run the Dart migrations for `billing_accounts` and `billing_periods` before enabling
Go schema initialization. Go creates Customer/Checkout intents, Stripe state/event
tables, the execution ledger, admissions, and the preserved trial-claim table at
startup. Trial API/onboarding/UI remain inactive. Existing billing history must
survive rollback.

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
| Review and integration | [G-1354](https://linear.app/genuineci/issue/G-1354) | Review the stacked PRs in dependency order and require passing checks on the integrated branch |
| Refund contact and verification | [G-1443](https://linear.app/genuineci/issue/G-1443) | Select a real support contact and validate the approved refund/cancellation procedure |
| Deployed sandbox verification | [G-1360](https://linear.app/genuineci/issue/G-1360) | Record results using the actual Stripe test environment and staging worker |
| Production activation | [G-1361](https://linear.app/genuineci/issue/G-1361) | Separate rollout after review, integration, sandbox evidence and operational configuration |

Jobs already admitted may finish after subscription expiry, allowance exhaustion,
or refund cancellation. Continue measuring those runs through completion; no overage
charge is introduced. Block new starts when the paid allowance is unavailable.
No fixed team-concurrency cap substitutes for accounting or reservations. Initial
trials, detailed usage API/UI, Native billing screens and periodic client polling
remain deferred.

## Worker lifecycle and recovery

The authenticated Dart worker routes proxy Cloud billing operations to Go over the
private service connection. Workers send an admission ID, job ID, run ID and host;
they cannot choose accounting timestamps. The server rechecks the current attempt
before accepting lifecycle events or completing a job/check run.

1. Claiming reserves up to 60 seconds of available allowance, with a two-minute
   deadline to start. Ineligible teams stay queued without blocking eligible teams.
   Claims for the same team serialize the allowance decision; host capacity still
   applies without a plan/team concurrency cap.
2. Run creation binds the admission to a new run ID. The worker must receive a
   successful metering-start acknowledgement before preparing its VM. Metering
   includes VM preparation, checkout and workflow execution, and ends before
   completion reporting and VM cleanup. Queue/dependency waiting is excluded.
3. The worker reports every 15 seconds. Server observations renew a 60-second lease.
   Finishing records one terminal interval; retries do not double-count it. Paid
   expiry, cancellation or allowance exhaustion does not interrupt admitted runs.
4. A worker claim poll also runs bounded recovery. An expired admission with no
   execution can release its reservation and requeue the still-current job. A new
   claim gets a new ID; late messages from the old attempt are rejected.
5. An expired execution lease is finalized at the last server observation and
   marked incomplete/abandoned. Recovery closes its admission but leaves the job
   in progress; it does not start another VM for work that might still be running.
   Confirm the actual VM outcome before operational cancellation or rerun. Existing
   runs are never stopped merely because a heartbeat or billing request failed.

Recovery is triggered by claim polls, not a separate background scheduler. Without
polling, persisted recovery waits until a later poll or lifecycle observation;
usage reads already bound expired leases instead of accumulating time indefinitely.
Retain incomplete records for investigation rather than inventing a finish time.

## Local validation

The integrated stack passed Go formatting, `go vet`, and 769 PostgreSQL race-test
cases/subtests, plus worker lifecycle/API tests and the Dart Frog production build.
The Dart-to-Go bridge suite uses actual HTTP handlers, Drift migrations and an
isolated PostgreSQL schema. Its three scenarios cover paid claim/run/meter/finish,
exhaustion and cancellation while running, reclaimed-attempt rejection, worker
authentication and server-owned timestamps. It uses a GitHub fixture and no real
Stripe objects or worker VMs.

To rerun the bridge, set `OPENCI_TEST_DATABASE_URL` to a disposable local PostgreSQL
database with schema-creation permissions, put Go and Dart on `PATH`, then run:

```sh
cd apps/openci_server
dart test integration_test/billing_worker_bridge_test.dart
```

The test builds `apps/genuineci_server/integration_test/worker_bridge`, which only
runs against its isolated test schema. It does not enable billing on a deployed
server. Full Go database tests use the same environment variable with
`go test -race ./...` from `apps/genuineci_server`.

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
| CI eligibility, parallel usage, renewal and worker loss | Verify queued jobs, atomic reservations, actual measured time, attempt recovery and the approved exhaustion behavior with deployed workers |
| Manual refund and access outcome | Verify a full refund for an eligible first payment, immediate cancellation, denial of new CI starts, and completion of existing runs in test mode |

## Approved manual refund operations

An application received within 168 hours of the first successful subscription
payment is eligible for a full refund. Renewals and re-subscriptions are excluded.
Use UTC payment and request timestamps to measure the elapsed window. Do not deduct
CI usage from the refund. Cancel the subscription immediately when processing the
refund; block new CI starts while allowing already-running CI to complete.

Refund requests go to [m.aoki@openci.org](mailto:m.aoki@openci.org), with the team
name included. The Web billing page contains this email link and the approved
terms; no custom refund API, request form or administration screen is required.

1. Verify the requesting current member and match the team to its retained Stripe
   Customer, Subscription, first successful payment and invoice. Record the request
   timestamp and support case. A new subscription must not reset first-payment history.
2. Compare elapsed time with 168 hours. Reject renewals/re-subscriptions and requests
   outside the window under the approved policy; retain the decision in the support case.
3. Check existing and pending refunds before acting. For an eligible payment, process
   one full [manual refund](https://docs.stripe.com/refunds) and
   [immediate subscription cancellation](https://docs.stripe.com/billing/subscriptions/cancel).
   Do not combine a full refund with a second refund or an additional prorated credit.
4. Record Stripe identifiers and actual outcomes. A pending/failed refund is not a
   completed refund. Re-read its state before retrying; do not create a duplicate.
5. Verify subscription webhook processing and denied new-start status. Existing runs
   continue and logs/settings remain accessible. Confirm the outcome in the support case.

The application does not infer access revocation from `charge.refunded`. Its current
access reconciliation follows subscription/invoice state. A refund by itself is not
evidence that cancellation or application access has changed. Verify the approved
subscription action, webhook processing and DB-backed status separately; retain
records instead of deleting or manually rewriting billing history. No refund or
production configuration change is performed by this document.
