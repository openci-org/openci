package billing

import (
	"context"
	"errors"
	"testing"

	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
)

func TestAdmissionSchemaRetainsClaimHistory(t *testing.T) {
	ctx, pool := newAdmissionTestDB(t)
	execCheckoutCreationSQL(t, ctx, pool, `
		INSERT INTO billing_admissions
			(id, job_id, team_id, worker_host, period_id, claimed_at_ms, start_by_ms, reserved_millis)
		VALUES ('first', 'job-1', 'team-1', 'worker-1', 'paid-1', 1000, 121000, 60000)
	`)
	if err := EnsureAdmissionsTable(ctx, pool); err != nil {
		t.Fatal(err)
	}
	for _, tc := range []struct {
		name, sql, code string
	}{
		{"second open claim", `INSERT INTO billing_admissions VALUES ('second', 'job-1', 'team-1', 'worker-2', 'paid-1', 2000, 122000, 1, NULL, NULL)`, "23505"},
		{"wrong period team", `INSERT INTO billing_admissions VALUES ('invalid', 'job-2', 'team-2', 'worker-1', 'paid-1', 2000, 122000, 1, NULL, NULL)`, "23503"},
		{"empty reservation", `UPDATE billing_admissions SET reserved_millis = 0`, "23514"},
		{"invalid deadline", `UPDATE billing_admissions SET start_by_ms = claimed_at_ms`, "23514"},
		{"invalid closure", `UPDATE billing_admissions SET closed_at_ms = claimed_at_ms - 1`, "23514"},
		{"account deletion", `DELETE FROM billing_accounts WHERE team_id = 'team-1'`, "23503"},
	} {
		t.Run(tc.name, func(t *testing.T) {
			_, err := pool.Exec(ctx, tc.sql)
			var pgErr *pgconn.PgError
			if !errors.As(err, &pgErr) || pgErr.Code != tc.code {
				t.Fatalf("want %s, got %v", tc.code, err)
			}
		})
	}
	execCheckoutCreationSQL(t, ctx, pool, `
		UPDATE billing_admissions SET closed_at_ms = 2000, run_id = 'run-1' WHERE id = 'first';
		INSERT INTO billing_admissions VALUES ('second', 'job-1', 'team-1', 'worker-2', 'paid-1', 3000, 123000, 60000, NULL, NULL)
	`)
	_, err := pool.Exec(ctx, `UPDATE billing_admissions SET run_id = 'run-1' WHERE id = 'second'`)
	var pgErr *pgconn.PgError
	if !errors.As(err, &pgErr) || pgErr.Code != "23505" {
		t.Fatal("a completed run must not be rebound to another claim")
	}
	var count int
	if err := pool.QueryRow(ctx, `SELECT count(*) FROM billing_admissions`).Scan(&count); err != nil || count != 2 {
		t.Fatal("closing a claim must retain its history and permit a new attempt")
	}
}

func TestAdmissionSchemaRollsBackMissingPeriods(t *testing.T) {
	ctx, pool := newCheckoutCreationSchemaTestDB(t)
	if err := EnsureAdmissionsTable(ctx, pool); err == nil {
		t.Fatal("paid-period storage is required")
	}
	var absent bool
	if err := pool.QueryRow(ctx, `SELECT to_regclass('billing_admissions') IS NULL`).Scan(&absent); err != nil || !absent {
		t.Fatal("failed initialization must not leave a partial admission table")
	}
}

func newAdmissionTestDB(t *testing.T) (context.Context, *pgxpool.Pool) {
	t.Helper()
	ctx, pool := newExecutionTestDB(t)
	if err := EnsureAdmissionsTable(ctx, pool); err != nil {
		t.Fatal(err)
	}
	return ctx, pool
}
