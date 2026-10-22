package billing

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/openci-org/openci/apps/genuineci_server/internal/testutil"
)

func TestClaimJobReservesAllowanceAndPersistsWorker(t *testing.T) {
	ctx, service := newJobClaimTestDB(t)
	vmName := "vm-1"
	claim, err := service.claimJob(ctx, workerClaimRequest{WorkerHost: "worker-1", VMName: &vmName})
	if err != nil || claim == nil || claim.JobID != "job-1" || claim.AdmissionID == "" {
		t.Fatalf("want the oldest paid job: claim=%+v, err=%v", claim, err)
	}
	var valid bool
	err = service.pool.QueryRow(ctx, `
		SELECT j.status = 'IN_PROGRESS' AND j.worker_host = 'worker-1' AND j.vm_name = 'vm-1'
			AND j.latest_run_id IS NULL AND a.period_id = 'paid-1' AND a.team_id = j.team_id
			AND a.reserved_millis = 60000 AND a.start_by_ms - a.claimed_at_ms = 120000
			AND a.worker_host = j.worker_host AND a.run_id IS NULL
		FROM build_jobs j JOIN billing_admissions a ON a.job_id = j.id WHERE a.id = $1
	`, claim.AdmissionID).Scan(&valid)
	if err != nil || !valid {
		t.Fatalf("job and admission must commit together: valid=%v, err=%v", valid, err)
	}
}

func TestClaimJobSkipsIneligibleTeam(t *testing.T) {
	for _, tc := range []struct{ name, sql string }{
		{"unpaid", `UPDATE billing_stripe_state SET subscription_status = 'incomplete' WHERE team_id = 'team-1'`},
		{"refunded and canceled", `UPDATE billing_stripe_state SET subscription_status = 'canceled' WHERE team_id = 'team-1'`},
		{"expired", `UPDATE billing_periods SET ends_at = starts_at + 1 WHERE id = 'paid-1'`},
		{"wrong mode", `UPDATE billing_customer_creations SET livemode = true WHERE team_id = 'team-1'`},
		{"wrong customer", `UPDATE billing_stripe_state SET stripe_customer_id = 'cus_wrong' WHERE team_id = 'team-1'`},
		{"wrong period", `UPDATE billing_stripe_state SET paid_period_id = 'paid-2' WHERE team_id = 'team-1'`},
		{"missing team", `DELETE FROM teams WHERE id = 'team-1'`},
		{"exhausted", `UPDATE billing_periods SET allowance_seconds = 0 WHERE id = 'paid-1'`},
	} {
		t.Run(tc.name, func(t *testing.T) {
			ctx, service := newJobClaimTestDB(t)
			testutil.ExecSQL(t, ctx, service.pool, tc.sql)
			claim, err := service.claimJob(ctx, workerClaimRequest{WorkerHost: "worker-1"})
			if err != nil || claim == nil || claim.JobID != "job-3" {
				t.Fatalf("blocked queue head must not block the other team: claim=%+v, err=%v", claim, err)
			}
			assertJobClaimCount(t, ctx, service.pool, "team-1", 0)
		})
	}
}

func TestClaimJobSerializesNearExhaustion(t *testing.T) {
	ctx, service := newJobClaimTestDB(t)
	testutil.ExecSQL(t, ctx, service.pool, `UPDATE billing_periods SET allowance_seconds = 1 WHERE id = 'paid-1'; DELETE FROM build_jobs WHERE team_id = 'team-2'`)
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
	testutil.WaitForLocks(t, ctx, service.pool, 2)
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
		t.Fatalf("want one admission for the last second, got %d", winners)
	}
	assertJobClaimCount(t, ctx, service.pool, "team-1", 1)
}

func TestClaimJobRechecksCancellationAfterLockWait(t *testing.T) {
	ctx, service := newJobClaimTestDB(t)
	blocker, err := service.pool.Begin(ctx)
	if err != nil {
		t.Fatal(err)
	}
	defer blocker.Rollback(ctx)
	if _, err := blocker.Exec(ctx, `SELECT team_id FROM billing_accounts WHERE team_id = 'team-1' FOR UPDATE`); err != nil {
		t.Fatal(err)
	}
	results := make(chan error, 1)
	go func() {
		claim, err := service.claimJob(ctx, workerClaimRequest{WorkerHost: "worker-1"})
		if err == nil && (claim == nil || claim.JobID != "job-3") {
			err = errors.New("canceled team was admitted")
		}
		results <- err
	}()
	testutil.WaitForLocks(t, ctx, service.pool, 1)
	if _, err := blocker.Exec(ctx, `UPDATE billing_stripe_state SET subscription_status = 'canceled' WHERE team_id = 'team-1'`); err != nil {
		t.Fatal(err)
	}
	if err := blocker.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	if err := <-results; err != nil {
		t.Fatal(err)
	}
}

