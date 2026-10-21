package billing

import (
	"context"
	"errors"
	"net/http"
	"sync"
	"testing"

	"github.com/stripe/stripe-go/v87"
)

func TestReconcileStripeEventCommitsPaidPeriodOnce(t *testing.T) {
	ctx, service, gateway := newReconciliationTest(t)
	event := stripe.Event{ID: "evt_paid", Type: stripe.EventTypeInvoicePaid, Created: 200}
	if err := service.reconcileStripeEvent(ctx, event, gateway.customer.ID); err != nil {
		t.Fatal(err)
	}
	state := stripeStateRecords(t, ctx, service)
	calls := gateway.calls
	if err := service.reconcileStripeEvent(ctx, event, gateway.customer.ID); err != nil {
		t.Fatal(err)
	}
	if gateway.calls != calls || stripeStateRecords(t, ctx, service) != state {
		t.Fatal("delivery retries must not call Stripe or mutate state")
	}
	assertStripeState(t, ctx, service, "active", "stripe:in_paid", 1, 1)
}

func TestReconcileStripeEventUsesCurrentStateForOldNotification(t *testing.T) {
	ctx, service, gateway := newReconciliationTest(t)
	if err := service.reconcileStripeEvent(ctx, stripe.Event{ID: "evt_paid", Created: 200}, gateway.customer.ID); err != nil {
		t.Fatal(err)
	}
	gateway.subscription.Status = stripe.SubscriptionStatusCanceled
	if err := service.reconcileStripeEvent(ctx, stripe.Event{ID: "evt_old", Created: 100}, gateway.customer.ID); err != nil {
		t.Fatal(err)
	}
	assertStripeState(t, ctx, service, "canceled", "stripe:in_paid", 1, 2)
	gateway.subscription.Status = stripe.SubscriptionStatusActive
	if err := service.reconcileStripeEvent(ctx, stripe.Event{ID: "evt_stale_observation", Created: 101}, gateway.customer.ID); err != nil {
		t.Fatal(err)
	}
	assertStripeState(t, ctx, service, "canceled", "stripe:in_paid", 1, 3)
}

func TestReconcileStripeEventDoesNotExtendFailedRenewal(t *testing.T) {
	ctx, service, gateway := newReconciliationTest(t)
	if err := service.reconcileStripeEvent(ctx, stripe.Event{ID: "evt_paid"}, gateway.customer.ID); err != nil {
		t.Fatal(err)
	}
	gateway.subscription.Status = stripe.SubscriptionStatusPastDue
	item := gateway.subscription.Items.Data[0]
	item.CurrentPeriodStart, item.CurrentPeriodEnd = item.CurrentPeriodEnd, item.CurrentPeriodEnd+30*24*60*60
	gateway.invoice.ID, gateway.invoice.Status = "in_unpaid", stripe.InvoiceStatusOpen
	gateway.subscription.LatestInvoice.ID = "in_unpaid"
	if err := service.reconcileStripeEvent(ctx, stripe.Event{ID: "evt_failed"}, gateway.customer.ID); err != nil {
		t.Fatal(err)
	}
	assertStripeState(t, ctx, service, "past_due", "stripe:in_paid", 1, 2)
}

