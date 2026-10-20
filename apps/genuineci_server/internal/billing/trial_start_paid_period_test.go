package billing

import (
	"context"
	"reflect"
	"testing"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

func TestStartTrialPaidPeriodBoundaries(t *testing.T) {
	paid := paidPeriodForTrialStartTest("team-1", "light")
	for _, tc := range []struct {
		name        string
		startsAt    time.Time
		wantStarted bool
	}{
		{"before paid period", paid.StartsAt.Add(-time.Nanosecond), true},
		{"at paid period start", paid.StartsAt, false},
		{"just before paid period end", paid.EndsAt.Add(-time.Nanosecond), false},
		{"at paid period end", paid.EndsAt, true},
		{"after paid period end", paid.EndsAt.Add(time.Second), true},
	} {
		t.Run(tc.name, func(t *testing.T) {
			ctx, pool := newTrialStartTestDB(t, "team-1")
			if err := pgx.BeginFunc(ctx, pool, func(tx pgx.Tx) error {
				return createBillingPeriod(ctx, tx, paid)
			}); err != nil {
				t.Fatal(err)
			}
			input := trialStart{
				PeriodID: "trial-1", UserID: "user-1", TeamID: "team-1", StartsAt: tc.startsAt,
			}

			started, err := startTrial(ctx, pool, input)

			if err != nil || started != tc.wantStarted {
				t.Fatalf("want started=%v, got started=%v, err=%v", tc.wantStarted, started, err)
			}
			wantCount := 0
			if tc.wantStarted {
				wantCount = 1
			}
			assertTrialRecordCounts(t, ctx, pool, wantCount)
			got, err := getBillingPeriod(ctx, pool, paid.TeamID, paid.ID)
			if err != nil || got == nil || !reflect.DeepEqual(*got, paid) {
				t.Fatalf("must preserve the paid period: got=%+v, err=%v", got, err)
			}
		})
	}
}

func TestStartTrialWithAnotherTeamsPaidPeriod(t *testing.T) {
	ctx, pool := newTrialStartTestDB(t, "team-1", "team-2")
	paid := paidPeriodForTrialStartTest("team-2", "pro")
	if err := pgx.BeginFunc(ctx, pool, func(tx pgx.Tx) error {
		return createBillingPeriod(ctx, tx, paid)
	}); err != nil {
		t.Fatal(err)
	}
	input := trialStart{
		PeriodID: "trial-1", UserID: "user-1", TeamID: "team-1", StartsAt: paid.StartsAt,
	}

	started, err := startTrial(ctx, pool, input)

	if err != nil || !started {
		t.Fatalf("another team's paid period must not block the trial: started=%v, err=%v", started, err)
	}
	assertTrialRecordCounts(t, ctx, pool, 1)
	assertOnlyTrialClaim(t, ctx, pool, trialClaim{UserID: input.UserID, TeamID: input.TeamID, ClaimedAt: input.StartsAt})
}

func TestStartTrialWaitsForPaidPeriodCommit(t *testing.T) {
	ctx, pool := newTrialStartTestDB(t, "team-1", "team-2")
	paid := paidPeriodForTrialStartTest("team-1", "pro")
	tx, err := pool.Begin(ctx)
	if err != nil {
		t.Fatal(err)
	}
	defer tx.Rollback(ctx)
	if _, err := tx.Exec(ctx,
		"SELECT team_id FROM billing_accounts WHERE team_id = $1 FOR UPDATE", paid.TeamID,
	); err != nil {
		t.Fatal(err)
	}
	if err := createBillingPeriod(ctx, tx, paid); err != nil {
		t.Fatal(err)
	}
	input := trialStart{
		PeriodID: "trial-1", UserID: "user-1", TeamID: "team-1", StartsAt: paid.StartsAt.Add(time.Hour),
	}
	type result struct {
		started bool
		err     error
	}
	results := make(chan result, 1)

	go func() {
		started, err := startTrial(ctx, pool, input)
		results <- result{started, err}
	}()
	waitForBillingLocks(t, ctx, pool, 1)
	if err := tx.Commit(ctx); err != nil {
		t.Fatal(err)
	}

	if got := <-results; got.err != nil || got.started {
		t.Fatalf("must see the paid period after acquiring the lock: started=%v, err=%v", got.started, got.err)
	}
	assertTrialRecordCounts(t, ctx, pool, 0)

	input.TeamID = "team-2"
	if started, err := startTrial(ctx, pool, input); err != nil || !started {
		t.Fatalf("rejection must leave the user eligible in another team: started=%v, err=%v", started, err)
	}
	assertTrialRecordCounts(t, ctx, pool, 1)
	assertOnlyTrialClaim(t, ctx, pool, trialClaim{UserID: input.UserID, TeamID: input.TeamID, ClaimedAt: input.StartsAt})
}

func paidPeriodForTrialStartTest(teamID, planID string) billingPeriod {
	allowance := int64(36000)
	if planID == "pro" {
		allowance = 360000
	}
	startsAt := time.Date(2040, 10, 1, 0, 0, 0, 0, time.UTC)
	return billingPeriod{
		ID: "paid-1", TeamID: teamID, PlanID: planID, PeriodType: "paid",
		StartsAt: startsAt, EndsAt: startsAt.AddDate(0, 1, 0), AllowanceSeconds: &allowance,
	}
}

func assertTrialRecordCounts(t *testing.T, ctx context.Context, pool *pgxpool.Pool, want int) {
	t.Helper()
	var claims, periods int
	err := pool.QueryRow(ctx, `
		SELECT (SELECT count(*) FROM billing_trial_claims),
			(SELECT count(*) FROM billing_periods WHERE period_type = 'trial')
	`).Scan(&claims, &periods)
	if err != nil || claims != want || periods != want {
		t.Fatalf("want %d claims and trial periods: claims=%d, periods=%d, err=%v", want, claims, periods, err)
	}
}
