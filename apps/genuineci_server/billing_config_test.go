package main

import (
	"os"
	"testing"
)

func TestBillingEnabled(t *testing.T) {
	const invalidMode = "SERVER_ACCESS_MODE must be self_hosted or cloud"
	const invalidFlag = "BILLING_ENABLED must be true or false"
	for _, tc := range []struct {
		name    string
		env     map[string]string
		want    bool
		wantErr string
	}{
		{"unset", nil, false, ""},
		{"flag alone", map[string]string{"BILLING_ENABLED": "true"}, false, ""},
		{"self hosted", map[string]string{"SERVER_ACCESS_MODE": "self_hosted"}, false, ""},
		{"self hosted ignores flag", map[string]string{"SERVER_ACCESS_MODE": "self_hosted", "BILLING_ENABLED": "true"}, false, ""},
		{"self hosted ignores invalid settings", map[string]string{"SERVER_ACCESS_MODE": "self_hosted", "BILLING_ENABLED": "invalid", "STRIPE_SECRET_KEY": "invalid"}, false, ""},
		{"cloud defaults off", map[string]string{"SERVER_ACCESS_MODE": "cloud"}, false, ""},
		{"disabled cloud ignores Stripe settings", map[string]string{"SERVER_ACCESS_MODE": "cloud", "BILLING_ENABLED": "false", "STRIPE_SECRET_KEY": "invalid"}, false, ""},
		{"cloud opted in", map[string]string{"SERVER_ACCESS_MODE": "cloud", "BILLING_ENABLED": "true"}, true, ""},
		{"empty mode", map[string]string{"SERVER_ACCESS_MODE": ""}, false, invalidMode},
		{"unknown mode", map[string]string{"SERVER_ACCESS_MODE": "public"}, false, invalidMode},
		{"uppercase mode", map[string]string{"SERVER_ACCESS_MODE": "CLOUD", "BILLING_ENABLED": "true"}, false, invalidMode},
		{"padded mode", map[string]string{"SERVER_ACCESS_MODE": "cloud ", "BILLING_ENABLED": "true"}, false, invalidMode},
		{"empty flag", map[string]string{"SERVER_ACCESS_MODE": "cloud", "BILLING_ENABLED": ""}, false, invalidFlag},
		{"numeric flag", map[string]string{"SERVER_ACCESS_MODE": "cloud", "BILLING_ENABLED": "1"}, false, invalidFlag},
		{"uppercase flag", map[string]string{"SERVER_ACCESS_MODE": "cloud", "BILLING_ENABLED": "TRUE"}, false, invalidFlag},
		{"padded flag", map[string]string{"SERVER_ACCESS_MODE": "cloud", "BILLING_ENABLED": "true "}, false, invalidFlag},
	} {
		t.Run(tc.name, func(t *testing.T) {
			for _, key := range []string{"SERVER_ACCESS_MODE", "BILLING_ENABLED", "STRIPE_SECRET_KEY"} {
				value, set := tc.env[key]
				t.Setenv(key, value)
				if !set {
					if err := os.Unsetenv(key); err != nil {
						t.Fatal(err)
					}
				}
			}
			got, err := billingEnabled()
			if got != tc.want {
				t.Errorf("want enabled=%v, got %v", tc.want, got)
			}
			if tc.wantErr == "" {
				if err != nil {
					t.Fatal(err)
				}
			} else if err == nil || err.Error() != tc.wantErr {
				t.Errorf("want error %q, got %v", tc.wantErr, err)
			}
		})
	}
}
