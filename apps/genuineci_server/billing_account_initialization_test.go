package main

import (
	"context"
	"crypto/rand"
	"errors"
	"fmt"
	"os"
	"testing"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

func TestEnsureBillingAccount(t *testing.T) {
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
	schema := pgx.Identifier{"billing_init_" + rand.Text()}.Sanitize()
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
	exec(`
		CREATE TABLE teams (id text PRIMARY KEY);
		CREATE TABLE billing_accounts (team_id text PRIMARY KEY CHECK (team_id <> 'fail'));
		INSERT INTO teams VALUES ('team-1'), ('concurrent'), ('deleted'), ('fail');
		INSERT INTO billing_accounts VALUES ('retained');
	`)

	for range 2 {
		if account, err := ensureBillingAccount(ctx, pool, "team-1"); err != nil || account == nil || account.TeamID != "team-1" {
			t.Fatalf("initialization must be repeatable: account=%+v, err=%v", account, err)
		}
	}
	for _, teamID := range []string{"missing", "retained", "team-1' OR true --"} {
		if account, err := ensureBillingAccount(ctx, pool, teamID); account != nil || !errors.Is(err, pgx.ErrNoRows) {
			t.Fatalf("want missing team %q, got account=%+v, err=%v", teamID, account, err)
		}
	}

	blocker, err := pool.Begin(ctx)
	if err != nil {
		t.Fatal(err)
	}
	defer blocker.Rollback(ctx)
	if _, err := blocker.Exec(ctx, "SELECT id FROM teams WHERE id = 'concurrent' FOR UPDATE"); err != nil {
		t.Fatal(err)
	}
	results := make(chan error, 2)
	for range 2 {
		go func() {
			account, err := ensureBillingAccount(ctx, pool, "concurrent")
			if err == nil && (account == nil || account.TeamID != "concurrent") {
				err = fmt.Errorf("unexpected account: %+v", account)
			}
			results <- err
		}()
	}
	waitForBillingLocks(t, ctx, pool, 2)
	if err := blocker.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	for range 2 {
		if err := <-results; err != nil {
			t.Fatal(err)
		}
	}

	deleter, err := pool.Begin(ctx)
	if err != nil {
		t.Fatal(err)
	}
	defer deleter.Rollback(ctx)
	if _, err := deleter.Exec(ctx, "DELETE FROM teams WHERE id = 'deleted'"); err != nil {
		t.Fatal(err)
	}
	go func() {
		_, err := ensureBillingAccount(ctx, pool, "deleted")
		results <- err
	}()
	waitForBillingLocks(t, ctx, pool, 1)
	if err := deleter.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	if err := <-results; !errors.Is(err, pgx.ErrNoRows) {
		t.Fatalf("want missing team after concurrent deletion, got %v", err)
	}

	if account, err := ensureBillingAccount(ctx, pool, "fail"); account != nil || err == nil {
		t.Fatalf("want insert error, got account=%+v, err=%v", account, err)
	}
	exec("ALTER TABLE billing_accounts DROP CONSTRAINT billing_accounts_team_id_check")
	if _, err := ensureBillingAccount(ctx, pool, "fail"); err != nil {
		t.Fatalf("failed initialization must release its locks: %v", err)
	}
	var count int
	if err := pool.QueryRow(ctx, "SELECT count(*) FROM billing_accounts").Scan(&count); err != nil || count != 4 {
		t.Fatalf("want retained, team-1, concurrent, and fail accounts: count=%d, err=%v", count, err)
	}
}

func waitForBillingLocks(t *testing.T, ctx context.Context, pool *pgxpool.Pool, want int) {
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
