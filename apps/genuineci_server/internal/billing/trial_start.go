package billing

import (
	"context"
	"crypto/rand"
	"errors"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
	billingconfig "github.com/openci-org/openci/apps/genuineci_server/internal/billing/config"
)

var ErrNotTeamMember = errors.New("trial start requires a current team member")

type TrialStartRequest struct {
	TeamID string
	UserID string
}

func StartTrial(ctx context.Context, pool *pgxpool.Pool, request TrialStartRequest) (bool, error) {
	return startTrial(ctx, pool, trialStart{
		PeriodID: rand.Text(),
		UserID:   request.UserID,
		TeamID:   request.TeamID,
	})
}

type trialStart struct {
	PeriodID string
	// UserID must come from verified authentication at the API boundary.
	UserID string
	TeamID string
	// A zero StartsAt selects the current time after acquiring the account lock.
	StartsAt time.Time
}

func startTrial(ctx context.Context, pool *pgxpool.Pool, input trialStart) (bool, error) {
	enabled, err := billingconfig.Enabled()
	if err != nil || !enabled {
		return false, err
	}
	allowanceSeconds, err := billingconfig.TrialAllowanceSeconds()
	if err != nil {
		return false, err
	}
	if input.UserID == "" {
		return false, ErrNotTeamMember
	}

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
			return ErrNotTeamMember
		}
		startsAt := input.StartsAt
		if startsAt.IsZero() {
			startsAt = time.Now()
		}
		period := newTrialBillingPeriod(input.PeriodID, input.TeamID, startsAt, allowanceSeconds)
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
