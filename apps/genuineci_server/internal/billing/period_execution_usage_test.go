package billing

import (
	"context"
	"reflect"
	"testing"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/openci-org/openci/apps/genuineci_server/internal/testutil"
)

func TestPeriodExecutionUsageSumsParallelRunsAcrossRenewal(t *testing.T) {
	ctx, pool := testutil.NewExecutionDB(t)
	seedPeriodExecutionUsage(t, ctx, pool)
	first := readPeriodExecutionUsage(t, ctx, pool, "team-1", "paid-1", 14000)
	if first == nil || first.AllowanceSeconds != 36000 || first.MeasuredMillis != 8000 || first.LeasedMillis != 0 || first.MeasurementIncomplete {
		t.Fatalf("first period must include parallel time and only its part of the crossing run: %+v", first)
	}
	next := readPeriodExecutionUsage(t, ctx, pool, "team-1", "paid-next", 14000)
	if next == nil || next.AllowanceSeconds != 360000 || next.MeasuredMillis != 4000 || next.LeasedMillis != 3000 || next.MeasurementIncomplete {
		t.Fatalf("renewal must separate measured usage from outstanding worker lease time: %+v", next)
	}
	for range 3 {
		if got := readPeriodExecutionUsage(t, ctx, pool, "team-1", "paid-next", 15000); !reflect.DeepEqual(got, next) {
			t.Fatal("reads must not invent measured time or reset the remaining worker lease")
		}
	}
	if usage := readPeriodExecutionUsage(t, ctx, pool, "team-2", "paid-1", 14000); usage != nil {
		t.Fatal("a period from another team must not be readable")
	}
	other := readPeriodExecutionUsage(t, ctx, pool, "team-2", "paid-2", 14000)
	if other == nil || other.MeasuredMillis != 7000 || other.LeasedMillis != 0 {
		t.Fatalf("another team must retain its independent totals: %+v", other)
	}
}

func TestPeriodExecutionUsageBoundsAbandonedMeasurements(t *testing.T) {
	ctx, pool := testutil.NewExecutionDB(t)
	seedPeriodExecutionUsage(t, ctx, pool)
	expired := readPeriodExecutionUsage(t, ctx, pool, "team-1", "paid-next", 16000)
	if expired == nil || expired.MeasuredMillis != 4000 || expired.LeasedMillis != 0 || !expired.MeasurementIncomplete {
		t.Fatalf("lease loss must release unverified time and flag the incomplete measurement: %+v", expired)
	}
	if err := pgx.BeginFunc(ctx, pool, func(tx pgx.Tx) error {
		_, err := expireExecutions(ctx, tx, time.UnixMilli(16000))
		return err
	}); err != nil {
		t.Fatal(err)
	}
	if got := readPeriodExecutionUsage(t, ctx, pool, "team-1", "paid-next", 900000); !reflect.DeepEqual(got, expired) {
		t.Fatal("expiry reconciliation and later reads must preserve the same bounded measurement")
	}
}

func TestPeriodExecutionUsageExcludesQueuesAndTrials(t *testing.T) {
	ctx, pool := testutil.NewExecutionDB(t)
	testutil.ExecSQL(t, ctx, pool, `
		CREATE TABLE build_jobs (id text PRIMARY KEY, team_id text, status text, created_at bigint);
		INSERT INTO build_jobs VALUES ('queued', 'team-1', 'QUEUED', 1), ('dependency-wait', 'team-1', 'WAITING', 1);
		INSERT INTO billing_periods (id, team_id, plan_id, period_type, starts_at, ends_at, allowance_seconds)
		VALUES ('trial', 'team-1', 'pro', 'trial', 0, 1000, 360000)
	`)
	usage := readPeriodExecutionUsage(t, ctx, pool, "team-1", "paid-1", 900000)
	if usage == nil || usage.MeasuredMillis != 0 || usage.LeasedMillis != 0 || usage.AllowanceSeconds != 36000 {
		t.Fatal("job creation and waiting time must not count as execution")
	}
	if got := readPeriodExecutionUsage(t, ctx, pool, "team-1", "trial", 900000); got != nil {
		t.Fatal("the deferred trial period must not participate in paid usage")
	}
}

func TestPeriodExecutionUsagePreservesIncompleteStartAtPeriodBoundary(t *testing.T) {
	ctx, pool := testutil.NewExecutionDB(t)
	testutil.ExecSQL(t, ctx, pool, `
		INSERT INTO billing_executions
			(run_id, team_id, job_id, worker_host, period_id, started_at_ms, observed_at_ms, lease_until_ms,
			finished_at_ms, outcome, measurement_incomplete)
		VALUES ('lost-at-start', 'team-1', 'job-1', 'worker-1', 'paid-1', 0, 0, 1000, 0, 'abandoned', true)
	`)
	usage := readPeriodExecutionUsage(t, ctx, pool, "team-1", "paid-1", 2000)
	if usage == nil || usage.MeasuredMillis != 0 || usage.LeasedMillis != 0 || !usage.MeasurementIncomplete {
		t.Fatalf("a worker lost before its first heartbeat must remain visible without estimated charges: %+v", usage)
	}
}

func seedPeriodExecutionUsage(t *testing.T, ctx context.Context, pool *pgxpool.Pool) {
	t.Helper()
	testutil.ExecSQL(t, ctx, pool, `
		UPDATE billing_periods SET ends_at = 10 WHERE id = 'paid-1';
		INSERT INTO billing_periods (id, team_id, plan_id, period_type, starts_at, ends_at, allowance_seconds)
		VALUES ('paid-next', 'team-1', 'pro', 'paid', 10, 20, 360000);
		INSERT INTO billing_executions
			(run_id, team_id, job_id, worker_host, period_id, started_at_ms, observed_at_ms, lease_until_ms, finished_at_ms, outcome)
		VALUES ('first', 'team-1', 'job-1', 'worker-1', 'paid-1', 1000, 5000, 60000, 5000, 'success'),
			('parallel', 'team-1', 'job-2', 'worker-2', 'paid-1', 2000, 5000, 60000, 5000, 'failure'),
			('crossing', 'team-1', 'job-3', 'worker-1', 'paid-1', 9000, 12000, 60000, 12000, 'success'),
			('running', 'team-1', 'job-4', 'worker-2', 'paid-next', 11000, 13000, 16000, NULL, NULL),
			('other', 'team-2', 'job-5', 'worker-1', 'paid-2', 1000, 8000, 60000, 8000, 'success')
	`)
}

func readPeriodExecutionUsage(t *testing.T, ctx context.Context, pool *pgxpool.Pool, teamID, periodID string, at int64) *periodExecutionUsage {
	t.Helper()
	var result *periodExecutionUsage
	if err := pgx.BeginFunc(ctx, pool, func(tx pgx.Tx) error {
		var err error
		result, err = getPeriodExecutionUsage(ctx, tx, periodExecutionUsageQuery{TeamID: teamID, PeriodID: periodID, At: time.UnixMilli(at)})
		return err
	}); err != nil {
		t.Fatal(err)
	}
	return result
}
