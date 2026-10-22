package billing

import (
	"context"
	"errors"
	"time"

	"github.com/stripe/stripe-go/v87"
)

func findStripeCheckoutSession(ctx context.Context, client *stripe.Client, creation checkoutCreation) (*stripe.CheckoutSession, error) {
	if client == nil || creation.IdempotencyKey == "" || creation.Request.CustomerID == "" {
		return nil, errStripeCheckoutReconciliationRequired
	}
	ctx, cancel := context.WithTimeout(ctx, 10*time.Second)
	defer cancel()
	params := &stripe.CheckoutSessionListParams{
		Customer:     stripe.String(creation.Request.CustomerID),
		ListParams:   stripe.ListParams{Limit: stripe.Int64(100)},
		CreatedRange: &stripe.RangeQueryParams{GreaterThanOrEqual: creation.CreatedAt.Add(-5 * time.Minute).Unix()},
	}
	params.AddExpand("data.line_items")
	var match *stripe.CheckoutSession
	count := 0
	for session, err := range client.V1CheckoutSessions.List(ctx, params).All(ctx) {
		if err != nil {
			if ctx.Err() != nil {
				return nil, ctx.Err()
			}
			return nil, errors.New("Stripe Checkout recovery lookup failed")
		}
		count++
		if count > 1000 || session == nil {
			return nil, errStripeCheckoutReconciliationRequired
		}
		if session.Metadata["checkout_creation_key"] != creation.IdempotencyKey {
			continue
		}
		if match != nil || validateStripeCheckoutIdentity(creation, session) != nil {
			return nil, errStripeCheckoutReconciliationRequired
		}
		items := session.LineItems
		if items == nil || items.HasMore || len(items.Data) != 1 {
			return nil, errStripeCheckoutReconciliationRequired
		}
		item := items.Data[0]
		if item == nil || item.Quantity != 1 || item.Price == nil || item.Price.ID != creation.Request.PriceID {
			return nil, errStripeCheckoutReconciliationRequired
		}
		switch session.Status {
		case stripe.CheckoutSessionStatusOpen, stripe.CheckoutSessionStatusComplete, stripe.CheckoutSessionStatusExpired:
			match = session
		default:
			return nil, errStripeCheckoutReconciliationRequired
		}
	}
	if match == nil {
		return nil, errStripeCheckoutReconciliationRequired
	}
	return match, nil
}
