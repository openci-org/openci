package billing

import (
	"encoding/json"
	"errors"
	"net/http"
	"testing"

	"github.com/stripe/stripe-go/v87"
)

func TestGetOwnedStripeCustomer(t *testing.T) {
	for _, body := range []string{
		`{"id":"cus_team","metadata":{"team_id":"team-1"}}`,
		`{"id":"cus_other","metadata":{"team_id":"team-1"}}`,
		`{"id":"cus_team","metadata":{"team_id":"team-2"}}`,
		`{"id":"cus_team","metadata":{"team_id":"team-1"},"livemode":true}`,
		`{"id":"cus_team","deleted":true}`,
	} {
		t.Run(body, func(t *testing.T) {
			client := newStripeReadTestClient(t, func(r *http.Request) (*http.Response, error) {
				if r.Method != http.MethodGet || r.URL.Path != "/v1/customers/cus_team" {
					t.Error("must retrieve the stored Customer")
				}
				return stripeTestResponse(http.StatusOK, body), nil
			})
			got, err := getOwnedStripeCustomer(t.Context(), client, stripeCustomerRequest{TeamID: "team-1"}, "cus_team")
			valid := body == `{"id":"cus_team","metadata":{"team_id":"team-1"}}`
			if valid && (err != nil || got == nil) || !valid && (err == nil || got != nil) {
				t.Fatalf("unexpected ownership result: got=%v, err=%v", got, err)
			}
		})
	}
}

func TestRequireNoStripeSubscription(t *testing.T) {
	for _, status := range []stripe.SubscriptionStatus{
		stripe.SubscriptionStatusActive, stripe.SubscriptionStatusTrialing,
		stripe.SubscriptionStatusPastDue, stripe.SubscriptionStatusUnpaid,
		stripe.SubscriptionStatusIncomplete, stripe.SubscriptionStatusPaused,
		stripe.SubscriptionStatusCanceled, stripe.SubscriptionStatusIncompleteExpired, "unknown",
	} {
		t.Run(string(status), func(t *testing.T) {
			customer := &stripe.Customer{ID: "cus_team"}
			client := newStripeReadTestClient(t, func(r *http.Request) (*http.Response, error) {
				if r.URL.Query().Get("customer") != customer.ID || r.URL.Query().Get("status") != "all" {
					t.Error("must inspect all subscription states for the Customer")
				}
				return subscriptionListResponse(t, []*stripe.Subscription{{ID: "sub_team", Customer: customer, Status: status}}, false), nil
			})
			err := requireNoStripeSubscription(t.Context(), client, customer)
			terminal := status == stripe.SubscriptionStatusCanceled || status == stripe.SubscriptionStatusIncompleteExpired
			if terminal && err != nil || !terminal && !errors.Is(err, errStripeSubscriptionExists) {
				t.Fatalf("nonterminal contracts must block another purchase: %v", err)
			}
		})
	}
}

func TestRequireNoStripeSubscriptionChecksLaterPages(t *testing.T) {
	customer := &stripe.Customer{ID: "cus_team"}
	calls := 0
	client := newStripeReadTestClient(t, func(r *http.Request) (*http.Response, error) {
		calls++
		if calls == 1 {
			return subscriptionListResponse(t, []*stripe.Subscription{{ID: "sub_old", Customer: customer, Status: stripe.SubscriptionStatusCanceled}}, true), nil
		}
		if r.URL.Query().Get("starting_after") != "sub_old" {
			t.Error("must follow pagination before allowing a purchase")
		}
		return subscriptionListResponse(t, []*stripe.Subscription{{ID: "sub_active", Customer: customer, Status: stripe.SubscriptionStatusActive}}, false), nil
	})
	if err := requireNoStripeSubscription(t.Context(), client, customer); !errors.Is(err, errStripeSubscriptionExists) || calls != 2 {
		t.Fatalf("must block the later active subscription: calls=%d, err=%v", calls, err)
	}
}

func subscriptionListResponse(t *testing.T, subscriptions []*stripe.Subscription, more bool) *http.Response {
	t.Helper()
	body, err := json.Marshal(map[string]any{"object": "list", "data": subscriptions, "has_more": more})
	if err != nil {
		t.Fatal(err)
	}
	return stripeTestResponse(http.StatusOK, string(body))
}
