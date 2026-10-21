package billing

import (
	"errors"
	"testing"
	"time"
)

func TestExpiredUnstartedAdmissionCanBeClaimedAgain(t *testing.T) {
	ctx, service := newJobClaimTestDB(t)
	limit := 1
	request := workerClaimRequest{WorkerHost: "worker-1", MaxConcurrentJobs: &limit}
	first, err := service.claimJob(ctx, request)
	if err != nil || first == nil {
		t.Fatalf("first claim: %+v, %v", first, err)
	}
	execCheckoutCreationSQL(t, ctx, service.pool, `UPDATE billing_admissions SET claimed_at_ms = 0, start_by_ms = 1`)
	second, err := service.claimJob(ctx, request)
	if err != nil || second == nil || second.JobID != first.JobID || second.AdmissionID == first.AdmissionID {
		t.Fatalf("expired reservation must release host capacity and get a fresh identity: %+v, %v", second, err)
	}
	var open, closed, executions int
	err = service.pool.QueryRow(ctx, `SELECT
		(SELECT count(*) FROM billing_admissions WHERE closed_at_ms IS NULL),
		(SELECT count(*) FROM billing_admissions WHERE closed_at_ms IS NOT NULL),
		(SELECT count(*) FROM billing_executions)`).Scan(&open, &closed, &executions)
	if err != nil || open != 1 || closed != 1 || executions != 0 {
		t.Fatalf("no execution means no charge, history must remain: %d, %d, %d, %v", open, closed, executions, err)
	}
}

func TestExpiredBoundAdmissionCannotStartAfterRecovery(t *testing.T) {
	ctx, service, request := newAdmittedExecutionTest(t)
	execCheckoutCreationSQL(t, ctx, service.pool, `
		ALTER TABLE build_runs ADD COLUMN status text DEFAULT 'in_progress', ADD COLUMN conclusion text, ADD COLUMN updated_at bigint;
		UPDATE billing_admissions SET claimed_at_ms = 0, start_by_ms = 1
	`)
	for range 2 {
		if err := service.recoverWorkerExecutions(ctx); err != nil {
			t.Fatal(err)
		}
	}
	if _, err := service.startAdmittedExecution(ctx, request); !errors.Is(err, errAdmissionNotCurrent) {
		t.Fatalf("late start must not launch another execution: %v", err)
	}
	var requeued, closedRun bool
	err := service.pool.QueryRow(ctx, `SELECT j.status = 'QUEUED' AND j.latest_run_id IS NULL AND j.worker_host IS NULL,
		r.status = 'completed' AND r.conclusion = 'failure' FROM build_jobs j JOIN build_runs r ON r.build_job_id = j.id WHERE r.id = 'run-1'`).Scan(&requeued, &closedRun)
	if err != nil || !requeued || !closedRun {
		t.Fatalf("unstarted attempt must be retained as failed before retry: %v", err)
	}
}

func TestLostStartedExecutionIsNotRequeuedOrChargedPastLastObservation(t *testing.T) {
	ctx, service, request := newAdmittedExecutionTest(t)
	if _, err := service.startAdmittedExecution(ctx, request); err != nil {
		t.Fatal(err)
	}
	at := time.Now().Add(-2 * time.Minute).UnixMilli()
	if _, err := service.pool.Exec(ctx, `UPDATE billing_executions SET started_at_ms = $1::bigint,
		observed_at_ms = $1::bigint + 1000, lease_until_ms = $1::bigint + 60000`, at); err != nil {
		t.Fatal(err)
	}
	if err := service.recoverWorkerExecutions(ctx); err != nil {
		t.Fatal(err)
	}
	var preserved bool
	err := service.pool.QueryRow(ctx, `SELECT e.finished_at_ms = e.observed_at_ms AND e.measurement_incomplete
		AND e.outcome = 'abandoned' AND a.closed_at_ms IS NOT NULL AND j.status = 'IN_PROGRESS'
		FROM billing_executions e JOIN billing_admissions a ON a.run_id = e.run_id JOIN build_jobs j ON j.id = e.job_id`).Scan(&preserved)
	if err != nil || !preserved {
		t.Fatalf("running CI must not be duplicated or have unobserved usage invented: %v", err)
	}
	request.Outcome = "success"
	result, err := service.reportAdmittedExecution(ctx, request)
	if err != nil || !result.MeasurementIncomplete || result.FinishedAt.UnixMilli() != at+1000 {
		t.Fatalf("late report must preserve incomplete measured history: %+v, %v", result, err)
	}
}

