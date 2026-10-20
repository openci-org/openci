package billing

import (
	"context"
	"errors"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type billingPeriod struct {
	ID               string
	TeamID           string
	PlanID           string
	PeriodType       string
	StartsAt         time.Time
	EndsAt           time.Time
	AllowanceSeconds *int64
}

func getBillingPeriod(ctx context.Context, pool *pgxpool.Pool, teamID, periodID string) (*billingPeriod, error) {
	var period billingPeriod
	var startsAt, endsAt int64
	err := pool.QueryRow(ctx, `
		SELECT id, team_id, plan_id, period_type, starts_at, ends_at, allowance_seconds
		FROM billing_periods WHERE team_id = $1 AND id = $2
	`, teamID, periodID).Scan(
		&period.ID, &period.TeamID, &period.PlanID, &period.PeriodType,
		&startsAt, &endsAt, &period.AllowanceSeconds,
	)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	period.StartsAt = time.Unix(startsAt, 0).UTC()
	period.EndsAt = time.Unix(endsAt, 0).UTC()
	return &period, nil
}

func createBillingPeriod(ctx context.Context, tx pgx.Tx, period billingPeriod) error {
	result, err := tx.Exec(ctx, `
		INSERT INTO billing_periods
			(id, team_id, plan_id, period_type, starts_at, ends_at, allowance_seconds)
		VALUES ($1, $2, $3, $4, $5, $6, $7)
		ON CONFLICT (id) DO NOTHING
	`, period.ID, period.TeamID, period.PlanID, period.PeriodType,
		period.StartsAt.Unix(), period.EndsAt.Unix(), period.AllowanceSeconds)
	if err != nil {
		return err
	}
	if result.RowsAffected() == 0 {
		var teamID string
		if err := tx.QueryRow(ctx,
			"SELECT team_id FROM billing_periods WHERE id = $1", period.ID,
		).Scan(&teamID); err != nil {
			return err
		}
		if teamID != period.TeamID {
			return errors.New("billing period ID belongs to another team")
		}
	}
	return nil
}
