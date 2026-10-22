package billing

import (
	"context"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

func EnsureAdmissionsTable(ctx context.Context, pool *pgxpool.Pool) error {
	return pgx.BeginFunc(ctx, pool, func(tx pgx.Tx) error {
		if _, err := tx.Exec(ctx, `
			SELECT pg_advisory_xact_lock(hashtext(current_schema()), hashtext('genuineci_billing_schema'))
		`); err != nil {
			return err
		}
		_, err := tx.Exec(ctx, `
			CREATE UNIQUE INDEX IF NOT EXISTS billing_periods_id_team ON billing_periods (id, team_id);
			CREATE TABLE IF NOT EXISTS billing_admissions (
				id text PRIMARY KEY CHECK (id <> ''),
				job_id text NOT NULL CHECK (job_id <> ''),
				team_id text NOT NULL REFERENCES billing_accounts(team_id),
				worker_host text NOT NULL CHECK (worker_host <> ''),
				period_id text NOT NULL,
				claimed_at_ms bigint NOT NULL,
				start_by_ms bigint NOT NULL,
				reserved_millis bigint NOT NULL CHECK (reserved_millis > 0),
				run_id text UNIQUE CHECK (run_id IS NULL OR run_id <> ''),
				closed_at_ms bigint,
				FOREIGN KEY (period_id, team_id) REFERENCES billing_periods(id, team_id),
				CHECK (start_by_ms > claimed_at_ms),
				CHECK (closed_at_ms IS NULL OR closed_at_ms >= claimed_at_ms)
			);
			CREATE UNIQUE INDEX IF NOT EXISTS billing_admissions_open_job
				ON billing_admissions(job_id) WHERE closed_at_ms IS NULL;
			CREATE INDEX IF NOT EXISTS billing_admissions_team_period
				ON billing_admissions(team_id, period_id) WHERE closed_at_ms IS NULL;
			CREATE INDEX IF NOT EXISTS billing_admissions_pending_start
				ON billing_admissions(start_by_ms) WHERE closed_at_ms IS NULL
		`)
		return err
	})
}
