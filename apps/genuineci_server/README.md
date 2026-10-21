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

`getStripeCheckoutSession` and `getStripeSubscription` each retrieve one object
by ID using the SDK, with a ten-second deadline including retries. Earlier caller
deadlines and cancellation are preserved. Request failures return a generic
error, and SDK logging is disabled to keep raw upstream errors and response
bodies out of logs. Ownership/payment validation and HTTP route integration
follow separately.
