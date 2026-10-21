package main

import (
	"context"
	"errors"
	"os"
	"os/exec"
	"strings"
	"testing"
	"time"
)

func TestMainBillingConfiguration(t *testing.T) {
	if os.Getenv("GENUINECI_TEST_MAIN") == "1" {
		main()
		return
	}
	executable, err := os.Executable()
	if err != nil {
		t.Fatal(err)
	}
	for _, tc := range []struct {
		name string
		env  []string
		want string
	}{
		{"default settings", nil, "DATABASE_URL must be set"},
		{"cloud requires Stripe configuration", []string{"SERVER_ACCESS_MODE=cloud", "BILLING_ENABLED=true"}, "STRIPE_LIVEMODE must be true or false"},
		{"cloud with configured allowance", []string{"SERVER_ACCESS_MODE=cloud", "BILLING_ENABLED=true", "BILLING_TRIAL_ALLOWANCE_SECONDS=1800"}, "STRIPE_LIVEMODE must be true or false"},
		{"configured billing requires database", []string{
			"SERVER_ACCESS_MODE=cloud", "BILLING_ENABLED=true", "STRIPE_LIVEMODE=false", "STRIPE_SECRET_KEY=sk_test_placeholder",
			"BILLING_DASHBOARD_ORIGIN=https://app.example", "STRIPE_PORTAL_CONFIGURATION_ID=bpc_test",
			"STRIPE_WEBHOOK_SECRET=whsec_test", "BILLING_INTERNAL_TOKEN=01234567890123456789012345678901",
			"STRIPE_LIGHT_PRICE_ID=price_light", "STRIPE_PRO_PRICE_ID=price_pro",
		}, "DATABASE_URL must be set"},
		{"self hosted ignores invalid settings", []string{"SERVER_ACCESS_MODE=self_hosted", "BILLING_ENABLED=invalid", "BILLING_TRIAL_ALLOWANCE_SECONDS=invalid", "STRIPE_SECRET_KEY=invalid"}, "DATABASE_URL must be set"},
		{"disabled cloud ignores invalid settings", []string{"SERVER_ACCESS_MODE=cloud", "BILLING_ENABLED=false", "BILLING_TRIAL_ALLOWANCE_SECONDS=invalid", "STRIPE_SECRET_KEY=invalid"}, "DATABASE_URL must be set"},
		{"invalid mode", []string{"SERVER_ACCESS_MODE=invalid"}, "SERVER_ACCESS_MODE must be self_hosted or cloud"},
		{"invalid flag", []string{"SERVER_ACCESS_MODE=cloud", "BILLING_ENABLED=invalid"}, "BILLING_ENABLED must be true or false"},
		{"invalid allowance", []string{"SERVER_ACCESS_MODE=cloud", "BILLING_ENABLED=true", "BILLING_TRIAL_ALLOWANCE_SECONDS=-1"}, "BILLING_TRIAL_ALLOWANCE_SECONDS must be a non-negative integer"},
	} {
		t.Run(tc.name, func(t *testing.T) {
			ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
			defer cancel()
			cmd := exec.CommandContext(ctx, executable, "-test.run=^TestMainBillingConfiguration$")
			// Keep DATABASE_URL absent so every child exits before connecting to a database.
			cmd.Env = append([]string{"GENUINECI_TEST_MAIN=1"}, tc.env...)
			output, err := cmd.CombinedOutput()
			var exitError *exec.ExitError
			if !errors.As(err, &exitError) || exitError.ExitCode() != 1 {
				t.Fatalf("want exit code 1, got %v; output: %s", err, output)
			}
			if !strings.Contains(string(output), tc.want) {
				t.Errorf("want output containing %q, got %s", tc.want, output)
			}
		})
	}
}
