package billing

import (
	"testing"

	"github.com/stripe/stripe-go/v87"
)

func TestValidateStripeCheckoutPrice(t *testing.T) {
	for _, tc := range []struct {
		name, planID string
		amount       int64
		livemode     bool
	}{
		{"Light in test mode", "light", 1_000, false},
		{"Light in live mode", "light", 1_000, true},
		{"Pro in test mode", "pro", 10_000, false},
		{"Pro in live mode", "pro", 10_000, true},
	} {
		t.Run(tc.name, func(t *testing.T) {
			price := validStripeCheckoutPrice()
			price.UnitAmount = tc.amount
			price.Livemode = tc.livemode

			if err := validateStripeCheckoutPrice(price, tc.planID, tc.livemode); err != nil {
				t.Fatal(err)
			}
		})
	}
}

func TestValidateStripeCheckoutPriceRejectsMismatches(t *testing.T) {
	for _, tc := range []struct {
		name   string
		change func(*stripe.Price)
	}{
		{"missing ID", func(p *stripe.Price) { p.ID = "" }},
		{"deleted price", func(p *stripe.Price) { p.Deleted = true }},
		{"inactive price", func(p *stripe.Price) { p.Active = false }},
		{"wrong mode", func(p *stripe.Price) { p.Livemode = true }},
		{"wrong currency", func(p *stripe.Price) { p.Currency = stripe.CurrencyJPY }},
		{"wrong amount", func(p *stripe.Price) { p.UnitAmount = 999 }},
		{"Pro amount for Light", func(p *stripe.Price) { p.UnitAmount = 10_000 }},
		{"tiered billing", func(p *stripe.Price) { p.BillingScheme = stripe.PriceBillingSchemeTiered }},
		{"customer-chosen amount", func(p *stripe.Price) { p.CustomUnitAmount = &stripe.PriceCustomUnitAmount{} }},
		{"quantity transformation", func(p *stripe.Price) {
			p.TransformQuantity = &stripe.PriceTransformQuantity{
				DivideBy: 10,
				Round:    stripe.PriceTransformQuantityRoundDown,
			}
		}},
		{"one-time price", func(p *stripe.Price) { p.Type = stripe.PriceTypeOneTime }},
		{"missing recurring settings", func(p *stripe.Price) { p.Recurring = nil }},
		{"yearly price", func(p *stripe.Price) { p.Recurring.Interval = stripe.PriceRecurringIntervalYear }},
		{"quarterly price", func(p *stripe.Price) { p.Recurring.IntervalCount = 3 }},
		{"metered usage", func(p *stripe.Price) { p.Recurring.UsageType = stripe.PriceRecurringUsageTypeMetered }},
		{"trial configured", func(p *stripe.Price) { p.Recurring.TrialPeriodDays = 7 }},
	} {
		t.Run(tc.name, func(t *testing.T) {
			price := validStripeCheckoutPrice()
			tc.change(price)

			if err := validateStripeCheckoutPrice(price, "light", false); err == nil {
				t.Fatal("mismatched price must not be accepted for Checkout")
			}
		})
	}
}

func TestValidateStripeCheckoutPriceRejectsMissingPrice(t *testing.T) {
	if err := validateStripeCheckoutPrice(nil, "light", false); err == nil {
		t.Fatal("missing price must not be accepted for Checkout")
	}
}

func TestValidateStripeCheckoutPriceRejectsUnknownPlan(t *testing.T) {
	if err := validateStripeCheckoutPrice(validStripeCheckoutPrice(), "unknown", false); err == nil {
		t.Fatal("unknown plan must not be accepted for Checkout")
	}
}

func validStripeCheckoutPrice() *stripe.Price {
	return &stripe.Price{
		ID:            "price_configured",
		Active:        true,
		Currency:      stripe.CurrencyUSD,
		UnitAmount:    1_000,
		BillingScheme: stripe.PriceBillingSchemePerUnit,
		Type:          stripe.PriceTypeRecurring,
		Recurring: &stripe.PriceRecurring{
			Interval:      stripe.PriceRecurringIntervalMonth,
			IntervalCount: 1,
			UsageType:     stripe.PriceRecurringUsageTypeLicensed,
		},
	}
}
