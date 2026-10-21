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
	result := &billingStatus{BillingEnabled: true, BlockReason: "payment_required"}
	var subscriptionStatus string
	var compatibleMode, checkoutPending bool
	var startsAt, endsAt *int64
	err := s.pool.QueryRow(ctx, `
		SELECT COALESCE(s.subscription_status, 'none'), s.plan_id, p.starts_at, p.ends_at,
			c.stripe_customer_id IS NOT NULL, COALESCE(s.cancel_at_period_end, false),
			COALESCE(c.livemode = $3, true) AND COALESCE(s.livemode = $3, true),
			EXISTS (SELECT 1 FROM billing_checkout_creations x WHERE x.team_id = t.id AND x.closed_at IS NULL)
		FROM teams t JOIN team_members m ON m.team_id = t.id AND m.user_id = $2
		LEFT JOIN billing_customer_creations c ON c.team_id = t.id
		LEFT JOIN billing_stripe_state s ON s.team_id = t.id
		LEFT JOIN billing_periods p ON p.id = s.paid_period_id AND p.team_id = t.id AND p.period_type = 'paid'
		WHERE t.id = $1
	`, member.TeamID, member.UserID, s.config.Livemode).Scan(
		&subscriptionStatus, &result.PlanID, &startsAt, &endsAt, &result.CanManageBilling,
		&result.CancelAtPeriodEnd, &compatibleMode, &checkoutPending,
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
	now := time.Now().Unix()
	paidNow := startsAt != nil && endsAt != nil && *startsAt <= now && now < *endsAt
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
	return result, nil
}
