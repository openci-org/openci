package billing

import (
	"context"
	"errors"
	"time"

	"github.com/jackc/pgx/v5"
)

var errComplimentaryPro = errors.New("team already has complimentary Pro")

func ensureComplimentaryProPeriod(ctx context.Context, tx pgx.Tx, teamID string, at time.Time) (*billingPeriod, error) {
	plan, err := getPaidBillingPlan("pro")
	if err != nil {
		return nil, err
	}
	utc := at.UTC()
	start := time.Date(utc.Year(), utc.Month(), 1, 0, 0, 0, 0, time.UTC)
	period := billingPeriod{
		ID:     "complimentary-pro:" + teamID + ":" + start.Format("2006-01"),
		TeamID: teamID, PlanID: "pro", PeriodType: "paid",
		StartsAt: start, EndsAt: start.AddDate(0, 1, 0), AllowanceSeconds: &plan.AllowanceSeconds,
	}
	if _, err := insertBillingPeriod(ctx, tx, period); err != nil {
		return nil, err
	}
	var matches bool
	err = tx.QueryRow(ctx, `
		SELECT team_id = $2 AND plan_id = 'pro' AND period_type = 'paid'
			AND starts_at = $3 AND ends_at = $4 AND COALESCE(allowance_seconds = $5, false)
		FROM billing_periods WHERE id = $1
	`, period.ID, teamID, start.Unix(), period.EndsAt.Unix(), plan.AllowanceSeconds).Scan(&matches)
	if err != nil {
		return nil, err
	}
	if !matches {
		return nil, errors.New("complimentary Pro period does not match the monthly allowance")
	}
	return &period, nil
}

func (s *Service) complimentaryProStatus(ctx context.Context, member billingMember) (*billingStatus, error) {
	planID := "pro"
	result := &billingStatus{BillingEnabled: true, PlanID: &planID, CanStartCI: true}
	err := withBillingMemberLock(ctx, s.pool, member, func(tx pgx.Tx) error {
		now := time.Now()
		period, err := ensureComplimentaryProPeriod(ctx, tx, member.TeamID, now)
		if err != nil {
			return err
		}
		usage, err := getPeriodExecutionUsage(ctx, tx, periodExecutionUsageQuery{TeamID: member.TeamID, PeriodID: period.ID, At: now})
		if err != nil {
			return err
		}
		available, err := usage.availableMillis()
		if err != nil {
			return err
		}
		if available == 0 {
			result.CanStartCI, result.BlockReason = false, "allowance_exhausted"
		}
		return nil
	})
	if err != nil {
		return nil, err
	}
	return result, nil
}
