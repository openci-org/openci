package billing

import "testing"

func TestStripeCheckoutPriceID(t *testing.T) {
	t.Setenv("SERVER_ACCESS_MODE", "cloud")
	t.Setenv("BILLING_ENABLED", "true")

	for _, tc := range []struct {
		name, planID, lightPrice, proPrice, want string
	}{
		{"Light", "light", "price_light", "price_pro", "price_light"},
		{"Pro", "pro", "price_light", "price_pro", "price_pro"},
		{"Light only", "light", "price_light", "", "price_light"},
		{"Pro only", "pro", "", "price_pro", "price_pro"},
		{"padded ID", "light", " \tprice_light\n", "", "price_light"},
	} {
		t.Run(tc.name, func(t *testing.T) {
			t.Setenv("STRIPE_LIGHT_PRICE_ID", tc.lightPrice)
			t.Setenv("STRIPE_PRO_PRICE_ID", tc.proPrice)

			priceID, err := stripeCheckoutPriceID(tc.planID)

			if err != nil {
				t.Fatal(err)
			}
			if priceID != tc.want {
				t.Fatalf("want Price ID %q, got %q", tc.want, priceID)
			}
		})
	}
}

func TestStripeCheckoutPriceIDRequiresSelectedPrice(t *testing.T) {
	t.Setenv("SERVER_ACCESS_MODE", "cloud")
	t.Setenv("BILLING_ENABLED", "true")
	t.Setenv("STRIPE_LIGHT_PRICE_ID", "price_light")
	t.Setenv("STRIPE_PRO_PRICE_ID", "price_pro")

	for _, tc := range []struct {
		name, planID, key, value string
	}{
		{"missing Light", "light", "STRIPE_LIGHT_PRICE_ID", ""},
		{"blank Light", "light", "STRIPE_LIGHT_PRICE_ID", " \t\n"},
		{"missing Pro", "pro", "STRIPE_PRO_PRICE_ID", ""},
		{"blank Pro", "pro", "STRIPE_PRO_PRICE_ID", " \t\n"},
	} {
		t.Run(tc.name, func(t *testing.T) {
			t.Setenv(tc.key, tc.value)

			priceID, err := stripeCheckoutPriceID(tc.planID)

			wantErr := tc.key + " must be set when billing is enabled"
			if priceID != "" || err == nil || err.Error() != wantErr {
				t.Fatalf("want no Price ID and error %q, got ID=%q, err=%v", wantErr, priceID, err)
			}
		})
	}
}

func TestStripeCheckoutPriceIDRejectsUnknownPlan(t *testing.T) {
	t.Setenv("SERVER_ACCESS_MODE", "cloud")
	t.Setenv("BILLING_ENABLED", "true")
	t.Setenv("STRIPE_LIGHT_PRICE_ID", "price_light")
	t.Setenv("STRIPE_PRO_PRICE_ID", "price_pro")

	for _, planID := range []string{"", "starter", "Light", " light ", "price_arbitrary"} {
		t.Run(planID, func(t *testing.T) {
			priceID, err := stripeCheckoutPriceID(planID)

			if priceID != "" || err == nil || err.Error() != "unknown paid billing plan" {
				t.Fatalf("want no Price ID and an unknown-plan error, got ID=%q, err=%v", priceID, err)
			}
		})
	}
}

func TestStripeCheckoutPriceIDWhenBillingDisabled(t *testing.T) {
	t.Setenv("STRIPE_LIGHT_PRICE_ID", "")
	t.Setenv("STRIPE_PRO_PRICE_ID", "")

	for _, tc := range []struct {
		name, mode, enabled string
	}{
		{"self hosted", "self_hosted", "invalid"},
		{"disabled cloud", "cloud", "false"},
	} {
		t.Run(tc.name, func(t *testing.T) {
			t.Setenv("SERVER_ACCESS_MODE", tc.mode)
			t.Setenv("BILLING_ENABLED", tc.enabled)

			priceID, err := stripeCheckoutPriceID("light")

			if priceID != "" || err != nil {
				t.Fatalf("disabled billing must not require a Price ID: ID=%q, err=%v", priceID, err)
			}
		})
	}
}

func TestStripeCheckoutPriceIDRejectsInvalidBillingConfiguration(t *testing.T) {
	t.Setenv("SERVER_ACCESS_MODE", "cloud")
	t.Setenv("BILLING_ENABLED", "invalid")
	t.Setenv("STRIPE_LIGHT_PRICE_ID", "price_light")

	priceID, err := stripeCheckoutPriceID("light")

	if priceID != "" || err == nil || err.Error() != "BILLING_ENABLED must be true or false" {
		t.Fatalf("want no Price ID and a billing configuration error, got ID=%q, err=%v", priceID, err)
	}
}
