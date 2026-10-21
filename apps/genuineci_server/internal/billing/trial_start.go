package billing

import (
	"context"
	"errors"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

var errNotTeamMember = errors.New("trial start requires a current team member")

type trialStart struct {
	PeriodID string
	// UserID must come from verified authentication at the API boundary.
	UserID   string
	TeamID   string
	StartsAt time.Time
}

func startTrial(ctx context.Context, pool *pgxpool.Pool, input trialStart) (bool, error) {
	enabled, err := Enabled()
	if err != nil || !enabled {
		return false, err
	}
	allowanceSeconds, err := TrialAllowanceSeconds()
	if err != nil {
		return false, err
	}
	if input.UserID == "" {
		return false, errNotTeamMember
	}

	period := newTrialBillingPeriod(input.PeriodID, input.TeamID, input.StartsAt, allowanceSeconds)
	started := false
	err = withBillingAccountLock(ctx, pool, input.TeamID, func(tx pgx.Tx, _ *billingAccount) error {
		var member bool
		err := tx.QueryRow(ctx, `
			SELECT EXISTS (
				SELECT 1 FROM team_members WHERE team_id = $1 AND user_id = $2
			)
		`, input.TeamID, input.UserID).Scan(&member)
		if err != nil {
			return err
		}
		if !member {
			return errNotTeamMember
		}
		paid, err := hasActivePaidPeriod(ctx, tx, input.TeamID, period.StartsAt)
		if err != nil || paid {
			return err
		}
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
