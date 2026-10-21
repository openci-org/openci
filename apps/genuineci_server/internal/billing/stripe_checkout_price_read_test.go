package billing

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"testing"

	"github.com/stripe/stripe-go/v87"
)

func TestGetStripeCheckoutPrice(t *testing.T) {
	for _, tc := range []struct {
		name, planID, priceID string
		amount                int64
		livemode              bool
	}{
		{"Light in test mode", "light", "price_light", 1_000, false},
		{"Light in live mode", "light", "price_light", 1_000, true},
		{"Pro in test mode", "pro", "price_pro", 10_000, false},
		{"Pro in live mode", "pro", "price_pro", 10_000, true},
	} {
		t.Run(tc.name, func(t *testing.T) {
			configured := validStripeCheckoutPrice()
			configured.ID = tc.priceID
			configured.UnitAmount = tc.amount
			configured.Livemode = tc.livemode
			client := newStripeReadTestClient(t, func(request *http.Request) (*http.Response, error) {
				if request.Method != http.MethodGet || request.URL.Path != "/v1/prices/"+tc.priceID {
					t.Errorf("must retrieve the server-selected Price: %s %s", request.Method, request.URL.Path)
				}
				return stripeCheckoutPriceTestResponse(t, configured), nil
			})
			t.Setenv("STRIPE_LIGHT_PRICE_ID", "price_light")
			t.Setenv("STRIPE_PRO_PRICE_ID", "price_pro")

			price, err := getStripeCheckoutPrice(t.Context(), client, tc.planID, tc.livemode)

			if err != nil {
				t.Fatal(err)
			}
			if price == nil || price.ID != tc.priceID {
				t.Fatal("expected the configured, validated Price")
			}
		})
	}
}

func TestGetStripeCheckoutPriceRejectsMismatches(t *testing.T) {
	for _, tc := range []struct {
		name   string
		change func(*stripe.Price)
	}{
		{"wrong ID", func(p *stripe.Price) { p.ID = "price_other" }},
		{"wrong plan amount", func(p *stripe.Price) { p.UnitAmount = 10_000 }},
		{"wrong mode", func(p *stripe.Price) { p.Livemode = true }},
		{"inactive", func(p *stripe.Price) { p.Active = false }},
	} {
		t.Run(tc.name, func(t *testing.T) {
			configured := validStripeCheckoutPrice()
			tc.change(configured)
			client := newStripeReadTestClient(t, func(*http.Request) (*http.Response, error) {
				return stripeCheckoutPriceTestResponse(t, configured), nil
			})
			t.Setenv("STRIPE_LIGHT_PRICE_ID", "price_configured")

			price, err := getStripeCheckoutPrice(t.Context(), client, "light", false)

			if price != nil || err == nil {
				t.Fatal("mismatched Price must not be returned for Checkout")
			}
		})
	}
}

func TestGetStripeCheckoutPriceRejectsInvalidInputBeforeRequest(t *testing.T) {
	client := newStripeReadTestClient(t, func(*http.Request) (*http.Response, error) {
		t.Error("invalid input must not make a Stripe request")
		return nil, errors.New("unexpected request")
	})
	for _, tc := range []struct {
		name, planID, configuredID string
		client                     *stripe.Client
	}{
		{"missing Price", "light", "", client},
		{"unknown plan", "unknown", "price_configured", client},
		{"missing client", "light", "price_configured", nil},
	} {
		t.Run(tc.name, func(t *testing.T) {
			t.Setenv("STRIPE_LIGHT_PRICE_ID", tc.configuredID)

			price, err := getStripeCheckoutPrice(t.Context(), tc.client, tc.planID, false)

			if price != nil || err == nil {
				t.Fatal("invalid input must return an error without a Price")
			}
		})
	}
}

func TestGetStripeCheckoutPriceWhenBillingDisabled(t *testing.T) {
	for _, tc := range []struct {
		name, mode, enabled string
	}{
		{"self hosted", "self_hosted", "invalid"},
		{"disabled cloud", "cloud", "false"},
	} {
		t.Run(tc.name, func(t *testing.T) {
			client := newStripeReadTestClient(t, func(*http.Request) (*http.Response, error) {
				t.Error("disabled billing must not make a Stripe request")
				return nil, errors.New("unexpected request")
			})
			t.Setenv("SERVER_ACCESS_MODE", tc.mode)
			t.Setenv("BILLING_ENABLED", tc.enabled)
			t.Setenv("STRIPE_LIGHT_PRICE_ID", "price_configured")

			price, err := getStripeCheckoutPrice(t.Context(), client, "light", false)

			if price != nil || err == nil || err.Error() != "Stripe billing is not configured" {
				t.Fatalf("want no Price and a disabled-billing error, got err=%v", err)
			}
		})
	}
}

func TestGetStripeCheckoutPricePreservesSanitizedFailure(t *testing.T) {
	client := newStripeReadTestClient(t, func(*http.Request) (*http.Response, error) {
		return stripeTestResponse(http.StatusNotFound, `{"error":{"message":"private Stripe details"}}`), nil
	})
	t.Setenv("STRIPE_LIGHT_PRICE_ID", "price_configured")

	price, err := getStripeCheckoutPrice(t.Context(), client, "light", false)

	if price != nil || err == nil || err.Error() != "Stripe Price retrieval failed" {
		t.Fatalf("want no Price and a sanitized retrieval error, got err=%v", err)
	}
}

func TestGetStripeCheckoutPricePreservesCancellation(t *testing.T) {
	ctx, cancel := context.WithCancel(t.Context())
	defer cancel()
	client := newStripeReadTestClient(t, func(request *http.Request) (*http.Response, error) {
		cancel()
		<-request.Context().Done()
		return nil, request.Context().Err()
	})
	t.Setenv("STRIPE_LIGHT_PRICE_ID", "price_configured")

	price, err := getStripeCheckoutPrice(ctx, client, "light", false)

	if price != nil || !errors.Is(err, context.Canceled) {
		t.Fatalf("want no Price and context cancellation, got err=%v", err)
	}
}

func stripeCheckoutPriceTestResponse(t *testing.T, price *stripe.Price) *http.Response {
	t.Helper()
	body, err := json.Marshal(price)
	if err != nil {
		t.Fatal(err)
	}
	return stripeTestResponse(http.StatusOK, string(body))
}
