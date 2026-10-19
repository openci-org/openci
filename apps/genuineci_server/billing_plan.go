package main

import "errors"

type paidBillingPlan struct {
	PriceUSDCents    int64
	AllowanceSeconds int64
}

func getPaidBillingPlan(planID string) (paidBillingPlan, error) {
	switch planID {
	case "light":
		return paidBillingPlan{
			PriceUSDCents:    1_000,
			AllowanceSeconds: 36_000,
		}, nil
	case "pro":
		return paidBillingPlan{
			PriceUSDCents:    10_000,
			AllowanceSeconds: 360_000,
		}, nil
	default:
		return paidBillingPlan{}, errors.New("unknown paid billing plan")
	}
}
