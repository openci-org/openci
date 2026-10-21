package billing

import (
	"context"
	"errors"
	"reflect"
	"testing"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
)

func TestEnsureCustomerCreationPersistsIntent(t *testing.T) {
	ctx, pool := newCustomerCreationTestDB(t)
	var previousKey string
	for _, tc := range []struct {
		teamID   string
		livemode bool
	}{
		{"team-1", false},
		{"team-2", true},
	} {
		before := time.Now().UTC().Truncate(time.Second)

		got, err := ensureCustomerCreation(ctx, pool, tc.teamID, tc.livemode)

		if err != nil || got == nil {
			t.Fatalf("want a saved intent: got=%+v, err=%v", got, err)
		}
		if got.TeamID != tc.teamID || got.Livemode != tc.livemode || got.StripeCustomerID != nil {
			t.Fatalf("want a pending intent for the requested team and mode, got %+v", got)
		}
		if got.IdempotencyKey == "" || got.IdempotencyKey == previousKey {
			t.Fatal("each team must receive a distinct nonempty key")
		}
		if got.CreatedAt.Before(before) || got.CreatedAt.After(time.Now()) || got.CreatedAt.Nanosecond() != 0 {
			t.Fatalf("want the current time in Unix seconds, got %v", got.CreatedAt)
		}
		stored := readCustomerCreation(t, ctx, pool, tc.teamID)
		if !reflect.DeepEqual(got, stored) {
			t.Fatalf("intent must be committed before returning: got=%+v, stored=%+v", got, stored)
		}
		previousKey = got.IdempotencyKey
	}
}

func TestEnsureCustomerCreationReusesStoredIntent(t *testing.T) {
	customerID := "cus_team1"
	for _, tc := range []struct {
		name       string
		customerID *string
	}{
		{"pending result", nil},
		{"recorded Customer", &customerID},
	} {
		t.Run(tc.name, func(t *testing.T) {
			ctx, pool := newCustomerCreationTestDB(t)
			_, err := pool.Exec(ctx, `
				INSERT INTO billing_customer_creations VALUES ('team-1', 'original-key', false, 1000, $1)
			`, tc.customerID)
			if err != nil {
				t.Fatal(err)
			}
			want := readCustomerCreation(t, ctx, pool, "team-1")
			pool.Reset()

			got, err := ensureCustomerCreation(ctx, pool, "team-1", false)

			if err != nil || !reflect.DeepEqual(got, want) {
				t.Fatalf("must reuse even an old intent after reconnect: want=%+v, got=%+v, err=%v", want, got, err)
			}
			if stored := readCustomerCreation(t, ctx, pool, "team-1"); !reflect.DeepEqual(stored, want) {
				t.Fatalf("must preserve the stored intent: want=%+v, got=%+v", want, stored)
			}
		})
	}
}

func TestEnsureCustomerCreationRejectsModeChange(t *testing.T) {
	ctx, pool := newCustomerCreationTestDB(t)
	execCustomerCreationSQL(t, ctx, pool, `
		INSERT INTO billing_customer_creations VALUES ('team-1', 'original-key', true, 1000, 'cus_team1')
	`)
	want := readCustomerCreation(t, ctx, pool, "team-1")

	got, err := ensureCustomerCreation(ctx, pool, "team-1", false)

	if got != nil || err == nil {
		t.Fatalf("mode mismatch must return no intent: got=%+v, err=%v", got, err)
	}
	got, err = ensureCustomerCreation(ctx, pool, "team-1", true)
	if err != nil || !reflect.DeepEqual(got, want) {
		t.Fatalf("mode mismatch must preserve the original intent: want=%+v, got=%+v, err=%v", want, got, err)
	}
}

func TestEnsureCustomerCreationRequiresLiveBillingAccount(t *testing.T) {
	for _, tc := range []struct{ name, sql string }{
		{"deleted team", "DELETE FROM teams WHERE id = 'team-1'"},
		{"uninitialized account", "DELETE FROM billing_accounts WHERE team_id = 'team-1'"},
	} {
		t.Run(tc.name, func(t *testing.T) {
			ctx, pool := newCustomerCreationTestDB(t)
			execCustomerCreationSQL(t, ctx, pool, tc.sql)

			got, err := ensureCustomerCreation(ctx, pool, "team-1", false)

			if got != nil || !errors.Is(err, pgx.ErrNoRows) {
				t.Fatalf("must require a current team and billing account: got=%+v, err=%v", got, err)
			}
			assertNoCustomerCreations(t, ctx, pool)
		})
	}
}

