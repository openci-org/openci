package schema

import (
	"context"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

func EnsureCheckoutCreationsTable(ctx context.Context, pool *pgxpool.Pool) error {
	return pgx.BeginFunc(ctx, pool, func(tx pgx.Tx) error {
		if _, err := tx.Exec(ctx, `
			SELECT pg_advisory_xact_lock(hashtext(current_schema()), hashtext('genuineci_billing_schema'))
		`); err != nil {
			return err
		}
		_, err := tx.Exec(ctx, `
			CREATE TABLE IF NOT EXISTS billing_checkout_creations (
				idempotency_key text PRIMARY KEY,
				team_id text NOT NULL REFERENCES billing_accounts(team_id),
				plan_id text NOT NULL,
				stripe_customer_id text NOT NULL,
				stripe_price_id text NOT NULL,
				success_url text NOT NULL,
				cancel_url text NOT NULL,
				livemode boolean NOT NULL,
				created_at bigint NOT NULL,
				stripe_checkout_session_id text UNIQUE,
				closed_at bigint
			);
			CREATE UNIQUE INDEX IF NOT EXISTS billing_checkout_creations_open_team
				ON billing_checkout_creations (team_id) WHERE closed_at IS NULL
		`)
		return err
	})
}
