package billing

import (
	"context"
	"errors"
	"math"
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
	ReservedMillis        int64
	MeasurementIncomplete bool
}

func (usage *periodExecutionUsage) availableMillis() (int64, error) {
	if usage == nil || usage.AllowanceSeconds < 0 || usage.AllowanceSeconds > math.MaxInt64/1000 {
		return 0, errors.New("paid period allowance is unavailable")
	}
	available := usage.AllowanceSeconds * 1000
	for _, used := range []int64{usage.MeasuredMillis, usage.LeasedMillis, usage.ReservedMillis} {
		available -= min(available, used)
	}
	return available, nil
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
				(e.finished_at_ms IS NULL AND e.lease_until_ms <= $3)), false),
			COALESCE((
				SELECT sum(a.reserved_millis) FROM billing_admissions a
				WHERE a.team_id = p.team_id AND a.closed_at_ms IS NULL
					AND $3 < p.ends_at * 1000
					AND a.start_by_ms > $3 AND a.start_by_ms > p.starts_at * 1000
					AND a.claimed_at_ms < p.ends_at * 1000
					AND NOT EXISTS (SELECT 1 FROM billing_executions started WHERE started.run_id = a.run_id)
			), 0)::bigint
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
		&result.ReservedMillis,
	)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	return &result, nil
}
