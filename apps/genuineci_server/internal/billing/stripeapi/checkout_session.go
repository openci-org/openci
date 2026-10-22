package stripeapi

import (
	"context"
	"errors"
	"strings"
	"time"

	"github.com/stripe/stripe-go/v87"
)

// GetCheckoutSession retrieves a session without establishing purchase eligibility or paid access.
func GetCheckoutSession(ctx context.Context, client *stripe.Client, sessionID string) (*stripe.CheckoutSession, error) {
	if client == nil {
		return nil, errors.New("Stripe billing is not configured")
	}
	if strings.TrimSpace(sessionID) == "" {
		return nil, errors.New("Stripe Checkout Session ID must be set")
	}

	ctx, cancel := context.WithTimeout(ctx, 10*time.Second)
	defer cancel()

	session, err := client.V1CheckoutSessions.Retrieve(ctx, sessionID, nil)
	if err != nil {
		if ctx.Err() != nil {
			return nil, ctx.Err()
		}
		return nil, errors.New("Stripe Checkout Session retrieval failed")
	}
	return session, nil
}
