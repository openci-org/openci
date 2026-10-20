package main

import "time"

func newTrialBillingPeriod(id, teamID string, startsAt time.Time, allowanceSeconds *int64) billingPeriod {
	startsAt = startsAt.UTC().Truncate(time.Second)
	if allowanceSeconds != nil {
		allowance := *allowanceSeconds
		allowanceSeconds = &allowance
	}
	return billingPeriod{
		ID:               id,
		TeamID:           teamID,
		PlanID:           "pro",
		PeriodType:       "trial",
		StartsAt:         startsAt,
		EndsAt:           startsAt.Add(7 * 24 * time.Hour),
		AllowanceSeconds: allowanceSeconds,
	}
}
