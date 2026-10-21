package billing

import (
	"context"
	"errors"
	"reflect"
	"testing"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/stripe/stripe-go/v87"
)

func TestRecordStripeCheckoutSession(t *testing.T) {
	for _, tc := range []struct {
		name     string
		livemode bool
		status   stripe.CheckoutSessionStatus
	}{
		{"test mode", false, stripe.CheckoutSessionStatusOpen},
		{"live mode", true, stripe.CheckoutSessionStatusOpen},
		{"completed Session without a payment URL", false, stripe.CheckoutSessionStatusComplete},
		{"expired Session without a payment URL", false, stripe.CheckoutSessionStatusExpired},
	} {
		t.Run(tc.name, func(t *testing.T) {
			ctx, pool, creation := newCheckoutCreationResultTestDB(t, tc.livemode)
			session := checkoutSessionForCreation(creation, "cs_checkout")
			session.Status = tc.status
			if session.Status == stripe.CheckoutSessionStatusOpen {
				session.URL = "https://checkout.stripe.com/c/pay/cs_checkout"
			}

			if err := recordStripeCheckoutSession(ctx, pool, creation, session); err != nil {
				t.Fatal(err)
			}

			want := creation
			want.StripeCheckoutSessionID = &session.ID
			if got := readCheckoutCreation(t, ctx, pool, creation.IdempotencyKey); !reflect.DeepEqual(*got, want) {
				t.Fatalf("must commit only the Session ID: want=%+v, got=%+v", want, got)
			}
			var unfinished bool
			if err := pool.QueryRow(ctx, "SELECT closed_at IS NULL FROM billing_checkout_creations").Scan(&unfinished); err != nil || !unfinished {
				t.Fatalf("saving a Session must not close the intent: unfinished=%v, err=%v", unfinished, err)
			}
			stored := checkoutCreationRecords(t, ctx, pool)
			pool.Reset()

			if err := recordStripeCheckoutSession(ctx, pool, creation, session); err != nil {
				t.Fatalf("the same result must be safe to retry after reconnect: %v", err)
			}
			if got := checkoutCreationRecords(t, ctx, pool); got != stored {
				t.Fatal("retry must preserve the stored record")
			}
		})
	}
}

func TestRecordStripeCheckoutSessionRejectsInvalidSession(t *testing.T) {
	creation := checkoutCreation{Request: checkoutCreationTestRequest()}
	t.Run("missing Session", func(t *testing.T) {
		if err := recordStripeCheckoutSession(t.Context(), nil, creation, nil); err == nil {
			t.Fatal("missing Session must be rejected before database access")
		}
	})
	for _, tc := range []struct {
		name   string
		change func(*stripe.CheckoutSession)
	}{
		{"missing ID", func(s *stripe.CheckoutSession) { s.ID = "" }},
		{"blank ID", func(s *stripe.CheckoutSession) { s.ID = " \t" }},
		{"one-time payment", func(s *stripe.CheckoutSession) { s.Mode = stripe.CheckoutSessionModePayment }},
		{"embedded checkout", func(s *stripe.CheckoutSession) { s.UIMode = stripe.CheckoutSessionUIModeEmbeddedPage }},
		{"wrong test/live mode", func(s *stripe.CheckoutSession) { s.Livemode = true }},
		{"missing Customer", func(s *stripe.CheckoutSession) { s.Customer = nil }},
		{"another Customer", func(s *stripe.CheckoutSession) { s.Customer.ID = "cus_other" }},
		{"deleted Customer", func(s *stripe.CheckoutSession) { s.Customer.Deleted = true }},
		{"missing team metadata", func(s *stripe.CheckoutSession) { s.Metadata = nil }},
		{"another team", func(s *stripe.CheckoutSession) { s.Metadata["team_id"] = "team-2" }},
		{"another client reference", func(s *stripe.CheckoutSession) { s.ClientReferenceID = "team-2" }},
		{"another success URL", func(s *stripe.CheckoutSession) { s.SuccessURL = "https://other.example/success" }},
		{"another cancel URL", func(s *stripe.CheckoutSession) { s.CancelURL = "https://other.example/cancel" }},
	} {
		t.Run(tc.name, func(t *testing.T) {
			session := checkoutSessionForCreation(creation, "cs_checkout")
			tc.change(session)

			if err := recordStripeCheckoutSession(t.Context(), nil, creation, session); err == nil {
				t.Fatal("invalid Session must be rejected before database access")
			}
		})
	}
}

