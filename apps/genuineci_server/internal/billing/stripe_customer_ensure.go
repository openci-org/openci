package billing

import (
	"context"
	"errors"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	billingconfig "github.com/openci-org/openci/apps/genuineci_server/internal/billing/config"
	"github.com/openci-org/openci/apps/genuineci_server/internal/billing/stripeapi"
	"github.com/stripe/stripe-go/v87"
)

// Leave a margin before Stripe can prune an API v1 idempotency key after 24 hours.
const stripeCustomerRetryWindow = 23 * time.Hour

var errStripeCustomerReconciliationRequired = errors.New("Stripe Customer creation requires reconciliation")

type stripeCustomerRequest struct {
	TeamID   string
	Livemode bool
}

func ensureStripeCustomer(ctx context.Context, pool *pgxpool.Pool, client *stripe.Client, request stripeCustomerRequest) (string, error) {
	enabled, err := billingconfig.Enabled()
	if err != nil {
		return "", err
	}
	if !enabled || client == nil {
		return "", errors.New("Stripe billing is not configured")
	}

	creation, err := ensureCustomerCreation(ctx, pool, request.TeamID, request.Livemode)
	if err != nil {
		return "", err
	}
	if creation.StripeCustomerID != nil {
		return *creation.StripeCustomerID, nil
	}

	now := time.Now()
	retryDeadline := creation.CreatedAt.Add(stripeCustomerRetryWindow)
	if now.Before(creation.CreatedAt) {
		return "", errStripeCustomerReconciliationRequired
	}

	var customer *stripe.Customer
	if now.Before(retryDeadline) {
		stripeCtx, cancel := context.WithDeadline(ctx, retryDeadline)
		defer cancel()
		customer, err = stripeapi.CreateCustomer(stripeCtx, client, stripeapi.CustomerCreateRequest{
			TeamID:         creation.TeamID,
			IdempotencyKey: creation.IdempotencyKey,
		})
	} else {
		customer, err = findStripeCustomer(ctx, client, stripeCustomerRequest{
			TeamID:   creation.TeamID,
			Livemode: creation.Livemode,
		})
	}
	if err != nil {
		return "", err
	}
	if err := recordStripeCustomer(ctx, pool, *creation, customer); err != nil {
		return "", err
	}
	return customer.ID, nil
}
