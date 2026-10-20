package main

import (
	"context"
	"crypto/rand"
	"errors"
	"os"
	"reflect"
	"testing"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

func TestCreateBillingPeriod(t *testing.T) {
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
	schema := pgx.Identifier{"billing_period_" + rand.Text()}.Sanitize()
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
		CREATE TABLE billing_accounts (team_id text PRIMARY KEY);
		INSERT INTO billing_accounts VALUES ('team-1'), ('team-2');
		CREATE TABLE billing_periods (
			id text PRIMARY KEY, team_id text NOT NULL REFERENCES billing_accounts(team_id),
			plan_id text NOT NULL CHECK (plan_id IN ('light', 'pro')),
			period_type text NOT NULL CHECK (period_type IN ('trial', 'paid')),
			starts_at bigint NOT NULL, ends_at bigint NOT NULL CHECK (ends_at > starts_at),
			allowance_seconds bigint CHECK (allowance_seconds IS NULL OR allowance_seconds >= 0),
			CHECK (period_type = 'trial' OR allowance_seconds IS NOT NULL)
		);
	`)
	if err != nil {
		t.Fatal(err)
	}
	create := func(period billingPeriod) error {
		return pgx.BeginFunc(ctx, pool, func(tx pgx.Tx) error {
			return createBillingPeriod(ctx, tx, period)
		})
	}
	assertPeriod := func(t *testing.T, want billingPeriod) {
		t.Helper()
		period, err := getBillingPeriod(ctx, pool, want.TeamID, want.ID)
		want.StartsAt, want.EndsAt = want.StartsAt.UTC(), want.EndsAt.UTC()
		if err != nil || period == nil || !reflect.DeepEqual(*period, want) {
			t.Fatalf("want %+v, got period=%+v, err=%v", want, period, err)
		}
	}
	allowance, updatedAllowance, zero := int64(36000), int64(360000), int64(0)
	startsAt := time.Date(2040, 10, 1, 9, 0, 0, 0, time.FixedZone("JST", 9*60*60))
	paid := billingPeriod{
		ID: "paid-1", TeamID: "team-1", PlanID: "light", PeriodType: "paid",
		StartsAt: startsAt, EndsAt: startsAt.AddDate(0, 1, 0), AllowanceSeconds: &allowance,
	}
	trial := paid
	trial.ID, trial.PlanID, trial.PeriodType, trial.AllowanceSeconds = "trial-1", "pro", "trial", nil
	trial.EndsAt = trial.StartsAt.Add(7 * 24 * time.Hour)
	trialZero := trial
	trialZero.ID, trialZero.AllowanceSeconds = "trial-zero", &zero
	for _, original := range []billingPeriod{paid, trial, trialZero} {
		t.Run(original.ID, func(t *testing.T) {
			if err := create(original); err != nil {
				t.Fatal(err)
			}
			assertPeriod(t, original)
			retry := original
			retry.PlanID, retry.PeriodType, retry.AllowanceSeconds = "pro", "paid", &updatedAllowance
			retry.StartsAt, retry.EndsAt = retry.StartsAt.AddDate(0, 1, 0), retry.EndsAt.AddDate(0, 1, 0)
			if err := create(retry); err != nil {
				t.Fatal(err)
			}
			assertPeriod(t, original)
		})
	}
	renewal := paid
	renewal.ID, renewal.PlanID, renewal.AllowanceSeconds = "paid-2", "pro", &updatedAllowance
	renewal.StartsAt, renewal.EndsAt = paid.EndsAt, paid.EndsAt.AddDate(0, 1, 0)
	if err := create(renewal); err != nil {
		t.Fatal(err)
	}
	assertPeriod(t, renewal)
	otherTeam := paid
	otherTeam.TeamID = "team-2"
	if err := create(otherTeam); err == nil {
		t.Fatal("must reject an ID already used by another team")
	}
	assertPeriod(t, paid)

	concurrent := paid
	concurrent.ID = "concurrent"
	blocker, err := pool.Begin(ctx)
	if err != nil {
		t.Fatal(err)
	}
	defer blocker.Rollback(ctx)
	if err := createBillingPeriod(ctx, blocker, concurrent); err != nil {
		t.Fatal(err)
	}
	retry := concurrent
	retry.AllowanceSeconds = &updatedAllowance
	results := make(chan error, 2)
	for range 2 {
		go func() { results <- create(retry) }()
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
	assertPeriod(t, concurrent)

	rolledBack := paid
	rolledBack.ID = "rolled-back"
	abort := errors.New("abort after period creation")
	err = pgx.BeginFunc(ctx, pool, func(tx pgx.Tx) error {
		if err := createBillingPeriod(ctx, tx, rolledBack); err != nil {
			return err
		}
		return abort
	})
	if !errors.Is(err, abort) {
		t.Fatalf("want rollback error, got %v", err)
	}
	negative := int64(-1)
	invalid := paid
	invalid.ID, invalid.AllowanceSeconds = "invalid", &negative
	if err := create(invalid); err == nil {
		t.Fatal("must propagate the database constraint error")
	}
	missingAccount := paid
	missingAccount.ID, missingAccount.TeamID = "missing-account", "missing"
	if err := create(missingAccount); err == nil {
		t.Fatal("must reject a missing billing account")
	}
	var count int
	if err := pool.QueryRow(ctx, "SELECT count(*) FROM billing_periods").Scan(&count); err != nil || count != 5 {
		t.Fatalf("want five periods without duplicates or rolled-back/invalid rows: count=%d, err=%v", count, err)
	}
}
