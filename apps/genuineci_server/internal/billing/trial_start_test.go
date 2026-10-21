package billing

import (
	"context"
	"errors"
	"reflect"
	"testing"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
)

func TestStartTrial(t *testing.T) {
	ctx, pool := newTrialStartTestDB(t, "team-1")
	input := trialStart{
		PeriodID: "trial-1",
		UserID:   "user-1",
		TeamID:   "team-1",
		StartsAt: time.Date(2040, 10, 1, 9, 0, 0, 123456789, time.FixedZone("JST", 9*60*60)),
	}

	started, err := startTrial(ctx, pool, input)

	if err != nil || !started {
		t.Fatalf("want a new trial: started=%v, err=%v", started, err)
	}
	assertOnlyStartedTrial(t, ctx, pool, input)
}

func TestStartTrialRetry(t *testing.T) {
	ctx, pool := newTrialStartTestDB(t, "team-1")
	original := trialStart{
		PeriodID: "trial-1", UserID: "user-1", TeamID: "team-1", StartsAt: time.Unix(1000, 0),
	}
	if started, err := startTrial(ctx, pool, original); err != nil || !started {
		t.Fatalf("seed original trial: started=%v, err=%v", started, err)
	}
	allowance := int64(1800)
	retry := original
	retry.PeriodID = "trial-retry"
	retry.StartsAt = original.StartsAt.Add(8 * 24 * time.Hour)
	retry.AllowanceSeconds = &allowance

	started, err := startTrial(ctx, pool, retry)

	if err != nil || started {
		t.Fatalf("retry must not restart an expired trial: started=%v, err=%v", started, err)
	}
	assertOnlyStartedTrial(t, ctx, pool, original)
}

func TestStartTrialRollback(t *testing.T) {
	ctx, pool := newTrialStartTestDB(t, "team-1")
	negative := int64(-1)
	input := trialStart{
		PeriodID:         "trial-1",
		UserID:           "user-1",
		TeamID:           "team-1",
		StartsAt:         time.Unix(1000, 0),
		AllowanceSeconds: &negative,
	}

	started, err := startTrial(ctx, pool, input)

	var pgErr *pgconn.PgError
	if started || !errors.As(err, &pgErr) || pgErr.Code != "23514" {
		t.Fatalf("want period constraint error: started=%v, err=%v", started, err)
	}
	assertNoStartedTrial(t, ctx, pool)

	input.AllowanceSeconds = nil
	if started, err := startTrial(ctx, pool, input); err != nil || !started {
		t.Fatalf("failed period creation must leave the user and team eligible: started=%v, err=%v", started, err)
	}
	assertOnlyStartedTrial(t, ctx, pool, input)
}

func TestStartTrialPeriodIDConflict(t *testing.T) {
	for _, ownerTeam := range []string{"team-1", "team-2"} {
		t.Run(ownerTeam, func(t *testing.T) {
			ctx, pool := newTrialStartTestDB(t, "team-1", "team-2")
			existing := newTrialBillingPeriod("existing-period", ownerTeam, time.Unix(1000, 0), nil)
			if err := pgx.BeginFunc(ctx, pool, func(tx pgx.Tx) error {
				return createBillingPeriod(ctx, tx, existing)
			}); err != nil {
				t.Fatal(err)
			}
			input := trialStart{
				PeriodID: existing.ID, UserID: "user-1", TeamID: "team-1", StartsAt: time.Unix(2000, 0),
			}

			started, err := startTrial(ctx, pool, input)

			if started || err == nil {
				t.Fatalf("must reject an existing period ID: started=%v, err=%v", started, err)
			}
			var claims int
			if err := pool.QueryRow(ctx, "SELECT count(*) FROM billing_trial_claims").Scan(&claims); err != nil || claims != 0 {
				t.Fatalf("period ID conflict must roll back the claim: count=%d, err=%v", claims, err)
			}
			got, err := getBillingPeriod(ctx, pool, existing.TeamID, existing.ID)
			if err != nil || got == nil || !reflect.DeepEqual(*got, existing) {
				t.Fatalf("must preserve existing period: got=%+v, err=%v", got, err)
			}
		})
	}
}

