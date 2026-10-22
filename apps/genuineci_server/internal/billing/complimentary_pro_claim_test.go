package billing

import (
	"context"
	"testing"
	"time"

	"github.com/jackc/pgx/v5"
)

func TestComplimentaryProClaimInitializesAccountWithoutWebVisit(t *testing.T) {
	ctx, service := newComplimentaryProClaimTest(t)
	claim, err := service.claimJob(ctx, workerClaimRequest{WorkerHost: "worker-1"})
	if err != nil || claim == nil || claim.JobID != "job-1" {
		t.Fatalf("configured team must start without visiting billing first: %+v, %v", claim, err)
	}
	var valid bool
	err = service.pool.QueryRow(ctx, `
		SELECT p.plan_id = 'pro' AND p.allowance_seconds = 360000 AND p.id LIKE 'complimentary-pro:%'
			AND a.reserved_millis = 60000
		FROM billing_admissions a JOIN billing_periods p ON p.id = a.period_id WHERE a.id = $1
	`, claim.AdmissionID).Scan(&valid)
	if err != nil || !valid {
		t.Fatalf("grant must use ordinary Pro reservations: valid=%v, err=%v", valid, err)
	}
	if _, err := service.claimJob(ctx, workerClaimRequest{WorkerHost: "worker-2"}); err != nil {
		t.Fatal(err)
	}
	if claim, err := service.claimJob(ctx, workerClaimRequest{WorkerHost: "worker-3"}); err != nil || claim != nil {
		t.Fatalf("unlisted unpaid team must stay queued: %+v, %v", claim, err)
	}
	assertJobClaimCount(t, ctx, service.pool, "team-2", 0)
}

func TestComplimentaryProSerializesReservationsAtAllowanceLimit(t *testing.T) {
	ctx, service := newComplimentaryProClaimTest(t)
	member := billingMember{TeamID: "team-1", UserID: "user-1"}
	if _, err := service.status(ctx, member); err != nil {
		t.Fatal(err)
	}
	var periodID string
	if err := service.pool.QueryRow(ctx, `SELECT id FROM billing_periods WHERE team_id = 'team-1'`).Scan(&periodID); err != nil {
		t.Fatal(err)
	}
	now := time.Now().UnixMilli()
	execCheckoutCreationSQL(t, ctx, service.pool, `
		INSERT INTO billing_admissions (id, job_id, team_id, worker_host, period_id, claimed_at_ms, start_by_ms, reserved_millis)
		VALUES ('existing', 'other-job', 'team-1', 'other-worker', $1, $2, $3, 359999000)
	`, periodID, now, now+120000)
	blocker, err := service.pool.Begin(ctx)
	if err != nil {
		t.Fatal(err)
	}
	defer blocker.Rollback(ctx)
	if _, err := blocker.Exec(ctx, `SELECT team_id FROM billing_accounts WHERE team_id = 'team-1' FOR UPDATE`); err != nil {
		t.Fatal(err)
	}
	type result struct {
		claim *workerClaim
		err   error
	}
	results := make(chan result, 2)
	for _, host := range []string{"worker-1", "worker-2"} {
		go func() {
			claim, err := service.claimJob(ctx, workerClaimRequest{WorkerHost: host})
			results <- result{claim, err}
		}()
	}
	waitForBillingLocks(t, ctx, service.pool, 2)
	if err := blocker.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	winners := 0
	for range 2 {
		got := <-results
		if got.err != nil {
			t.Fatal(got.err)
		}
		if got.claim != nil {
			winners++
		}
	}
	if winners != 1 {
		t.Fatalf("the last second must admit exactly one job, got %d", winners)
	}
	status, err := service.status(ctx, member)
	if err != nil || status.CanStartCI || status.BlockReason != "allowance_exhausted" {
		t.Fatalf("status must include reservations without replenishing the grant: %+v, %v", status, err)
	}
	var nextAvailable int64
	err = withBillingMemberLock(ctx, service.pool, member, func(tx pgx.Tx) error {
		var err error
		next := time.Now().UTC().AddDate(0, 1, 0)
		_, nextAvailable, err = service.availableClaimBudget(ctx, tx, "team-1", next)
		return err
	})
	if err != nil || nextAvailable != 360000000 {
		t.Fatalf("next month must have its own full allowance: %d, %v", nextAvailable, err)
	}
}

func TestComplimentaryProRemovalStopsNewClaimsAndLetsRunningWorkFinish(t *testing.T) {
	ctx, service := newComplimentaryProClaimTest(t)
	claim, err := service.claimJob(ctx, workerClaimRequest{WorkerHost: "worker-1"})
	if err != nil || claim == nil {
		t.Fatalf("claim failed: %+v, %v", claim, err)
	}
	execCheckoutCreationSQL(t, ctx, service.pool, `CREATE TABLE build_runs (id text PRIMARY KEY, build_job_id text); INSERT INTO build_runs VALUES ('run-1', 'job-1'); UPDATE build_jobs SET latest_run_id = 'run-1' WHERE id = 'job-1'; UPDATE billing_admissions SET run_id = 'run-1'`)
	request := workerExecutionRequest{AdmissionID: claim.AdmissionID, JobID: claim.JobID, RunID: "run-1", WorkerHost: "worker-1"}
	if _, err := service.startAdmittedExecution(ctx, request); err != nil {
		t.Fatal(err)
	}
	service.config.ComplimentaryProTeamIDs = nil
	if claim, err := service.claimJob(ctx, workerClaimRequest{WorkerHost: "worker-2"}); err != nil || claim != nil {
		t.Fatalf("retained grant period alone must not allow new work: %+v, %v", claim, err)
	}
	status, err := service.status(ctx, billingMember{TeamID: "team-1", UserID: "user-1"})
	if err != nil || status.CanStartCI || !status.CanCheckout {
		t.Fatalf("removed grant must return to paid eligibility: %+v, %v", status, err)
	}
	request.Outcome = "success"
	execution, err := service.reportAdmittedExecution(ctx, request)
	if err != nil || execution.FinishedAt == nil || *execution.Outcome != "success" {
		t.Fatalf("already-running work must finish with its history retained: %+v, %v", execution, err)
	}
}

func newComplimentaryProClaimTest(t *testing.T) (context.Context, *Service) {
	t.Helper()
	ctx, service := newJobClaimTestDB(t)
	execCheckoutCreationSQL(t, ctx, service.pool, `DELETE FROM billing_stripe_state; DELETE FROM billing_customer_creations; DELETE FROM billing_periods; DELETE FROM billing_accounts`)
	service.config.ComplimentaryProTeamIDs = []string{"team-1"}
	return ctx, service
}
