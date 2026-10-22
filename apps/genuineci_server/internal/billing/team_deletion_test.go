package billing

import (
	"context"
	"errors"
	"net/http"
	"sync"
	"testing"

	"github.com/jackc/pgx/v5"
	"github.com/stripe/stripe-go/v87"
)

func TestDeleteTeamAllowsEveryCurrentMemberAndRetainsIdentity(t *testing.T) {
	for _, userID := range []string{"user-1", "user-2", "outsider", ""} {
		t.Run(userID, func(t *testing.T) {
			ctx, service, gateway := newCheckoutFlowTest(t)
			err := service.deleteTeam(ctx, billingMember{TeamID: "team-1", UserID: userID})
			allowed := userID == "user-1" || userID == "user-2"
			if allowed && err != nil || !allowed && !errors.Is(err, errBillingForbidden) {
				t.Fatalf("unexpected deletion result: %v", err)
			}
			assertTeamDeleted(t, ctx, service, allowed)
			if gateway.calls != 0 {
				t.Fatal("teams without a purchase and unauthorized users need no Stripe requests")
			}
		})
	}
}

func TestDeleteTeamBlocksActiveOrUncertainPurchases(t *testing.T) {
	for _, scenario := range []string{"open session", "unknown session", "active subscription", "unknown subscription", "unresolved customer", "wrong mode", "wrong session key", "Stripe unavailable"} {
		t.Run(scenario, func(t *testing.T) {
			ctx, service, gateway := newCheckoutFlowTest(t)
			member := billingMember{TeamID: "team-1", UserID: "user-1"}
			if _, err := service.checkout(ctx, member, "light"); err != nil {
				t.Fatal(err)
			}
			switch scenario {
			case "unknown session":
				execCheckoutCreationSQL(t, ctx, service.pool, "UPDATE billing_checkout_creations SET stripe_checkout_session_id = NULL")
			case "active subscription":
				gateway.subscription = checkoutFlowSubscription(stripe.SubscriptionStatusActive)
			case "unknown subscription":
				gateway.subscription = checkoutFlowSubscription("future_status")
			case "unresolved customer":
				execCheckoutCreationSQL(t, ctx, service.pool, "UPDATE billing_customer_creations SET stripe_customer_id = NULL")
			case "wrong mode":
				service.config.Livemode = true
			case "wrong session key":
				gateway.sessions["cs_1"].Status = stripe.CheckoutSessionStatusExpired
				gateway.sessions["cs_1"].Metadata["checkout_creation_key"] = "different-key"
			case "Stripe unavailable":
				service.stripe = newStripeReadTestClient(t, func(*http.Request) (*http.Response, error) {
					return nil, errors.New("unavailable")
				})
			}
			if err := service.deleteTeam(ctx, member); err == nil {
				t.Fatal("a current or uncertain purchase must prevent deletion")
			}
			assertTeamDeleted(t, ctx, service, false)
			var open int
			if err := service.pool.QueryRow(ctx, "SELECT count(*) FROM billing_checkout_creations WHERE closed_at IS NULL").Scan(&open); err != nil || open != 1 {
				t.Fatal("a failed deletion must preserve the open intent")
			}
		})
	}
}

func TestDeleteTeamRetainsEndedPurchaseHistory(t *testing.T) {
	for _, scenario := range []string{"expired session", "canceled subscription", "incomplete expired subscription"} {
		t.Run(scenario, func(t *testing.T) {
			ctx, service, gateway := newCheckoutFlowTest(t)
			member := billingMember{TeamID: "team-1", UserID: "user-1"}
			if _, err := service.checkout(ctx, member, "light"); err != nil {
				t.Fatal(err)
			}
			gateway.sessions["cs_1"].Status = stripe.CheckoutSessionStatusExpired
			if scenario != "expired session" {
				status := stripe.SubscriptionStatusCanceled
				if scenario == "incomplete expired subscription" {
					status = stripe.SubscriptionStatusIncompleteExpired
				}
				gateway.subscription = checkoutFlowSubscription(status)
				gateway.sessions["cs_1"].Status = stripe.CheckoutSessionStatusComplete
				gateway.sessions["cs_1"].Subscription = &stripe.Subscription{ID: "sub_team"}
			}
			if err := service.deleteTeam(ctx, member); err != nil {
				t.Fatal(err)
			}
			assertTeamDeleted(t, ctx, service, true)
			var closed bool
			if err := service.pool.QueryRow(ctx, `
				SELECT x.closed_at IS NOT NULL FROM billing_checkout_creations x
				JOIN billing_customer_creations c ON c.team_id = x.team_id
				WHERE x.stripe_checkout_session_id = 'cs_1' AND c.stripe_customer_id = 'cus_team'
			`).Scan(&closed); err != nil || !closed {
				t.Fatal("deletion must retain the Customer and ended Checkout identities")
			}
			if _, err := service.checkout(ctx, member, "pro"); !errors.Is(err, errBillingForbidden) {
				t.Fatal("a deleted team cannot open another Checkout")
			}
		})
	}
}