func TestReconcileStripeEventTracksPortalCancellation(t *testing.T) {
	for _, mode := range []string{"classic", "flexible"} {
		t.Run(mode, func(t *testing.T) {
			ctx, service, gateway := newReconciliationTest(t)
			gateway.subscription.CancelAt = gateway.subscription.Items.Data[0].CurrentPeriodEnd
			gateway.subscription.CancelAtPeriodEnd = mode == "classic"
			if err := service.reconcileStripeEvent(ctx, stripe.Event{ID: "evt_cancel_scheduled"}, gateway.customer.ID); err != nil {
				t.Fatal(err)
			}
			var scheduled bool
			err := service.pool.QueryRow(ctx, "SELECT cancel_at_period_end FROM billing_stripe_state WHERE team_id = 'team-1'").Scan(&scheduled)
			if err != nil || !scheduled {
				t.Fatalf("Portal cancellation must be reflected in persisted state: scheduled=%v, err=%v", scheduled, err)
			}
			assertStripeState(t, ctx, service, "active", "stripe:in_paid", 1, 1)

			gateway.subscription.CancelAt = 0
			gateway.subscription.CancelAtPeriodEnd = false
			if err := service.reconcileStripeEvent(ctx, stripe.Event{ID: "evt_cancel_removed"}, gateway.customer.ID); err != nil {
				t.Fatal(err)
			}
			err = service.pool.QueryRow(ctx, "SELECT cancel_at_period_end FROM billing_stripe_state WHERE team_id = 'team-1'").Scan(&scheduled)
			if err != nil || scheduled {
				t.Fatalf("resuming the subscription must clear the cancellation: scheduled=%v, err=%v", scheduled, err)
			}
			assertStripeState(t, ctx, service, "active", "stripe:in_paid", 1, 2)
		})
	}
}

func TestReconcileStripeEventFailsClosedOnMismatches(t *testing.T) {
	for _, mismatch := range []string{"customer metadata", "purchase key", "Price", "invoice Customer"} {
		t.Run(mismatch, func(t *testing.T) {
			ctx, service, gateway := newReconciliationTest(t)
			switch mismatch {
			case "customer metadata":
				gateway.customer.Metadata["team_id"] = "team-2"
			case "purchase key":
				gateway.session.Metadata["checkout_creation_key"] = "unrelated"
			case "Price":
				gateway.subscription.Items.Data[0].Price.ID = "price_unrelated"
			case "invoice Customer":
				gateway.invoice.Customer.ID = "cus_other"
			}
			if err := service.reconcileStripeEvent(ctx, stripe.Event{ID: "evt_invalid"}, gateway.customer.ID); err != nil {
				t.Fatal(err)
			}
			assertStripeState(t, ctx, service, "unverified", "", 0, 1)
		})
	}
}

func TestReconcileStripeEventRollsBackAndRetries(t *testing.T) {
	for _, failure := range []string{"Stripe outage", "event commit"} {
		t.Run(failure, func(t *testing.T) {
			ctx, service, gateway := newReconciliationTest(t)
			if failure == "Stripe outage" {
				gateway.fail = true
			} else {
				execCheckoutCreationSQL(t, ctx, service.pool, `
				CREATE TABLE allowed_events (id text PRIMARY KEY);
				ALTER TABLE billing_stripe_events ADD CONSTRAINT reject_event FOREIGN KEY (event_id)
				REFERENCES allowed_events(id) DEFERRABLE INITIALLY DEFERRED
			`)
			}
			event := stripe.Event{ID: "evt_retry"}
			if err := service.reconcileStripeEvent(ctx, event, gateway.customer.ID); err == nil {
				t.Fatal("failure must be reported for retry")
			}
			var count int
			if err := service.pool.QueryRow(ctx, "SELECT (SELECT count(*) FROM billing_periods) + (SELECT count(*) FROM billing_stripe_state) + (SELECT count(*) FROM billing_stripe_events)").Scan(&count); err != nil || count != 0 {
				t.Fatal("failed reconciliation must not leave partial grants or deduplication records")
			}
			gateway.fail = false
			if failure == "event commit" {
				execCheckoutCreationSQL(t, ctx, service.pool, "ALTER TABLE billing_stripe_events DROP CONSTRAINT reject_event")
			}
			if err := service.reconcileStripeEvent(ctx, event, gateway.customer.ID); err != nil {
				t.Fatal(err)
			}
			assertStripeState(t, ctx, service, "active", "stripe:in_paid", 1, 1)
		})
	}
}

func TestReconcileStripeEventsConcurrent(t *testing.T) {
	ctx, service, gateway := newReconciliationTest(t)
	results := make(chan error, 2)
	for range 2 {
		go func() {
			results <- service.reconcileStripeEvent(ctx, stripe.Event{ID: "evt_same"}, gateway.customer.ID)
		}()
	}
	for range 2 {
		if err := <-results; err != nil {
			t.Fatal(err)
		}
	}
	assertStripeState(t, ctx, service, "active", "stripe:in_paid", 1, 1)
}

