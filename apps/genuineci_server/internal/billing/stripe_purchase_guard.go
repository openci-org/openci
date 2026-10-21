package billing

import (
	"context"
	"errors"
	"time"

	"github.com/stripe/stripe-go/v87"
)

var errStripeSubscriptionExists = errors.New("the team already has a Stripe subscription; use billing management")
var errStripeCustomerOwnership = errors.New("Stripe Customer does not belong to the team in the configured mode")

func getOwnedStripeCustomer(ctx context.Context, client *stripe.Client, request stripeCustomerRequest, customerID string) (*stripe.Customer, error) {
	if client == nil || customerID == "" || request.TeamID == "" {
		return nil, errors.New("Stripe Customer ownership is not configured")
	}
	ctx, cancel := context.WithTimeout(ctx, 10*time.Second)
	defer cancel()
	customer, err := client.V1Customers.Retrieve(ctx, customerID, nil)
	if err != nil {
		if ctx.Err() != nil {
			return nil, ctx.Err()
		}
		return nil, errors.New("Stripe Customer retrieval failed")
	}
	if customer == nil || customer.ID != customerID || customer.Deleted ||
		customer.Livemode != request.Livemode || customer.Metadata["team_id"] != request.TeamID {
		return nil, errStripeCustomerOwnership
	}
	return customer, nil
}

func requireNoStripeSubscription(ctx context.Context, client *stripe.Client, customer *stripe.Customer) error {
	if client == nil || customer == nil || customer.ID == "" || customer.Deleted {
		return errors.New("Stripe Customer is not available")
	}
	ctx, cancel := context.WithTimeout(ctx, 10*time.Second)
	defer cancel()
	params := &stripe.SubscriptionListParams{
		Customer: stripe.String(customer.ID), Status: stripe.String("all"),
		ListParams: stripe.ListParams{Limit: stripe.Int64(100)},
	}
	count := 0
	for subscription, err := range client.V1Subscriptions.List(ctx, params).All(ctx) {
		if err != nil {
			if ctx.Err() != nil {
				return ctx.Err()
			}
			return errors.New("Stripe subscription lookup failed")
		}
		count++
		if count > 1000 || subscription == nil || subscription.ID == "" || subscription.Customer == nil ||
			subscription.Customer.ID != customer.ID || subscription.Livemode != customer.Livemode {
			return errors.New("Stripe subscription ownership could not be established")
		}
		switch subscription.Status {
		case stripe.SubscriptionStatusCanceled, stripe.SubscriptionStatusIncompleteExpired:
		default:
			return errStripeSubscriptionExists
		}
	}
	return nil
}
