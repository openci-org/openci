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

func TestRecordStripeCustomer(t *testing.T) {
	for _, tc := range []struct {
		name     string
		livemode bool
	}{
		{"test mode", false},
		{"live mode", true},
	} {
		t.Run(tc.name, func(t *testing.T) {
			ctx, pool, creation := newCustomerCreationResultTestDB(t, tc.livemode)
			customer := customerForCreation(creation, "cus_team1")
			want := creation
			want.StripeCustomerID = &customer.ID

			if err := recordStripeCustomer(ctx, pool, creation, customer); err != nil {
				t.Fatal(err)
			}
			assertStoredCustomerCreation(t, ctx, pool, want)
			pool.Reset()

			if err := recordStripeCustomer(ctx, pool, creation, customer); err != nil {
				t.Fatalf("the same result must be safe to retry after reconnect: %v", err)
			}
			assertStoredCustomerCreation(t, ctx, pool, want)
		})
	}
}

func TestRecordStripeCustomerRejectsInvalidCustomer(t *testing.T) {
	metadata := map[string]string{"team_id": "team-1"}
	for _, tc := range []struct {
		name     string
		customer *stripe.Customer
	}{
		{"missing Customer", nil},
		{"missing ID", &stripe.Customer{Metadata: metadata}},
		{"deleted", &stripe.Customer{ID: "cus_team1", Metadata: metadata, Deleted: true}},
		{"wrong mode", &stripe.Customer{ID: "cus_team1", Metadata: metadata, Livemode: true}},
		{"missing team metadata", &stripe.Customer{ID: "cus_team1"}},
		{"another team", &stripe.Customer{ID: "cus_team1", Metadata: map[string]string{"team_id": "team-2"}}},
	} {
		t.Run(tc.name, func(t *testing.T) {
			ctx, pool, creation := newCustomerCreationResultTestDB(t, false)

			if err := recordStripeCustomer(ctx, pool, creation, tc.customer); err == nil {
				t.Fatal("invalid Customer must be rejected")
			}
			assertStoredCustomerCreation(t, ctx, pool, creation)
		})
	}
}

func TestRecordStripeCustomerRejectsChangedIntent(t *testing.T) {
	for _, tc := range []struct{ name, sql string }{
		{"different key", "UPDATE billing_customer_creations SET idempotency_key = 'replacement-key'"},
		{"different mode", "UPDATE billing_customer_creations SET livemode = true"},
		{"different Customer", "UPDATE billing_customer_creations SET stripe_customer_id = 'cus_original'"},
	} {
		t.Run(tc.name, func(t *testing.T) {
			ctx, pool, creation := newCustomerCreationResultTestDB(t, false)
			execCustomerCreationSQL(t, ctx, pool, tc.sql)
			want := *readCustomerCreation(t, ctx, pool, creation.TeamID)

			err := recordStripeCustomer(ctx, pool, creation, customerForCreation(creation, "cus_team1"))

			if err == nil {
				t.Fatal("a stale result must not change the stored intent")
			}
			assertStoredCustomerCreation(t, ctx, pool, want)
		})
	}
}

func TestRecordStripeCustomerRequiresIntent(t *testing.T) {
	ctx, pool, creation := newCustomerCreationResultTestDB(t, false)
	execCustomerCreationSQL(t, ctx, pool, "DELETE FROM billing_customer_creations")

	err := recordStripeCustomer(ctx, pool, creation, customerForCreation(creation, "cus_team1"))

	if err == nil {
		t.Fatal("recording a result must not initialize a missing intent")
	}
	assertNoCustomerCreations(t, ctx, pool)
}

func TestRecordStripeCustomerRejectsDeletedTeam(t *testing.T) {
	ctx, pool, creation := newCustomerCreationResultTestDB(t, false)
	execCustomerCreationSQL(t, ctx, pool, "DELETE FROM teams WHERE id = 'team-1'")

	err := recordStripeCustomer(ctx, pool, creation, customerForCreation(creation, "cus_team1"))

	if !errors.Is(err, pgx.ErrNoRows) {
		t.Fatalf("must require a current team, got %v", err)
	}
	assertStoredCustomerCreation(t, ctx, pool, creation)
}

func TestRecordStripeCustomerCannotShareCustomer(t *testing.T) {
	ctx, pool, first := newCustomerCreationResultTestDB(t, false)
	customer := customerForCreation(first, "cus_team1")
	if err := recordStripeCustomer(ctx, pool, first, customer); err != nil {
		t.Fatal(err)
	}
	first.StripeCustomerID = &customer.ID
	second, err := ensureCustomerCreation(ctx, pool, "team-2", false)
	if err != nil {
		t.Fatal(err)
	}

	err = recordStripeCustomer(ctx, pool, *second, customerForCreation(*second, customer.ID))

	var pgErr *pgconn.PgError
	if !errors.As(err, &pgErr) || pgErr.Code != "23505" {
		t.Fatalf("must reject a Customer already linked to another team, got %v", err)
	}
	assertStoredCustomerCreation(t, ctx, pool, first)
	assertStoredCustomerCreation(t, ctx, pool, *second)
}

