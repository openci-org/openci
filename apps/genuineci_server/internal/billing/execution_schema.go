package billing

import (
	"context"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

func EnsureExecutionsTable(ctx context.Context, pool *pgxpool.Pool) error {
	return pgx.BeginFunc(ctx, pool, func(tx pgx.Tx) error {
		if _, err := tx.Exec(ctx, `
			SELECT pg_advisory_xact_lock(hashtext(current_schema()), hashtext('genuineci_billing_schema'))
		`); err != nil {
			return err
		}
		_, err := tx.Exec(ctx, `
			CREATE UNIQUE INDEX IF NOT EXISTS billing_periods_id_team
				ON billing_periods (id, team_id);
			CREATE TABLE IF NOT EXISTS billing_executions (
				run_id text PRIMARY KEY CHECK (run_id <> ''),
				team_id text NOT NULL REFERENCES billing_accounts(team_id),
				job_id text NOT NULL CHECK (job_id <> ''),
				worker_host text NOT NULL CHECK (worker_host <> ''),
				period_id text NOT NULL,
				started_at_ms bigint NOT NULL,
				observed_at_ms bigint NOT NULL,
				lease_until_ms bigint NOT NULL,
				finished_at_ms bigint,
				outcome text CHECK (outcome IN ('success', 'failure', 'cancelled', 'timed_out', 'abandoned')),
				measurement_incomplete boolean NOT NULL DEFAULT false,
				FOREIGN KEY (period_id, team_id) REFERENCES billing_periods(id, team_id),
				CHECK (observed_at_ms >= started_at_ms),
				CHECK (lease_until_ms >= observed_at_ms),
				CHECK (finished_at_ms IS NULL OR finished_at_ms = observed_at_ms),
				CHECK ((finished_at_ms IS NULL) = (outcome IS NULL)),
				CHECK (measurement_incomplete = (outcome IS NOT DISTINCT FROM 'abandoned'))
			);
			CREATE INDEX IF NOT EXISTS billing_executions_team_start
				ON billing_executions (team_id, started_at_ms);
			CREATE INDEX IF NOT EXISTS billing_executions_unfinished_lease
				ON billing_executions (lease_until_ms) WHERE finished_at_ms IS NULL
		`)
		return err
	})
}
