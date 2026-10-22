package stripeapi_test

import (
	"github.com/openci-org/openci/apps/genuineci_server/internal/billing/stripeapi"
	"testing"
)

func TestNewStripeClient(t *testing.T) {
	t.Setenv("SERVER_ACCESS_MODE", "cloud")
	t.Setenv("BILLING_ENABLED", "true")
	t.Setenv("STRIPE_SECRET_KEY", "sk_test_placeholder")

	client, err := stripeapi.NewClient()

	if err != nil {
		t.Fatal(err)
	}
	if client == nil {
		t.Fatal("enabled Cloud billing must create a Stripe client")
	}
}

func TestNewStripeClientWhenBillingDisabled(t *testing.T) {
	for _, tc := range []struct {
		name, mode, enabled string
	}{
		{"self hosted", "self_hosted", "invalid"},
		{"disabled cloud", "cloud", "false"},
	} {
		t.Run(tc.name, func(t *testing.T) {
			t.Setenv("SERVER_ACCESS_MODE", tc.mode)
			t.Setenv("BILLING_ENABLED", tc.enabled)
			t.Setenv("STRIPE_SECRET_KEY", "")

			client, err := stripeapi.NewClient()

			if err != nil {
				t.Fatal(err)
			}
			if client != nil {
				t.Fatal("disabled billing must not create a Stripe client")
			}
		})
	}
}

func TestNewStripeClientRequiresKey(t *testing.T) {
	for name, key := range map[string]string{
		"empty":      "",
		"whitespace": " \t\n",
	} {
		t.Run(name, func(t *testing.T) {
			t.Setenv("SERVER_ACCESS_MODE", "cloud")
			t.Setenv("BILLING_ENABLED", "true")
			t.Setenv("STRIPE_SECRET_KEY", key)

			client, err := stripeapi.NewClient()

			if client != nil {
				t.Fatal("missing key must not create a Stripe client")
			}
			if err == nil || err.Error() != "STRIPE_SECRET_KEY must be set when billing is enabled" {
				t.Fatalf("want missing-key error, got %v", err)
			}
		})
	}
}

func TestNewStripeClientRejectsInvalidBillingConfiguration(t *testing.T) {
	t.Setenv("SERVER_ACCESS_MODE", "cloud")
	t.Setenv("BILLING_ENABLED", "invalid")
	t.Setenv("STRIPE_SECRET_KEY", "sk_test_placeholder")

	client, err := stripeapi.NewClient()

	if client != nil {
		t.Fatal("invalid billing configuration must not create a Stripe client")
	}
	if err == nil || err.Error() != "BILLING_ENABLED must be true or false" {
		t.Fatalf("want billing configuration error, got %v", err)
	}
}
