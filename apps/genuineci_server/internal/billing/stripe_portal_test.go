package billing

import (
	"context"
	"encoding/json"
	"errors"
	"net/http"
	"net/url"
	"reflect"
	"strings"
	"testing"

	"github.com/stripe/stripe-go/v87"
)

func TestCreateStripePortalSession(t *testing.T) {
	request := stripePortalRequest{CustomerID: "cus_team", ConfigurationID: "bpc_team", ReturnURL: "https://app.example/billing?team=team-1"}
	client := newStripeReadTestClient(t, func(r *http.Request) (*http.Response, error) {
		if r.Method == http.MethodGet {
			if r.URL.Path != "/v1/billing_portal/configurations/bpc_team" {
				t.Error("must retrieve the configured Portal policy")
			}
			return portalConfigurationResponse(t, validPortalConfiguration()), nil
		}
		if err := r.ParseForm(); err != nil {
			t.Fatal(err)
		}
		want := url.Values{"customer": {request.CustomerID}, "configuration": {request.ConfigurationID}, "return_url": {request.ReturnURL}}
		if r.URL.Path != "/v1/billing_portal/sessions" || !reflect.DeepEqual(r.PostForm, want) {
			t.Error("must use server-owned Customer, configuration, and return URL")
		}
		return stripeTestResponse(http.StatusOK, `{"id":"bps_team","customer":"cus_team","configuration":"bpc_team","return_url":"https://app.example/billing?team=team-1","url":"https://billing.stripe.com/p/session/test"}`), nil
	})
	if session, err := createStripePortalSession(t.Context(), client, request); err != nil || session == nil || session.ID != "bps_team" {
		t.Fatalf("want a matched Portal Session: session=%v, err=%v", session, err)
	}
}

func TestCreateStripePortalSessionRejectsUnsafeConfiguration(t *testing.T) {
	for _, tc := range []struct {
		name   string
		change func(*stripe.BillingPortalConfiguration)
	}{
		{"inactive", func(c *stripe.BillingPortalConfiguration) { c.Active = false }},
		{"wrong mode", func(c *stripe.BillingPortalConfiguration) { c.Livemode = true }},
		{"missing features", func(c *stripe.BillingPortalConfiguration) { c.Features = nil }},
		{"no invoices", func(c *stripe.BillingPortalConfiguration) { c.Features.InvoiceHistory.Enabled = false }},
		{"no card updates", func(c *stripe.BillingPortalConfiguration) { c.Features.PaymentMethodUpdate.Enabled = false }},
		{"plan or quantity changes", func(c *stripe.BillingPortalConfiguration) { c.Features.SubscriptionUpdate.Enabled = true }},
		{"immediate cancellation", func(c *stripe.BillingPortalConfiguration) { c.Features.SubscriptionCancel.Mode = "immediately" }},
		{"public login", func(c *stripe.BillingPortalConfiguration) {
			c.LoginPage = &stripe.BillingPortalConfigurationLoginPage{Enabled: true}
		}},
	} {
		t.Run(tc.name, func(t *testing.T) {
			config := validPortalConfiguration()
			tc.change(config)
			client := newStripeReadTestClient(t, func(r *http.Request) (*http.Response, error) {
				if r.Method != http.MethodGet {
					t.Error("invalid policy must prevent Session creation")
				}
				return portalConfigurationResponse(t, config), nil
			})
			request := stripePortalRequest{CustomerID: "cus_team", ConfigurationID: "bpc_team", ReturnURL: "https://app.example/billing"}
			if got, err := createStripePortalSession(t.Context(), client, request); got != nil || err == nil {
				t.Fatal("unsafe Portal configuration must not return a Session")
			}
		})
	}
}

func TestCreateStripePortalSessionRejectsMismatchedResponse(t *testing.T) {
	for field, value := range map[string]any{
		"customer": "cus_other", "configuration": "bpc_other", "livemode": true,
		"return_url": "https://other.example/billing", "url": "",
	} {
		t.Run(field, func(t *testing.T) {
			client := newStripeReadTestClient(t, func(r *http.Request) (*http.Response, error) {
				if r.Method == http.MethodGet {
					return portalConfigurationResponse(t, validPortalConfiguration()), nil
				}
				response := map[string]any{
					"id": "bps_team", "customer": "cus_team", "configuration": "bpc_team",
					"return_url": "https://app.example/billing", "url": "https://billing.stripe.com/p/session/test",
				}
				response[field] = value
				body, err := json.Marshal(response)
				if err != nil {
					t.Fatal(err)
				}
				return stripeTestResponse(http.StatusOK, string(body)), nil
			})
			request := stripePortalRequest{CustomerID: "cus_team", ConfigurationID: "bpc_team", ReturnURL: "https://app.example/billing"}
			if got, err := createStripePortalSession(t.Context(), client, request); got != nil || err == nil {
				t.Fatal("must not expose an unmatched Portal Session")
			}
		})
	}
}

func TestCreateStripePortalSessionPreservesCancellationAndSanitizesErrors(t *testing.T) {
	for _, canceled := range []bool{false, true} {
		t.Run(map[bool]string{false: "SDK failure", true: "cancellation"}[canceled], func(t *testing.T) {
			ctx, cancel := context.WithCancel(t.Context())
			defer cancel()
			client := newStripeReadTestClient(t, func(*http.Request) (*http.Response, error) {
				if canceled {
					cancel()
				}
				return nil, errors.New("sk_test_sensitive")
			})
			request := stripePortalRequest{CustomerID: "cus_team", ConfigurationID: "bpc_team", ReturnURL: "https://app.example/billing"}
			got, err := createStripePortalSession(ctx, client, request)
			if got != nil || err == nil || strings.Contains(err.Error(), "sensitive") || canceled && !errors.Is(err, context.Canceled) {
				t.Fatalf("must sanitize errors and preserve cancellation: %v", err)
			}
		})
	}
}

func validPortalConfiguration() *stripe.BillingPortalConfiguration {
	return &stripe.BillingPortalConfiguration{
		ID: "bpc_team", Active: true,
		Features: &stripe.BillingPortalConfigurationFeatures{
			InvoiceHistory:      &stripe.BillingPortalConfigurationFeaturesInvoiceHistory{Enabled: true},
			PaymentMethodUpdate: &stripe.BillingPortalConfigurationFeaturesPaymentMethodUpdate{Enabled: true},
			SubscriptionUpdate:  &stripe.BillingPortalConfigurationFeaturesSubscriptionUpdate{},
			SubscriptionCancel: &stripe.BillingPortalConfigurationFeaturesSubscriptionCancel{
				Enabled: true, Mode: stripe.BillingPortalConfigurationFeaturesSubscriptionCancelModeAtPeriodEnd,
				ProrationBehavior: stripe.BillingPortalConfigurationFeaturesSubscriptionCancelProrationBehaviorNone,
			},
		},
	}
}

func portalConfigurationResponse(t *testing.T, config *stripe.BillingPortalConfiguration) *http.Response {
	t.Helper()
	body, err := json.Marshal(config)
	if err != nil {
		t.Fatal(err)
	}
	return stripeTestResponse(http.StatusOK, string(body))
}