func TestRecordStripeCheckoutSessionRejectsChangedIntent(t *testing.T) {
	for _, tc := range []struct{ name, assignment string }{
		{"key", "idempotency_key = 'replacement-key'"},
		{"team", "team_id = 'team-2'"},
		{"plan", "plan_id = 'pro'"},
		{"Customer", "stripe_customer_id = 'cus_other'"},
		{"Price", "stripe_price_id = 'price_other'"},
		{"success URL", "success_url = 'https://other.example/success'"},
		{"cancel URL", "cancel_url = 'https://other.example/cancel'"},
		{"mode", "livemode = true"},
		{"creation time", "created_at = created_at + 1"},
		{"closed intent", "closed_at = 1800000100"},
		{"different Session already saved", "stripe_checkout_session_id = 'cs_other'"},
	} {
		t.Run(tc.name, func(t *testing.T) {
			ctx, pool, creation := newCheckoutCreationResultTestDB(t, false)
			execCheckoutCreationSQL(t, ctx, pool, "UPDATE billing_checkout_creations SET "+tc.assignment)
			want := checkoutCreationRecords(t, ctx, pool)

			err := recordStripeCheckoutSession(ctx, pool, creation, checkoutSessionForCreation(creation, "cs_checkout"))

			if err == nil {
				t.Fatal("stale results must not overwrite a changed or closed intent")
			}
			if got := checkoutCreationRecords(t, ctx, pool); got != want {
				t.Fatalf("must preserve the record: want=%s, got=%s", want, got)
			}
		})
	}
}

func TestRecordStripeCheckoutSessionDoesNotRecreateMissingIntent(t *testing.T) {
	ctx, pool, creation := newCheckoutCreationResultTestDB(t, false)
	execCheckoutCreationSQL(t, ctx, pool, "DELETE FROM billing_checkout_creations")

	if err := recordStripeCheckoutSession(ctx, pool, creation, checkoutSessionForCreation(creation, "cs_checkout")); err == nil {
		t.Fatal("missing intent must be rejected")
	}
	assertCheckoutCreationCount(t, ctx, pool, 0)
}

func TestRecordStripeCheckoutSessionRejectsDeletedTeam(t *testing.T) {
	ctx, pool, creation := newCheckoutCreationResultTestDB(t, false)
	execCheckoutCreationSQL(t, ctx, pool, "DELETE FROM teams WHERE id = 'team-1'")
	want := checkoutCreationRecords(t, ctx, pool)

	err := recordStripeCheckoutSession(ctx, pool, creation, checkoutSessionForCreation(creation, "cs_checkout"))

	if !errors.Is(err, pgx.ErrNoRows) {
		t.Fatalf("must require a current team, got %v", err)
	}
	if got := checkoutCreationRecords(t, ctx, pool); got != want {
		t.Fatal("deleted team's intent must remain unchanged")
	}
}

func TestRecordStripeCheckoutSessionCannotReuseHistoricalSession(t *testing.T) {
	ctx, pool, first := newCheckoutCreationResultTestDB(t, false)
	session := checkoutSessionForCreation(first, "cs_checkout")
	if err := recordStripeCheckoutSession(ctx, pool, first, session); err != nil {
		t.Fatal(err)
	}
	execCheckoutCreationSQL(t, ctx, pool, "UPDATE billing_checkout_creations SET closed_at = 1800000100")
	second, err := ensureCheckoutCreation(ctx, pool, first.Request)
	if err != nil {
		t.Fatal(err)
	}
	want := checkoutCreationRecords(t, ctx, pool)

	err = recordStripeCheckoutSession(ctx, pool, *second, session)

	var pgErr *pgconn.PgError
	if !errors.As(err, &pgErr) || pgErr.Code != "23505" {
		t.Fatalf("a Session must belong to only one intent, including closed history: %v", err)
	}
	if got := checkoutCreationRecords(t, ctx, pool); got != want {
		t.Fatal("historical Session conflict must leave both intents unchanged")
	}
}

