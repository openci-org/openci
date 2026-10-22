package billing

import (
	"context"
	"errors"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	billingconfig "github.com/openci-org/openci/apps/genuineci_server/internal/billing/config"
	"github.com/openci-org/openci/apps/genuineci_server/internal/billing/stripeapi"
	"github.com/stripe/stripe-go/v87"
)

var errStripeCheckoutCompleted = errors.New("Checkout completed; refresh billing state before another purchase")

func expireCheckoutCreation(ctx context.Context, pool *pgxpool.Pool, client *stripe.Client, creation checkoutCreation) error {
	enabled, err := billingconfig.Enabled()
	if err != nil {
		return err
	}
	if !enabled || client == nil || creation.StripeCheckoutSessionID == nil {
		return errStripeCheckoutReconciliationRequired
	}
	ctx, cancel := context.WithTimeout(ctx, 10*time.Second)
	defer cancel()
	id := *creation.StripeCheckoutSessionID
	session, err := stripeapi.GetCheckoutSession(ctx, client, id)
	if err != nil {
		return err
	}
	if err := validateCheckoutForExpiry(creation, session); err != nil {
		return err
	}
	if session.Status == stripe.CheckoutSessionStatusOpen {
		params := &stripe.CheckoutSessionExpireParams{}
		params.SetIdempotencyKey(creation.IdempotencyKey + ":expire")
		session, err = client.V1CheckoutSessions.Expire(ctx, id, params)
		if err != nil {
			if ctx.Err() != nil {
				return ctx.Err()
			}
			session, err = stripeapi.GetCheckoutSession(ctx, client, id)
			if err != nil {
				return err
			}
		}
		if err := validateCheckoutForExpiry(creation, session); err != nil {
			return err
		}
	}
	if session.Status != stripe.CheckoutSessionStatusExpired || session.PaymentStatus != stripe.CheckoutSessionPaymentStatusUnpaid {
		return errStripeCheckoutReconciliationRequired
	}
	return withBillingAccountLock(ctx, pool, creation.Request.TeamID, func(tx pgx.Tx, account *billingAccount) error {
		result, err := tx.Exec(ctx, `
			UPDATE billing_checkout_creations SET closed_at = COALESCE(closed_at, $4)
			WHERE team_id = $1 AND idempotency_key = $2 AND stripe_checkout_session_id = $3
		`, account.TeamID, creation.IdempotencyKey, id, time.Now().Unix())
		if err != nil {
			return err
		}
		if result.RowsAffected() != 1 {
			return errStripeCheckoutReconciliationRequired
		}
		return nil
	})
}

func validateCheckoutForExpiry(creation checkoutCreation, session *stripe.CheckoutSession) error {
	if err := validateStripeCheckoutIdentity(creation, session); err != nil {
		return err
	}
	if session.ID != *creation.StripeCheckoutSessionID || session.Metadata["checkout_creation_key"] != creation.IdempotencyKey {
		return errStripeCheckoutReconciliationRequired
	}
	if session.Status == stripe.CheckoutSessionStatusComplete || session.Subscription != nil {
		return errStripeCheckoutCompleted
	}
	return nil
}
