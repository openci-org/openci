package billing

import (
	"context"
	"crypto/rand"
	"errors"
	"os"
	"testing"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
)

func TestEnsureCheckoutCreationsTablePreservesRecords(t *testing.T) {
	ctx, pool := newCheckoutCreationSchemaTestDB(t)
	seedCheckoutCreationRecords(t, ctx, pool)
	want := checkoutCreationRecords(t, ctx, pool)
	pool.Reset()

	if err := EnsureCheckoutCreationsTable(ctx, pool); err != nil {
		t.Fatal(err)
	}

	if got := checkoutCreationRecords(t, ctx, pool); got != want {
		t.Fatalf("reinitialization must preserve pending, open, and closed records: want %s, got %s", want, got)
	}
}

func TestCheckoutCreationTableConstraints(t *testing.T) {
	ctx, pool := newCheckoutCreationSchemaTestDB(t)
	seedCheckoutCreationRecords(t, ctx, pool)
	for _, tc := range []struct{ name, sql, code string }{
		{"duplicate key", "UPDATE billing_checkout_creations SET idempotency_key = 'closed-2' WHERE idempotency_key = 'pending-1'", "23505"},
		{"another unfinished Checkout for the team", "UPDATE billing_checkout_creations SET team_id = 'team-1' WHERE idempotency_key = 'pending-3'", "23505"},
		{"reuse a Session from a closed record", "UPDATE billing_checkout_creations SET stripe_checkout_session_id = 'cs_closed' WHERE idempotency_key = 'pending-1'", "23505"},
		{"reopen while another Checkout exists", "UPDATE billing_checkout_creations SET closed_at = NULL WHERE idempotency_key = 'closed-2'", "23505"},
		{"missing account", "UPDATE billing_checkout_creations SET team_id = 'missing' WHERE idempotency_key = 'pending-1'", "23503"},
		{"missing Price for retry", "UPDATE billing_checkout_creations SET stripe_price_id = NULL WHERE idempotency_key = 'pending-1'", "23502"},
		{"delete billing identity", "DELETE FROM billing_accounts WHERE team_id = 'team-1'", "23503"},
	} {
		t.Run(tc.name, func(t *testing.T) {
			_, err := pool.Exec(ctx, tc.sql)

			var pgErr *pgconn.PgError
			if !errors.As(err, &pgErr) || pgErr.Code != tc.code {
				t.Fatalf("want constraint error %s, got %v", tc.code, err)
			}
		})
	}
}

func TestCheckoutCreationTableRetainsHistoryWhenStartingAgain(t *testing.T) {
	ctx, pool := newCheckoutCreationSchemaTestDB(t)
	seedCheckoutCreationRecords(t, ctx, pool)
	execCheckoutCreationSQL(t, ctx, pool, `
		UPDATE billing_checkout_creations SET closed_at = 1800000100 WHERE idempotency_key = 'open-2'
	`)

	execCheckoutCreationSQL(t, ctx, pool, `
		INSERT INTO billing_checkout_creations
			(idempotency_key, team_id, plan_id, stripe_customer_id, stripe_price_id,
			 success_url, cancel_url, livemode, created_at)
		VALUES ('next-2', 'team-2', 'pro', 'cus_team-2', 'price_pro',
			'https://app.example.com/billing?checkout=success',
			'https://app.example.com/billing?checkout=cancel', true, 1800000200)
	`)

	var history, unfinished int
	err := pool.QueryRow(ctx, `
		SELECT count(*), count(*) FILTER (WHERE closed_at IS NULL)
		FROM billing_checkout_creations WHERE team_id = 'team-2'
	`).Scan(&history, &unfinished)
	if err != nil || history != 3 || unfinished != 1 {
		t.Fatalf("want two historical records and one unfinished Checkout: history=%d, unfinished=%d, err=%v", history, unfinished, err)
	}
}

func TestEnsureCheckoutCreationsTableConcurrent(t *testing.T) {
	ctx, pool := newCheckoutCreationSchemaTestDB(t)
	blocker, err := pool.Begin(ctx)
	if err != nil {
		t.Fatal(err)
	}
	defer blocker.Rollback(ctx)
	if _, err := blocker.Exec(ctx, `
		SELECT pg_advisory_xact_lock(hashtext(current_schema()), hashtext('genuineci_billing_schema'))
	`); err != nil {
		t.Fatal(err)
	}
	results := make(chan error, 2)
	for range 2 {
		go func() { results <- EnsureCheckoutCreationsTable(ctx, pool) }()
	}
	waitForBillingLocks(t, ctx, pool, 2)
	if err := blocker.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	for range 2 {
		if err := <-results; err != nil {
			t.Fatalf("concurrent initialization must succeed: %v", err)
		}
	}
}

