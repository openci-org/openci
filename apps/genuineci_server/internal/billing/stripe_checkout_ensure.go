package billing

import (
	"context"
	"errors"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/stripe/stripe-go/v87"
)

const stripeCheckoutRetryWindow = 23 * time.Hour

var errStripeCheckoutReconciliationRequired = errors.New("Stripe Checkout creation requires reconciliation")

func ensureStripeCheckoutSession(ctx context.Context, pool *pgxpool.Pool, client *stripe.Client, request checkoutCreationRequest) (*stripe.CheckoutSession, error) {
	enabled, err := Enabled()
	if err != nil {
		return nil, err
	}
	if !enabled || client == nil {
		return nil, errors.New("Stripe billing is not configured")
	}
	creation, err := ensureCheckoutCreation(ctx, pool, request)
	if err != nil {
		return nil, err
	}

	var session *stripe.CheckoutSession
	if creation.StripeCheckoutSessionID != nil {
		session, err = getStripeCheckoutSession(ctx, client, *creation.StripeCheckoutSessionID)
		if err == nil && (session == nil || session.ID != *creation.StripeCheckoutSessionID) {
			return nil, errStripeCheckoutReconciliationRequired
		}
	} else {
		now := time.Now()
		deadline := creation.CreatedAt.Add(stripeCheckoutRetryWindow)
		if now.Before(creation.CreatedAt) || !now.Before(deadline) {
			return nil, errStripeCheckoutReconciliationRequired
		}
		stripeCtx, cancel := context.WithDeadline(ctx, deadline)
		defer cancel()
		original := creation.Request
		session, err = createStripeCheckoutSession(stripeCtx, client, stripeCheckoutCreateRequest{
			TeamID: original.TeamID, CustomerID: original.CustomerID, PriceID: original.PriceID,
			SuccessURL: original.SuccessURL, CancelURL: original.CancelURL,
			IdempotencyKey: creation.IdempotencyKey,
		})
	}
	if err != nil {
		return nil, err
	}
	if session.Metadata["checkout_creation_key"] != creation.IdempotencyKey {
		return nil, errStripeCheckoutReconciliationRequired
	}
	if err := recordStripeCheckoutSession(ctx, pool, *creation, session); err != nil {
		return nil, err
	}
	return session, nil
}
