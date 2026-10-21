package main

import (
	"reflect"
	"testing"
	"time"
)

func TestNewTrialBillingPeriod(t *testing.T) {
	location, err := time.LoadLocation("America/New_York")
	if err != nil {
		t.Fatal(err)
	}
	// Cross daylight saving time while keeping the trial exactly 168 hours.
	startsAt := time.Date(2026, 3, 7, 12, 0, 0, 123456789, location)
	zero, seconds := int64(0), int64(1800)
	for _, tc := range []struct {
		name      string
		allowance *int64
	}{
		{"unset allowance", nil},
		{"zero allowance", &zero},
		{"configured allowance", &seconds},
	} {
		t.Run(tc.name, func(t *testing.T) {
			got := newTrialBillingPeriod("trial-1", "team-1", startsAt, tc.allowance)
			want := billingPeriod{
				ID:               "trial-1",
				TeamID:           "team-1",
				PlanID:           "pro",
				PeriodType:       "trial",
				StartsAt:         time.Date(2026, 3, 7, 17, 0, 0, 0, time.UTC),
				EndsAt:           time.Date(2026, 3, 14, 17, 0, 0, 0, time.UTC),
				AllowanceSeconds: tc.allowance,
			}
			if !reflect.DeepEqual(got, want) {
				t.Fatalf("want %+v, got %+v", want, got)
			}
			if tc.allowance != nil {
				original := *tc.allowance
				*tc.allowance = original + 1
				if *got.AllowanceSeconds != original {
					t.Fatal("changing the input must not change the period allowance")
				}
			}
		})
	}
}