func TestEnsureCheckoutCreationsTableRequiresBillingAccounts(t *testing.T) {
	ctx, pool := newCheckoutCreationSchemaTestDB(t)
	execCheckoutCreationSQL(t, ctx, pool, "DROP TABLE billing_accounts")

	err := EnsureCheckoutCreationsTable(ctx, pool)

	var pgErr *pgconn.PgError
	if !errors.As(err, &pgErr) || pgErr.Code != "42P01" {
		t.Fatalf("want missing billing_accounts error, got %v", err)
	}
	var absent bool
	err = pool.QueryRow(ctx, `
		SELECT to_regclass('billing_checkout_creations') IS NULL
			AND to_regclass('billing_checkout_creations_open_team') IS NULL
	`).Scan(&absent)
	if err != nil || !absent {
		t.Fatalf("failed initialization must leave no table or index: absent=%v, err=%v", absent, err)
	}
	execCheckoutCreationSQL(t, ctx, pool, "CREATE TABLE billing_accounts (team_id text PRIMARY KEY)")
	if err := EnsureCheckoutCreationsTable(ctx, pool); err != nil {
		t.Fatalf("initialization must allow retry after rollback: %v", err)
	}
}

func TestEnsureCheckoutCreationsTableHonorsCancellation(t *testing.T) {
	ctx, pool := newCheckoutCreationSchemaTestDB(t)
	canceled, cancel := context.WithCancel(ctx)
	cancel()

	if err := EnsureCheckoutCreationsTable(canceled, pool); !errors.Is(err, context.Canceled) {
		t.Fatalf("want cancellation error, got %v", err)
	}
}

func newCheckoutCreationSchemaTestDB(t *testing.T) (context.Context, *pgxpool.Pool) {
	t.Helper()
	databaseURL := os.Getenv("OPENCI_TEST_DATABASE_URL")
	if databaseURL == "" {
		t.Skip("Set OPENCI_TEST_DATABASE_URL to run PostgreSQL tests")
	}
	ctx, cancel := context.WithTimeout(t.Context(), 15*time.Second)
	t.Cleanup(cancel)
	config, err := pgxpool.ParseConfig(databaseURL)
	if err != nil {
		t.Fatal(err)
	}
	schema := pgx.Identifier{"billing_checkout_schema_" + rand.Text()}.Sanitize()
	config.MaxConns = 4
	config.ConnConfig.RuntimeParams["search_path"] = schema
	config.ConnConfig.RuntimeParams["application_name"] = schema
	pool, err := pgxpool.NewWithConfig(ctx, config)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(pool.Close)
	execCheckoutCreationSQL(t, ctx, pool, "CREATE SCHEMA "+schema)
	t.Cleanup(func() {
		cancel()
		cleanup, stop := context.WithTimeout(context.Background(), 5*time.Second)
		defer stop()
		if _, err := pool.Exec(cleanup, "DROP SCHEMA "+schema+" CASCADE"); err != nil {
			t.Error(err)
		}
	})
	execCheckoutCreationSQL(t, ctx, pool, `
		CREATE TABLE billing_accounts (team_id text PRIMARY KEY);
		INSERT INTO billing_accounts VALUES ('team-1'), ('team-2'), ('team-3')
	`)
	return ctx, pool
}

func seedCheckoutCreationRecords(t *testing.T, ctx context.Context, pool *pgxpool.Pool) {
	t.Helper()
	if err := EnsureCheckoutCreationsTable(ctx, pool); err != nil {
		t.Fatal(err)
	}
	closedAt := int64(1800000050)
	for _, row := range []struct {
		key, teamID, sessionID string
		livemode               bool
		closedAt               *int64
	}{
		{"pending-1", "team-1", "", false, nil},
		{"pending-3", "team-3", "", false, nil},
		{"open-2", "team-2", "cs_open", true, nil},
		{"closed-2", "team-2", "cs_closed", true, &closedAt},
	} {
		execCheckoutCreationSQL(t, ctx, pool, `
			INSERT INTO billing_checkout_creations
				(idempotency_key, team_id, plan_id, stripe_customer_id, stripe_price_id,
				 success_url, cancel_url, livemode, created_at, stripe_checkout_session_id, closed_at)
			VALUES ($1, $2, 'light', $3, 'price_light',
				'https://app.example.com/billing?checkout=success',
				'https://app.example.com/billing?checkout=cancel', $4, 1800000000, NULLIF($5, ''), $6)
		`, row.key, row.teamID, "cus_"+row.teamID, row.livemode, row.sessionID, row.closedAt)
	}
}

func checkoutCreationRecords(t *testing.T, ctx context.Context, pool *pgxpool.Pool) string {
	t.Helper()
	var records string
	err := pool.QueryRow(ctx, `
		SELECT jsonb_agg(to_jsonb(creation) ORDER BY idempotency_key)::text
		FROM billing_checkout_creations AS creation
	`).Scan(&records)
	if err != nil {
		t.Fatal(err)
	}
	return records
}

func execCheckoutCreationSQL(t *testing.T, ctx context.Context, pool *pgxpool.Pool, sql string, args ...any) {
	t.Helper()
	if _, err := pool.Exec(ctx, sql, args...); err != nil {
		t.Fatal(err)
	}
}
