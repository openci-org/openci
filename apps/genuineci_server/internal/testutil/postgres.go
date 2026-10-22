package testutil

import (
	"context"
	"crypto/rand"
	"os"
	"testing"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	billingschema "github.com/openci-org/openci/apps/genuineci_server/internal/billing/schema"
)

func NewCustomerCreationSchemaDB(t *testing.T) (context.Context, *pgxpool.Pool) {
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
	schema := pgx.Identifier{"billing_customer_schema_" + rand.Text()}.Sanitize()
	config.MaxConns = 4
	config.ConnConfig.RuntimeParams["search_path"] = schema
	config.ConnConfig.RuntimeParams["application_name"] = schema
	pool, err := pgxpool.NewWithConfig(ctx, config)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(pool.Close)
	ExecSQL(t, ctx, pool, "CREATE SCHEMA "+schema)
	t.Cleanup(func() {
		cancel()
		cleanup, stop := context.WithTimeout(context.Background(), 5*time.Second)
		defer stop()
		if _, err := pool.Exec(cleanup, "DROP SCHEMA "+schema+" CASCADE"); err != nil {
			t.Error(err)
		}
	})
	ExecSQL(t, ctx, pool, `
		CREATE TABLE billing_accounts (team_id text PRIMARY KEY);
		INSERT INTO billing_accounts VALUES ('team-1'), ('team-2'), ('team-3')
	`)
	return ctx, pool
}

func NewCheckoutCreationSchemaDB(t *testing.T) (context.Context, *pgxpool.Pool) {
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
	ExecSQL(t, ctx, pool, "CREATE SCHEMA "+schema)
	t.Cleanup(func() {
		cancel()
		cleanup, stop := context.WithTimeout(context.Background(), 5*time.Second)
		defer stop()
		if _, err := pool.Exec(cleanup, "DROP SCHEMA "+schema+" CASCADE"); err != nil {
			t.Error(err)
		}
	})
	ExecSQL(t, ctx, pool, `
		CREATE TABLE billing_accounts (team_id text PRIMARY KEY);
		INSERT INTO billing_accounts VALUES ('team-1'), ('team-2'), ('team-3')
	`)
	return ctx, pool
}

func ExecSQL(t *testing.T, ctx context.Context, pool *pgxpool.Pool, sql string, args ...any) {
	t.Helper()
	if _, err := pool.Exec(ctx, sql, args...); err != nil {
		t.Fatal(err)
	}
}

func WaitForLocks(t *testing.T, ctx context.Context, pool *pgxpool.Pool, want int) {
	t.Helper()
	for {
		var waiting int
		err := pool.QueryRow(ctx, `
			SELECT count(*) FROM pg_stat_activity
			WHERE application_name = current_setting('application_name') AND wait_event_type = 'Lock'
		`).Scan(&waiting)
		if err != nil {
			t.Fatal(err)
		}
		if waiting >= want {
			return
		}
		select {
		case <-ctx.Done():
			t.Fatal(ctx.Err())
		case <-time.After(time.Millisecond):
		}
	}
}

func NewCheckoutCreationDB(t *testing.T) (context.Context, *pgxpool.Pool) {
	t.Helper()
	ctx, pool := NewCheckoutCreationSchemaDB(t)
	ExecSQL(t, ctx, pool, `
		CREATE TABLE teams (id text PRIMARY KEY);
		INSERT INTO teams VALUES ('team-1'), ('team-2'), ('team-3')
	`)
	if err := billingschema.EnsureCheckoutCreationsTable(ctx, pool); err != nil {
		t.Fatal(err)
	}
	return ctx, pool
}

func NewBillingMemberDB(t *testing.T) (context.Context, *pgxpool.Pool) {
	t.Helper()
	ctx, pool := NewCheckoutCreationDB(t)
	ExecSQL(t, ctx, pool, `
		CREATE TABLE team_members (team_id text NOT NULL, user_id text NOT NULL, PRIMARY KEY(team_id, user_id));
		INSERT INTO team_members VALUES ('team-1', 'user-1'), ('team-1', 'user-2'), ('team-2', 'outsider')
	`)
	return ctx, pool
}

func NewStripeStateDB(t *testing.T) (context.Context, *pgxpool.Pool) {
	t.Helper()
	ctx, pool := NewBillingMemberDB(t)
	ExecSQL(t, ctx, pool, `
		CREATE TABLE billing_periods (
			id text PRIMARY KEY, team_id text NOT NULL REFERENCES billing_accounts(team_id),
			plan_id text NOT NULL, period_type text NOT NULL,
			starts_at bigint NOT NULL, ends_at bigint NOT NULL CHECK (ends_at > starts_at),
			allowance_seconds bigint
		)
	`)
	if err := billingschema.EnsureCustomerCreationsTable(ctx, pool); err != nil {
		t.Fatal(err)
	}
	if err := billingschema.EnsureStripeStateTables(ctx, pool); err != nil {
		t.Fatal(err)
	}
	if err := billingschema.EnsureExecutionsTable(ctx, pool); err != nil {
		t.Fatal(err)
	}
	if err := billingschema.EnsureAdmissionsTable(ctx, pool); err != nil {
		t.Fatal(err)
	}
	return ctx, pool
}

func NewExecutionDB(t *testing.T) (context.Context, *pgxpool.Pool) {
	t.Helper()
	ctx, pool := NewStripeStateDB(t)
	ExecSQL(t, ctx, pool, `
		INSERT INTO billing_periods (id, team_id, plan_id, period_type, starts_at, ends_at, allowance_seconds)
		VALUES ('paid-1', 'team-1', 'light', 'paid', 0, 1000, 36000),
			('paid-2', 'team-2', 'pro', 'paid', 0, 1000, 360000)
	`)
	if err := billingschema.EnsureExecutionsTable(ctx, pool); err != nil {
		t.Fatal(err)
	}
	return ctx, pool
}

func NewAdmissionDB(t *testing.T) (context.Context, *pgxpool.Pool) {
	t.Helper()
	ctx, pool := NewExecutionDB(t)
	if err := billingschema.EnsureAdmissionsTable(ctx, pool); err != nil {
		t.Fatal(err)
	}
	return ctx, pool
}

func CheckoutCreationRecords(t *testing.T, ctx context.Context, pool *pgxpool.Pool) string {
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
