// Package testutil provides isolated database fixtures and fake Stripe clients for tests.
package testutil

import (
	"strings"
	"testing"
)

func SetBillingEnvironment(t *testing.T) {
	t.Helper()
	for key, value := range map[string]string{
		"SERVER_ACCESS_MODE": "cloud", "BILLING_ENABLED": "true", "STRIPE_LIVEMODE": "false",
		"BILLING_DASHBOARD_ORIGIN": "https://app.example/", "STRIPE_PORTAL_CONFIGURATION_ID": "bpc_team",
		"BILLING_INTERNAL_TOKEN": strings.Repeat("test", 8), "STRIPE_WEBHOOK_SECRET": "whsec_test_endpoint",
		"STRIPE_LIGHT_PRICE_ID": "price_light", "STRIPE_PRO_PRICE_ID": "price_pro",
		"BILLING_COMPLIMENTARY_PRO_TEAM_IDS": "",
	} {
		t.Setenv(key, value)
	}
}
