package billing

import (
	"context"
	"errors"
	"strings"
	"time"

	"github.com/stripe/stripe-go/v87"
)

func getStripePrice(ctx context.Context, client *stripe.Client, priceID string) (*stripe.Price, error) {
	if client == nil {
		return nil, errors.New("Stripe billing is not configured")
	}
	if strings.TrimSpace(priceID) == "" {
		return nil, errors.New("Stripe Price ID must be set")
	}

	ctx, cancel := context.WithTimeout(ctx, 10*time.Second)
	defer cancel()

	price, err := client.V1Prices.Retrieve(ctx, priceID, nil)
	if err != nil {
		if ctx.Err() != nil {
			return nil, ctx.Err()
		}
		return nil, errors.New("Stripe Price retrieval failed")
	}
	return price, nil
}
