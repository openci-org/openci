package billing

import (
	"context"
	"errors"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/stripe/stripe-go/v87"
)

func recordStripeCustomer(ctx context.Context, pool *pgxpool.Pool, creation customerCreation, customer *stripe.Customer) error {
	available := customer != nil && customer.ID != "" && !customer.Deleted
	if !available {
		return errors.New("Stripe Customer is not available")
	}
	matchesIntent := customer.Metadata["team_id"] == creation.TeamID &&
		customer.Livemode == creation.Livemode
	if !matchesIntent {
		return errors.New("Stripe Customer does not match the creation intent")
	}

	return withBillingAccountLock(ctx, pool, creation.TeamID, func(tx pgx.Tx, account *billingAccount) error {
		result, err := tx.Exec(ctx, `
			UPDATE billing_customer_creations SET stripe_customer_id = $4
			WHERE team_id = $1 AND idempotency_key = $2 AND livemode = $3
				AND (stripe_customer_id IS NULL OR stripe_customer_id = $4)
		`, account.TeamID, creation.IdempotencyKey, creation.Livemode, customer.ID)
		if err != nil {
			return err
		}
		if result.RowsAffected() != 1 {
			return errors.New("Stripe Customer creation intent is missing, changed, or already linked")
		}
		return nil
	})
}
