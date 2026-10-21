package billing

import (
	"context"
	"testing"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

func TestStartTrialRequest(t *testing.T) {
	ctx, pool := newTrialStartTestDB(t, "team-1")
	addTrialStartMembers(t, ctx, pool, "team-1", "user-1")
	t.Setenv("BILLING_TRIAL_ALLOWANCE_SECONDS", "1800")
	request := TrialStartRequest{TeamID: "team-1", UserID: "user-1"}
	before := time.Now().Unix()

	started, err := StartTrial(ctx, pool, request)

	after := time.Now().Unix()
	if err != nil || !started {
		t.Fatalf("want a new trial: started=%v, err=%v", started, err)
	}
	input := readStartedTrialInput(t, ctx, pool, request)
	if input.PeriodID == "" || input.StartsAt.Unix() < before || input.StartsAt.Unix() > after {
		t.Fatalf("want a server-generated ID and current start time, got %+v", input)
	}
	allowance := int64(1800)
	assertOnlyStartedTrial(t, ctx, pool, input, &allowance)

	if started, err := StartTrial(ctx, pool, request); err != nil || started {
		t.Fatalf("retry must preserve the original trial: started=%v, err=%v", started, err)
	}
	assertOnlyStartedTrial(t, ctx, pool, input, &allowance)
}

func TestStartTrialRequestsForDifferentTeams(t *testing.T) {
	ctx, pool := newTrialStartTestDB(t, "team-1", "team-2")
	for _, request := range []TrialStartRequest{
		{TeamID: "team-1", UserID: "user-1"},
		{TeamID: "team-2", UserID: "user-2"},
	} {
		addTrialStartMembers(t, ctx, pool, request.TeamID, request.UserID)

		started, err := StartTrial(ctx, pool, request)

		if err != nil || !started {
			t.Fatalf("each team must receive its own period: team=%q, started=%v, err=%v", request.TeamID, started, err)
		}
	}
	assertTrialRecordCounts(t, ctx, pool, 2)
}

func TestStartTrialRequestUsesTimeAfterLockWait(t *testing.T) {
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
	request := TrialStartRequest{TeamID: "team-1", UserID: "user-1"}
	type result struct {
		started bool
		err     error
	}
	results := make(chan result, 1)

	go func() {
		started, err := StartTrial(ctx, pool, request)
		results <- result{started, err}
	}()
	waitForBillingLocks(t, ctx, pool, 1)
	// Cross a storage-second boundary so a timestamp captured before the wait fails.
	time.Sleep(time.Until(time.Now().Truncate(time.Second).Add(time.Second)))
	releasedAt := time.Now().Unix()
	if err := blocker.Commit(ctx); err != nil {
		t.Fatal(err)
	}

	if got := <-results; got.err != nil || !got.started {
		t.Fatalf("want a new trial after the wait: started=%v, err=%v", got.started, got.err)
	}
	input := readStartedTrialInput(t, ctx, pool, request)
	if input.StartsAt.Unix() < releasedAt || input.StartsAt.Unix() > time.Now().Unix() {
		t.Fatalf("trial must begin after the lock wait, got %v", input.StartsAt)
	}
	assertOnlyStartedTrial(t, ctx, pool, input, nil)
}

func readStartedTrialInput(t *testing.T, ctx context.Context, pool *pgxpool.Pool, request TrialStartRequest) trialStart {
	t.Helper()
	input := trialStart{UserID: request.UserID, TeamID: request.TeamID}
	var startsAt int64
	if err := pool.QueryRow(ctx,
		"SELECT id, starts_at FROM billing_periods WHERE team_id = $1 AND period_type = 'trial'", request.TeamID,
	).Scan(&input.PeriodID, &startsAt); err != nil {
		t.Fatal(err)
	}
	input.StartsAt = time.Unix(startsAt, 0).UTC()
	return input
}
