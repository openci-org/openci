package billing

import (
	"testing"
	"time"

	"github.com/stripe/stripe-go/v87"
)

func TestVerifiedStripePaidPeriod(t *testing.T) {
	creation, subscription, invoice := paidStripeFixtures()
	period, err := verifiedStripePaidPeriod(creation, subscription, invoice)
	if err != nil || period.ID != "stripe:in_paid" || period.TeamID != "team-1" || period.PlanID != "light" ||
		period.PeriodType != "paid" || *period.AllowanceSeconds != 36000 || period.StartsAt.Unix() != invoice.Lines.Data[0].Period.Start ||
		period.EndsAt.Unix() != invoice.Lines.Data[0].Period.End {
		t.Fatalf("paid invoice must produce its immutable plan and period: period=%+v, err=%v", period, err)
	}
	subscription.Items.Data[0].Price.Active = false
	if _, err := verifiedStripePaidPeriod(creation, subscription, invoice); err != nil {
		t.Fatal("archiving a Price must not invalidate an existing paid subscription")
	}
}

func TestVerifiedStripePaidPeriodRejectsMismatches(t *testing.T) {
	for _, tc := range []struct {
		name   string
		change func(*stripe.Subscription, *stripe.Invoice)
	}{
		{"unpaid", func(s *stripe.Subscription, i *stripe.Invoice) { i.Status = stripe.InvoiceStatusOpen }},
		{"amount outstanding", func(s *stripe.Subscription, i *stripe.Invoice) { i.AmountRemaining = 1 }},
		{"underpaid", func(s *stripe.Subscription, i *stripe.Invoice) { i.AmountPaid = 999 }},
		{"manual settlement", func(s *stripe.Subscription, i *stripe.Invoice) { i.AmountPaidOffStripe = 1000 }},
		{"wrong customer", func(s *stripe.Subscription, i *stripe.Invoice) { i.Customer.ID = "cus_other" }},
		{"wrong subscription", func(s *stripe.Subscription, i *stripe.Invoice) {
			i.Parent.SubscriptionDetails.Subscription.ID = "sub_other"
		}},
		{"wrong mode", func(s *stripe.Subscription, i *stripe.Invoice) { i.Livemode = true }},
		{"wrong team", func(s *stripe.Subscription, i *stripe.Invoice) { s.Metadata["team_id"] = "team-2" }},
		{"wrong Price", func(s *stripe.Subscription, i *stripe.Invoice) {
			i.Lines.Data[0].Pricing.PriceDetails.Price.ID = "price_other"
		}},
		{"wrong quantity", func(s *stripe.Subscription, i *stripe.Invoice) { i.Lines.Data[0].Quantity = 2 }},
		{"more lines", func(s *stripe.Subscription, i *stripe.Invoice) { i.Lines.HasMore = true }},
		{"unrelated line", func(s *stripe.Subscription, i *stripe.Invoice) { i.Lines.Data[0].Invoice = "in_other" }},
		{"wrong period", func(s *stripe.Subscription, i *stripe.Invoice) { i.Lines.Data[0].Period.End++ }},
		{"proration", func(s *stripe.Subscription, i *stripe.Invoice) {
			i.Lines.Data[0].Parent.SubscriptionItemDetails.Proration = true
		}},
		{"manual invoice", func(s *stripe.Subscription, i *stripe.Invoice) { i.BillingReason = stripe.InvoiceBillingReasonManual }},
		{"free trial", func(s *stripe.Subscription, i *stripe.Invoice) { s.TrialEnd = 1 }},
		{"paused collection", func(s *stripe.Subscription, i *stripe.Invoice) {
			s.PauseCollection = &stripe.SubscriptionPauseCollection{}
		}},
		{"changed plan amount", func(s *stripe.Subscription, i *stripe.Invoice) { s.Items.Data[0].Price.UnitAmount = 1 }},
	} {
		t.Run(tc.name, func(t *testing.T) {
			creation, subscription, invoice := paidStripeFixtures()
			tc.change(subscription, invoice)
			if period, err := verifiedStripePaidPeriod(creation, subscription, invoice); period != nil || err == nil {
				t.Fatal("mismatched payment must not grant a period")
			}
		})
	}
}

func paidStripeFixtures() (checkoutCreation, *stripe.Subscription, *stripe.Invoice) {
	creation := checkoutCreation{Request: checkoutCreationTestRequest(), IdempotencyKey: "purchase-key"}
	price := validStripeCheckoutPrice()
	price.ID = creation.Request.PriceID
	start := time.Now().Add(-time.Hour).Truncate(time.Second).Unix()
	end := start + int64(30*24*time.Hour/time.Second)
	subscription := &stripe.Subscription{
		ID: "sub_paid", Customer: &stripe.Customer{ID: creation.Request.CustomerID}, Status: stripe.SubscriptionStatusActive,
		Metadata: map[string]string{"team_id": creation.Request.TeamID}, LatestInvoice: &stripe.Invoice{ID: "in_paid"},
		Items: &stripe.SubscriptionItemList{Data: []*stripe.SubscriptionItem{{
			ID: "si_plan", Price: price, Quantity: 1, CurrentPeriodStart: start, CurrentPeriodEnd: end,
		}}},
	}
	invoice := &stripe.Invoice{
		ID: "in_paid", Customer: &stripe.Customer{ID: creation.Request.CustomerID}, Status: stripe.InvoiceStatusPaid,
		AmountPaid: 1000, Currency: stripe.CurrencyUSD, CollectionMethod: stripe.InvoiceCollectionMethodChargeAutomatically,
		BillingReason: stripe.InvoiceBillingReasonSubscriptionCreate,
		Parent:        &stripe.InvoiceParent{SubscriptionDetails: &stripe.InvoiceParentSubscriptionDetails{Subscription: &stripe.Subscription{ID: subscription.ID}}},
		Lines: &stripe.InvoiceLineItemList{Data: []*stripe.InvoiceLineItem{{
			ID: "il_plan", Invoice: "in_paid", Amount: 1000, Currency: stripe.CurrencyUSD, Quantity: 1,
			Period:  &stripe.Period{Start: start, End: end},
			Pricing: &stripe.InvoiceLineItemPricing{PriceDetails: &stripe.InvoiceLineItemPricingPriceDetails{Price: &stripe.Price{ID: price.ID}}},
			Parent: &stripe.InvoiceLineItemParent{SubscriptionItemDetails: &stripe.InvoiceLineItemParentSubscriptionItemDetails{
				Subscription: subscription.ID, SubscriptionItem: "si_plan",
			}},
		}}},
	}
	return creation, subscription, invoice
}
