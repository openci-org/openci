package billing

import (
	"encoding/json"
	"errors"
	"net/http"
	"testing"

	"github.com/stripe/stripe-go/v87"
)

func TestCurrentStripeSubscriptionReadsAllPages(t *testing.T) {
	_, active, _ := paidStripeFixtures()
	old := *active
	old.ID, old.Status = "sub_old", stripe.SubscriptionStatusCanceled
	pages := 0
	client := newStripeReadTestClient(t, func(r *http.Request) (*http.Response, error) {
		pages++
		if r.URL.Query().Get("status") != "all" || r.URL.Query().Get("customer") != active.Customer.ID {
			t.Fatal("must inspect all statuses for the team's Customer")
		}
		data, more := []*stripe.Subscription{&old}, true
		if pages == 2 {
			if r.URL.Query().Get("starting_after") != "sub_old" {
				t.Fatal("must paginate")
			}
			data, more = []*stripe.Subscription{active}, false
		}
		return stripeObjectResponse(t, map[string]any{"object": "list", "data": data, "has_more": more}), nil
	})
	got, err := currentStripeSubscription(t.Context(), client, active.Customer)
	if err != nil || got.ID != active.ID || pages != 2 {
		t.Fatalf("must choose the current contract: %v", err)
	}
}

func TestCurrentStripeSubscriptionRejectsAmbiguousContracts(t *testing.T) {
	_, subscription, _ := paidStripeFixtures()
	client := newStripeReadTestClient(t, func(r *http.Request) (*http.Response, error) {
		return stripeObjectResponse(t, map[string]any{"object": "list", "data": []*stripe.Subscription{subscription, subscription}}), nil
	})
	if got, err := currentStripeSubscription(t.Context(), client, subscription.Customer); got != nil || !errors.Is(err, errStripePaymentUnverified) {
		t.Fatal("multiple nonterminal contracts must fail closed")
	}
}

func TestSubscriptionCheckoutRequiresAnUnambiguousCompletedPurchase(t *testing.T) {
	for _, outcome := range []string{"one", "none", "multiple", "wrong Customer", "open"} {
		t.Run(outcome, func(t *testing.T) {
			creation, subscription, _ := paidStripeFixtures()
			session := checkoutSessionForCreation(creation, "cs_paid")
			session.Status, session.Subscription = stripe.CheckoutSessionStatusComplete, subscription
			data := []*stripe.CheckoutSession{session}
			switch outcome {
			case "none":
				data = nil
			case "multiple":
				data = append(data, session)
			case "wrong Customer":
				session.Customer.ID = "cus_other"
			case "open":
				session.Status = stripe.CheckoutSessionStatusOpen
			}
			client := newStripeReadTestClient(t, func(r *http.Request) (*http.Response, error) {
				if r.URL.Query().Get("subscription") != subscription.ID {
					t.Fatal("must filter by subscription")
				}
				return stripeObjectResponse(t, map[string]any{"object": "list", "data": data}), nil
			})
			got, err := subscriptionCheckout(t.Context(), client, subscription)
			if outcome == "one" {
				if err != nil || got.ID != session.ID {
					t.Fatalf("expected purchase: %v", err)
				}
			} else if got != nil || !errors.Is(err, errStripePaymentUnverified) {
				t.Fatal("must reject ambiguous purchase")
			}
		})
	}
}

func TestGetStripeInvoiceValidatesIdentityAndSanitizesFailure(t *testing.T) {
	for _, outcome := range []string{"paid", "wrong ID", "upstream failure"} {
		t.Run(outcome, func(t *testing.T) {
			client := newStripeReadTestClient(t, func(r *http.Request) (*http.Response, error) {
				if outcome == "upstream failure" {
					return nil, errors.New("sensitive provider response")
				}
				_, _, invoice := paidStripeFixtures()
				if outcome == "wrong ID" {
					invoice.ID = "in_other"
				}
				return stripeObjectResponse(t, invoice), nil
			})
			invoice, err := getStripeInvoice(t.Context(), client, "in_paid")
			if outcome == "paid" {
				if err != nil || invoice.ID != "in_paid" {
					t.Fatal(err)
				}
			} else if invoice != nil || err == nil || err.Error() == "sensitive provider response" {
				t.Fatal("must return a sanitized failure")
			}
		})
	}
}

func stripeObjectResponse(t *testing.T, value any) *http.Response {
	t.Helper()
	body, err := json.Marshal(value)
	if err != nil {
		t.Fatal(err)
	}
	return stripeTestResponse(http.StatusOK, string(body))
}
