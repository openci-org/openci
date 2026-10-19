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
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
)

func TestWithBillingAccountLock(t *testing.T) {
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
	schema := pgx.Identifier{"billing_lock_" + rand.Text()}.Sanitize()
	config.MaxConns = 4
	config.ConnConfig.RuntimeParams["search_path"] = schema
	config.ConnConfig.RuntimeParams["application_name"] = schema
	pool, err := pgxpool.NewWithConfig(ctx, config)
	if err != nil {
		t.Fatal(err)
	}
	defer pool.Close()
	if _, err := pool.Exec(ctx, "CREATE SCHEMA "+schema); err != nil {
		t.Fatal(err)
	}
	defer func() {
		cancel()
		cleanup, stop := context.WithTimeout(context.Background(), 5*time.Second)
		defer stop()
		if _, err := pool.Exec(cleanup, "DROP SCHEMA "+schema+" CASCADE"); err != nil {
			t.Error(err)
		}
	}()
	_, err = pool.Exec(ctx, `
		CREATE TABLE teams (id text PRIMARY KEY);
		CREATE TABLE billing_accounts (team_id text PRIMARY KEY);
		CREATE TABLE billing_actions (team_id text);
		INSERT INTO teams VALUES ('team-1'), ('team-2'), ('uninitialized'), ('deleted');
		INSERT INTO billing_accounts VALUES ('team-1'), ('team-2'), ('retained'), ('deleted');
	`)
	if err != nil {
		t.Fatal(err)
	}
	record := func(tx pgx.Tx, account *billingAccount) error {
		_, err := tx.Exec(ctx, "INSERT INTO billing_actions VALUES ($1)", account.TeamID)
		return err
	}

	for _, teamID := range []string{"missing", "retained", "uninitialized", "team-1' OR true --"} {
		called := false
		err := withBillingAccountLock(ctx, pool, teamID, func(pgx.Tx, *billingAccount) error {
			called = true
			return nil
		})
		if !errors.Is(err, pgx.ErrNoRows) || called {
			t.Fatalf("must reject team %q before action: called=%v, err=%v", teamID, called, err)
		}
	}

	failure := errors.New("action failed")
	for _, actionErr := range []error{nil, failure} {
		err := withBillingAccountLock(ctx, pool, "team-1", func(tx pgx.Tx, account *billingAccount) error {
			if account.TeamID != "team-1" {
				return fmt.Errorf("unexpected account: %+v", account)
			}
			lockErr := pgx.BeginFunc(ctx, pool, func(other pgx.Tx) error {
				_, err := other.Exec(ctx, "SELECT team_id FROM billing_accounts WHERE team_id = 'team-1' FOR UPDATE NOWAIT")
				return err
			})
			var pgErr *pgconn.PgError
			if !errors.As(lockErr, &pgErr) || pgErr.Code != "55P03" {
				return fmt.Errorf("account must stay locked during action: %v", lockErr)
			}
			if err := record(tx, account); err != nil {
				return err
			}
			return actionErr
		})
		if !errors.Is(err, actionErr) {
			t.Fatalf("want action error %v, got %v", actionErr, err)
		}
		var count int
		if err := pool.QueryRow(ctx, "SELECT count(*) FROM billing_actions").Scan(&count); err != nil || count != 1 {
			t.Fatalf("only the successful action should commit: count=%d, err=%v", count, err)
		}
	}

	blocker, err := pool.Begin(ctx)
	if err != nil {
		t.Fatal(err)
	}
	defer blocker.Rollback(ctx)
	if _, err := blocker.Exec(ctx, "SELECT team_id FROM billing_accounts WHERE team_id = 'team-1' FOR UPDATE"); err != nil {
		t.Fatal(err)
	}
	results := make(chan error, 1)
	go func() { results <- withBillingAccountLock(ctx, pool, "team-1", record) }()
	waitForBillingLocks(t, ctx, pool, 1)
	if err := withBillingAccountLock(ctx, pool, "team-2", record); err != nil {
		t.Fatalf("another team must not be blocked: %v", err)
	}
	if err := blocker.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	if err := <-results; err != nil {
		t.Fatal(err)
	}

	deleter, err := pool.Begin(ctx)
	if err != nil {
		t.Fatal(err)
	}
	defer deleter.Rollback(ctx)
	if _, err := deleter.Exec(ctx, "DELETE FROM teams WHERE id = 'deleted'"); err != nil {
		t.Fatal(err)
	}
	go func() { results <- withBillingAccountLock(ctx, pool, "deleted", record) }()
	waitForBillingLocks(t, ctx, pool, 1)
	if err := deleter.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	if err := <-results; !errors.Is(err, pgx.ErrNoRows) {
		t.Fatalf("want missing team after concurrent deletion, got %v", err)
	}
	var accounts, actions int
	err = pool.QueryRow(ctx, `
		SELECT (SELECT count(*) FROM billing_accounts), (SELECT count(*) FROM billing_actions)
	`).Scan(&accounts, &actions)
	if err != nil || accounts != 4 || actions != 3 {
		t.Fatalf("want unchanged identities and three committed actions: accounts=%d, actions=%d, err=%v", accounts, actions, err)
	}
}
