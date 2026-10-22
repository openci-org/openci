package schema_test

import (
	"context"
	"errors"
	"testing"

	"github.com/jackc/pgx/v5/pgconn"
	billingschema "github.com/openci-org/openci/apps/genuineci_server/internal/billing/schema"
	"github.com/openci-org/openci/apps/genuineci_server/internal/testutil"
)

func TestEnsureCustomerCreationsTablePreservesRecords(t *testing.T) {
	ctx, pool := testutil.NewCustomerCreationSchemaDB(t)
	if err := billingschema.EnsureCustomerCreationsTable(ctx, pool); err != nil {
		t.Fatal(err)
	}
	testutil.ExecSQL(t, ctx, pool, `
		INSERT INTO billing_customer_creations VALUES
			('team-1', 'key-1', false, 1800000000, NULL),
			('team-2', 'key-2', true, 1800000001, NULL),
			('team-3', 'key-3', true, 1800000002, 'cus_team3')
	`)
	pool.Reset()

	if err := billingschema.EnsureCustomerCreationsTable(ctx, pool); err != nil {
		t.Fatal(err)
	}

	type record struct {
		teamID, key, customerID string
		livemode                bool
		createdAt               int64
	}
	for _, want := range []record{
		{"team-1", "key-1", "", false, 1800000000},
		{"team-2", "key-2", "", true, 1800000001},
		{"team-3", "key-3", "cus_team3", true, 1800000002},
	} {
		var got record
		err := pool.QueryRow(ctx, `
			SELECT team_id, idempotency_key, COALESCE(stripe_customer_id, ''), livemode, created_at
			FROM billing_customer_creations WHERE team_id = $1
		`, want.teamID).Scan(&got.teamID, &got.key, &got.customerID, &got.livemode, &got.createdAt)
		if err != nil {
			t.Fatal(err)
		}
		if got != want {
			t.Fatalf("reinitialization must preserve the creation record: want %+v, got %+v", want, got)
		}
	}
}

func TestCustomerCreationTableConstraints(t *testing.T) {
	ctx, pool := testutil.NewCustomerCreationSchemaDB(t)
	if err := billingschema.EnsureCustomerCreationsTable(ctx, pool); err != nil {
		t.Fatal(err)
	}
	testutil.ExecSQL(t, ctx, pool, `
		INSERT INTO billing_customer_creations VALUES ('team-1', 'key-1', false, 1000, 'cus_team1')
	`)
	for _, tc := range []struct{ name, sql, code string }{
		{"duplicate team", "INSERT INTO billing_customer_creations VALUES ('team-1', 'key-2', false, 2000, NULL)", "23505"},
		{"duplicate key", "INSERT INTO billing_customer_creations VALUES ('team-2', 'key-1', false, 2000, NULL)", "23505"},
		{"duplicate Customer", "INSERT INTO billing_customer_creations VALUES ('team-2', 'key-2', false, 2000, 'cus_team1')", "23505"},
		{"missing account", "INSERT INTO billing_customer_creations VALUES ('missing', 'key-2', false, 2000, NULL)", "23503"},
		{"null team", "INSERT INTO billing_customer_creations VALUES (NULL, 'key-2', false, 2000, NULL)", "23502"},
		{"null key", "INSERT INTO billing_customer_creations VALUES ('team-2', NULL, false, 2000, NULL)", "23502"},
		{"null mode", "INSERT INTO billing_customer_creations VALUES ('team-2', 'key-2', NULL, 2000, NULL)", "23502"},
		{"null timestamp", "INSERT INTO billing_customer_creations VALUES ('team-2', 'key-2', false, NULL, NULL)", "23502"},
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

func TestEnsureCustomerCreationsTableConcurrent(t *testing.T) {
	ctx, pool := testutil.NewCustomerCreationSchemaDB(t)
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
		go func() { results <- billingschema.EnsureCustomerCreationsTable(ctx, pool) }()
	}
	// Both initializers must wait for the shared schema lock before creating tables.
	testutil.WaitForLocks(t, ctx, pool, 2)
	if err := blocker.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	for range 2 {
		if err := <-results; err != nil {
			t.Fatalf("concurrent initialization must succeed: %v", err)
		}
	}
}

func TestEnsureCustomerCreationsTableRequiresBillingAccounts(t *testing.T) {
	ctx, pool := testutil.NewCustomerCreationSchemaDB(t)
	testutil.ExecSQL(t, ctx, pool, "DROP TABLE billing_accounts")

	err := billingschema.EnsureCustomerCreationsTable(ctx, pool)

	var pgErr *pgconn.PgError
	if !errors.As(err, &pgErr) || pgErr.Code != "42P01" {
		t.Fatalf("want missing billing_accounts error, got %v", err)
	}
	var absent bool
	if err := pool.QueryRow(ctx, "SELECT to_regclass('billing_customer_creations') IS NULL").Scan(&absent); err != nil || !absent {
		t.Fatalf("failed initialization must leave no table: absent=%v, err=%v", absent, err)
	}
	testutil.ExecSQL(t, ctx, pool, "CREATE TABLE billing_accounts (team_id text PRIMARY KEY)")
	if err := billingschema.EnsureCustomerCreationsTable(ctx, pool); err != nil {
		t.Fatalf("initialization must allow retry after rollback: %v", err)
	}
}

func TestEnsureCustomerCreationsTableHonorsCancellation(t *testing.T) {
	ctx, pool := testutil.NewCustomerCreationSchemaDB(t)
	canceled, cancel := context.WithCancel(ctx)
	cancel()

	if err := billingschema.EnsureCustomerCreationsTable(canceled, pool); !errors.Is(err, context.Canceled) {
		t.Fatalf("want cancellation error, got %v", err)
	}
}
