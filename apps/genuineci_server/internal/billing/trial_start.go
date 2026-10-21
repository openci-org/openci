package billing

import (
	"context"
	"errors"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type trialStart struct {
	PeriodID         string
	UserID           string
	TeamID           string
	StartsAt         time.Time
	AllowanceSeconds *int64
}

func startTrial(ctx context.Context, pool *pgxpool.Pool, input trialStart) (bool, error) {
	period := newTrialBillingPeriod(input.PeriodID, input.TeamID, input.StartsAt, input.AllowanceSeconds)
	started := false
	err := withBillingAccountLock(ctx, pool, input.TeamID, func(tx pgx.Tx, _ *billingAccount) error {
		claimed, err := createTrialClaim(ctx, tx, trialClaim{
			UserID:    input.UserID,
			TeamID:    input.TeamID,
			ClaimedAt: period.StartsAt,
		})
		if err != nil || !claimed {
			return err
		}
		created, err := insertBillingPeriod(ctx, tx, period)
		if err != nil {
			return err
		}
		if !created {
			return errors.New("billing period ID already exists")
		}
		started = true
		return nil
	})
	if err != nil {
		return false, err
	}
	return started, nil
}
