# Billing on Functions and FSC

Dedicated self-hosted environments set `OPENCI_SELF_HOSTED=true` and
`BILLING_ENABLED=false` on Node Functions and the executor Job, and compile the
Dashboard with `--dart-define=OPENCI_SELF_HOSTED=true`. This hides billing UI,
rejects purchases, removes Stripe secret bindings and bypasses subscription/time
allowances. It preserves team authorization, GitHub verification and execution
leases, deadlines and cleanup. `StartSelfHostedBuildExecution` atomically binds
the queued job to its claimed dispatch and creates the run without a billing
admission; normal run numbering, logs and GitHub Checks still follow. Team deletion
still uses `teamBilling`; the cleanup scheduler must also remain deployed. Teams with existing Stripe records
are rejected rather than silently converted. `BILLING_ENABLED=false` alone only
pauses billing purchases and does not bypass the executor's quota checks.

Dashboard billing and team deletion use `teamBilling`, a Gen2 callable in
`asia-northeast1`. Stripe events enter `stripeWebhook`. Billing data and the
executor's usage ledger share the FSC `billing` connector. All billing operations
remain `NO_ACCESS`; only trusted backend identities execute them.

| Action       | Input beyond `action`            | Result                                                               |
| ------------ | -------------------------------- | -------------------------------------------------------------------- |
| `status`     | `teamId`                         | Card registration, CI eligibility and available actions              |
| `checkout`   | `teamId`, `planId: light \| pro` | Old clients receive `monthly_plans_closed`                           |
| `setupCard`  | `teamId`, `termsVersion`         | Card-only Stripe Checkout URL or `registered: true` after completion |
| `portal`     | `teamId`                         | Verified Stripe Customer Portal URL                                  |
| `deleteTeam` | `teamId`                         | `success: true` after deletion commits                               |

Firebase verifies the ID token. Anonymous users are rejected. Functions use the
verified UID to check FSC membership before Stripe access and again before
returning data. Customer/Checkout creation and team deletion recheck membership
inside their transactions, serialized on the team row. Every current member has
the same billing rights, preserving the existing policy. Dashboard binds the
callable to its active Firebase app and discards results after connection or
account changes. Existing cloud/web visibility rules are unchanged.

## Stripe and entitlement behavior

### Postpaid card registration

Cloud team members confirm **JPY 1 per CI minute including tax**, with monthly
automatic collection in arrears. The web dashboard sends `ci-jpy1-tax-included-monthly-v1`
only after consent. The server reuses the team's Stripe Customer and records the
member, server time, terms version and exact Checkout Session before returning
its URL. Concurrent requests share the session; after expiry a new request records
fresh consent. Checkout uses `mode=setup` and collects the card at zero initial charge.

The signed `checkout.session.completed` / `.expired` notifications and billing
status refresh reconcile the stored session. Completion verifies the Stripe mode,
customer, succeeded off-session SetupIntent and attached card before setting the
Customer's default invoice payment method. The pending session is resolved once.
A delayed delivery cannot restore a card replaced through the Portal. The status
response supplies `cardSetupStatus` for eligible Cloud teams; `needs_card` directs
members to the Portal when the default card is missing.

Team deletion expires an open zero-charge card setup after existing purchase
and subscription checks pass. Its terminal receipt fences late setup notifications.

### Starting Cloud CI

Before allocating a VM, the executor calls `ciCardEligibility` with its Google
identity token. Only the project's `openci-executor` service account can invoke
this Function. It checks the team's consent, Stripe mode, Customer and current
default invoice card using the same verification as the dashboard. The executor
receives the verified session ID. Its FSC transaction binds that session to the
team and postpaid period before creating the run.

A missing, pending or removed card leaves the job queued. The existing GitHub
check links to the team's billing page. The scheduler skips that job while other
teams can run. Checkout completion, a verified `customer.updated` notification,
or a billing-page refresh after a Portal card change makes the same job eligible
for the next queue retry. The executor checks the card again at admission.

Postpaid runs use a Japan calendar month period with no prepaid time allowance.
The execution, heartbeat and completion records feed the monthly usage statement.
The courtesy allowlist still uses a separate UTC month period and its existing
360,000-second allowance. Dedicated self-hosted deployments use their existing
execution path.

### Cutover from monthly plans

1. Deploy the additive card schema and the billing and dispatch connectors. Deploy
   `ciCardEligibility`, `teamBilling`, `stripeWebhook` and the updated dispatcher.
   Enable `customer.updated` on the Stripe webhook destination.
