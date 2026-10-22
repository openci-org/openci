package billing

import (
	"errors"
	"net/http"
	"strings"
	"testing"
	"time"

	"github.com/jackc/pgx/v5"
	billingconfig "github.com/openci-org/openci/apps/genuineci_server/internal/billing/config"
	"github.com/openci-org/openci/apps/genuineci_server/internal/testutil"
)

func TestComplimentaryProRenewsByUTCMonthWithoutResettingHistory(t *testing.T) {
	ctx, pool := testutil.NewStripeStateDB(t)
	before := time.Date(2040, 1, 1, 8, 59, 59, 0, time.FixedZone("JST", 9*60*60))
	var first *billingPeriod
	err := withBillingMemberLock(ctx, pool, billingMember{TeamID: "team-1", UserID: "user-1"}, func(tx pgx.Tx) error {
		var err error
		first, err = ensureComplimentaryProPeriod(ctx, tx, "team-1", before)
		if err != nil {
			return err
		}
		repeated, err := ensureComplimentaryProPeriod(ctx, tx, "team-1", before.Add(-time.Hour))
		if err != nil || repeated.ID != first.ID {
			return errors.New("same month must reuse the existing allowance")
		}
		next, err := ensureComplimentaryProPeriod(ctx, tx, "team-1", before.Add(time.Second))
		if err != nil {
			return err
		}
		if first.ID == next.ID || !first.EndsAt.Equal(next.StartsAt) || *next.AllowanceSeconds != 360000 {
			return errors.New("month boundary must grant a new Pro allowance")
		}
		return nil
	})
	if err != nil {
		t.Fatal(err)
	}
	if first.StartsAt != time.Date(2039, 12, 1, 0, 0, 0, 0, time.UTC) || first.EndsAt != time.Date(2040, 1, 1, 0, 0, 0, 0, time.UTC) {
		t.Fatalf("period must use UTC calendar months: %+v", first)
	}
	var periods int
	if err := pool.QueryRow(ctx, `SELECT count(*) FROM billing_periods WHERE team_id = 'team-1'`).Scan(&periods); err != nil || periods != 2 {
		t.Fatalf("both immutable periods must remain: count=%d, err=%v", periods, err)
	}
	testutil.ExecSQL(t, ctx, pool, `UPDATE billing_periods SET allowance_seconds = 1 WHERE id = $1`, first.ID)
	err = withBillingMemberLock(ctx, pool, billingMember{TeamID: "team-1", UserID: "user-1"}, func(tx pgx.Tx) error {
		_, err := ensureComplimentaryProPeriod(ctx, tx, "team-1", before)
		return err
	})
	if err == nil {
		t.Fatal("a conflicting stored allowance must fail instead of being reset")
	}
}

func TestComplimentaryProRequiresMembershipAndDoesNotCreateStripeObjects(t *testing.T) {
	ctx, pool := testutil.NewStripeStateDB(t)
	service := &Service{pool: pool, config: billingconfig.Config{ComplimentaryProTeamIDs: []string{"team-1"}}}
	for _, member := range []billingMember{{TeamID: "team-1", UserID: "outsider"}, {TeamID: "team-1"}, {TeamID: "missing", UserID: "user-1"}} {
		if status, err := service.status(ctx, member); status != nil || !errors.Is(err, errBillingForbidden) {
			t.Fatalf("grant must not bypass membership: %+v, %v", status, err)
		}
	}
	for _, userID := range []string{"user-1", "user-2"} {
		status, err := service.status(ctx, billingMember{TeamID: "team-1", UserID: userID})
		if err != nil || status.PlanID == nil || *status.PlanID != "pro" || !status.CanStartCI || status.CanCheckout || status.CanManageBilling || status.PaidUntil != nil {
			t.Fatalf("members must see Pro without a Stripe payment or purchase action: %+v, %v", status, err)
		}
	}
	status, err := service.status(ctx, billingMember{TeamID: "team-2", UserID: "outsider"})
	if err != nil || status.CanStartCI || !status.CanCheckout || status.BlockReason != "payment_required" {
		t.Fatalf("unlisted unpaid team must remain blocked: %+v, %v", status, err)
	}
	var stripeRecords int
	if err := pool.QueryRow(ctx, `SELECT (SELECT count(*) FROM billing_stripe_state) + (SELECT count(*) FROM billing_customer_creations) + (SELECT count(*) FROM billing_checkout_creations)`).Scan(&stripeRecords); err != nil || stripeRecords != 0 {
		t.Fatal("complimentary access must not fabricate Stripe records")
	}
}

func TestComplimentaryProBlocksCheckoutBeforeStripe(t *testing.T) {
	_, pool := testutil.NewStripeStateDB(t)
	config := &billingconfig.Config{InternalToken: strings.Repeat("x", 32), ComplimentaryProTeamIDs: []string{"team-1"}}
	mux := http.NewServeMux()
	RegisterRoutes(mux, pool, nil, config)
	for _, userID := range []string{"outsider", "user-1"} {
		response := billingHTTPRequest(mux, *config, http.MethodPost, "/internal/billing/teams/team-1/checkout", `{"planId":"pro"}`, userID)
		if userID == "outsider" && response.Code != http.StatusForbidden {
			t.Fatal("membership must be checked before revealing grant status")
		}
		if userID == "user-1" && (response.Code != http.StatusConflict || !strings.Contains(response.Body.String(), "complimentary_pro")) {
			t.Fatalf("complimentary team must not purchase another plan: %d %s", response.Code, response.Body)
		}
	}
}

func TestComplimentaryProMetersExecutionAcrossMonthBoundary(t *testing.T) {
	ctx, pool := testutil.NewStripeStateDB(t)
	service := &Service{pool: pool, config: billingconfig.Config{ComplimentaryProTeamIDs: []string{"team-1"}}}
	boundary := time.Date(2040, 1, 1, 0, 0, 0, 0, time.UTC)
	err := withBillingMemberLock(ctx, pool, billingMember{TeamID: "team-1", UserID: "user-1"}, func(tx pgx.Tx) error {
		previous, err := ensureComplimentaryProPeriod(ctx, tx, "team-1", boundary.Add(-time.Hour))
		if err != nil {
			return err
		}
		_, err = tx.Exec(ctx, `
			INSERT INTO billing_executions
				(run_id, team_id, job_id, worker_host, period_id, started_at_ms, observed_at_ms, lease_until_ms, finished_at_ms, outcome)
			VALUES ('run', 'team-1', 'job', 'worker', $1, $2, $3, $3, $3, 'success')
		`, previous.ID, boundary.Add(-time.Hour).UnixMilli(), boundary.Add(30*time.Minute).UnixMilli())
		if err != nil {
			return err
		}
		_, available, err := service.availableClaimBudget(ctx, tx, "team-1", boundary.Add(time.Hour))
		if err != nil {
			return err
		}
		if available != (6000-30)*60000 {
			return errors.New("the new month must include its 30 minutes of overlapping execution")
		}
		return nil
	})
	if err != nil {
		t.Fatal(err)
	}
}