func TestRecoveryLeavesActiveExecutionAndAdmissionAlone(t *testing.T) {
	ctx, service, request := newAdmittedExecutionTest(t)
	if _, err := service.startAdmittedExecution(ctx, request); err != nil {
		t.Fatal(err)
	}
	if err := service.recoverWorkerExecutions(ctx); err != nil {
		t.Fatal(err)
	}
	var active bool
	err := service.pool.QueryRow(ctx, `SELECT e.finished_at_ms IS NULL AND a.closed_at_ms IS NULL
		FROM billing_executions e JOIN billing_admissions a ON a.run_id = e.run_id`).Scan(&active)
	if err != nil || !active {
		t.Fatal("active execution must retain its lease and admission")
	}
}

func TestConcurrentRecoveryAndClaimsDoNotDuplicateAnExpiredJob(t *testing.T) {
	ctx, service := newJobClaimTestDB(t)
	limit := 1
	request := workerClaimRequest{WorkerHost: "worker-1", MaxConcurrentJobs: &limit}
	if claim, err := service.claimJob(ctx, request); err != nil || claim == nil {
		t.Fatal("initial claim failed")
	}
	execCheckoutCreationSQL(t, ctx, service.pool, `UPDATE billing_admissions SET claimed_at_ms = 0, start_by_ms = 1`)
	type result struct {
		claim *workerClaim
		err   error
	}
	results := make(chan result, 2)
	for range 2 {
		go func() {
			claim, err := service.claimJob(ctx, request)
			results <- result{claim, err}
		}()
	}
	claimed := 0
	for range 2 {
		result := <-results
		if result.err != nil {
			t.Fatal(result.err)
		}
		if result.claim != nil {
			claimed++
			if result.claim.JobID != "job-1" {
				t.Fatal("host capacity must not admit a second job")
			}
		}
	}
	if claimed != 1 {
		t.Fatalf("want one recovery winner, got %d", claimed)
	}
}

func TestRecoveryDoesNotRestoreCancelledJobs(t *testing.T) {
	ctx, service := newJobClaimTestDB(t)
	if claim, err := service.claimJob(ctx, workerClaimRequest{WorkerHost: "worker-1"}); err != nil || claim == nil {
		t.Fatal("claim failed")
	}
	execCheckoutCreationSQL(t, ctx, service.pool, `UPDATE billing_admissions SET claimed_at_ms = 0, start_by_ms = 1; UPDATE build_jobs SET status = 'CANCELLED' WHERE id = 'job-1'`)
	if err := service.recoverWorkerExecutions(ctx); err != nil {
		t.Fatal(err)
	}
	var retained bool
	err := service.pool.QueryRow(ctx, `SELECT j.status = 'CANCELLED' AND a.closed_at_ms IS NOT NULL
		FROM build_jobs j JOIN billing_admissions a ON a.job_id = j.id`).Scan(&retained)
	if err != nil || !retained {
		t.Fatal("cancellation must survive reservation recovery")
	}
}

func TestRecoverySkipsLockedJobsAndRetainsDeletedJobHistory(t *testing.T) {
	ctx, service := newJobClaimTestDB(t)
	claim, err := service.claimJob(ctx, workerClaimRequest{WorkerHost: "worker-1"})
	if err != nil || claim == nil {
		t.Fatal(err)
	}
	execCheckoutCreationSQL(t, ctx, service.pool, `UPDATE billing_admissions SET claimed_at_ms = 0, start_by_ms = 1`)
	lock, err := service.pool.Begin(ctx)
	if err != nil {
		t.Fatal(err)
	}
	defer lock.Rollback(ctx)
	if _, err := lock.Exec(ctx, `SELECT id FROM build_jobs WHERE id = 'job-1' FOR UPDATE`); err != nil {
		t.Fatal(err)
	}
	if err := service.recoverWorkerExecutions(ctx); err != nil {
		t.Fatalf("recovery must skip a locked job: %v", err)
	}
	var open bool
	if err := service.pool.QueryRow(ctx, `SELECT closed_at_ms IS NULL FROM billing_admissions`).Scan(&open); err != nil || !open {
		t.Fatal("busy admission was changed")
	}
	if _, err := lock.Exec(ctx, `DELETE FROM build_jobs WHERE id = 'job-1'`); err != nil {
		t.Fatal(err)
	}
	if err := lock.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	if err := service.recoverWorkerExecutions(ctx); err != nil {
		t.Fatal(err)
	}
	if err := service.pool.QueryRow(ctx, `SELECT closed_at_ms IS NULL FROM billing_admissions`).Scan(&open); err != nil || open {
		t.Fatal("deleted display job must not prevent closing durable history")
	}
}