2. Register the production team's invoice card and verify it on the billing page.
   Roll out the executor image and dashboard together. Existing queued jobs will
   use the next eligible worker after registration.
3. At cutover, end the owner's old Light/Pro subscription in Stripe and expire any
   outstanding subscription Checkout links. Verify its next renewal was removed.
   Keep the historical invoices and execution records. When preparing the first
   postpaid invoice, include only runs from postpaid periods.

The callable rejects new Light/Pro purchases. Legacy subscription webhooks still
reconcile historical paid periods and invoice events for deletion and accounting.
Monthly invoice issuance is a later step.

Customer Portal configuration must enable invoice history and payment method
updates, disable subscription updates and public login, and allow cancellation
only at period end without proration. The billing return URL comes from server
configuration. Error responses and logs exclude raw Stripe/FSC exceptions,
tokens and payment URLs.

## Monthly postpaid statements

`GetTeamMonthlyUsage` is a read-only billing connector operation for one team.
It takes any date in the target Japan calendar month. Each run contributes the
overlap of that month with the interval from successful `prepare_vm` completion
to its last measured billing observation. Only a persisted success starts that
interval; failed preparation and older runs without that evidence contribute
zero. Step metadata survives log retention. Concurrent runs and retries count
individually. A run qualifies only when it belongs to a postpaid billing period.
The old monthly plans, courtesy teams and self-hosted runs contribute zero.

The statement sums milliseconds across the team and rounds up to minutes
once for the month. Each minute is **JPY 1 including tax**. For an optional USD
equivalent, pass the exchange rate in JPY per USD as a decimal string. The
query divides the monthly yen total by that rate and rounds once to the nearest
cent (half up). Both the rate and USD amount are null when no rate is supplied.
The current month includes usage already observed by the executor. After closing,
reads use the saved runs and the recorded exchange rate.

With the demo SQL Connect emulator running, from the repository root:

```sh
FIREBASE_DATA_CONNECT_EMULATOR_HOST=127.0.0.1:9399 firebase dataconnect:execute \
  firebase/dataconnect/billing/monthly_usage.gql GetTeamMonthlyUsage \
  --config firebase/dataconnect/firebase.json --project demo-openci \
  --vars '{"teamId":"example-team","month":"2026-11-01","jpyPerUsd":"150"}'
```

The rate in this example is illustrative. `runs` contains up to 100 rows in
run ID order. On a full page, pass its last `runId` as `afterRunId` to read
the next page. Totals always cover the entire team and month.

### Close the month for manual Stripe collection

Use a privileged operator identity. Pass the first day of a completed Japan
calendar month. The closing transaction freezes every run and the tax-inclusive
amount under the unique team/month key. An open execution that could still
change the month makes closure retryable after its next observation or cleanup.
Repeating the close with the same currency and rate returns the same statement.
A change of rate, rate date or currency is rejected.

From the repository root, the following command closes an example team in the
demo emulator. Supply real team identifiers in an operational environment.

```sh
FIREBASE_DATA_CONNECT_EMULATOR_HOST=127.0.0.1:9399 firebase dataconnect:execute \
  firebase/dataconnect/billing CloseTeamMonthlyStatement \
  --config firebase/dataconnect/firebase.json --project demo-openci \
  --vars '{"teamId":"example-team","month":"2026-10-01","currency":"JPY"}'
```

For USD, pass `"currency":"USD"`, a positive `jpyPerUsd` decimal string and
`rateDate` (YYYY-MM-DD). The operator supplies the adopted rate and its date.
The receipt records the yen total, rate and final amount in USD cents. A JPY
statement has no FX rate. A zero amount requires no card collection.

1. Read `GetClosedMonthlyStatement` with `teamId` and `month`. Use its saved
   `stripeInvoiceId` if present. Otherwise create a Stripe draft on the team's
   matching customer and currency and compare its tax-inclusive amount.
2. Run `LinkMonthlyStatementInvoice` with `teamId`, `month` and the draft's
   `invoiceId` before issuing it. Retries reuse that ID. An invoice already
   linked to another month or team cannot be attached here.
3. Issue the linked draft from Stripe with automatic card collection. Reconcile
   payment success, any small-amount balance carried forward, or payment
   failure in Stripe. The SQL operations never create or charge an invoice.

## Team deletion and credential cleanup

Deletion verifies the current customer and the absence of any live subscription.
It rejects pending customer creation or an unresolved/open Checkout. It does not
cancel a paid subscription or expire an open purchase on the user's behalf.
The FSC transaction compares the observed customer intent, customer ID and Stripe
revision, checks that no open Checkout remains, then removes the team and its
dependent memberships, connections and secret references. Billing identities
and build/usage history survive.

