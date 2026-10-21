package billing

import (
	"context"
	"errors"
	"time"

	"github.com/stripe/stripe-go/v87"
)

type stripePortalRequest struct {
	CustomerID      string
	ConfigurationID string
	ReturnURL       string
	Livemode        bool
}

func createStripePortalSession(ctx context.Context, client *stripe.Client, request stripePortalRequest) (*stripe.BillingPortalSession, error) {
	if client == nil || request.CustomerID == "" || request.ConfigurationID == "" || request.ReturnURL == "" {
		return nil, errors.New("Stripe Portal requires a Customer, configuration, and return URL")
	}
	ctx, cancel := context.WithTimeout(ctx, 10*time.Second)
	defer cancel()
	config, err := client.V1BillingPortalConfigurations.Retrieve(ctx, request.ConfigurationID, nil)
	if err != nil {
		if ctx.Err() != nil {
			return nil, ctx.Err()
		}
		return nil, errors.New("Stripe Portal configuration retrieval failed")
	}
	if config == nil || config.ID != request.ConfigurationID || !config.Active || config.Livemode != request.Livemode {
		return nil, errors.New("Stripe Portal configuration is not available in the configured mode")
	}
	features := config.Features
	if features == nil || features.InvoiceHistory == nil || !features.InvoiceHistory.Enabled ||
		features.PaymentMethodUpdate == nil || !features.PaymentMethodUpdate.Enabled {
		return nil, errors.New("Stripe Portal must support invoices and payment method updates")
	}
	if features.SubscriptionUpdate == nil || features.SubscriptionUpdate.Enabled ||
		config.LoginPage != nil && config.LoginPage.Enabled {
		return nil, errors.New("Stripe Portal must disable subscription updates and public login")
	}
	cancellation := features.SubscriptionCancel
	if cancellation == nil || !cancellation.Enabled ||
		cancellation.Mode != stripe.BillingPortalConfigurationFeaturesSubscriptionCancelModeAtPeriodEnd ||
		cancellation.ProrationBehavior != stripe.BillingPortalConfigurationFeaturesSubscriptionCancelProrationBehaviorNone {
		return nil, errors.New("Stripe Portal must cancel at period end without proration")
	}
	session, err := client.V1BillingPortalSessions.Create(ctx, &stripe.BillingPortalSessionCreateParams{
		Customer: stripe.String(request.CustomerID), Configuration: stripe.String(request.ConfigurationID),
		ReturnURL: stripe.String(request.ReturnURL),
	})
	if err != nil {
		if ctx.Err() != nil {
			return nil, ctx.Err()
		}
		return nil, errors.New("Stripe Portal Session creation failed")
	}
	if session == nil || session.ID == "" || session.URL == "" || session.Customer != request.CustomerID ||
		session.Configuration == nil || session.Configuration.ID != request.ConfigurationID ||
		session.ReturnURL != request.ReturnURL || session.Livemode != request.Livemode {
		return nil, errors.New("Stripe Portal Session does not match the request")
	}
	return session, nil
}
