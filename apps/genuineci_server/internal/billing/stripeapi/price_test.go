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
			client := testutil.NewStripeClient(t, func(*http.Request) (*http.Response, error) {
				if tc.status == 0 {
					return nil, errors.New(tc.body)
				}
				return testutil.StripeResponse(tc.status, tc.body), nil
			})

			price, err := stripeapi.GetPrice(t.Context(), client, "price_light")

			if price != nil || err == nil || err.Error() != "Stripe Price retrieval failed" {
				t.Fatalf("expected no price and a sanitized error, got err=%v", err)
			}
		})
	}
}

func TestGetStripePriceHonorsCancellation(t *testing.T) {
	ctx, cancel := context.WithCancel(t.Context())
	defer cancel()
	client := testutil.NewStripeClient(t, func(request *http.Request) (*http.Response, error) {
		cancel()
		<-request.Context().Done()
		return nil, request.Context().Err()
	})

	price, err := stripeapi.GetPrice(ctx, client, "price_light")

	if price != nil || !errors.Is(err, context.Canceled) {
		t.Fatalf("expected cancellation with no price, got err=%v", err)
	}
}

func TestGetStripePriceHonorsEarlierDeadline(t *testing.T) {
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

	price, err := stripeapi.GetPrice(ctx, client, "price_light")

	if price != nil || !errors.Is(err, context.DeadlineExceeded) {
		t.Fatalf("expected deadline exceeded with no price, got err=%v", err)
	}
}

func TestGetStripePriceRejectsMissingConfigurationOrID(t *testing.T) {
	client := testutil.NewStripeClient(t, func(*http.Request) (*http.Response, error) {
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
			price, err := stripeapi.GetPrice(t.Context(), tc.client, tc.priceID)

			if price != nil || err == nil || err.Error() != tc.want {
				t.Fatalf("expected no price and error %q, got %v", tc.want, err)
			}
		})
	}
}
