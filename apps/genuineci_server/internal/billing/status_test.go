package billing

import (
	"errors"
	"testing"
	"time"

	"github.com/stripe/stripe-go/v87"
)

func TestBillingStatusReadsOnlyPersistedState(t *testing.T) {
	ctx, service, gateway := newReconciliationTest(t)
	if err := service.reconcileStripeEvent(ctx, stripe.Event{ID: "evt_paid"}, gateway.customer.ID); err != nil {
		t.Fatal(err)
	}
	service.stripe = nil
	member := billingMember{TeamID: "team-1", UserID: "user-1"}
	status, err := service.status(ctx, member)
	if err != nil || !status.CanStartCI || status.PlanID == nil || *status.PlanID != "light" ||
		!status.CanManageBilling || status.CanCheckout || status.PaidUntil == nil || status.BlockReason != "" {
		t.Fatalf("must read the persisted paid state without Stripe: status=%+v, err=%v", status, err)
	}
	before := stripeStateRecords(t, ctx, service)
	if _, err := service.status(ctx, member); err != nil {
		t.Fatal(err)
	}
	if stripeStateRecords(t, ctx, service) != before {
		t.Fatal("status reads must not refresh or mutate billing state")
	}
}

func TestBillingStatusRequiresCurrentMember(t *testing.T) {
	ctx, pool := newStripeStateTestDB(t)
	service := &Service{pool: pool}
	for _, member := range []billingMember{{TeamID: "team-1", UserID: "outsider"}, {TeamID: "team-1"}, {TeamID: "missing", UserID: "user-1"}} {
		if status, err := service.status(ctx, member); status != nil || !errors.Is(err, errBillingForbidden) {
			t.Fatal("must reject nonmembers")
		}
	}
	status, err := service.status(ctx, billingMember{TeamID: "team-1", UserID: "user-2"})
	if err != nil || !status.CanCheckout || status.CanStartCI || status.CanManageBilling || status.BlockReason != "payment_required" {
		t.Fatalf("new member can choose a plan without a Stripe Customer: %+v, %v", status, err)
	}
}

func TestBillingStatusAccessBoundaries(t *testing.T) {
	for _, tc := range []struct {
		name, state, periodType string
		start, end              int64
		canStart, canCheckout   bool
		reason                  string
	}{
		{"paid", "active", "paid", -3600, 3600, true, false, ""},
		{"period end cancellation", "active", "paid", -3600, 3600, true, false, ""},
		{"expired", "active", "paid", -3600, -1, false, false, "payment_required"},
		{"future", "active", "paid", 3600, 7200, false, false, "payment_required"},
		{"failed renewal", "past_due", "paid", -3600, -1, false, false, "payment_required"},
		{"immediate cancellation", "canceled", "paid", -3600, 3600, false, true, "subscription_ended"},
		{"unpaid", "unpaid", "paid", -3600, 3600, false, false, "payment_required"},
		{"trial record", "active", "trial", -3600, 3600, false, false, "payment_required"},
		{"unverified", "unverified", "paid", -3600, 3600, false, false, "billing_unavailable"},
	} {
		t.Run(tc.name, func(t *testing.T) {
			ctx, pool := newStripeStateTestDB(t)
			now := time.Now().Unix()
			execCheckoutCreationSQL(t, ctx, pool, `
				INSERT INTO billing_periods VALUES ('period', 'team-1', 'light', $1, $2, $3, 36000)
			`, tc.periodType, now+tc.start, now+tc.end)
			execCheckoutCreationSQL(t, ctx, pool, `
				INSERT INTO billing_stripe_state (team_id, stripe_customer_id, livemode, stripe_subscription_id, subscription_status, plan_id, paid_period_id, synced_at, cancel_at_period_end)
				VALUES ('team-1', 'cus_team', false, 'sub_team', $1, 'light', 'period', $2, $3)
			`, tc.state, now, tc.name == "period end cancellation")
			service := &Service{pool: pool}
			status, err := service.status(ctx, billingMember{TeamID: "team-1", UserID: "user-1"})
			if err != nil || status.CanStartCI != tc.canStart || status.CanCheckout != tc.canCheckout || status.BlockReason != tc.reason {
				t.Fatalf("unexpected access decision: %+v, %v", status, err)
			}
		})
	}
}