func TestEnsureCustomerCreationConcurrent(t *testing.T) {
	ctx, pool := newCustomerCreationTestDB(t)
	blocker, err := pool.Begin(ctx)
	if err != nil {
		t.Fatal(err)
	}
	defer blocker.Rollback(ctx)
	if _, err := blocker.Exec(ctx, "SELECT team_id FROM billing_accounts WHERE team_id = 'team-1' FOR UPDATE"); err != nil {
		t.Fatal(err)
	}
	type result struct {
		creation *customerCreation
		err      error
	}
	results := make(chan result, 2)
	for range 2 {
		go func() {
			creation, err := ensureCustomerCreation(ctx, pool, "team-1", false)
			results <- result{creation, err}
		}()
	}
	waitForBillingLocks(t, ctx, pool, 2)
	if err := blocker.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	var first *customerCreation
	for range 2 {
		got := <-results
		if got.err != nil || got.creation == nil {
			t.Fatalf("concurrent initialization must succeed: got=%+v, err=%v", got.creation, got.err)
		}
		if first == nil {
			first = got.creation
		} else if !reflect.DeepEqual(got.creation, first) {
			t.Fatalf("both callers must return the same intent: first=%+v, other=%+v", first, got.creation)
		}
	}
	if stored := readCustomerCreation(t, ctx, pool, "team-1"); !reflect.DeepEqual(first, stored) {
		t.Fatalf("both callers must use the committed intent: got=%+v, stored=%+v", first, stored)
	}
}

func TestEnsureCustomerCreationCommitFailure(t *testing.T) {
	ctx, pool := newCustomerCreationTestDB(t)
	// Let INSERT and SELECT succeed, then reject the key only at COMMIT.
	execCustomerCreationSQL(t, ctx, pool, `
		CREATE TABLE allowed_customer_keys (key text PRIMARY KEY);
		ALTER TABLE billing_customer_creations ADD CONSTRAINT reject_key_at_commit
			FOREIGN KEY (idempotency_key) REFERENCES allowed_customer_keys(key)
			DEFERRABLE INITIALLY DEFERRED
	`)

	got, err := ensureCustomerCreation(ctx, pool, "team-1", false)

	var pgErr *pgconn.PgError
	if got != nil || !errors.As(err, &pgErr) || pgErr.Code != "23503" {
		t.Fatalf("failed commit must return no usable key: got=%+v, err=%v", got, err)
	}
	assertNoCustomerCreations(t, ctx, pool)
	execCustomerCreationSQL(t, ctx, pool, "ALTER TABLE billing_customer_creations DROP CONSTRAINT reject_key_at_commit")
	if got, err := ensureCustomerCreation(ctx, pool, "team-1", false); err != nil || got == nil {
		t.Fatalf("must allow retry after rollback: got=%+v, err=%v", got, err)
	}
}

func TestEnsureCustomerCreationCanceled(t *testing.T) {
	ctx, pool := newCustomerCreationTestDB(t)
	canceled, cancel := context.WithCancel(ctx)
	cancel()

	got, err := ensureCustomerCreation(canceled, pool, "team-1", false)

	if got != nil || !errors.Is(err, context.Canceled) {
		t.Fatalf("canceled operation must return no intent: got=%+v, err=%v", got, err)
	}
	assertNoCustomerCreations(t, ctx, pool)
}

func newCustomerCreationTestDB(t *testing.T) (context.Context, *pgxpool.Pool) {
	t.Helper()
	ctx, pool := newCustomerCreationSchemaTestDB(t)
	execCustomerCreationSQL(t, ctx, pool, `
		CREATE TABLE teams (id text PRIMARY KEY);
		INSERT INTO teams VALUES ('team-1'), ('team-2'), ('team-3')
	`)
	if err := EnsureCustomerCreationsTable(ctx, pool); err != nil {
		t.Fatal(err)
	}
	return ctx, pool
}

func readCustomerCreation(t *testing.T, ctx context.Context, pool *pgxpool.Pool, teamID string) *customerCreation {
	t.Helper()
	var creation customerCreation
	var createdAt int64
	err := pool.QueryRow(ctx, `
		SELECT team_id, idempotency_key, livemode, created_at, stripe_customer_id
		FROM billing_customer_creations WHERE team_id = $1
	`, teamID).Scan(&creation.TeamID, &creation.IdempotencyKey, &creation.Livemode, &createdAt, &creation.StripeCustomerID)
	if err != nil {
		t.Fatal(err)
	}
	creation.CreatedAt = time.Unix(createdAt, 0).UTC()
	return &creation
}

func assertNoCustomerCreations(t *testing.T, ctx context.Context, pool *pgxpool.Pool) {
	t.Helper()
	var count int
	if err := pool.QueryRow(ctx, "SELECT count(*) FROM billing_customer_creations").Scan(&count); err != nil || count != 0 {
		t.Fatalf("want no creation intents: count=%d, err=%v", count, err)
	}
}