func TestDeleteTeamRechecksMembershipAfterLockWait(t *testing.T) {
	ctx, service, _ := newCheckoutFlowTest(t)
	blocker, err := service.pool.Begin(ctx)
	if err != nil {
		t.Fatal(err)
	}
	defer blocker.Rollback(ctx)
	if _, err := blocker.Exec(ctx, "SELECT id FROM teams WHERE id = 'team-1' FOR UPDATE"); err != nil {
		t.Fatal(err)
	}
	result := make(chan error, 1)
	go func() { result <- service.deleteTeam(ctx, billingMember{TeamID: "team-1", UserID: "user-1"}) }()
	waitForBillingLocks(t, ctx, service.pool, 1)
	if _, err := blocker.Exec(ctx, "DELETE FROM team_members WHERE team_id = 'team-1' AND user_id = 'user-1'"); err != nil {
		t.Fatal(err)
	}
	if err := blocker.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	if err := <-result; !errors.Is(err, errBillingForbidden) {
		t.Fatalf("removed members must not delete the team: %v", err)
	}
	var exists bool
	if err := service.pool.QueryRow(ctx, "SELECT EXISTS(SELECT 1 FROM teams WHERE id = 'team-1')").Scan(&exists); err != nil || !exists {
		t.Fatal("the team must remain")
	}
}

func TestDeleteTeamPreventsConcurrentCheckoutIntent(t *testing.T) {
	ctx, service, gateway := newCheckoutFlowTest(t)
	owner := stripeCustomerRequest{TeamID: "team-1", Livemode: false}
	if _, err := ensureStripeCustomer(ctx, service.pool, service.stripe, owner); err != nil {
		t.Fatal(err)
	}
	entered, resume := make(chan struct{}), make(chan struct{})
	release := sync.OnceFunc(func() { close(resume) })
	defer release()
	service.stripe = newStripeReadTestClient(t, func(r *http.Request) (*http.Response, error) {
		if r.URL.Path == "/v1/customers/cus_team" {
			close(entered)
			select {
			case <-resume:
			case <-r.Context().Done():
				return nil, r.Context().Err()
			}
		}
		return gateway.request(r)
	})
	deleted := make(chan error, 1)
	go func() { deleted <- service.deleteTeam(ctx, billingMember{TeamID: "team-1", UserID: "user-1"}) }()
	select {
	case <-entered:
	case <-ctx.Done():
		t.Fatal(ctx.Err())
	}
	created := make(chan error, 1)
	go func() {
		_, err := ensureCheckoutCreation(ctx, service.pool, checkoutCreationRequest{
			TeamID: "team-1", PlanID: "light", CustomerID: "cus_team", PriceID: "price_light",
			SuccessURL: service.config.returnURL("team-1", "success"), CancelURL: service.config.returnURL("team-1", "cancel"),
		})
		created <- err
	}()
	waitForBillingLocks(t, ctx, service.pool, 1)
	release()
	if err := <-deleted; err != nil {
		t.Fatal(err)
	}
	if err := <-created; !errors.Is(err, pgx.ErrNoRows) {
		t.Fatalf("Checkout must observe the deleted team after waiting: %v", err)
	}
	assertTeamDeleted(t, ctx, service, true)
}

func assertTeamDeleted(t *testing.T, ctx context.Context, service *Service, deleted bool) {
	t.Helper()
	var teamExists, accountExists bool
	var members int
	err := service.pool.QueryRow(ctx, `
		SELECT EXISTS(SELECT 1 FROM teams WHERE id = 'team-1'),
			EXISTS(SELECT 1 FROM billing_accounts WHERE team_id = 'team-1'),
			(SELECT count(*) FROM team_members WHERE team_id = 'team-1')
	`).Scan(&teamExists, &accountExists, &members)
	wantMembers := 2
	if deleted {
		wantMembers = 0
	}
	if err != nil || teamExists == deleted || !accountExists || members != wantMembers {
		t.Fatalf("unexpected team lifecycle: exists=%v, tombstone=%v, members=%d, err=%v", teamExists, accountExists, members, err)
	}
}
