package testutil

import (
	"encoding/json"
	"io"
	"net/http"
	"strings"
	"testing"

	"github.com/openci-org/openci/apps/genuineci_server/internal/billing/stripeapi"
	"github.com/stripe/stripe-go/v87"
)

func NewStripeClient(t *testing.T, transport StripeTransport) *stripe.Client {
	t.Helper()
	t.Setenv("SERVER_ACCESS_MODE", "cloud")
	t.Setenv("BILLING_ENABLED", "true")
	t.Setenv("STRIPE_SECRET_KEY", "sk_test_placeholder")
	client, err := stripeapi.NewClient()
	if err != nil {
		t.Fatal(err)
	}
	backend := client.V1CheckoutSessions.B.(*stripe.BackendImplementation)
	backend.HTTPClient = &http.Client{Transport: transport}
	backend.SetMaxNetworkRetries(0)
	return client
}

func StripeResponse(status int, body string) *http.Response {
	return &http.Response{
		StatusCode: status,
		Header:     http.Header{"Content-Type": {"application/json"}},
		Body:       io.NopCloser(strings.NewReader(body)),
	}
}

func PortalConfiguration() *stripe.BillingPortalConfiguration {
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

func PortalConfigurationResponse(t *testing.T, config *stripe.BillingPortalConfiguration) *http.Response {
	t.Helper()
	body, err := json.Marshal(config)
	if err != nil {
		t.Fatal(err)
	}
	return StripeResponse(http.StatusOK, string(body))
}

type StripeTransport func(*http.Request) (*http.Response, error)

func (transport StripeTransport) RoundTrip(request *http.Request) (*http.Response, error) {
	return transport(request)
}
