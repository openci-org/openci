package billing

import (
	"context"
	"errors"
	"time"

	"github.com/jackc/pgx/v5"
)

type executionObservation struct {
	Identity   executionIdentity
	At         time.Time
	LeaseUntil time.Time
	Outcome    string
}

func observeExecution(ctx context.Context, tx pgx.Tx, request executionObservation) (*execution, error) {
	switch request.Outcome {
	case "", "success", "failure", "cancelled", "timed_out":
	default:
		return nil, errors.New("unsupported execution outcome")
	}
	stored, err := getExecution(ctx, tx, request.Identity.RunID)
	if err != nil {
		return nil, err
	}
	if stored == nil || stored.Identity != request.Identity {
		return nil, errExecutionIdentity
	}
	if stored.FinishedAt != nil {
		return stored, nil
	}
	at := request.At.UnixMilli()
	if at < stored.StartedAt.UnixMilli() {
		return nil, errors.New("execution observation precedes its start")
	}
	if request.Outcome == "" && at <= stored.ObservedAt.UnixMilli() {
		return stored, nil
	}
	lease := stored.LeaseUntil.UnixMilli()
	var finished *int64
	var outcome *string
	incomplete := at >= lease
	if incomplete {
		at = stored.ObservedAt.UnixMilli()
		finished = &at
		value := "abandoned"
		outcome = &value
	} else if request.Outcome != "" {
		at = max(at, stored.ObservedAt.UnixMilli())
		finished, outcome = &at, &request.Outcome
	} else {
		if request.LeaseUntil.UnixMilli() <= at {
			return nil, errors.New("execution lease must end after its observation")
		}
		lease = max(lease, request.LeaseUntil.UnixMilli())
	}
	_, err = tx.Exec(ctx, `
		UPDATE billing_executions SET observed_at_ms = $2, lease_until_ms = $3,
			finished_at_ms = $4, outcome = $5, measurement_incomplete = $6
		WHERE run_id = $1
	`, request.Identity.RunID, at, lease, finished, outcome, incomplete)
	if err != nil {
		return nil, err
	}
	return getExecution(ctx, tx, request.Identity.RunID)
}

func expireExecutions(ctx context.Context, tx pgx.Tx, at time.Time) (int64, error) {
	result, err := tx.Exec(ctx, `
		WITH expired AS (
			SELECT run_id FROM billing_executions
			WHERE finished_at_ms IS NULL AND lease_until_ms <= $1
			ORDER BY lease_until_ms LIMIT 100 FOR UPDATE SKIP LOCKED
		)
		UPDATE billing_executions e SET finished_at_ms = observed_at_ms,
			outcome = 'abandoned', measurement_incomplete = true
		FROM expired WHERE e.run_id = expired.run_id
	`, at.UnixMilli())
	return result.RowsAffected(), err
}
