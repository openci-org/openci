package billing

import (
	"context"
	"crypto/rand"
	"errors"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

var errCheckoutCreationConflict = errors.New("unfinished Checkout creation does not match the requested plan, Customer, or mode")

type checkoutCreationRequest struct {
	TeamID     string
	PlanID     string
	CustomerID string
	PriceID    string
	SuccessURL string
	CancelURL  string
	Livemode   bool
}

type checkoutCreation struct {
	Request                 checkoutCreationRequest
	IdempotencyKey          string
	CreatedAt               time.Time
	StripeCheckoutSessionID *string
}

func ensureCheckoutCreation(ctx context.Context, pool *pgxpool.Pool, request checkoutCreationRequest) (*checkoutCreation, error) {
	if _, err := getPaidBillingPlan(request.PlanID); err != nil {
		return nil, err
	}
	for _, value := range []string{request.TeamID, request.CustomerID, request.PriceID, request.SuccessURL, request.CancelURL} {
		if strings.TrimSpace(value) == "" {
			return nil, errors.New("Checkout creation requires a team, Customer, Price, and return URLs")
		}
	}

	var creation checkoutCreation
	err := withBillingAccountLock(ctx, pool, request.TeamID, func(tx pgx.Tx, account *billingAccount) error {
		_, err := tx.Exec(ctx, `
			INSERT INTO billing_checkout_creations
				(team_id, plan_id, stripe_customer_id, stripe_price_id, success_url, cancel_url,
				 livemode, idempotency_key, created_at)
			VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9)
			ON CONFLICT (team_id) WHERE closed_at IS NULL DO NOTHING
		`, account.TeamID, request.PlanID, request.CustomerID, request.PriceID,
			request.SuccessURL, request.CancelURL, request.Livemode, rand.Text(), time.Now().Unix())
		if err != nil {
			return err
		}

		var createdAt int64
		err = tx.QueryRow(ctx, `
			SELECT team_id, plan_id, stripe_customer_id, stripe_price_id, success_url, cancel_url,
				livemode, idempotency_key, created_at, stripe_checkout_session_id
			FROM billing_checkout_creations WHERE team_id = $1 AND closed_at IS NULL
		`, account.TeamID).Scan(
			&creation.Request.TeamID, &creation.Request.PlanID, &creation.Request.CustomerID,
			&creation.Request.PriceID, &creation.Request.SuccessURL, &creation.Request.CancelURL,
			&creation.Request.Livemode, &creation.IdempotencyKey, &createdAt, &creation.StripeCheckoutSessionID,
		)
		if err != nil {
			return err
		}
		matchesPurchase := creation.Request.PlanID == request.PlanID &&
			creation.Request.CustomerID == request.CustomerID &&
			creation.Request.Livemode == request.Livemode
		if !matchesPurchase {
			return errCheckoutCreationConflict
		}
		creation.CreatedAt = time.Unix(createdAt, 0).UTC()
		return nil
	})
	if err != nil {
		return nil, err
	}
	return &creation, nil
}
