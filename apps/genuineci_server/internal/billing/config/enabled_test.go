package config_test

import (
	"os"
	"testing"

	billingconfig "github.com/openci-org/openci/apps/genuineci_server/internal/billing/config"
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
			got, err := billingconfig.Enabled()
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

func TestTrialAllowanceSeconds(t *testing.T) {
	const invalidAllowance = "BILLING_TRIAL_ALLOWANCE_SECONDS must be a non-negative integer"
	zero, seconds := int64(0), int64(1800)
	for _, tc := range []struct {
		name    string
		env     map[string]string
		want    *int64
		wantErr string
	}{
		{"unset allowance", map[string]string{"SERVER_ACCESS_MODE": "cloud", "BILLING_ENABLED": "true"}, nil, ""},
		{"zero allowance", map[string]string{"SERVER_ACCESS_MODE": "cloud", "BILLING_ENABLED": "true", "BILLING_TRIAL_ALLOWANCE_SECONDS": "0"}, &zero, ""},
		{"configured allowance", map[string]string{"SERVER_ACCESS_MODE": "cloud", "BILLING_ENABLED": "true", "BILLING_TRIAL_ALLOWANCE_SECONDS": "1800"}, &seconds, ""},
		{"unset mode ignores allowance", map[string]string{"BILLING_ENABLED": "true", "BILLING_TRIAL_ALLOWANCE_SECONDS": "invalid"}, nil, ""},
		{"self hosted ignores allowance", map[string]string{"SERVER_ACCESS_MODE": "self_hosted", "BILLING_ENABLED": "invalid", "BILLING_TRIAL_ALLOWANCE_SECONDS": "invalid"}, nil, ""},
		{"disabled cloud ignores allowance", map[string]string{"SERVER_ACCESS_MODE": "cloud", "BILLING_ENABLED": "false", "BILLING_TRIAL_ALLOWANCE_SECONDS": "invalid"}, nil, ""},
		{"cloud defaults off", map[string]string{"SERVER_ACCESS_MODE": "cloud", "BILLING_TRIAL_ALLOWANCE_SECONDS": "invalid"}, nil, ""},
		{"invalid mode", map[string]string{"SERVER_ACCESS_MODE": "invalid"}, nil, "SERVER_ACCESS_MODE must be self_hosted or cloud"},
		{"invalid flag", map[string]string{"SERVER_ACCESS_MODE": "cloud", "BILLING_ENABLED": "invalid"}, nil, "BILLING_ENABLED must be true or false"},
		{"empty allowance", map[string]string{"SERVER_ACCESS_MODE": "cloud", "BILLING_ENABLED": "true", "BILLING_TRIAL_ALLOWANCE_SECONDS": ""}, nil, invalidAllowance},
		{"negative allowance", map[string]string{"SERVER_ACCESS_MODE": "cloud", "BILLING_ENABLED": "true", "BILLING_TRIAL_ALLOWANCE_SECONDS": "-1"}, nil, invalidAllowance},
		{"fractional allowance", map[string]string{"SERVER_ACCESS_MODE": "cloud", "BILLING_ENABLED": "true", "BILLING_TRIAL_ALLOWANCE_SECONDS": "1.5"}, nil, invalidAllowance},
		{"invalid allowance", map[string]string{"SERVER_ACCESS_MODE": "cloud", "BILLING_ENABLED": "true", "BILLING_TRIAL_ALLOWANCE_SECONDS": "invalid"}, nil, invalidAllowance},
		{"padded allowance", map[string]string{"SERVER_ACCESS_MODE": "cloud", "BILLING_ENABLED": "true", "BILLING_TRIAL_ALLOWANCE_SECONDS": "1800 "}, nil, invalidAllowance},
		{"overflow", map[string]string{"SERVER_ACCESS_MODE": "cloud", "BILLING_ENABLED": "true", "BILLING_TRIAL_ALLOWANCE_SECONDS": "9223372036854775808"}, nil, invalidAllowance},
	} {
		t.Run(tc.name, func(t *testing.T) {
			for _, key := range []string{"SERVER_ACCESS_MODE", "BILLING_ENABLED", "BILLING_TRIAL_ALLOWANCE_SECONDS"} {
				value, set := tc.env[key]
				t.Setenv(key, value)
				if !set {
					if err := os.Unsetenv(key); err != nil {
						t.Fatal(err)
					}
				}
			}
			got, err := billingconfig.TrialAllowanceSeconds()
			if tc.wantErr == "" {
				if err != nil {
					t.Fatal(err)
				}
			} else if err == nil || err.Error() != tc.wantErr {
				t.Errorf("want error %q, got %v", tc.wantErr, err)
			}
			if (got == nil) != (tc.want == nil) {
				t.Fatalf("want configured=%v, got configured=%v", tc.want != nil, got != nil)
			}
			if got != nil && *got != *tc.want {
				t.Errorf("want allowance %d, got %d", *tc.want, *got)
			}
		})
	}
}
