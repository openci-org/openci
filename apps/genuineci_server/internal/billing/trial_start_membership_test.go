package billing

import (
	"errors"
	"testing"
	"time"
)

func TestStartTrialByAnyMember(t *testing.T) {
	for _, userID := range []string{"user-1", "user-2"} {
		t.Run(userID, func(t *testing.T) {
			ctx, pool := newTrialStartTestDB(t, "team-1")
			addTrialStartMembers(t, ctx, pool, "team-1", "user-1", "user-2")
			input := trialStart{
				PeriodID: "trial-1", UserID: userID, TeamID: "team-1", StartsAt: time.Unix(1000, 0),
			}

			started, err := startTrial(ctx, pool, input)

			if err != nil || !started {
				t.Fatalf("any current member must be able to start: started=%v, err=%v", started, err)
			}
			assertOnlyStartedTrial(t, ctx, pool, input, nil)
		})
	}
}

func TestStartTrialByNonMember(t *testing.T) {
	for _, tc := range []struct{ name, userID string }{
		{"not in any team", "outsider"},
		{"member of another team", "user-2"},
	} {
		t.Run(tc.name, func(t *testing.T) {
			ctx, pool := newTrialStartTestDB(t, "team-1", "team-2")
			addTrialStartMembers(t, ctx, pool, "team-1", "user-1")
			addTrialStartMembers(t, ctx, pool, "team-2", "user-2")
			input := trialStart{
				PeriodID: "trial-1", UserID: tc.userID, TeamID: "team-1", StartsAt: time.Unix(1000, 0),
			}

			started, err := startTrial(ctx, pool, input)

			if started || !errors.Is(err, ErrNotTeamMember) {
				t.Fatalf("must reject a non-member: started=%v, err=%v", started, err)
			}
			assertNoStartedTrial(t, ctx, pool)

			addTrialStartMembers(t, ctx, pool, "team-1", tc.userID)
			if started, err := startTrial(ctx, pool, input); err != nil || !started {
				t.Fatalf("rejection must leave the user and team eligible after joining: started=%v, err=%v", started, err)
			}
			assertOnlyStartedTrial(t, ctx, pool, input, nil)
		})
	}
}

func TestStartTrialByRemovedMember(t *testing.T) {
	ctx, pool := newTrialStartTestDB(t, "team-1")
	addTrialStartMembers(t, ctx, pool, "team-1", "user-1")
	if _, err := pool.Exec(ctx, "DELETE FROM team_members WHERE team_id = 'team-1' AND user_id = 'user-1'"); err != nil {
		t.Fatal(err)
	}
	input := trialStart{
		PeriodID: "trial-1", UserID: "user-1", TeamID: "team-1", StartsAt: time.Unix(1000, 0),
	}

	started, err := startTrial(ctx, pool, input)

	if started || !errors.Is(err, ErrNotTeamMember) {
		t.Fatalf("must reject a removed member: started=%v, err=%v", started, err)
	}
	assertNoStartedTrial(t, ctx, pool)
}

func TestStartTrialChecksMembershipAfterLockWait(t *testing.T) {
	ctx, pool := newTrialStartTestDB(t, "team-1")
	addTrialStartMembers(t, ctx, pool, "team-1", "user-1")
	blocker, err := pool.Begin(ctx)
	if err != nil {
		t.Fatal(err)
	}
	defer blocker.Rollback(ctx)
	if _, err := blocker.Exec(ctx, "SELECT team_id FROM billing_accounts WHERE team_id = 'team-1' FOR UPDATE"); err != nil {
		t.Fatal(err)
	}
	input := trialStart{
		PeriodID: "trial-1", UserID: "user-1", TeamID: "team-1", StartsAt: time.Unix(1000, 0),
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
	if _, err := blocker.Exec(ctx, "DELETE FROM team_members WHERE team_id = 'team-1' AND user_id = 'user-1'"); err != nil {
		t.Fatal(err)
	}
	if err := blocker.Commit(ctx); err != nil {
		t.Fatal(err)
	}

	if got := <-results; got.started || !errors.Is(got.err, ErrNotTeamMember) {
		t.Fatalf("must see membership removal after acquiring the lock: started=%v, err=%v", got.started, got.err)
	}
	assertNoStartedTrial(t, ctx, pool)
}

func TestStartTrialWithoutUser(t *testing.T) {
	t.Setenv("SERVER_ACCESS_MODE", "cloud")
	t.Setenv("BILLING_ENABLED", "true")
	t.Setenv("BILLING_TRIAL_ALLOWANCE_SECONDS", "0")
	request := TrialStartRequest{TeamID: "team-1"}

	// A nil pool ensures a missing UID is rejected before database access.
	started, err := StartTrial(t.Context(), nil, request)

	if started || !errors.Is(err, ErrNotTeamMember) {
		t.Fatalf("must reject a missing UID: started=%v, err=%v", started, err)
	}
}
