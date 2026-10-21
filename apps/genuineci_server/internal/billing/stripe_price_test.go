package billing

import (
	"context"
	"errors"
	"net/http"
	"testing"
	"time"

	"github.com/stripe/stripe-go/v87"
)

func TestGetStripePrice(t *testing.T) {
	client := newStripeReadTestClient(t, func(request *http.Request) (*http.Response, error) {
		if request.Method != http.MethodGet || request.URL.Path != "/v1/prices/price_light" {
			t.Errorf("unexpected request: %s %s", request.Method, request.URL.Path)
		}
		deadline, ok := request.Context().Deadline()
		if !ok || time.Until(deadline) <= 0 || time.Until(deadline) > 10*time.Second {
			t.Error("Stripe reads must have a deadline within ten seconds")
		}
		return stripeTestResponse(http.StatusOK, `{
			"id": "price_light",
			"object": "price",
			"active": true,
			"livemode": false,
			"currency": "usd",
			"unit_amount": 1000,
			"billing_scheme": "per_unit",
			"type": "recurring",
			"recurring": {"interval": "month", "interval_count": 1, "usage_type": "licensed"}
		}`), nil
	})

	price, err := getStripePrice(t.Context(), client, "price_light")

	if err != nil {
		t.Fatal(err)
	}
	if price == nil || price.ID != "price_light" {
		t.Fatal("expected the requested Price")
	}
	if err := validateStripeCheckoutPrice(price, "light", false); err != nil {
		t.Fatalf("retrieved Price must be usable by Checkout validation: %v", err)
	}
}

func TestGetStripePriceSanitizesFailures(t *testing.T) {
	for _, tc := range []struct {
		name   string
		status int
		body   string
	}{
		{"Stripe error", http.StatusUnauthorized, `{"error":{"type":"invalid_request_error","message":"invalid sk_test_sensitive"}}`},
		{"missing price", http.StatusNotFound, `{"error":{"type":"invalid_request_error","code":"resource_missing","message":"private price details"}}`},
		{"invalid JSON", http.StatusOK, `upstream body with sk_test_sensitive`},
		{"transport error", 0, "transport failure containing sk_test_sensitive"},
	} {
		t.Run(tc.name, func(t *testing.T) {
			client := newStripeReadTestClient(t, func(*http.Request) (*http.Response, error) {
				if tc.status == 0 {
					return nil, errors.New(tc.body)
				}
				return stripeTestResponse(tc.status, tc.body), nil
			})

			price, err := getStripePrice(t.Context(), client, "price_light")

			if price != nil || err == nil || err.Error() != "Stripe Price retrieval failed" {
				t.Fatalf("expected no price and a sanitized error, got err=%v", err)
			}
		})
	}
}

func TestGetStripePriceHonorsCancellation(t *testing.T) {
	ctx, cancel := context.WithCancel(t.Context())
	defer cancel()
	client := newStripeReadTestClient(t, func(request *http.Request) (*http.Response, error) {
		cancel()
		<-request.Context().Done()
		return nil, request.Context().Err()
	})

	price, err := getStripePrice(ctx, client, "price_light")

	if price != nil || !errors.Is(err, context.Canceled) {
		t.Fatalf("expected cancellation with no price, got err=%v", err)
	}
}

func TestGetStripePriceHonorsEarlierDeadline(t *testing.T) {
	ctx, cancel := context.WithTimeout(t.Context(), 100*time.Millisecond)
	defer cancel()
	wantDeadline, _ := ctx.Deadline()
	client := newStripeReadTestClient(t, func(request *http.Request) (*http.Response, error) {
		if deadline, ok := request.Context().Deadline(); !ok || !deadline.Equal(wantDeadline) {
			t.Error("must preserve the caller's earlier deadline")
		}
		<-request.Context().Done()
		return nil, request.Context().Err()
	})

	price, err := getStripePrice(ctx, client, "price_light")

	if price != nil || !errors.Is(err, context.DeadlineExceeded) {
		t.Fatalf("expected deadline exceeded with no price, got err=%v", err)
	}
}

func TestGetStripePriceRejectsMissingConfigurationOrID(t *testing.T) {
	client := newStripeReadTestClient(t, func(*http.Request) (*http.Response, error) {
		t.Error("invalid input must not make a Stripe request")
		return nil, errors.New("unexpected request")
	})
	for _, tc := range []struct {
		name    string
		client  *stripe.Client
		priceID string
		want    string
	}{
		{"disabled billing", nil, "price_light", "Stripe billing is not configured"},
		{"empty ID", client, "", "Stripe Price ID must be set"},
		{"blank ID", client, " \t", "Stripe Price ID must be set"},
	} {
		t.Run(tc.name, func(t *testing.T) {
			price, err := getStripePrice(t.Context(), tc.client, tc.priceID)

			if price != nil || err == nil || err.Error() != tc.want {
				t.Fatalf("expected no price and error %q, got %v", tc.want, err)
			}
		})
	}
}