func TestStartTrialConcurrent(t *testing.T) {
	for _, tc := range []struct {
		name, userID, teamID string
	}{
		{"same team", "user-2", "team-1"},
		{"same user across teams", "user-1", "team-2"},
	} {
		t.Run(tc.name, func(t *testing.T) {
			ctx, pool := newTrialStartTestDB(t, "team-1", "team-2")
			original := trialStart{
				PeriodID: "trial-1", UserID: "user-1", TeamID: "team-1", StartsAt: time.Unix(1000, 0),
			}
			competing := trialStart{
				PeriodID: "trial-2", UserID: tc.userID, TeamID: tc.teamID, StartsAt: original.StartsAt.Add(time.Hour),
			}
			// Pause the first start after it records its claim but before saving its period.
			blocker, err := pool.Begin(ctx)
			if err != nil {
				t.Fatal(err)
			}
			defer blocker.Rollback(ctx)
			if _, err := blocker.Exec(ctx, "LOCK TABLE billing_periods IN ACCESS EXCLUSIVE MODE"); err != nil {
				t.Fatal(err)
			}
			type result struct {
				started bool
				err     error
			}
			results := make(chan result, 2)

			go func() {
				started, err := startTrial(ctx, pool, original)
				results <- result{started, err}
			}()
			waitForBillingLocks(t, ctx, pool, 1)
			go func() {
				started, err := startTrial(ctx, pool, competing)
				results <- result{started, err}
			}()
			waitForBillingLocks(t, ctx, pool, 2)
			if err := blocker.Commit(ctx); err != nil {
				t.Fatal(err)
			}

			starts := 0
			for range 2 {
				got := <-results
				if got.err != nil {
					t.Fatal(got.err)
				}
				if got.started {
					starts++
				}
			}
			if starts != 1 {
				t.Fatalf("want exactly one successful start, got %d", starts)
			}
			assertOnlyStartedTrial(t, ctx, pool, original)

			unused := trialStart{
				PeriodID: "trial-unused", UserID: "user-2", TeamID: "team-2", StartsAt: original.StartsAt,
			}
			if started, err := startTrial(ctx, pool, unused); err != nil || !started {
				t.Fatalf("losing attempt must not consume the unused user or team: started=%v, err=%v", started, err)
			}
		})
	}
}

func TestStartTrialDeletedTeam(t *testing.T) {
	ctx, pool := newTrialStartTestDB(t, "team-1")
	if _, err := pool.Exec(ctx, "DELETE FROM teams WHERE id = 'team-1'"); err != nil {
		t.Fatal(err)
	}
	input := trialStart{
		PeriodID: "trial-1", UserID: "user-1", TeamID: "team-1", StartsAt: time.Unix(1000, 0),
	}

	started, err := startTrial(ctx, pool, input)

	if started || !errors.Is(err, pgx.ErrNoRows) {
		t.Fatalf("must reject a deleted team: started=%v, err=%v", started, err)
	}
	assertNoStartedTrial(t, ctx, pool)
}

func newTrialStartTestDB(t *testing.T, teamIDs ...string) (context.Context, *pgxpool.Pool) {
	t.Helper()
	ctx, pool := newTrialClaimTestDB(t, teamIDs...)
	if _, err := pool.Exec(ctx, `
		CREATE TABLE teams (id text PRIMARY KEY);
		CREATE TABLE billing_periods (
			id text PRIMARY KEY, team_id text NOT NULL REFERENCES billing_accounts(team_id),
			plan_id text NOT NULL CHECK (plan_id IN ('light', 'pro')),
			period_type text NOT NULL CHECK (period_type IN ('trial', 'paid')),
			starts_at bigint NOT NULL, ends_at bigint NOT NULL CHECK (ends_at > starts_at),
			allowance_seconds bigint CHECK (allowance_seconds IS NULL OR allowance_seconds >= 0),
			CHECK (period_type = 'trial' OR allowance_seconds IS NOT NULL)
		);
	`); err != nil {
		t.Fatal(err)
	}
	for _, teamID := range teamIDs {
		if _, err := pool.Exec(ctx, "INSERT INTO teams (id) VALUES ($1)", teamID); err != nil {
			t.Fatal(err)
		}
	}
	return ctx, pool
}

func assertOnlyStartedTrial(t *testing.T, ctx context.Context, pool *pgxpool.Pool, input trialStart) {
	t.Helper()
	startsAt := input.StartsAt.UTC().Truncate(time.Second)
	assertOnlyTrialClaim(t, ctx, pool, trialClaim{UserID: input.UserID, TeamID: input.TeamID, ClaimedAt: startsAt})
	want := billingPeriod{
		ID: input.PeriodID, TeamID: input.TeamID, PlanID: "pro", PeriodType: "trial",
		StartsAt: startsAt, EndsAt: startsAt.Add(7 * 24 * time.Hour), AllowanceSeconds: input.AllowanceSeconds,
	}
	got, err := getBillingPeriod(ctx, pool, input.TeamID, input.PeriodID)
	if err != nil || got == nil || !reflect.DeepEqual(*got, want) {
		t.Fatalf("want trial period %+v, got %+v, err=%v", want, got, err)
	}
	var periods int
	if err := pool.QueryRow(ctx, "SELECT count(*) FROM billing_periods").Scan(&periods); err != nil || periods != 1 {
		t.Fatalf("want exactly one trial period: count=%d, err=%v", periods, err)
	}
}

func assertNoStartedTrial(t *testing.T, ctx context.Context, pool *pgxpool.Pool) {
	t.Helper()
	var claims, periods int
	err := pool.QueryRow(ctx, `
		SELECT (SELECT count(*) FROM billing_trial_claims), (SELECT count(*) FROM billing_periods)
	`).Scan(&claims, &periods)
	if err != nil || claims != 0 || periods != 0 {
		t.Fatalf("want no trial records: claims=%d, periods=%d, err=%v", claims, periods, err)
	}
}
