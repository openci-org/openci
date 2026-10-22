package billing

import (
	"net/url"
	"strings"
	"testing"
)

func TestLoadServiceConfig(t *testing.T) {
	setBillingServiceEnvironment(t)
	config, err := LoadServiceConfig()
	if err != nil || config == nil || config.Livemode || config.LightPriceID != "price_light" || config.ProPriceID != "price_pro" {
		t.Fatalf("unexpected service configuration: err=%v", err)
	}
	teamID := "team&result=forged/#"
	got, err := url.Parse(config.returnURL(teamID, "success"))
	if err != nil || got.Host != "app.example" || got.Path != "/billing" || got.Query().Get("teamId") != teamID || got.Query().Get("result") != "success" {
		t.Fatal("team identity must remain a query value under the server-owned origin")
	}
}

func TestLoadServiceConfigRejectsInvalidSettings(t *testing.T) {
	for _, tc := range []struct{ name, key, value string }{
		{"unset mode", "STRIPE_LIVEMODE", ""},
		{"remote HTTP", "BILLING_DASHBOARD_ORIGIN", "http://app.example"},
		{"credentials", "BILLING_DASHBOARD_ORIGIN", "https://user:secret@app.example"},
		{"path", "BILLING_DASHBOARD_ORIGIN", "https://app.example/path"},
		{"query", "BILLING_DASHBOARD_ORIGIN", "https://app.example?return=evil"},
		{"empty query", "BILLING_DASHBOARD_ORIGIN", "https://app.example?"},
		{"empty fragment", "BILLING_DASHBOARD_ORIGIN", "https://app.example#"},
		{"missing Portal", "STRIPE_PORTAL_CONFIGURATION_ID", ""},
		{"short internal token", "BILLING_INTERNAL_TOKEN", "short-sensitive"},
		{"missing webhook secret", "STRIPE_WEBHOOK_SECRET", ""},
		{"same Prices", "STRIPE_PRO_PRICE_ID", "price_light"},
		{"empty complimentary team", "BILLING_COMPLIMENTARY_PRO_TEAM_IDS", "team-1,,team-2"},
		{"whitespace in complimentary team", "BILLING_COMPLIMENTARY_PRO_TEAM_IDS", "team 1"},
		{"control in complimentary team", "BILLING_COMPLIMENTARY_PRO_TEAM_IDS", "team\x01"},
	} {
		t.Run(tc.name, func(t *testing.T) {
			setBillingServiceEnvironment(t)
			t.Setenv(tc.key, tc.value)
			if config, err := LoadServiceConfig(); config != nil || err == nil || strings.Contains(err.Error(), "sensitive") {
				t.Fatal("invalid configuration must fail without exposing secret values")
			}
		})
	}
}

func TestLoadServiceConfigDisabled(t *testing.T) {
	for _, mode := range []string{"self_hosted", "cloud"} {
		t.Run(mode, func(t *testing.T) {
			t.Setenv("SERVER_ACCESS_MODE", mode)
			t.Setenv("BILLING_ENABLED", "false")
			t.Setenv("STRIPE_LIVEMODE", "invalid")
			if config, err := LoadServiceConfig(); config != nil || err != nil {
				t.Fatal("disabled billing must not require Stripe or dashboard settings")
			}
		})
	}
}

func setBillingServiceEnvironment(t *testing.T) {
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

func TestLoadComplimentaryProTeams(t *testing.T) {
	setBillingServiceEnvironment(t)
	config, err := LoadServiceConfig()
	if err != nil || config.hasComplimentaryPro("team-1") || config.hasComplimentaryPro("") {
		t.Fatal("complimentary Pro must be opt-in")
	}
	t.Setenv("BILLING_COMPLIMENTARY_PRO_TEAM_IDS", " team-1, team-2 ")
	config, err = LoadServiceConfig()
	if err != nil || !config.hasComplimentaryPro("team-1") || !config.hasComplimentaryPro("team-2") || config.hasComplimentaryPro("team") || config.hasComplimentaryPro("team-3") {
		t.Fatal("only exact configured team IDs may receive complimentary Pro")
	}
}