func TestClaimJobHonorsHostCapacityWithoutPlanConcurrencyCap(t *testing.T) {
	ctx, service := newJobClaimTestDB(t)
	limit := 1
	request := workerClaimRequest{WorkerHost: "worker-1", MaxConcurrentJobs: &limit}
	if claim, err := service.claimJob(ctx, request); err != nil || claim == nil {
		t.Fatalf("first claim failed: %v", err)
	}
	if claim, err := service.claimJob(ctx, request); err != nil || claim != nil {
		t.Fatalf("host capacity must block another claim: %+v, %v", claim, err)
	}
	request.WorkerHost = "worker-2"
	if claim, err := service.claimJob(ctx, request); err != nil || claim == nil || claim.JobID != "job-2" {
		t.Fatalf("same plan must permit another host: %+v, %v", claim, err)
	}
	assertJobClaimCount(t, ctx, service.pool, "team-1", 2)
}

func TestClaimJobRollsBackReservationOnJobUpdateFailure(t *testing.T) {
	ctx, service := newJobClaimTestDB(t)
	testutil.ExecSQL(t, ctx, service.pool, `ALTER TABLE build_jobs ADD CHECK (status <> 'IN_PROGRESS')`)
	if claim, err := service.claimJob(ctx, workerClaimRequest{WorkerHost: "worker-1"}); err == nil || claim != nil {
		t.Fatal("failed job update must fail the entire claim")
	}
	assertJobClaimCount(t, ctx, service.pool, "team-1", 0)
}

func TestClaimJobRejectsInvalidWorkerBeforeDatabaseAccess(t *testing.T) {
	zero := 0
	for _, request := range []workerClaimRequest{{}, {WorkerHost: "with space"}, {WorkerHost: "worker\x00"}, {WorkerHost: "worker", MaxConcurrentJobs: &zero}} {
		if _, err := (&Service{}).claimJob(t.Context(), request); !errors.Is(err, errWorkerClaim) {
			t.Fatalf("want invalid request, got %v", err)
		}
	}
}

func newJobClaimTestDB(t *testing.T) (context.Context, *Service) {
	t.Helper()
	ctx, pool := testutil.NewAdmissionDB(t)
	now := time.Now().Unix()
	if _, err := pool.Exec(ctx, `UPDATE billing_periods SET starts_at = $1::bigint - 100, ends_at = $1::bigint + 3600`, now); err != nil {
		t.Fatal(err)
	}
	testutil.ExecSQL(t, ctx, pool, `
		INSERT INTO billing_customer_creations VALUES ('team-1', 'key-1', false, 0, 'cus_1'), ('team-2', 'key-2', false, 0, 'cus_2');
		INSERT INTO billing_stripe_state (team_id, stripe_customer_id, livemode, stripe_subscription_id, subscription_status, plan_id, paid_period_id, synced_at)
		VALUES ('team-1', 'cus_1', false, 'sub_1', 'active', 'light', 'paid-1', 0), ('team-2', 'cus_2', false, 'sub_2', 'active', 'pro', 'paid-2', 0);
		CREATE TABLE build_jobs (id text PRIMARY KEY, team_id text, status text, worker_host text, vm_name text, created_at bigint, updated_at bigint, latest_run_id text);
		INSERT INTO build_jobs (id, team_id, status, created_at, latest_run_id)
		VALUES ('job-1', 'team-1', 'QUEUED', 1, 'old-run'), ('job-2', 'team-1', 'QUEUED', 2, NULL), ('job-3', 'team-2', 'QUEUED', 3, NULL)
	`)
	return ctx, &Service{pool: pool}
}

func assertJobClaimCount(t *testing.T, ctx context.Context, pool *pgxpool.Pool, teamID string, want int) {
	t.Helper()
	var admissions, jobs int
	err := pool.QueryRow(ctx, `SELECT (SELECT count(*) FROM billing_admissions WHERE team_id = $1), (SELECT count(*) FROM build_jobs WHERE team_id = $1 AND status = 'IN_PROGRESS')`, teamID).Scan(&admissions, &jobs)
	if err != nil || admissions != want || jobs != want {
		t.Fatalf("want %d admissions and claimed jobs, got %d and %d: %v", want, admissions, jobs, err)
	}
}