func TestRecordStripeCheckoutSessionConcurrent(t *testing.T) {
	for _, tc := range []struct {
		name, otherID string
		successes     int
	}{
		{"same Session", "cs_checkout", 2},
		{"different Sessions", "cs_other", 1},
	} {
		t.Run(tc.name, func(t *testing.T) {
			ctx, pool, creation := newCheckoutCreationResultTestDB(t, false)
			blocker, err := pool.Begin(ctx)
			if err != nil {
				t.Fatal(err)
			}
			defer blocker.Rollback(ctx)
			if _, err := blocker.Exec(ctx, "SELECT team_id FROM billing_accounts WHERE team_id = 'team-1' FOR UPDATE"); err != nil {
				t.Fatal(err)
			}
			type result struct {
				id  string
				err error
			}
			results := make(chan result, 2)
			for _, id := range []string{"cs_checkout", tc.otherID} {
				go func() {
					err := recordStripeCheckoutSession(ctx, pool, creation, checkoutSessionForCreation(creation, id))
					results <- result{id, err}
				}()
			}
			waitForBillingLocks(t, ctx, pool, 2)
			if err := blocker.Commit(ctx); err != nil {
				t.Fatal(err)
			}
			successes := 0
			var winner string
			for range 2 {
				got := <-results
				if got.err == nil {
					successes++
					winner = got.id
				} else if got.err.Error() != "Stripe Checkout creation intent is missing, changed, closed, or already linked" {
					t.Fatalf("unexpected concurrent result: %v", got.err)
				}
			}
			if successes != tc.successes {
				t.Fatalf("want %d successful records, got %d", tc.successes, successes)
			}
			stored := readCheckoutCreation(t, ctx, pool, creation.IdempotencyKey)
			if stored.StripeCheckoutSessionID == nil || *stored.StripeCheckoutSessionID != winner {
				t.Fatalf("must preserve the winning Session %q: got %+v", winner, stored)
			}
		})
	}
}

func TestRecordStripeCheckoutSessionCommitFailure(t *testing.T) {
	ctx, pool, creation := newCheckoutCreationResultTestDB(t, false)
	execCheckoutCreationSQL(t, ctx, pool, `
		CREATE TABLE allowed_checkout_sessions (id text PRIMARY KEY);
		ALTER TABLE billing_checkout_creations ADD CONSTRAINT reject_session_at_commit
			FOREIGN KEY (stripe_checkout_session_id) REFERENCES allowed_checkout_sessions(id)
			DEFERRABLE INITIALLY DEFERRED
	`)
	want := checkoutCreationRecords(t, ctx, pool)
	session := checkoutSessionForCreation(creation, "cs_checkout")

	err := recordStripeCheckoutSession(ctx, pool, creation, session)

	var pgErr *pgconn.PgError
	if !errors.As(err, &pgErr) || pgErr.Code != "23503" {
		t.Fatalf("must report failure at commit, got %v", err)
	}
	if got := checkoutCreationRecords(t, ctx, pool); got != want {
		t.Fatal("failed commit must not store the Session")
	}
	execCheckoutCreationSQL(t, ctx, pool, "ALTER TABLE billing_checkout_creations DROP CONSTRAINT reject_session_at_commit")
	if err := recordStripeCheckoutSession(ctx, pool, creation, session); err != nil {
		t.Fatalf("must allow the same result to be retried after rollback: %v", err)
	}
	if stored := readCheckoutCreation(t, ctx, pool, creation.IdempotencyKey); stored.StripeCheckoutSessionID == nil || *stored.StripeCheckoutSessionID != session.ID {
		t.Fatal("retry must commit the Session ID")
	}
}

func TestRecordStripeCheckoutSessionCanceled(t *testing.T) {
	ctx, pool, creation := newCheckoutCreationResultTestDB(t, false)
	want := checkoutCreationRecords(t, ctx, pool)
	canceled, cancel := context.WithCancel(ctx)
	cancel()

	err := recordStripeCheckoutSession(canceled, pool, creation, checkoutSessionForCreation(creation, "cs_checkout"))

	if !errors.Is(err, context.Canceled) {
		t.Fatalf("want cancellation, got %v", err)
	}
	if got := checkoutCreationRecords(t, ctx, pool); got != want {
		t.Fatal("canceled operation must leave the intent unchanged")
	}
}

func newCheckoutCreationResultTestDB(t *testing.T, livemode bool) (context.Context, *pgxpool.Pool, checkoutCreation) {
	t.Helper()
	ctx, pool := newCheckoutCreationTestDB(t)
	request := checkoutCreationTestRequest()
	request.Livemode = livemode
	creation, err := ensureCheckoutCreation(ctx, pool, request)
	if err != nil {
		t.Fatal(err)
	}
	return ctx, pool, *creation
}

func checkoutSessionForCreation(creation checkoutCreation, id string) *stripe.CheckoutSession {
	return &stripe.CheckoutSession{
		ID:                id,
		Mode:              stripe.CheckoutSessionModeSubscription,
		UIMode:            stripe.CheckoutSessionUIModeHostedPage,
		Livemode:          creation.Request.Livemode,
		Customer:          &stripe.Customer{ID: creation.Request.CustomerID},
		ClientReferenceID: creation.Request.TeamID,
		Metadata:          map[string]string{"team_id": creation.Request.TeamID},
		SuccessURL:        creation.Request.SuccessURL,
		CancelURL:         creation.Request.CancelURL,
	}
}
