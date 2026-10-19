package main

import "testing"

func TestGetPaidBillingPlan(t *testing.T) {
	for _, tc := range []struct {
		planID string
		want   paidBillingPlan
	}{
		{"light", paidBillingPlan{PriceUSDCents: 1_000, AllowanceSeconds: 36_000}},
		{"pro", paidBillingPlan{PriceUSDCents: 10_000, AllowanceSeconds: 360_000}},
	} {
		t.Run(tc.planID, func(t *testing.T) {
			got, err := getPaidBillingPlan(tc.planID)
			if err != nil {
				t.Fatal(err)
			}
			if got != tc.want {
				t.Errorf("want %+v, got %+v", tc.want, got)
			}
		})
	}
}

func TestGetPaidBillingPlanRejectsUnknownPlan(t *testing.T) {
	for _, planID := range []string{"", "trial", "free", "unknown", "Pro", "pro "} {
		t.Run(planID, func(t *testing.T) {
			got, err := getPaidBillingPlan(planID)
			if err == nil {
				t.Fatal("expected an error for an unknown paid billing plan")
			}
			if got != (paidBillingPlan{}) {
				t.Errorf("unknown plan must not grant a paid allowance, got %+v", got)
			}
		})
	}
}
