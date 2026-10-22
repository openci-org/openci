package stripeapi

import (
	"context"
	"errors"
	"strings"
	"time"

	"github.com/stripe/stripe-go/v87"
)

// GetSubscription retrieves a subscription without deciding paid access.
func GetSubscription(ctx context.Context, client *stripe.Client, subscriptionID string) (*stripe.Subscription, error) {
	if client == nil {
		return nil, errors.New("Stripe billing is not configured")
	}
	if strings.TrimSpace(subscriptionID) == "" {
		return nil, errors.New("Stripe Subscription ID must be set")
	}

	ctx, cancel := context.WithTimeout(ctx, 10*time.Second)
	defer cancel()

	subscription, err := client.V1Subscriptions.Retrieve(ctx, subscriptionID, nil)
	if err != nil {
		if ctx.Err() != nil {
			return nil, ctx.Err()
		}
		return nil, errors.New("Stripe Subscription retrieval failed")
	}
	return subscription, nil
}
