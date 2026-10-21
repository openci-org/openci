package billing

import (
	"context"
	"crypto/rand"
	"errors"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type customerCreation struct {
	TeamID           string
	IdempotencyKey   string
	Livemode         bool
	CreatedAt        time.Time
	StripeCustomerID *string
}

func ensureCustomerCreation(ctx context.Context, pool *pgxpool.Pool, teamID string, livemode bool) (*customerCreation, error) {
	var creation customerCreation
	err := withBillingAccountLock(ctx, pool, teamID, func(tx pgx.Tx, account *billingAccount) error {
		_, err := tx.Exec(ctx, `
			INSERT INTO billing_customer_creations (team_id, idempotency_key, livemode, created_at)
			VALUES ($1, $2, $3, $4)
			ON CONFLICT (team_id) DO NOTHING
		`, account.TeamID, rand.Text(), livemode, time.Now().Unix())
		if err != nil {
			return err
		}

		var createdAt int64
		err = tx.QueryRow(ctx, `
			SELECT team_id, idempotency_key, livemode, created_at, stripe_customer_id
			FROM billing_customer_creations WHERE team_id = $1
		`, account.TeamID).Scan(
			&creation.TeamID, &creation.IdempotencyKey, &creation.Livemode,
			&createdAt, &creation.StripeCustomerID,
		)
		if err != nil {
			return err
		}
		if creation.Livemode != livemode {
			return errors.New("Stripe Customer creation mode does not match the configured mode")
		}
		creation.CreatedAt = time.Unix(createdAt, 0).UTC()
		return nil
	})
	if err != nil {
		return nil, err
	}
	return &creation, nil
}
