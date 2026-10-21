package main

import (
	"context"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

func ensureBillingTrialClaimsTable(ctx context.Context, pool *pgxpool.Pool) error {
	return pgx.BeginFunc(ctx, pool, func(tx pgx.Tx) error {
		// Serialize schema creation when multiple servers start at the same time.
		if _, err := tx.Exec(ctx, `
			SELECT pg_advisory_xact_lock(hashtext(current_schema()), hashtext('genuineci_billing_schema'))
		`); err != nil {
			return err
		}
		_, err := tx.Exec(ctx, `
			CREATE TABLE IF NOT EXISTS billing_trial_claims (
				user_id text PRIMARY KEY,
				team_id text NOT NULL UNIQUE REFERENCES billing_accounts(team_id),
				claimed_at bigint NOT NULL
			)
		`)
		return err
	})
}
