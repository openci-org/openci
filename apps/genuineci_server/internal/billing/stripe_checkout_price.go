package billing

import (
	"errors"

	"github.com/stripe/stripe-go/v87"
)

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