The same transaction stores a `BillingTeamDeletion` receipt, scoped to the
initiating UID, and captures the disappearing credential references. A lost
response can therefore be retried without deleting again or losing cleanup work.
`cleanDeletedTeamCredentials` processes due receipts hourly after a 24-hour grace
period for in-flight builds. It checks for other references, uses the existing
managed-secret/OAuth vaults, and acknowledges each path separately. A timeout or
failed destruction leaves durable work to retry; completion requires empty lists.
Imported credentials not owned by these vaults are not destroyed. The receipt
remains after cleanup for retry identity; secret references are cleared.

## Configuration and deployment

The billing HTTP Functions use 256 MiB, one CPU, concurrency one, min instances zero,
and a 300-second timeout. Cleanup uses the same limits and max instances one.

| Setting                              | Value                                                            |
| ------------------------------------ | ---------------------------------------------------------------- |
| `BILLING_ENABLED`                    | `false` by default; explicit `true` after migration/verification |
| `STRIPE_SECRET_KEY`                  | Firebase secret; `sk_`/`rk_` mode must match `STRIPE_LIVEMODE`   |
| `STRIPE_WEBHOOK_SECRET`              | Firebase secret for this endpoint, `whsec_...`                   |
| `STRIPE_LIVEMODE`                    | Explicit `true` or `false` when enabled                          |
| `STRIPE_PORTAL_CONFIGURATION_ID`     | Validated Customer Portal configuration                          |
| `BILLING_DASHBOARD_ORIGIN`           | HTTPS origin; loopback HTTP allowed for local development        |
| `BILLING_COMPLIMENTARY_PRO_TEAM_IDS` | Optional comma-separated exact team IDs                          |
| `SECRET_MANAGER_PROJECT`             | Cleanup project; defaults to `GCLOUD_PROJECT`                    |

The billing HTTP runtime identity needs privileged FSC access and access to
its declared Stripe secrets. Cleanup additionally needs FSC `secrets` reads and
Secret Manager permissions used by `ManagedSecretVault` and
`GitHubCredentialVault` (inspect/destroy managed versions; inspect/delete OAuth
secrets). It does not need Stripe keys. The import operator needs legacy DB read
access and FSC privileged reads/inserts. No legacy `BILLING_INTERNAL_TOKEN` or
`BILLING_SERVICE_URL` is used by these Functions.

Configure regular snapshot webhook events with the installed SDK API version
(`2026-10-28.endive` for the locked `stripe@23.1.0`), rather than organization/thin
events. Subscribe to:

- `checkout.session.completed`, `checkout.session.expired`
- `customer.subscription.created`, `.updated`, `.deleted`, `.paused`, `.resumed`
- `invoice.paid`, `.payment_failed`, `.payment_action_required`, `.marked_uncollectible`, `.voided`
- `customer.updated`, `customer.deleted`

See [Stripe webhook configuration](https://docs.stripe.com/webhooks). Keep the
executor's `BILLING_STRIPE_LIVEMODE` consistent with `STRIPE_LIVEMODE`, and give
both runtimes the same complimentary team list.

## Production data ownership

FSC owns billing accounts, periods, purchase intents, Stripe observations and
consumed execution usage. The production cutover is complete; legacy writers,
server code and the one-time PostgreSQL import tool are retired. The unused trial
claim table and activation operations have also been removed.

Retain billing and build history after team deletion. Retirement backups cannot
replace the current ledger without reconciliation: doing so would lose purchases
and usage recorded since cutover. See [the deployment report](DEPLOYMENT.md) and
[legacy retirement](LEGACY_RETIREMENT.md).

## Validation

Run Functions lint/type checks and unit tests, then the FSC emulator billing suite.
It covers all privileged operations rejecting client credentials, concurrent
Checkout, lost responses, membership revocation, paid/failed renewal, cancellation,
cleanup receipts and real Admin SDK ledger writes/readback. Stripe HTTP transport is
mocked through the official SDK. Run Dashboard billing/team tests, shared-package
analysis/tests and a Dashboard web build after removing the REST methods.

Local tests do not deploy Functions, migrate production rows, configure Stripe,
or verify live Stripe/IAM/Secret Manager access.

For the completed production cutover and real Stripe Sandbox verification of
purchases, payment-method changes, cancellation and repurchase, see
[the deployment report](DEPLOYMENT.md#stripe-sandbox-verification-on-2026-10-31-jst).
Direct plan switching on an active subscription remains disabled.
