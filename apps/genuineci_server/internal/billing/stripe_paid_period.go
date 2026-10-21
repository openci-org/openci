package billing

import (
	"errors"
	"strconv"
	"time"

	"github.com/stripe/stripe-go/v87"
)

var errStripePaymentUnverified = errors.New("Stripe payment does not match the team's purchase")

func validateStripePurchase(creation checkoutCreation, subscription *stripe.Subscription) error {
	belongsToTeam := subscription != nil && subscription.ID != "" && subscription.Customer != nil &&
		subscription.Customer.ID == creation.Request.CustomerID && subscription.Livemode == creation.Request.Livemode &&
		subscription.Metadata["team_id"] == creation.Request.TeamID
	if !belongsToTeam {
		return errStripePaymentUnverified
	}
	singlePaidItem := subscription.Items != nil && !subscription.Items.HasMore && len(subscription.Items.Data) == 1 &&
		subscription.PauseCollection == nil && subscription.TrialStart == 0 && subscription.TrialEnd == 0
	if !singlePaidItem {
		return errStripePaymentUnverified
	}
	item := subscription.Items.Data[0]
	if item == nil || item.Deleted || item.ID == "" || item.Quantity != 1 || item.CurrentTrial != nil ||
		item.Price == nil || item.Price.ID != creation.Request.PriceID ||
		item.CurrentPeriodStart <= 0 || item.CurrentPeriodEnd <= item.CurrentPeriodStart {
		return errStripePaymentUnverified
	}
	price := *item.Price
	price.Active = true
	if err := validateStripeCheckoutPrice(&price, creation.Request.PlanID, creation.Request.Livemode); err != nil {
		return errStripePaymentUnverified
	}
	if !price.UnitAmountDecimal.IsZero() && price.UnitAmountDecimal.String() != strconv.FormatInt(price.UnitAmount, 10) {
		return errStripePaymentUnverified
	}
	return nil
}

func verifiedStripePaidPeriod(creation checkoutCreation, subscription *stripe.Subscription, invoice *stripe.Invoice) (*billingPeriod, error) {
	if err := validateStripePurchase(creation, subscription); err != nil {
		return nil, err
	}
	belongsToPurchase := invoice != nil && invoice.ID != "" && !invoice.Deleted && invoice.Customer != nil &&
		invoice.Customer.ID == creation.Request.CustomerID && invoice.Livemode == creation.Request.Livemode &&
		invoice.Parent != nil && invoice.Parent.SubscriptionDetails != nil && invoice.Parent.SubscriptionDetails.Subscription != nil &&
		invoice.Parent.SubscriptionDetails.Subscription.ID == subscription.ID
	if !belongsToPurchase {
		return nil, errStripePaymentUnverified
	}
	plan, _ := getPaidBillingPlan(creation.Request.PlanID)
	paidInFull := invoice.Status == stripe.InvoiceStatusPaid && invoice.AmountRemaining == 0 &&
		invoice.AmountPaid >= plan.PriceUSDCents && invoice.AmountPaidOffStripe == 0 && invoice.Currency == stripe.CurrencyUSD &&
		invoice.CollectionMethod == stripe.InvoiceCollectionMethodChargeAutomatically && len(invoice.Discounts) == 0 &&
		len(invoice.TotalDiscountAmounts) == 0
	regularSubscriptionInvoice := invoice.BillingReason == stripe.InvoiceBillingReasonSubscriptionCreate ||
		invoice.BillingReason == stripe.InvoiceBillingReasonSubscriptionCycle
	if !paidInFull || !regularSubscriptionInvoice {
		return nil, errStripePaymentUnverified
	}
	if invoice.Lines == nil || invoice.Lines.HasMore || len(invoice.Lines.Data) != 1 {
		return nil, errStripePaymentUnverified
	}
	item, line := subscription.Items.Data[0], invoice.Lines.Data[0]
	if line == nil || line.ID == "" || line.Invoice != invoice.ID || line.Livemode != creation.Request.Livemode ||
		line.Quantity != 1 || (!line.QuantityDecimal.IsZero() && line.QuantityDecimal.String() != "1") ||
		line.Amount != plan.PriceUSDCents || line.Currency != stripe.CurrencyUSD || len(line.Discounts) != 0 || len(line.DiscountAmounts) != 0 ||
		line.Pricing == nil || line.Pricing.PriceDetails == nil || line.Pricing.PriceDetails.Price == nil ||
		line.Pricing.PriceDetails.Price.ID != creation.Request.PriceID || line.Parent == nil || line.Parent.SubscriptionItemDetails == nil {
		return nil, errStripePaymentUnverified
	}
	parent := line.Parent.SubscriptionItemDetails
	if parent.Proration || parent.Subscription != subscription.ID || parent.SubscriptionItem != item.ID ||
		line.Period == nil || line.Period.Start != item.CurrentPeriodStart || line.Period.End != item.CurrentPeriodEnd {
		return nil, errStripePaymentUnverified
	}
	return &billingPeriod{
		ID: "stripe:" + invoice.ID, TeamID: creation.Request.TeamID, PlanID: creation.Request.PlanID, PeriodType: "paid",
		StartsAt: time.Unix(line.Period.Start, 0).UTC(), EndsAt: time.Unix(line.Period.End, 0).UTC(),
		AllowanceSeconds: &plan.AllowanceSeconds,
	}, nil
}