type reconciliationGateway struct {
	mu           sync.Mutex
	customer     *stripe.Customer
	subscription *stripe.Subscription
	session      *stripe.CheckoutSession
	invoice      *stripe.Invoice
	calls        int
	fail         bool
}

func newReconciliationTest(t *testing.T) (context.Context, *Service, *reconciliationGateway) {
	t.Helper()
	ctx, pool := newStripeStateTestDB(t)
	setBillingServiceEnvironment(t)
	config, err := LoadServiceConfig()
	if err != nil {
		t.Fatal(err)
	}
	fixture, subscription, invoice := paidStripeFixtures()
	creation, err := ensureCheckoutCreation(ctx, pool, fixture.Request)
	if err != nil {
		t.Fatal(err)
	}
	execCheckoutCreationSQL(t, ctx, pool, `
		INSERT INTO billing_customer_creations (team_id, idempotency_key, livemode, created_at, stripe_customer_id)
		VALUES ($1, 'customer-key', false, 1, $2)
	`, fixture.Request.TeamID, fixture.Request.CustomerID)
	session := checkoutSessionForCreation(*creation, "cs_paid")
	session.Status, session.Subscription = stripe.CheckoutSessionStatusComplete, &stripe.Subscription{ID: subscription.ID}
	session.Metadata["checkout_creation_key"] = creation.IdempotencyKey
	gateway := &reconciliationGateway{
		customer:     &stripe.Customer{ID: fixture.Request.CustomerID, Metadata: map[string]string{"team_id": fixture.Request.TeamID}},
		subscription: subscription, session: session, invoice: invoice,
	}
	client := newStripeReadTestClient(t, func(r *http.Request) (*http.Response, error) {
		gateway.mu.Lock()
		defer gateway.mu.Unlock()
		gateway.calls++
		if gateway.fail {
			return nil, errors.New("Stripe unavailable")
		}
		switch r.URL.Path {
		case "/v1/customers/" + gateway.customer.ID:
			return stripeObjectResponse(t, gateway.customer), nil
		case "/v1/subscriptions":
			return stripeObjectResponse(t, map[string]any{"object": "list", "data": []*stripe.Subscription{gateway.subscription}}), nil
		case "/v1/checkout/sessions":
			return stripeObjectResponse(t, map[string]any{"object": "list", "data": []*stripe.CheckoutSession{gateway.session}}), nil
		case "/v1/invoices/" + gateway.invoice.ID:
			return stripeObjectResponse(t, gateway.invoice), nil
		default:
			return nil, errors.New("unexpected reconciliation request")
		}
	})
	return ctx, &Service{pool: pool, stripe: client, config: *config}, gateway
}

func assertStripeState(t *testing.T, ctx context.Context, service *Service, status, periodID string, periods, events int) {
	t.Helper()
	var gotStatus, gotPeriod string
	var gotPeriods, gotEvents int
	err := service.pool.QueryRow(ctx, `
		SELECT subscription_status, COALESCE(paid_period_id, ''),
			(SELECT count(*) FROM billing_periods), (SELECT count(*) FROM billing_stripe_events)
		FROM billing_stripe_state WHERE team_id = 'team-1'
	`).Scan(&gotStatus, &gotPeriod, &gotPeriods, &gotEvents)
	if err != nil || gotStatus != status || gotPeriod != periodID || gotPeriods != periods || gotEvents != events {
		t.Fatalf("unexpected persisted state: status=%s, period=%s, periods=%d, events=%d, err=%v", gotStatus, gotPeriod, gotPeriods, gotEvents, err)
	}
}

func stripeStateRecords(t *testing.T, ctx context.Context, service *Service) string {
	t.Helper()
	var result string
	if err := service.pool.QueryRow(ctx, "SELECT to_jsonb(s)::text FROM billing_stripe_state s WHERE team_id = 'team-1'").Scan(&result); err != nil {
		t.Fatal(err)
	}
	return result
}
