package billing

import (
	"context"
	"errors"
	"reflect"
	"testing"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/openci-org/openci/apps/genuineci_server/internal/testutil"
)

func TestExecutionHeartbeatAndFinishAreMonotonicAndIdempotent(t *testing.T) {
	for _, outcome := range []string{"success", "failure", "cancelled", "timed_out"} {
		t.Run(outcome, func(t *testing.T) {
			ctx, pool, id := startedExecutionTest(t)
			observe := func(at int64, result string) *execution {
				return observeExecutionTest(t, ctx, pool, executionObservation{
					Identity: id, At: time.UnixMilli(at), LeaseUntil: time.UnixMilli(at + 60000), Outcome: result,
				})
			}
			first := observe(2000, "")
			if first.ObservedAt.UnixMilli() != 2000 || first.FinishedAt != nil {
				t.Fatal("heartbeat must advance the measured interval")
			}
			for _, at := range []int64{1500, 2000} {
				if got := observe(at, ""); !reflect.DeepEqual(got, first) {
					t.Fatal("duplicate and out-of-order heartbeat must not rewrite the lease")
				}
			}
			finished := observe(3000, outcome)
			if finished.FinishedAt == nil || finished.FinishedAt.UnixMilli() != 3000 || *finished.Outcome != outcome || finished.MeasurementIncomplete {
				t.Fatal("finish must retain the measured time and outcome")
			}
			for _, result := range []string{outcome, "failure", ""} {
				if got := observe(5000, result); !reflect.DeepEqual(got, finished) {
					t.Fatal("a finished execution must never grow or change outcome")
				}
			}
		})
	}
}

func TestExpiredExecutionCannotResumeAndStopsAtLastObservation(t *testing.T) {
	ctx, pool, id := startedExecutionTest(t)
	for _, at := range []int64{61001, 90000} {
		got := observeExecutionTest(t, ctx, pool, executionObservation{
			Identity: id, At: time.UnixMilli(at), LeaseUntil: time.UnixMilli(at + 60000),
		})
		if got.FinishedAt == nil || got.FinishedAt.UnixMilli() != 1001 || *got.Outcome != "abandoned" || !got.MeasurementIncomplete {
			t.Fatal("an expired worker must not extend or resurrect its measurement")
		}
	}
}

func TestExecutionObservationRejectsAnotherWorkerAndInvalidEvents(t *testing.T) {
	for _, scenario := range []string{"worker", "missing run", "unsupported outcome", "before start", "invalid lease"} {
		t.Run(scenario, func(t *testing.T) {
			ctx, pool, id := startedExecutionTest(t)
			request := executionObservation{Identity: id, At: time.UnixMilli(2000), LeaseUntil: time.UnixMilli(62000)}
			switch scenario {
			case "worker":
				request.Identity.WorkerHost = "other-worker"
			case "missing run":
				request.Identity.RunID = "missing"
			case "unsupported outcome":
				request.Outcome = "skipped"
			case "before start":
				request.At = time.UnixMilli(1)
			case "invalid lease":
				request.LeaseUntil = request.At
			}
			if err := pgx.BeginFunc(ctx, pool, func(tx pgx.Tx) error {
				_, err := observeExecution(ctx, tx, request)
				return err
			}); err == nil {
				t.Fatal("invalid observations must not change measured usage")
			}
		})
	}
}

func TestExecutionExpiryIsBoundedAndDoesNotDoubleCount(t *testing.T) {
	ctx, pool, id := startedExecutionTest(t)
	observeExecutionTest(t, ctx, pool, executionObservation{
		Identity: id, At: time.UnixMilli(2000), LeaseUntil: time.UnixMilli(62000),
	})
	for _, want := range []int64{1, 0} {
		if err := pgx.BeginFunc(ctx, pool, func(tx pgx.Tx) error {
			count, err := expireExecutions(ctx, tx, time.UnixMilli(62000))
			if err == nil && count != want {
				return errors.New("unexpected number of expired executions")
			}
			return err
		}); err != nil {
			t.Fatal(err)
		}
	}
	got := observeExecutionTest(t, ctx, pool, executionObservation{Identity: id, At: time.UnixMilli(90000), Outcome: "success"})
	if got.FinishedAt == nil || got.FinishedAt.UnixMilli() != 2000 || !got.MeasurementIncomplete {
		t.Fatal("worker loss must retain only verified time and mark incomplete measurement")
	}
}

func TestConcurrentExecutionFinishesPreserveFirstResult(t *testing.T) {
	ctx, pool, id := startedExecutionTest(t)
	tx, err := pool.Begin(ctx)
	if err != nil {
		t.Fatal(err)
	}
	defer tx.Rollback(ctx)
	winner, err := observeExecution(ctx, tx, executionObservation{Identity: id, At: time.UnixMilli(3000), Outcome: "success"})
	if err != nil {
		t.Fatal(err)
	}
	type result struct {
		execution *execution
		err       error
	}
	results := make(chan result, 1)
	go func() {
		var got *execution
		err := pgx.BeginFunc(ctx, pool, func(tx pgx.Tx) error {
			var err error
			got, err = observeExecution(ctx, tx, executionObservation{Identity: id, At: time.UnixMilli(4000), Outcome: "failure"})
			return err
		})
		results <- result{got, err}
	}()
	testutil.WaitForLocks(t, ctx, pool, 1)
	if err := tx.Commit(ctx); err != nil {
		t.Fatal(err)
	}
	if got := <-results; got.err != nil || !reflect.DeepEqual(got.execution, winner) {
		t.Fatalf("concurrent duplicate finish must preserve the committed outcome: %v", got.err)
	}
}

func startedExecutionTest(t *testing.T) (context.Context, *pgxpool.Pool, executionIdentity) {
	t.Helper()
	ctx, pool := testutil.NewExecutionDB(t)
	request := executionStartFixture()
	if err := pgx.BeginFunc(ctx, pool, func(tx pgx.Tx) error {
		_, err := createExecution(ctx, tx, request)
		return err
	}); err != nil {
		t.Fatal(err)
	}
	return ctx, pool, request.Identity
}

func observeExecutionTest(t *testing.T, ctx context.Context, pool *pgxpool.Pool, request executionObservation) *execution {
	t.Helper()
	var result *execution
	if err := pgx.BeginFunc(ctx, pool, func(tx pgx.Tx) error {
		var err error
		result, err = observeExecution(ctx, tx, request)
		return err
	}); err != nil {
		t.Fatal(err)
	}
	return result
}
