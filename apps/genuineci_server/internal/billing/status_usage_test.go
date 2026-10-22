package billing

import (
	"testing"
	"time"

	"github.com/openci-org/openci/apps/genuineci_server/internal/testutil"
)

func TestBillingStatusUsesPersistedExecutionBudget(t *testing.T) {
	for _, tc := range []struct {
		name           string
		allowance      int64
		measuredMillis int64
		leaseMillis    int64
		finished       bool
		canStart       bool
	}{
		{"empty period", 120, 0, 0, true, true},
		{"remaining allowance", 120, 119999, 0, true, true},
		{"exactly exhausted", 120, 120000, 0, true, false},
		{"over allowance", 120, 120001, 0, true, false},
		{"all remaining time leased", 120, 60000, 60000, false, false},
		{"remaining beyond lease", 121, 60000, 60000, false, true},
		{"expired lease releases unobserved time", 120, 60000, -1000, false, true},
		{"zero allowance", 0, 0, 0, true, false},
	} {
		t.Run(tc.name, func(t *testing.T) {
			ctx, pool := testutil.NewStripeStateDB(t)
			now := time.Now().Truncate(time.Millisecond)
			observed := now.UnixMilli()
			lease := observed + tc.leaseMillis
			if tc.leaseMillis < 0 {
				observed = lease - 1000
			}
			testutil.ExecSQL(t, ctx, pool, `
				INSERT INTO billing_periods VALUES ('paid', 'team-1', 'light', 'paid', $1, $2, $3);
			`, now.Add(-time.Hour).Unix(), now.Add(time.Hour).Unix(), tc.allowance)
			testutil.ExecSQL(t, ctx, pool, `
				INSERT INTO billing_stripe_state
					(team_id, stripe_customer_id, livemode, stripe_subscription_id, subscription_status, plan_id, paid_period_id, synced_at)
				VALUES ('team-1', 'cus_team', false, 'sub_team', 'active', 'light', 'paid', $1)
			`, now.Unix())
			var finished *int64
			var outcome *string
			if tc.finished {
				finished = &observed
				value := "success"
				outcome = &value
			}
			testutil.ExecSQL(t, ctx, pool, `
				INSERT INTO billing_executions
					(run_id, team_id, job_id, worker_host, period_id, started_at_ms, observed_at_ms, lease_until_ms, finished_at_ms, outcome)
				VALUES ('run', 'team-1', 'job', 'worker', 'paid', $1, $2, $3, $4, $5)
			`, observed-tc.measuredMillis, observed, lease, finished, outcome)
			service := &Service{pool: pool}
			for range 2 {
				status, err := service.status(ctx, billingMember{TeamID: "team-1", UserID: "user-1"})
				if err != nil || status == nil || status.CanStartCI != tc.canStart {
					t.Fatalf("unexpected allowance decision: status=%+v, err=%v", status, err)
				}
				wantReason := ""
				if !tc.canStart {
					wantReason = "allowance_exhausted"
				}
				if status.BlockReason != wantReason || status.PlanID == nil || *status.PlanID != "light" || status.CanCheckout {
					t.Fatalf("budget must affect only new-start access, retaining the existing subscription: %+v", status)
				}
			}
			var storedObserved int64
			var storedFinished *int64
			if err := pool.QueryRow(ctx, `SELECT observed_at_ms, finished_at_ms FROM billing_executions WHERE run_id = 'run'`).Scan(&storedObserved, &storedFinished); err != nil || storedObserved != observed || (storedFinished != nil) != tc.finished {
				t.Fatal("status reads must not advance measurement or finalize an expired execution")
			}
		})
	}
}

func TestBillingStatusRejectsMissingUsageAllowance(t *testing.T) {
	ctx, pool := testutil.NewStripeStateDB(t)
	now := time.Now()
	testutil.ExecSQL(t, ctx, pool, `
		INSERT INTO billing_periods VALUES ('paid', 'team-1', 'light', 'paid', $1, $2, NULL)
	`, now.Add(-time.Hour).Unix(), now.Add(time.Hour).Unix())
	testutil.ExecSQL(t, ctx, pool, `
		INSERT INTO billing_stripe_state
			(team_id, stripe_customer_id, livemode, stripe_subscription_id, subscription_status, plan_id, paid_period_id, synced_at)
		VALUES ('team-1', 'cus_team', false, 'sub_team', 'active', 'light', 'paid', $1)
	`, now.Unix())
	service := &Service{pool: pool}
	status, err := service.status(ctx, billingMember{TeamID: "team-1", UserID: "user-1"})
	if err != nil || status == nil || status.CanStartCI || status.BlockReason != "billing_unavailable" {
		t.Fatalf("an incomplete paid-period snapshot must not grant CI access: %+v, %v", status, err)
	}
}
