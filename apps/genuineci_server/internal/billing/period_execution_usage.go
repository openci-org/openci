package billing

import (
	"context"
	"errors"
	"time"

	"github.com/jackc/pgx/v5"
)

type periodExecutionUsageQuery struct {
	TeamID   string
	PeriodID string
	At       time.Time
}

type periodExecutionUsage struct {
	AllowanceSeconds      int64
	MeasuredMillis        int64
	LeasedMillis          int64
	MeasurementIncomplete bool
}

func getPeriodExecutionUsage(ctx context.Context, tx pgx.Tx, request periodExecutionUsageQuery) (*periodExecutionUsage, error) {
	var result periodExecutionUsage
	err := tx.QueryRow(ctx, `
		SELECT p.allowance_seconds,
			COALESCE(sum(GREATEST(0,
				LEAST(e.observed_at_ms, p.ends_at * 1000) - GREATEST(e.started_at_ms, p.starts_at * 1000)
			)) FILTER (WHERE e.run_id IS NOT NULL), 0)::bigint,
			COALESCE(sum(GREATEST(0,
				LEAST(e.lease_until_ms, p.ends_at * 1000) - GREATEST(e.observed_at_ms, p.starts_at * 1000)
			)) FILTER (WHERE e.finished_at_ms IS NULL AND e.lease_until_ms > $3), 0)::bigint,
			COALESCE(bool_or(e.measurement_incomplete OR
				(e.finished_at_ms IS NULL AND e.lease_until_ms <= $3)), false)
		FROM billing_periods p
		LEFT JOIN billing_executions e ON e.team_id = p.team_id
			AND e.started_at_ms < p.ends_at * 1000
			AND (COALESCE(e.finished_at_ms, e.lease_until_ms) > p.starts_at * 1000
				OR e.started_at_ms >= p.starts_at * 1000)
		WHERE p.id = $1 AND p.team_id = $2 AND p.period_type = 'paid'
			AND p.allowance_seconds IS NOT NULL AND p.allowance_seconds >= 0
		GROUP BY p.id, p.allowance_seconds
	`, request.PeriodID, request.TeamID, request.At.UnixMilli()).Scan(
		&result.AllowanceSeconds, &result.MeasuredMillis, &result.LeasedMillis, &result.MeasurementIncomplete,
	)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	return &result, nil
}
