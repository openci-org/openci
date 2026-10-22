package billing

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/openci-org/openci/apps/genuineci_server/internal/testutil"
)

func TestAdmittedExecutionStartsAndFinishesOnce(t *testing.T) {
	ctx, service, request := newAdmittedExecutionTest(t)
	before := time.Now().UnixMilli()
	first, err := service.startAdmittedExecution(ctx, request)
	if err != nil || first == nil || first.StartedAt.UnixMilli() < before || first.LeaseUntil.Sub(first.StartedAt) != time.Minute {
		t.Fatalf("server must create a bounded execution lease: %+v, %v", first, err)
	}
	repeated, err := service.startAdmittedExecution(ctx, request)
	if err != nil || !repeated.StartedAt.Equal(first.StartedAt) {
		t.Fatal("retry must preserve the original start")
	}
	request.Outcome = "success"
	finished, err := service.reportAdmittedExecution(ctx, request)
	if err != nil || finished.FinishedAt == nil || *finished.Outcome != "success" {
		t.Fatalf("finish failed: %+v, %v", finished, err)
	}
	request.Outcome = "failure"
	repeated, err = service.reportAdmittedExecution(ctx, request)
	if err != nil || !repeated.FinishedAt.Equal(*finished.FinishedAt) || *repeated.Outcome != "success" {
		t.Fatal("first completion must win")
	}
	var closed bool
	if err := service.pool.QueryRow(ctx, `SELECT closed_at_ms IS NOT NULL FROM billing_admissions WHERE id = $1`, request.AdmissionID).Scan(&closed); err != nil || !closed {
		t.Fatal("finish must release the admission")
	}
}

func TestAdmittedExecutionContinuesAfterEntitlementEnds(t *testing.T) {
	ctx, service, request := newAdmittedExecutionTest(t)
	testutil.ExecSQL(t, ctx, service.pool, `UPDATE billing_stripe_state SET subscription_status = 'canceled'; UPDATE billing_periods SET allowance_seconds = 0, ends_at = starts_at + 1; DELETE FROM teams`)
	if _, err := service.startAdmittedExecution(ctx, request); err != nil {
		t.Fatalf("accepted admission must survive period end and cancellation: %v", err)
	}
	if execution, err := service.reportAdmittedExecution(ctx, request); err != nil || execution.FinishedAt != nil {
		t.Fatalf("running work must keep measuring: %+v, %v", execution, err)
	}
	request.Outcome = "success"
	if execution, err := service.reportAdmittedExecution(ctx, request); err != nil || execution.FinishedAt == nil {
		t.Fatalf("running work must finish normally: %+v, %v", execution, err)
	}
}

func TestAdmittedExecutionRejectsStaleOrUnboundIdentity(t *testing.T) {
	for _, tc := range []struct{ name, sql string }{
		{"unbound", `UPDATE billing_admissions SET run_id = NULL`},
		{"other worker", `UPDATE build_jobs SET worker_host = 'worker-2'`},
		{"old run", `UPDATE build_jobs SET latest_run_id = 'new-run'`},
		{"unrelated run", `UPDATE build_runs SET build_job_id = 'job-2'`},
		{"closed claim", `UPDATE billing_admissions SET closed_at_ms = claimed_at_ms`},
		{"start deadline", `UPDATE billing_admissions SET claimed_at_ms = 0, start_by_ms = 1`},
		{"already completed job", `UPDATE build_jobs SET status = 'FAILURE'`},
	} {
		t.Run(tc.name, func(t *testing.T) {
			ctx, service, request := newAdmittedExecutionTest(t)
			testutil.ExecSQL(t, ctx, service.pool, tc.sql)
			if _, err := service.startAdmittedExecution(ctx, request); !errors.Is(err, errAdmissionNotCurrent) {
				t.Fatalf("stale claim must be rejected: %v", err)
			}
			var count int
			if err := service.pool.QueryRow(ctx, `SELECT count(*) FROM billing_executions`).Scan(&count); err != nil || count != 0 {
				t.Fatal("rejected start must not charge usage")
			}
		})
	}
}

func TestAdmittedExecutionCannotResurrectExpiredMeasurement(t *testing.T) {
	ctx, service, request := newAdmittedExecutionTest(t)
	if _, err := service.startAdmittedExecution(ctx, request); err != nil {
		t.Fatal(err)
	}
	before := time.Now().Add(-2 * time.Minute).UnixMilli()
	if _, err := service.pool.Exec(ctx, `UPDATE billing_executions SET started_at_ms = $1::bigint, observed_at_ms = $1::bigint + 1000, lease_until_ms = $1::bigint + 60000`, before); err != nil {
		t.Fatal(err)
	}
	result, err := service.startAdmittedExecution(ctx, request)
	if err != nil || !result.MeasurementIncomplete || result.FinishedAt == nil || *result.Outcome != "abandoned" || result.FinishedAt.UnixMilli() != before+1000 {
		t.Fatalf("expired lease must stop at last verified measurement: %+v, %v", result, err)
	}
	request.Outcome = "success"
	result, err = service.reportAdmittedExecution(ctx, request)
	if err != nil || !result.MeasurementIncomplete || *result.Outcome != "abandoned" {
		t.Fatal("late completion must not invent missing usage")
	}
}

func TestAdmittedExecutionRejectsInvalidRequestsBeforeDB(t *testing.T) {
	service := &Service{}
	if _, err := service.startAdmittedExecution(t.Context(), workerExecutionRequest{}); !errors.Is(err, errExecutionRequest) {
		t.Fatal("missing identity must fail early")
	}
	if _, err := service.reportAdmittedExecution(t.Context(), workerExecutionRequest{Outcome: "invented"}); !errors.Is(err, errExecutionRequest) {
		t.Fatal("unknown outcome must fail early")
	}
}

func newAdmittedExecutionTest(t *testing.T) (context.Context, *Service, workerExecutionRequest) {
	t.Helper()
	ctx, service := newJobClaimTestDB(t)
	claim, err := service.claimJob(ctx, workerClaimRequest{WorkerHost: "worker-1"})
	if err != nil || claim == nil {
		t.Fatalf("claim failed: %+v, %v", claim, err)
	}
	testutil.ExecSQL(t, ctx, service.pool, `CREATE TABLE build_runs (id text PRIMARY KEY, build_job_id text); INSERT INTO build_runs VALUES ('run-1', 'job-1'); UPDATE build_jobs SET latest_run_id = 'run-1' WHERE id = 'job-1'; UPDATE billing_admissions SET run_id = 'run-1'`)
	return ctx, service, workerExecutionRequest{AdmissionID: claim.AdmissionID, JobID: claim.JobID, RunID: "run-1", WorkerHost: "worker-1"}
}
