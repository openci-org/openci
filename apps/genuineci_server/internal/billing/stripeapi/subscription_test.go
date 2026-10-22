package stripeapi_test

import (
	"context"
	"errors"
	"net/http"
	"testing"
	"time"

	"github.com/openci-org/openci/apps/genuineci_server/internal/billing/stripeapi"
	"github.com/openci-org/openci/apps/genuineci_server/internal/testutil"
	"github.com/stripe/stripe-go/v87"
)

func TestGetStripeSubscription(t *testing.T) {
	client := testutil.NewStripeClient(t, func(request *http.Request) (*http.Response, error) {
		if request.Method != http.MethodGet || request.URL.Path != "/v1/subscriptions/sub_team" {
			t.Errorf("unexpected request: %s %s", request.Method, request.URL.Path)
		}
		deadline, ok := request.Context().Deadline()
		if !ok || time.Until(deadline) <= 0 || time.Until(deadline) > 10*time.Second {
			t.Error("Stripe reads must have a deadline within ten seconds")
		}
		return testutil.StripeResponse(http.StatusOK, `{
			"id": "sub_team",
			"object": "subscription",
			"status": "active",
			"customer": "cus_team",
			"items": {"data": [{"id": "si_team", "price": {"id": "price_light"}}]}
		}`), nil
	})

	subscription, err := stripeapi.GetSubscription(t.Context(), client, "sub_team")

	if err != nil {
		t.Fatal(err)
	}
	if subscription.ID != "sub_team" || subscription.Status != stripe.SubscriptionStatusActive {
		t.Fatal("expected the requested Subscription")
	}
	if subscription.Customer == nil || subscription.Customer.ID != "cus_team" {
		t.Fatal("expected the customer reference")
	}
	if subscription.Items == nil || len(subscription.Items.Data) != 1 {
		t.Fatal("expected one subscription item")
	}
	if price := subscription.Items.Data[0].Price; price == nil || price.ID != "price_light" {
		t.Fatal("expected the subscription item's price")
	}
}

func TestGetStripeSubscriptionSanitizesFailures(t *testing.T) {
	for _, tc := range []struct {
		name   string
		status int
		body   string
	}{
		{"Stripe error", http.StatusUnauthorized, `{"error":{"type":"invalid_request_error","message":"invalid sk_test_sensitive"}}`},
		{"missing subscription", http.StatusNotFound, `{"error":{"type":"invalid_request_error","code":"resource_missing","message":"private subscription details"}}`},
		{"invalid JSON", http.StatusOK, `upstream body with sk_test_sensitive`},
		{"transport error", 0, "transport failure containing sk_test_sensitive"},
	} {
		t.Run(tc.name, func(t *testing.T) {
			client := testutil.NewStripeClient(t, func(*http.Request) (*http.Response, error) {
				if tc.status == 0 {
					return nil, errors.New(tc.body)
				}
				return testutil.StripeResponse(tc.status, tc.body), nil
			})

			subscription, err := stripeapi.GetSubscription(t.Context(), client, "sub_team")

			if subscription != nil || err == nil || err.Error() != "Stripe Subscription retrieval failed" {
				t.Fatalf("expected no subscription and a sanitized error, got err=%v", err)
			}
		})
	}
}

func TestGetStripeSubscriptionHonorsCancellation(t *testing.T) {
	ctx, cancel := context.WithCancel(t.Context())
	defer cancel()
	client := testutil.NewStripeClient(t, func(request *http.Request) (*http.Response, error) {
		cancel()
		<-request.Context().Done()
		return nil, request.Context().Err()
	})

	subscription, err := stripeapi.GetSubscription(ctx, client, "sub_team")

	if subscription != nil || !errors.Is(err, context.Canceled) {
		t.Fatalf("expected cancellation with no subscription, got err=%v", err)
	}
}

func TestGetStripeSubscriptionHonorsEarlierDeadline(t *testing.T) {
	ctx, cancel := context.WithTimeout(t.Context(), 100*time.Millisecond)
	defer cancel()
	wantDeadline, _ := ctx.Deadline()
	client := testutil.NewStripeClient(t, func(request *http.Request) (*http.Response, error) {
		if deadline, ok := request.Context().Deadline(); !ok || !deadline.Equal(wantDeadline) {
			t.Error("must preserve the caller's earlier deadline")
		}
		<-request.Context().Done()
		return nil, request.Context().Err()
	})

	subscription, err := stripeapi.GetSubscription(ctx, client, "sub_team")

	if subscription != nil || !errors.Is(err, context.DeadlineExceeded) {
		t.Fatalf("expected deadline exceeded with no subscription, got err=%v", err)
	}
}

func TestGetStripeSubscriptionRejectsMissingConfigurationOrID(t *testing.T) {
	client := testutil.NewStripeClient(t, func(*http.Request) (*http.Response, error) {
		t.Error("invalid input must not make a Stripe request")
		return nil, errors.New("unexpected request")
	})
	for _, tc := range []struct {
		name           string
		client         *stripe.Client
		subscriptionID string
		want           string
	}{
		{"disabled billing", nil, "sub_team", "Stripe billing is not configured"},
		{"empty ID", client, "", "Stripe Subscription ID must be set"},
		{"blank ID", client, " \t", "Stripe Subscription ID must be set"},
	} {
		t.Run(tc.name, func(t *testing.T) {
			subscription, err := stripeapi.GetSubscription(t.Context(), tc.client, tc.subscriptionID)

			if subscription != nil || err == nil || err.Error() != tc.want {
				t.Fatalf("expected no subscription and error %q, got %v", tc.want, err)
			}
		})
	}
}