func TestRecordStripeCustomerConcurrent(t *testing.T) {
	for _, tc := range []struct {
		name, otherID string
		successes     int
	}{
		{"same Customer", "cus_team1", 2},
		{"different Customers", "cus_other", 1},
	} {
		t.Run(tc.name, func(t *testing.T) {
			ctx, pool, creation := newCustomerCreationResultTestDB(t, false)
			blocker, err := pool.Begin(ctx)
			if err != nil {
				t.Fatal(err)
			}
			defer blocker.Rollback(ctx)
			if _, err := blocker.Exec(ctx, "SELECT team_id FROM billing_accounts WHERE team_id = 'team-1' FOR UPDATE"); err != nil {
				t.Fatal(err)
			}
			type result struct {
				customerID string
				err        error
			}
			results := make(chan result, 2)
			for _, id := range []string{"cus_team1", tc.otherID} {
				go func() {
					err := recordStripeCustomer(ctx, pool, creation, customerForCreation(creation, id))
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
					winner = got.customerID
				}
			}
			if successes != tc.successes {
				t.Fatalf("want %d successful records, got %d", tc.successes, successes)
			}
			creation.StripeCustomerID = &winner
			assertStoredCustomerCreation(t, ctx, pool, creation)
		})
	}
}

func TestRecordStripeCustomerCommitFailure(t *testing.T) {
	ctx, pool, creation := newCustomerCreationResultTestDB(t, false)
	// Allow UPDATE, but reject the Customer ID at COMMIT.
	execCustomerCreationSQL(t, ctx, pool, `
		CREATE TABLE allowed_customers (id text PRIMARY KEY);
		ALTER TABLE billing_customer_creations ADD CONSTRAINT reject_customer_at_commit
			FOREIGN KEY (stripe_customer_id) REFERENCES allowed_customers(id)
			DEFERRABLE INITIALLY DEFERRED
	`)
	customer := customerForCreation(creation, "cus_team1")

	err := recordStripeCustomer(ctx, pool, creation, customer)

	var pgErr *pgconn.PgError
	if !errors.As(err, &pgErr) || pgErr.Code != "23503" {
		t.Fatalf("must report failure at commit, got %v", err)
	}
	assertStoredCustomerCreation(t, ctx, pool, creation)
	execCustomerCreationSQL(t, ctx, pool, "ALTER TABLE billing_customer_creations DROP CONSTRAINT reject_customer_at_commit")
	if err := recordStripeCustomer(ctx, pool, creation, customer); err != nil {
		t.Fatalf("must allow the same result to be retried after rollback: %v", err)
	}
	creation.StripeCustomerID = &customer.ID
	assertStoredCustomerCreation(t, ctx, pool, creation)
}

func TestRecordStripeCustomerCanceled(t *testing.T) {
	ctx, pool, creation := newCustomerCreationResultTestDB(t, false)
	canceled, cancel := context.WithCancel(ctx)
	cancel()

	err := recordStripeCustomer(canceled, pool, creation, customerForCreation(creation, "cus_team1"))

	if !errors.Is(err, context.Canceled) {
		t.Fatalf("want cancellation, got %v", err)
	}
	assertStoredCustomerCreation(t, ctx, pool, creation)
}

func newCustomerCreationResultTestDB(t *testing.T, livemode bool) (context.Context, *pgxpool.Pool, customerCreation) {
	t.Helper()
	ctx, pool := newCustomerCreationTestDB(t)
	creation, err := ensureCustomerCreation(ctx, pool, "team-1", livemode)
	if err != nil {
		t.Fatal(err)
	}
	return ctx, pool, *creation
}

func customerForCreation(creation customerCreation, id string) *stripe.Customer {
	return &stripe.Customer{
		ID:       id,
		Metadata: map[string]string{"team_id": creation.TeamID},
		Livemode: creation.Livemode,
	}
}

func assertStoredCustomerCreation(t *testing.T, ctx context.Context, pool *pgxpool.Pool, want customerCreation) {
	t.Helper()
	got := readCustomerCreation(t, ctx, pool, want.TeamID)
	if !reflect.DeepEqual(*got, want) {
		t.Fatalf("unexpected stored intent: want=%+v, got=%+v", want, got)
	}
}
