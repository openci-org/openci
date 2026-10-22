package billing

import (
	"context"
	"errors"

	billingconfig "github.com/openci-org/openci/apps/genuineci_server/internal/billing/config"
	"github.com/openci-org/openci/apps/genuineci_server/internal/billing/stripeapi"
	"github.com/stripe/stripe-go/v87"
)

func getStripeCheckoutPrice(ctx context.Context, client *stripe.Client, planID string, livemode bool) (*stripe.Price, error) {
	priceID, err := billingconfig.CheckoutPriceID(planID)
	if err != nil {
		return nil, err
	}
	if priceID == "" {
		return nil, errors.New("Stripe billing is not configured")
	}

	price, err := stripeapi.GetPrice(ctx, client, priceID)
	if err != nil {
		return nil, err
	}
	if err := validateStripeCheckoutPrice(price, planID, livemode); err != nil {
		return nil, err
	}
	if price.ID != priceID {
		return nil, errors.New("Stripe Price does not match the configured ID")
	}
	return price, nil
}

func validateStripeCheckoutPrice(price *stripe.Price, planID string, livemode bool) error {
	plan, err := getPaidBillingPlan(planID)
	if err != nil {
		return err
	}

	availableInMode := price != nil &&
		price.ID != "" &&
		!price.Deleted &&
		price.Active &&
		price.Livemode == livemode
	if !availableInMode {
		return errors.New("Stripe Price is not available in the configured mode")
	}

	matchesFixedUSDAmount := price.Currency == stripe.CurrencyUSD &&
		price.UnitAmount == plan.PriceUSDCents &&
		price.BillingScheme == stripe.PriceBillingSchemePerUnit &&
		price.CustomUnitAmount == nil &&
		price.TransformQuantity == nil
	if !matchesFixedUSDAmount {
		return errors.New("Stripe Price must match the plan's fixed USD amount")
	}

	recurring := price.Recurring
	monthlyWithoutTrial := price.Type == stripe.PriceTypeRecurring &&
		recurring != nil &&
		recurring.Interval == stripe.PriceRecurringIntervalMonth &&
		recurring.IntervalCount == 1 &&
		recurring.UsageType == stripe.PriceRecurringUsageTypeLicensed &&
		recurring.TrialPeriodDays == 0
	if !monthlyWithoutTrial {
		return errors.New("Stripe Price must be monthly, licensed, and have no trial")
	}
	return nil
}
