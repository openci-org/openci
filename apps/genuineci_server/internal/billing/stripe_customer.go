package billing

import (
	"context"
	"errors"
	"strings"
	"time"

	"github.com/stripe/stripe-go/v87"
)

type stripeCustomerCreateRequest struct {
	TeamID         string
	IdempotencyKey string
}

func createStripeCustomer(ctx context.Context, client *stripe.Client, request stripeCustomerCreateRequest) (*stripe.Customer, error) {
	if client == nil {
		return nil, errors.New("Stripe billing is not configured")
	}
	if strings.TrimSpace(request.TeamID) == "" {
		return nil, errors.New("Stripe Customer team ID must be set")
	}
	if strings.TrimSpace(request.IdempotencyKey) == "" {
		return nil, errors.New("Stripe Customer idempotency key must be set")
	}

	ctx, cancel := context.WithTimeout(ctx, 10*time.Second)
	defer cancel()
	params := &stripe.CustomerCreateParams{
		Metadata: map[string]string{"team_id": request.TeamID},
	}
	params.SetIdempotencyKey(request.IdempotencyKey)

	customer, err := client.V1Customers.Create(ctx, params)
	if err != nil {
		if ctx.Err() != nil {
			return nil, ctx.Err()
		}
		return nil, errors.New("Stripe Customer creation failed")
	}
	if customer == nil || customer.ID == "" {
		return nil, errors.New("Stripe Customer creation failed")
	}
	return customer, nil
}
