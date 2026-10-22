package schema

import (
	"context"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

func EnsureStripeStateTables(ctx context.Context, pool *pgxpool.Pool) error {
	return pgx.BeginFunc(ctx, pool, func(tx pgx.Tx) error {
		if _, err := tx.Exec(ctx, `
			SELECT pg_advisory_xact_lock(hashtext(current_schema()), hashtext('genuineci_billing_schema'))
		`); err != nil {
			return err
		}
		_, err := tx.Exec(ctx, `
			CREATE TABLE IF NOT EXISTS billing_stripe_state (
				team_id text PRIMARY KEY REFERENCES billing_accounts(team_id),
				stripe_customer_id text NOT NULL UNIQUE,
				livemode boolean NOT NULL,
				stripe_subscription_id text UNIQUE,
				subscription_status text NOT NULL,
				plan_id text CHECK (plan_id IN ('light', 'pro')),
				paid_period_id text REFERENCES billing_periods(id),
				cancel_at_period_end boolean NOT NULL DEFAULT false,
				synced_at bigint NOT NULL
			);
			CREATE TABLE IF NOT EXISTS billing_stripe_events (
				event_id text PRIMARY KEY,
				event_type text NOT NULL,
				event_created bigint NOT NULL,
				processed_at bigint NOT NULL
			)
		`)
		return err
	})
}
