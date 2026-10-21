package billing

import (
	"context"
	"errors"
	"strings"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/stripe/stripe-go/v87"
)

func recordStripeCheckoutSession(ctx context.Context, pool *pgxpool.Pool, creation checkoutCreation, session *stripe.CheckoutSession) error {
	if session == nil || strings.TrimSpace(session.ID) == "" {
		return errors.New("Stripe Checkout Session is not available")
	}
	request := creation.Request
	matchesCheckoutMode := session.Mode == stripe.CheckoutSessionModeSubscription &&
		session.UIMode == stripe.CheckoutSessionUIModeHostedPage &&
		session.Livemode == request.Livemode
	if !matchesCheckoutMode {
		return errors.New("Stripe Checkout Session does not match the expected mode")
	}
	matchesCustomer := session.Customer != nil && !session.Customer.Deleted &&
		session.Customer.ID == request.CustomerID
	matchesTeam := session.ClientReferenceID == request.TeamID &&
		session.Metadata["team_id"] == request.TeamID
	if !matchesCustomer || !matchesTeam {
		return errors.New("Stripe Checkout Session does not match the expected team and Customer")
	}
	if session.SuccessURL != request.SuccessURL || session.CancelURL != request.CancelURL {
		return errors.New("Stripe Checkout Session does not match the expected return URLs")
	}

	return withBillingAccountLock(ctx, pool, request.TeamID, func(tx pgx.Tx, account *billingAccount) error {
		result, err := tx.Exec(ctx, `
			UPDATE billing_checkout_creations SET stripe_checkout_session_id = $10
			WHERE team_id = $1 AND idempotency_key = $2 AND plan_id = $3
				AND stripe_customer_id = $4 AND stripe_price_id = $5
				AND success_url = $6 AND cancel_url = $7 AND livemode = $8 AND created_at = $9
				AND closed_at IS NULL
				AND (stripe_checkout_session_id IS NULL OR stripe_checkout_session_id = $10)
		`, account.TeamID, creation.IdempotencyKey, request.PlanID, request.CustomerID,
			request.PriceID, request.SuccessURL, request.CancelURL, request.Livemode,
			creation.CreatedAt.Unix(), session.ID)
		if err != nil {
			return err
		}
		if result.RowsAffected() != 1 {
			return errors.New("Stripe Checkout creation intent is missing, changed, closed, or already linked")
		}
		return nil
	})
}
