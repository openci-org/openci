package billing

import (
	"context"
	"errors"
	"time"

	"github.com/stripe/stripe-go/v87"
)

func currentStripeSubscription(ctx context.Context, client *stripe.Client, customer *stripe.Customer) (*stripe.Subscription, error) {
	ctx, cancel := context.WithTimeout(ctx, 10*time.Second)
	defer cancel()
	params := &stripe.SubscriptionListParams{
		Customer: stripe.String(customer.ID), Status: stripe.String("all"),
		ListParams: stripe.ListParams{Limit: stripe.Int64(100)},
	}
	var current, terminal *stripe.Subscription
	count := 0
	for subscription, err := range client.V1Subscriptions.List(ctx, params).All(ctx) {
		if err != nil {
			return nil, stripeReadError(ctx, "Stripe subscription lookup failed")
		}
		count++
		if count > 1000 || subscription == nil || subscription.ID == "" || subscription.Customer == nil ||
			subscription.Customer.ID != customer.ID || subscription.Livemode != customer.Livemode {
			return nil, errStripePaymentUnverified
		}
		switch subscription.Status {
		case stripe.SubscriptionStatusCanceled, stripe.SubscriptionStatusIncompleteExpired:
			if terminal == nil || subscription.Created > terminal.Created ||
				(subscription.Created == terminal.Created && subscription.ID > terminal.ID) {
				terminal = subscription
			}
		default:
			if current != nil {
				return nil, errStripePaymentUnverified
			}
			current = subscription
		}
	}
	if current != nil {
		return current, nil
	}
	return terminal, nil
}

func subscriptionCheckout(ctx context.Context, client *stripe.Client, subscription *stripe.Subscription) (*stripe.CheckoutSession, error) {
	ctx, cancel := context.WithTimeout(ctx, 10*time.Second)
	defer cancel()
	params := &stripe.CheckoutSessionListParams{
		Customer: stripe.String(subscription.Customer.ID), Subscription: stripe.String(subscription.ID),
		ListParams: stripe.ListParams{Limit: stripe.Int64(2)},
	}
	var found *stripe.CheckoutSession
	for session, err := range client.V1CheckoutSessions.List(ctx, params).All(ctx) {
		if err != nil {
			return nil, stripeReadError(ctx, "Stripe purchase lookup failed")
		}
		if found != nil || session == nil || session.ID == "" || session.Customer == nil ||
			session.Customer.ID != subscription.Customer.ID || session.Subscription == nil ||
			session.Subscription.ID != subscription.ID || session.Livemode != subscription.Livemode ||
			session.Status != stripe.CheckoutSessionStatusComplete {
			return nil, errStripePaymentUnverified
		}
		found = session
	}
	if found == nil {
		return nil, errStripePaymentUnverified
	}
	return found, nil
}

func getStripeInvoice(ctx context.Context, client *stripe.Client, invoiceID string) (*stripe.Invoice, error) {
	if invoiceID == "" {
		return nil, errStripePaymentUnverified
	}
	ctx, cancel := context.WithTimeout(ctx, 10*time.Second)
	defer cancel()
	invoice, err := client.V1Invoices.Retrieve(ctx, invoiceID, nil)
	if err != nil {
		return nil, stripeReadError(ctx, "Stripe invoice retrieval failed")
	}
	if invoice == nil || invoice.ID != invoiceID {
		return nil, errStripePaymentUnverified
	}
	return invoice, nil
}

func stripeReadError(ctx context.Context, message string) error {
	if ctx.Err() != nil {
		return ctx.Err()
	}
	return errors.New(message)
}
