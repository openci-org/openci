package billing

import (
	"errors"
	"reflect"
	"testing"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/openci-org/openci/apps/genuineci_server/internal/testutil"
)

func TestCreateExecutionPreservesFirstStartAndAllowsDistinctReruns(t *testing.T) {
	ctx, pool := testutil.NewExecutionDB(t)
	request := executionStartFixture()
	var original *execution
	err := pgx.BeginFunc(ctx, pool, func(tx pgx.Tx) error {
		var err error
		original, err = createExecution(ctx, tx, request)
		return err
	})
	if err != nil {
		t.Fatal(err)
	}
	if original.StartedAt.UnixMilli() != request.StartedAt.UnixMilli() || original.ObservedAt != original.StartedAt || original.FinishedAt != nil {
		t.Fatal("an execution starts with zero measured time and no outcome")
	}
	retry := request
	retry.StartedAt, retry.LeaseUntil = request.StartedAt.Add(time.Second), request.LeaseUntil.Add(time.Second)
	if err := pgx.BeginFunc(ctx, pool, func(tx pgx.Tx) error {
		got, err := createExecution(ctx, tx, retry)
		if err == nil && !reflect.DeepEqual(got, original) {
			t.Fatal("a retry must not reset start time or extend the original lease")
		}
		return err
	}); err != nil {
		t.Fatal(err)
	}
	retry.Identity.RunID = "rerun"
	if err := pgx.BeginFunc(ctx, pool, func(tx pgx.Tx) error {
		_, err := createExecution(ctx, tx, retry)
		return err
	}); err != nil {
		t.Fatal(err)
	}
	var count int
	if err := pool.QueryRow(ctx, "SELECT count(*) FROM billing_executions WHERE job_id = 'job-1'").Scan(&count); err != nil || count != 2 {
		t.Fatal("reruns require separate durable measurements")
	}
}

func TestCreateExecutionRejectsChangedIdentityAndIneligiblePeriods(t *testing.T) {
	for _, scenario := range []string{"worker", "job", "team", "period", "trial", "future period", "empty identity", "invalid lease"} {
		t.Run(scenario, func(t *testing.T) {
			ctx, pool := testutil.NewExecutionDB(t)
			request := executionStartFixture()
			if err := pgx.BeginFunc(ctx, pool, func(tx pgx.Tx) error {
				_, err := createExecution(ctx, tx, request)
				return err
			}); err != nil {
				t.Fatal(err)
			}
			switch scenario {
			case "worker":
				request.Identity.WorkerHost = "other-worker"
			case "job":
				request.Identity.JobID = "other-job"
			case "team":
				request.Identity.TeamID, request.Identity.PeriodID = "team-2", "paid-2"
			case "period":
				request.Identity.PeriodID = "paid-2"
			case "trial":
				request.Identity.RunID = "new-run"
				testutil.ExecSQL(t, ctx, pool, "UPDATE billing_periods SET period_type = 'trial' WHERE id = 'paid-1'")
			case "future period":
				request.Identity.RunID = "new-run"
				testutil.ExecSQL(t, ctx, pool, "UPDATE billing_periods SET starts_at = 100 WHERE id = 'paid-1'")
			case "empty identity":
				request.Identity.WorkerHost = " "
			case "invalid lease":
				request.LeaseUntil = request.StartedAt
			}
			err := pgx.BeginFunc(ctx, pool, func(tx pgx.Tx) error {
				_, err := createExecution(ctx, tx, request)
				return err
			})
			if err == nil {
				t.Fatal("invalid identity, period, and time must not create or rewrite usage")
			}
		})
	}
}

func TestCreateExecutionConcurrentRetryAndRollback(t *testing.T) {
	ctx, pool := testutil.NewExecutionDB(t)
	request := executionStartFixture()
	tx, err := pool.Begin(ctx)
	if err != nil {
		t.Fatal(err)
	}
	defer tx.Rollback(ctx)
	if _, err := createExecution(ctx, tx, request); err != nil {
		t.Fatal(err)
	}
	result := make(chan error, 1)
	go func() {
		result <- pgx.BeginFunc(ctx, pool, func(tx pgx.Tx) error {
			_, err := createExecution(ctx, tx, request)
			return err
		})
	}()
	testutil.WaitForLocks(t, ctx, pool, 1)
	if err := tx.Rollback(ctx); err != nil {
		t.Fatal(err)
	}
	if err := <-result; err != nil {
		t.Fatalf("retry after rollback must establish the measurement: %v", err)
	}
	if err := pgx.BeginFunc(ctx, pool, func(tx pgx.Tx) error {
		got, err := getExecution(ctx, tx, request.Identity.RunID)
		if err == nil && (got == nil || got.Identity != request.Identity) {
			return errors.New("concurrent retry did not retain the expected identity")
		}
		return err
	}); err != nil {
		t.Fatal(err)
	}
}

func executionStartFixture() executionStart {
	return executionStart{
		Identity:  executionIdentity{RunID: "run-1", TeamID: "team-1", JobID: "job-1", WorkerHost: "worker-1", PeriodID: "paid-1"},
		StartedAt: time.UnixMilli(1001), LeaseUntil: time.UnixMilli(61001),
	}
}
