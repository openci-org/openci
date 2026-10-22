package billing

import (
	"context"
	"errors"
	"time"

	"github.com/jackc/pgx/v5"
)

type billingStatus struct {
	BillingEnabled    bool       `json:"billingEnabled"`
	PlanID            *string    `json:"planId"`
	CanStartCI        bool       `json:"canStartCi"`
	BlockReason       string     `json:"blockReason"`
	PaidUntil         *time.Time `json:"paidUntil"`
	CanCheckout       bool       `json:"canCheckout"`
	CanManageBilling  bool       `json:"canManageBilling"`
	CancelAtPeriodEnd bool       `json:"cancelAtPeriodEnd"`
}

func (s *Service) status(ctx context.Context, member billingMember) (*billingStatus, error) {
	if member.UserID == "" || member.TeamID == "" {
		return nil, errBillingForbidden
	}
	if s.config.hasComplimentaryPro(member.TeamID) {
		return s.complimentaryProStatus(ctx, member)
	}
	tx, err := s.pool.BeginTx(ctx, pgx.TxOptions{IsoLevel: pgx.RepeatableRead, AccessMode: pgx.ReadOnly})
	if err != nil {
		return nil, err
	}
	defer tx.Rollback(ctx)
	result := &billingStatus{BillingEnabled: true, BlockReason: "payment_required"}
	var subscriptionStatus string
	var compatibleMode, checkoutPending bool
	var startsAt, endsAt *int64
	var periodID *string
	err = tx.QueryRow(ctx, `
		SELECT COALESCE(s.subscription_status, 'none'), s.plan_id, p.starts_at, p.ends_at,
			c.stripe_customer_id IS NOT NULL, COALESCE(s.cancel_at_period_end, false),
			COALESCE(c.livemode = $3, true) AND COALESCE(s.livemode = $3, true),
			EXISTS (SELECT 1 FROM billing_checkout_creations x WHERE x.team_id = t.id AND x.closed_at IS NULL), p.id
		FROM teams t JOIN team_members m ON m.team_id = t.id AND m.user_id = $2
		LEFT JOIN billing_customer_creations c ON c.team_id = t.id
		LEFT JOIN billing_stripe_state s ON s.team_id = t.id
		LEFT JOIN billing_periods p ON p.id = s.paid_period_id AND p.team_id = t.id AND p.period_type = 'paid'
		WHERE t.id = $1
	`, member.TeamID, member.UserID, s.config.Livemode).Scan(
		&subscriptionStatus, &result.PlanID, &startsAt, &endsAt, &result.CanManageBilling,
		&result.CancelAtPeriodEnd, &compatibleMode, &checkoutPending, &periodID,
	)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, errBillingForbidden
	}
	if err != nil {
		return nil, err
	}
	if !compatibleMode {
		return &billingStatus{BillingEnabled: true, BlockReason: "billing_unavailable"}, nil
	}
	if endsAt != nil {
		until := time.Unix(*endsAt, 0).UTC()
		result.PaidUntil = &until
	}
	result.CanCheckout = subscriptionStatus == "none" || subscriptionStatus == "canceled" || subscriptionStatus == "incomplete_expired"
	now := time.Now()
	paidNow := startsAt != nil && endsAt != nil && *startsAt <= now.Unix() && now.Unix() < *endsAt
	result.CanStartCI = paidNow && (subscriptionStatus == "active" || subscriptionStatus == "past_due")
	switch {
	case result.CanStartCI:
		result.BlockReason = ""
	case subscriptionStatus == "unverified":
		result.BlockReason = "billing_unavailable"
	case subscriptionStatus == "canceled" || subscriptionStatus == "incomplete_expired":
		result.BlockReason = "subscription_ended"
	case subscriptionStatus == "incomplete" || subscriptionStatus == "none" && checkoutPending:
		result.BlockReason = "payment_pending"
	}
	if result.CanStartCI && periodID != nil {
		usage, err := getPeriodExecutionUsage(ctx, tx, periodExecutionUsageQuery{TeamID: member.TeamID, PeriodID: *periodID, At: now})
		if err != nil {
			return nil, err
		}
		available, err := usage.availableMillis()
		if err != nil {
			result.CanStartCI, result.BlockReason = false, "billing_unavailable"
		} else if available == 0 {
			result.CanStartCI, result.BlockReason = false, "allowance_exhausted"
		}
	}
	if err := tx.Commit(ctx); err != nil {
		return nil, err
	}
	return result, nil
}
