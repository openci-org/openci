package main

import (
	"context"
	"errors"
	"os"
	"testing"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

func TestGetBillingAccount(t *testing.T) {
	databaseURL := os.Getenv("OPENCI_TEST_DATABASE_URL")
	if databaseURL == "" {
		t.Skip("Set OPENCI_TEST_DATABASE_URL to run PostgreSQL tests")
	}
	ctx, cancel := context.WithTimeout(t.Context(), 10*time.Second)
	defer cancel()
	config, err := pgxpool.ParseConfig(databaseURL)
	if err != nil {
		t.Fatal(err)
	}
	// Keep the temporary table on one connection and exclude persistent schemas.
	config.MaxConns = 1
	config.ConnConfig.RuntimeParams["search_path"] = "pg_temp"
	pool, err := pgxpool.NewWithConfig(ctx, config)
	if err != nil {
		t.Fatal(err)
	}
	defer pool.Close()
	_, err = pool.Exec(ctx, `
		CREATE TEMP TABLE billing_accounts (team_id text PRIMARY KEY);
		INSERT INTO billing_accounts VALUES ('team-1'), ('team-2');
	`)
	if err != nil {
		t.Fatal(err)
	}

	for _, tc := range []struct{ teamID, want string }{
		{"team-1", "team-1"},
		{"team-2", "team-2"},
		{"missing", ""},
		{"team-1' OR true --", ""},
	} {
		t.Run(tc.teamID, func(t *testing.T) {
			account, err := getBillingAccount(ctx, pool, tc.teamID)
			if err != nil {
				t.Fatal(err)
			}
			if tc.want == "" {
				if account != nil {
					t.Fatalf("want no account, got %+v", account)
				}
			} else if account == nil || account.TeamID != tc.want {
				t.Fatalf("want team %q, got %+v", tc.want, account)
			}
		})
	}
	var count int
	if err := pool.QueryRow(ctx, "SELECT count(*) FROM billing_accounts").Scan(&count); err != nil || count != 2 {
		t.Fatalf("reads must not create accounts: count=%d, err=%v", count, err)
	}

	canceled, stop := context.WithCancel(ctx)
	stop()
	if account, err := getBillingAccount(canceled, pool, "team-1"); account != nil || !errors.Is(err, context.Canceled) {
		t.Fatalf("want cancellation error, got account=%+v, err=%v", account, err)
	}
	if _, err := pool.Exec(ctx, "DROP TABLE pg_temp.billing_accounts"); err != nil {
		t.Fatal(err)
	}
	if account, err := getBillingAccount(ctx, pool, "team-1"); account != nil || err == nil {
		t.Fatalf("want database error, got account=%+v, err=%v", account, err)
	}
}
