package billing

import (
	"context"
	"errors"
	"strings"
	"time"

	"github.com/stripe/stripe-go/v87"
)

type stripeCheckoutCreateRequest struct {
	TeamID         string
	CustomerID     string
	PriceID        string
	SuccessURL     string
	CancelURL      string
	IdempotencyKey string
}

func createStripeCheckoutSession(ctx context.Context, client *stripe.Client, request stripeCheckoutCreateRequest) (*stripe.CheckoutSession, error) {
	if client == nil {
		return nil, errors.New("Stripe billing is not configured")
	}
	if strings.TrimSpace(request.TeamID) == "" {
		return nil, errors.New("Stripe Checkout team ID must be set")
	}
	if strings.TrimSpace(request.CustomerID) == "" {
		return nil, errors.New("Stripe Checkout Customer ID must be set")
	}
	if strings.TrimSpace(request.PriceID) == "" {
		return nil, errors.New("Stripe Checkout Price ID must be set")
	}
	if strings.TrimSpace(request.SuccessURL) == "" || strings.TrimSpace(request.CancelURL) == "" {
		return nil, errors.New("Stripe Checkout return URLs must be set")
	}
	if strings.TrimSpace(request.IdempotencyKey) == "" {
		return nil, errors.New("Stripe Checkout idempotency key must be set")
	}

	ctx, cancel := context.WithTimeout(ctx, 10*time.Second)
	defer cancel()
	params := &stripe.CheckoutSessionCreateParams{
		Mode:                      stripe.String(stripe.CheckoutSessionModeSubscription),
		UIMode:                    stripe.String(stripe.CheckoutSessionUIModeHostedPage),
		Customer:                  stripe.String(request.CustomerID),
		ClientReferenceID:         stripe.String(request.TeamID),
		SuccessURL:                stripe.String(request.SuccessURL),
		CancelURL:                 stripe.String(request.CancelURL),
		AllowedPaymentMethodTypes: []*string{stripe.String(stripe.PaymentMethodTypeCard)},
		AdaptivePricing:           &stripe.CheckoutSessionCreateAdaptivePricingParams{Enabled: stripe.Bool(false)},
		LineItems: []*stripe.CheckoutSessionCreateLineItemParams{
			{Price: stripe.String(request.PriceID), Quantity: stripe.Int64(1)},
		},
		Metadata: map[string]string{
			"team_id": request.TeamID, "checkout_creation_key": request.IdempotencyKey,
		},
		SubscriptionData: &stripe.CheckoutSessionCreateSubscriptionDataParams{
			Metadata: map[string]string{"team_id": request.TeamID},
		},
	}
	params.SetIdempotencyKey(request.IdempotencyKey)
	session, err := client.V1CheckoutSessions.Create(ctx, params)
	if err != nil {
		if ctx.Err() != nil {
			return nil, ctx.Err()
		}
		return nil, errors.New("Stripe Checkout Session creation failed")
	}
	if session == nil || session.ID == "" || session.URL == "" {
		return nil, errors.New("Stripe Checkout Session creation failed")
	}
	return session, nil
}
