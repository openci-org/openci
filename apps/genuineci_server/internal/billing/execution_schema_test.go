package billing

import (
	"context"
	"errors"
	"testing"

	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
)

func TestExecutionSchemaRetainsRecordsAcrossCleanupAndRestart(t *testing.T) {
	ctx, pool := newExecutionTestDB(t)
	execCheckoutCreationSQL(t, ctx, pool, `
		INSERT INTO billing_executions
			(run_id, team_id, job_id, worker_host, period_id, started_at_ms, observed_at_ms, lease_until_ms, finished_at_ms, outcome)
		VALUES ('run-1', 'team-1', 'job-1', 'worker-1', 'paid-1', 1000, 2500, 60000, 2500, 'success');
		CREATE TABLE build_jobs (id text PRIMARY KEY);
		CREATE TABLE build_runs (id text PRIMARY KEY);
		INSERT INTO build_jobs VALUES ('job-1');
		INSERT INTO build_runs VALUES ('run-1');
		DELETE FROM build_runs;
		DELETE FROM build_jobs;
		DELETE FROM teams WHERE id = 'team-1'
	`)
	if err := EnsureExecutionsTable(ctx, pool); err != nil {
		t.Fatal(err)
	}
	var duration int64
	if err := pool.QueryRow(ctx, `
		SELECT finished_at_ms - started_at_ms FROM billing_executions
		WHERE run_id = 'run-1' AND team_id = 'team-1' AND outcome = 'success'
	`).Scan(&duration); err != nil || duration != 1500 {
		t.Fatalf("measured time and identity must survive ordinary cleanup: duration=%d, err=%v", duration, err)
	}
}

func TestExecutionSchemaRejectsInvalidLifecycle(t *testing.T) {
	ctx, pool := newExecutionTestDB(t)
	execCheckoutCreationSQL(t, ctx, pool, `
		INSERT INTO billing_executions
			(run_id, team_id, job_id, worker_host, period_id, started_at_ms, observed_at_ms, lease_until_ms)
		VALUES ('run-1', 'team-1', 'job-1', 'worker-1', 'paid-1', 1000, 2000, 60000)
	`)
	for _, tc := range []struct{ name, sql, code string }{
		{"duplicate attempt", "INSERT INTO billing_executions SELECT * FROM billing_executions", "23505"},
		{"observation before start", "UPDATE billing_executions SET observed_at_ms = 999", "23514"},
		{"lease before observation", "UPDATE billing_executions SET lease_until_ms = 1999", "23514"},
		{"finish after measurement", "UPDATE billing_executions SET finished_at_ms = 3000, outcome = 'success'", "23514"},
		{"outcome without finish", "UPDATE billing_executions SET outcome = 'success'", "23514"},
		{"finish without outcome", "UPDATE billing_executions SET finished_at_ms = 2000", "23514"},
		{"unsupported outcome", "UPDATE billing_executions SET finished_at_ms = 2000, outcome = 'skipped'", "23514"},
		{"abandoned must be incomplete", "UPDATE billing_executions SET finished_at_ms = 2000, outcome = 'abandoned'", "23514"},
		{"unfinished must not be marked incomplete", "UPDATE billing_executions SET measurement_incomplete = true", "23514"},
		{"another team's period", "UPDATE billing_executions SET period_id = 'paid-2'", "23503"},
		{"missing account", "UPDATE billing_executions SET team_id = 'missing'", "23503"},
		{"missing period", "UPDATE billing_executions SET period_id = 'missing'", "23503"},
		{"account retention", "DELETE FROM billing_accounts WHERE team_id = 'team-1'", "23503"},
		{"period retention", "DELETE FROM billing_periods WHERE id = 'paid-1'", "23503"},
	} {
		t.Run(tc.name, func(t *testing.T) {
			_, err := pool.Exec(ctx, tc.sql)
			var pgErr *pgconn.PgError
			if !errors.As(err, &pgErr) || pgErr.Code != tc.code {
				t.Fatalf("want database constraint %s, got %v", tc.code, err)
			}
		})
	}
}

func TestExecutionSchemaRollsBackWithoutPeriods(t *testing.T) {
	ctx, pool := newCheckoutCreationSchemaTestDB(t)
	if err := EnsureExecutionsTable(ctx, pool); err == nil {
		t.Fatal("period storage must exist before ledger creation")
	}
	var absent bool
	if err := pool.QueryRow(ctx, "SELECT to_regclass('billing_executions') IS NULL").Scan(&absent); err != nil || !absent {
		t.Fatal("failed schema creation must not leave a partial ledger")
	}
}

func newExecutionTestDB(t *testing.T) (context.Context, *pgxpool.Pool) {
	t.Helper()
	ctx, pool := newStripeStateTestDB(t)
	execCheckoutCreationSQL(t, ctx, pool, `
		INSERT INTO billing_periods (id, team_id, plan_id, period_type, starts_at, ends_at, allowance_seconds)
		VALUES ('paid-1', 'team-1', 'light', 'paid', 0, 1000, 36000),
			('paid-2', 'team-2', 'pro', 'paid', 0, 1000, 360000)
	`)
	if err := EnsureExecutionsTable(ctx, pool); err != nil {
		t.Fatal(err)
	}
	return ctx, pool
}
