package billing

import (
	"context"
	"errors"
	"fmt"
	"net/http"
	"testing"
	"time"

	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/openci-org/openci/apps/genuineci_server/internal/testutil"
)

func TestEnsureStripeCustomerRecoversExpiredIntent(t *testing.T) {
	for _, tc := range []struct {
		name     string
		livemode bool
	}{
		{"test mode", false},
		{"live mode", true},
	} {
		t.Run(tc.name, func(t *testing.T) {
			ctx, pool, intent := newExpiredCustomerCreationTestDB(t, tc.livemode)
			pool.Reset()
			requests := 0
			client := testutil.NewStripeClient(t, func(request *http.Request) (*http.Response, error) {
				requests++
				if request.Method != http.MethodGet || request.URL.Path != "/v1/customers/search" {
					t.Error("recovery must search for an existing Customer, never create one")
				}
				assertStoredCustomerCreation(t, ctx, pool, intent)
				if _, err := pool.Exec(ctx, "SELECT team_id FROM billing_accounts WHERE team_id = 'team-1' FOR UPDATE NOWAIT"); err != nil {
					t.Fatalf("recovery must release the account lock before calling Stripe: %v", err)
				}
				body := fmt.Sprintf(`{
					"data":[{"id":"cus_recovered","metadata":{"team_id":"team-1"},"livemode":%t}],
					"has_more":false
				}`, tc.livemode)
				return testutil.StripeResponse(http.StatusOK, body), nil
			})
			input := stripeCustomerRequest{TeamID: intent.TeamID, Livemode: intent.Livemode}

			id, err := ensureStripeCustomer(ctx, pool, client, input)

			if err != nil || id != "cus_recovered" {
				t.Fatalf("must recover and save the existing Customer: id=%q, err=%v", id, err)
			}
			intent.StripeCustomerID = &id
			assertStoredCustomerCreation(t, ctx, pool, intent)
			pool.Reset()
			if again, err := ensureStripeCustomer(ctx, pool, client, input); err != nil || again != id {
				t.Fatalf("must reuse the recovered Customer after reconnect: id=%q, err=%v", again, err)
			}
			if requests != 1 {
				t.Fatalf("a recovered Customer must not require another Stripe request, got %d", requests)
			}
		})
	}
}

func TestEnsureStripeCustomerKeepsUnresolvedRecoveryPending(t *testing.T) {
	for _, tc := range []struct {
		name   string
		status int
		body   string
	}{
		{"ambiguous results", http.StatusOK, `{"data":[{"id":"cus_one","metadata":{"team_id":"team-1"}},{"id":"cus_two","metadata":{"team_id":"team-1"}}]}`},
		{"mismatched result", http.StatusOK, `{"data":[{"id":"cus_other","metadata":{"team_id":"another-team"}}]}`},
		{"search failure", http.StatusInternalServerError, `{"error":{"message":"private Stripe details"}}`},
	} {
		t.Run(tc.name, func(t *testing.T) {
			ctx, pool, intent := newExpiredCustomerCreationTestDB(t, false)
			requests := 0
			client := testutil.NewStripeClient(t, func(request *http.Request) (*http.Response, error) {
				requests++
				if request.Method != http.MethodGet || request.URL.Path != "/v1/customers/search" {
					t.Error("unresolved recovery must not fall back to Customer creation")
				}
				return testutil.StripeResponse(tc.status, tc.body), nil
			})

			id, err := ensureStripeCustomer(ctx, pool, client, stripeCustomerRequest{TeamID: intent.TeamID})

			if id != "" || err == nil {
				t.Fatalf("unresolved recovery must return no Customer ID: id=%q, err=%v", id, err)
			}
			if requests != 1 {
				t.Fatalf("want one lookup without a creation attempt, got %d requests", requests)
			}
			assertStoredCustomerCreation(t, ctx, pool, intent)
		})
	}
}

func TestEnsureStripeCustomerRecoveryRequiresCommit(t *testing.T) {
	ctx, pool, intent := newExpiredCustomerCreationTestDB(t, false)
	testutil.ExecSQL(t, ctx, pool, `
		CREATE TABLE allowed_customers (id text PRIMARY KEY);
		ALTER TABLE billing_customer_creations ADD CONSTRAINT reject_recovery_at_commit
			FOREIGN KEY (stripe_customer_id) REFERENCES allowed_customers(id)
			DEFERRABLE INITIALLY DEFERRED
	`)
	requests := 0
	client := testutil.NewStripeClient(t, func(request *http.Request) (*http.Response, error) {
		requests++
		if request.Method != http.MethodGet || request.URL.Path != "/v1/customers/search" {
			t.Error("recovery retries must only search for an existing Customer")
		}
		return testutil.StripeResponse(http.StatusOK, `{"data":[{"id":"cus_recovered","metadata":{"team_id":"team-1"}}]}`), nil
	})
	input := stripeCustomerRequest{TeamID: intent.TeamID}

	id, err := ensureStripeCustomer(ctx, pool, client, input)

	var pgErr *pgconn.PgError
	if id != "" || !errors.As(err, &pgErr) || pgErr.Code != "23503" {
		t.Fatalf("failed recovery commit must return no Customer ID: id=%q, err=%v", id, err)
	}
	assertStoredCustomerCreation(t, ctx, pool, intent)
	testutil.ExecSQL(t, ctx, pool, "ALTER TABLE billing_customer_creations DROP CONSTRAINT reject_recovery_at_commit")
	pool.Reset()

	id, err = ensureStripeCustomer(ctx, pool, client, input)

	if err != nil || id != "cus_recovered" || requests != 2 {
		t.Fatalf("must retry recovery after a failed commit: id=%q, requests=%d, err=%v", id, requests, err)
	}
	intent.StripeCustomerID = &id
	assertStoredCustomerCreation(t, ctx, pool, intent)
}

func newExpiredCustomerCreationTestDB(t *testing.T, livemode bool) (context.Context, *pgxpool.Pool, customerCreation) {
	t.Helper()
	ctx, pool, intent := newCustomerCreationResultTestDB(t, livemode)
	intent.CreatedAt = time.Now().UTC().Truncate(time.Second).Add(-25 * time.Hour)
	if _, err := pool.Exec(ctx, "UPDATE billing_customer_creations SET created_at = $1 WHERE team_id = $2", intent.CreatedAt.Unix(), intent.TeamID); err != nil {
		t.Fatal(err)
	}
	return ctx, pool, intent
}
