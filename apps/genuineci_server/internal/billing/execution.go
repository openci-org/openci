package billing

import (
	"context"
	"errors"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"
)

var errExecutionIdentity = errors.New("execution identity does not match its durable record or paid period")

type executionIdentity struct {
	RunID      string
	TeamID     string
	JobID      string
	WorkerHost string
	PeriodID   string
}

type execution struct {
	Identity              executionIdentity
	StartedAt             time.Time
	ObservedAt            time.Time
	LeaseUntil            time.Time
	FinishedAt            *time.Time
	Outcome               *string
	MeasurementIncomplete bool
}

type executionStart struct {
	Identity   executionIdentity
	StartedAt  time.Time
	LeaseUntil time.Time
}

func createExecution(ctx context.Context, tx pgx.Tx, request executionStart) (*execution, error) {
	id := request.Identity
	for _, value := range []string{id.RunID, id.TeamID, id.JobID, id.WorkerHost, id.PeriodID} {
		if strings.TrimSpace(value) == "" {
			return nil, errExecutionIdentity
		}
	}
	if request.LeaseUntil.UnixMilli() <= request.StartedAt.UnixMilli() {
		return nil, errors.New("execution lease must end after execution starts")
	}
	_, err := tx.Exec(ctx, `
		INSERT INTO billing_executions
			(run_id, team_id, job_id, worker_host, period_id, started_at_ms, observed_at_ms, lease_until_ms)
		SELECT $1, $2, $3, $4, p.id, $6, $6, $7 FROM billing_periods p
		WHERE p.id = $5 AND p.team_id = $2 AND p.period_type = 'paid' AND p.starts_at <= $8
		ON CONFLICT (run_id) DO NOTHING
	`, id.RunID, id.TeamID, id.JobID, id.WorkerHost, id.PeriodID,
		request.StartedAt.UnixMilli(), request.LeaseUntil.UnixMilli(), request.StartedAt.Unix())
	if err != nil {
		return nil, err
	}
	stored, err := getExecution(ctx, tx, id.RunID)
	if err != nil {
		return nil, err
	}
	if stored == nil || stored.Identity != id {
		return nil, errExecutionIdentity
	}
	return stored, nil
}

func getExecution(ctx context.Context, tx pgx.Tx, runID string) (*execution, error) {
	var result execution
	var start, observed, lease int64
	var finished *int64
	err := tx.QueryRow(ctx, `
		SELECT run_id, team_id, job_id, worker_host, period_id,
			started_at_ms, observed_at_ms, lease_until_ms, finished_at_ms, outcome, measurement_incomplete
		FROM billing_executions WHERE run_id = $1 FOR UPDATE
	`, runID).Scan(
		&result.Identity.RunID, &result.Identity.TeamID, &result.Identity.JobID,
		&result.Identity.WorkerHost, &result.Identity.PeriodID, &start, &observed, &lease,
		&finished, &result.Outcome, &result.MeasurementIncomplete,
	)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	result.StartedAt, result.ObservedAt, result.LeaseUntil = time.UnixMilli(start).UTC(), time.UnixMilli(observed).UTC(), time.UnixMilli(lease).UTC()
	if finished != nil {
		at := time.UnixMilli(*finished).UTC()
		result.FinishedAt = &at
	}
	return &result, nil
}
