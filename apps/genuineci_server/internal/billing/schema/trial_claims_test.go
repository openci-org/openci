package schema_test

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
	billingschema "github.com/openci-org/openci/apps/genuineci_server/internal/billing/schema"
	"github.com/openci-org/openci/apps/genuineci_server/internal/testutil"
)

func TestEnsureBillingTrialClaimsTable(t *testing.T) {
	databaseURL := os.Getenv("OPENCI_TEST_DATABASE_URL")
	if databaseURL == "" {
		t.Skip("Set OPENCI_TEST_DATABASE_URL to run PostgreSQL tests")
	}
	ctx, cancel := context.WithTimeout(t.Context(), 15*time.Second)
	defer cancel()
	config, err := pgxpool.ParseConfig(databaseURL)
	if err != nil {
		t.Fatal(err)
	}
	schema := pgx.Identifier{"billing_claim_" + rand.Text()}.Sanitize()
	config.MaxConns = 4
	config.ConnConfig.RuntimeParams["search_path"] = schema
	config.ConnConfig.RuntimeParams["application_name"] = schema
	pool, err := pgxpool.NewWithConfig(ctx, config)
	if err != nil {
		t.Fatal(err)
	}
	defer pool.Close()
	exec := func(sql string) {
		t.Helper()
		if _, err := pool.Exec(ctx, sql); err != nil {
			t.Fatal(err)
		}
	}
	exec("CREATE SCHEMA " + schema)
	defer func() {
		cancel()
		cleanup, stop := context.WithTimeout(context.Background(), 5*time.Second)
		defer stop()
		if _, err := pool.Exec(cleanup, "DROP SCHEMA "+schema+" CASCADE"); err != nil {
			t.Error(err)
		}
	}()

	var pgErr *pgconn.PgError
	if err := billingschema.EnsureTrialClaimsTable(ctx, pool); !errors.As(err, &pgErr) || pgErr.Code != "42P01" {
		t.Fatalf("must reject missing billing_accounts: %v", err)
	}
	var absent bool
	if err := pool.QueryRow(ctx, "SELECT to_regclass('billing_trial_claims') IS NULL").Scan(&absent); err != nil || !absent {
		t.Fatalf("failed initialization must leave no table: absent=%v, err=%v", absent, err)
	}
	exec(`
		CREATE TABLE teams (id text PRIMARY KEY);
		CREATE TABLE billing_accounts (team_id text PRIMARY KEY);
		INSERT INTO teams VALUES ('team-1'), ('team-2');
		INSERT INTO billing_accounts VALUES ('team-1'), ('team-2');
	`)

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
		go func() { results <- billingschema.EnsureTrialClaimsTable(ctx, pool) }()
	}
	testutil.WaitForLocks(t, ctx, pool, 2)
	if err := blocker.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	for range 2 {
		if err := <-results; err != nil {
			t.Fatalf("concurrent initialization must succeed: %v", err)
		}
	}

	claimedAt := time.Date(2040, 10, 1, 9, 0, 0, 0, time.FixedZone("JST", 9*60*60))
	if _, err := pool.Exec(ctx, "INSERT INTO billing_trial_claims VALUES ($1, $2, $3)",
		"user-1", "team-1", claimedAt.Unix()); err != nil {
		t.Fatal(err)
	}
	for _, tc := range []struct{ name, sql, code string }{
		{"duplicate user", "INSERT INTO billing_trial_claims VALUES ('user-1', 'team-2', 0)", "23505"},
		{"duplicate team", "INSERT INTO billing_trial_claims VALUES ('user-2', 'team-1', 0)", "23505"},
		{"missing account", "INSERT INTO billing_trial_claims VALUES ('user-2', 'missing', 0)", "23503"},
		{"null user", "INSERT INTO billing_trial_claims VALUES (NULL, 'team-2', 0)", "23502"},
		{"null team", "INSERT INTO billing_trial_claims VALUES ('user-2', NULL, 0)", "23502"},
		{"null timestamp", "INSERT INTO billing_trial_claims VALUES ('user-2', 'team-2', NULL)", "23502"},
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
	exec(`
		INSERT INTO billing_trial_claims VALUES ('user-2', 'team-2', 0);
		DELETE FROM teams WHERE id = 'team-1';
	`)
	pool.Reset()
	if err := billingschema.EnsureTrialClaimsTable(ctx, pool); err != nil {
		t.Fatal(err)
	}
	var userID, teamID string
	var timestamp int64
	err = pool.QueryRow(ctx, `
		SELECT user_id, team_id, claimed_at FROM billing_trial_claims WHERE user_id = 'user-1'
	`).Scan(&userID, &teamID, &timestamp)
	if err != nil || userID != "user-1" || teamID != "team-1" || timestamp != claimedAt.Unix() {
		t.Fatalf("claim must survive team deletion and reinitialization: user=%q, team=%q, timestamp=%d, err=%v",
			userID, teamID, timestamp, err)
	}
	var accounts, claims int
	err = pool.QueryRow(ctx, `
		SELECT (SELECT count(*) FROM billing_accounts), (SELECT count(*) FROM billing_trial_claims)
	`).Scan(&accounts, &claims)
	if err != nil || accounts != 2 || claims != 2 {
		t.Fatalf("must retain accounts and claims: accounts=%d, claims=%d, err=%v", accounts, claims, err)
	}

	canceled, stop := context.WithCancel(ctx)
	stop()
	if err := billingschema.EnsureTrialClaimsTable(canceled, pool); !errors.Is(err, context.Canceled) {
		t.Fatalf("want cancellation error, got %v", err)
	}
}
