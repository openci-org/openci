package schema

import (
	"context"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

func EnsureCustomerCreationsTable(ctx context.Context, pool *pgxpool.Pool) error {
	return pgx.BeginFunc(ctx, pool, func(tx pgx.Tx) error {
		if _, err := tx.Exec(ctx, `
			SELECT pg_advisory_xact_lock(hashtext(current_schema()), hashtext('genuineci_billing_schema'))
		`); err != nil {
			return err
		}
		_, err := tx.Exec(ctx, `
			CREATE TABLE IF NOT EXISTS billing_customer_creations (
				team_id text PRIMARY KEY REFERENCES billing_accounts(team_id),
				idempotency_key text NOT NULL UNIQUE,
				livemode boolean NOT NULL,
				created_at bigint NOT NULL,
				stripe_customer_id text UNIQUE
			)
		`)
		return err
	})
}
