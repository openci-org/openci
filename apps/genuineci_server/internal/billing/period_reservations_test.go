package billing

import "testing"

func TestPeriodUsageReservesUnstartedClaimsWithoutChargingWaitingTime(t *testing.T) {
	ctx, pool := newAdmissionTestDB(t)
	execCheckoutCreationSQL(t, ctx, pool, `
		UPDATE billing_periods SET allowance_seconds = 120 WHERE id = 'paid-1';
		INSERT INTO billing_admissions VALUES
			('pending', 'job-1', 'team-1', 'worker-1', 'paid-1', 1000, 121000, 60000, NULL, NULL),
			('bound', 'job-2', 'team-1', 'worker-2', 'paid-1', 1000, 121000, 60000, 'run-2', NULL),
			('expired', 'job-3', 'team-1', 'worker-3', 'paid-1', 1000, 10000, 60000, NULL, NULL),
			('closed', 'job-4', 'team-1', 'worker-4', 'paid-1', 1000, 121000, 60000, NULL, 2000),
			('other', 'job-5', 'team-2', 'worker-5', 'paid-2', 1000, 121000, 60000, NULL, NULL)
	`)
	before := readPeriodExecutionUsage(t, ctx, pool, "team-1", "paid-1", 10000)
	available, err := before.availableMillis()
	if err != nil || available != 0 || before.MeasuredMillis != 0 || before.LeasedMillis != 0 || before.ReservedMillis != 120000 {
		t.Fatalf("pending and bound-but-unstarted claims must reserve without measured consumption: %+v, %v", before, err)
	}
	execCheckoutCreationSQL(t, ctx, pool, `
		INSERT INTO billing_executions
			(run_id, team_id, job_id, worker_host, period_id, started_at_ms, observed_at_ms, lease_until_ms)
		VALUES ('run-2', 'team-1', 'job-2', 'worker-2', 'paid-1', 10000, 11000, 71000)
	`)
	after := readPeriodExecutionUsage(t, ctx, pool, "team-1", "paid-1", 11000)
	available, err = after.availableMillis()
	if err != nil || available != 0 || after.ReservedMillis != 60000 || after.MeasuredMillis != 1000 || after.LeasedMillis != 60000 {
		t.Fatalf("execution measurement must replace its reservation without double counting: %+v, %v", after, err)
	}
	late := readPeriodExecutionUsage(t, ctx, pool, "team-1", "paid-1", 121000)
	available, err = late.availableMillis()
	if err != nil || available != 119000 || late.ReservedMillis != 0 || late.LeasedMillis != 0 || !late.MeasurementIncomplete {
		t.Fatalf("expired reservations and leases must release only unobserved time: %+v, %v", late, err)
	}
}

func TestPendingReservationCrossesRenewalWithoutResettingItsBudget(t *testing.T) {
	ctx, pool := newAdmissionTestDB(t)
	execCheckoutCreationSQL(t, ctx, pool, `
		UPDATE billing_periods SET ends_at = 10 WHERE id = 'paid-1';
		INSERT INTO billing_periods VALUES ('renewal', 'team-1', 'pro', 'paid', 10, 1000, 360000);
		INSERT INTO billing_admissions VALUES ('crossing', 'job-1', 'team-1', 'worker-1', 'paid-1', 9000, 129000, 60000, NULL, NULL)
	`)
	usage := readPeriodExecutionUsage(t, ctx, pool, "team-1", "renewal", 10000)
	available, err := usage.availableMillis()
	if err != nil || usage.ReservedMillis != 60000 || usage.MeasuredMillis != 0 || available != 359940000 {
		t.Fatalf("an already admitted job can start across renewal and must reserve once in the new period: %+v, %v", usage, err)
	}
	if old := readPeriodExecutionUsage(t, ctx, pool, "team-1", "paid-1", 10000); old.ReservedMillis != 0 {
		t.Fatal("the ended period must not retain unstarted reservations as historical usage")
	}
}
