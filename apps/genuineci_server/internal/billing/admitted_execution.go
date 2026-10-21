package billing

import (
	"context"
	"errors"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"
)

var errAdmissionNotCurrent = errors.New("worker admission is not current")
var errExecutionRequest = errors.New("invalid execution request")

type workerExecutionRequest struct {
	AdmissionID string `json:"admissionId"`
	JobID       string `json:"jobId"`
	RunID       string `json:"runId"`
	WorkerHost  string `json:"workerHost"`
	Outcome     string `json:"outcome,omitempty"`
}

type executionAdmission struct {
	Identity executionIdentity
	StartBy  time.Time
	Closed   bool
	Running  bool
}

func (s *Service) startAdmittedExecution(ctx context.Context, request workerExecutionRequest) (*execution, error) {
	if request.Outcome != "" {
		return nil, errExecutionRequest
	}
	return s.withExecutionAdmission(ctx, request, func(tx pgx.Tx, admission executionAdmission) (*execution, error) {
		now := time.Now()
		stored, err := getExecution(ctx, tx, request.RunID)
		if err != nil {
			return nil, err
		}
		if stored != nil {
			return observeExecution(ctx, tx, executionObservation{Identity: admission.Identity, At: now, LeaseUntil: now.Add(time.Minute)})
		}
		if admission.Closed || !admission.Running || !now.Before(admission.StartBy) {
			return nil, errAdmissionNotCurrent
		}
		return createExecution(ctx, tx, executionStart{Identity: admission.Identity, StartedAt: now, LeaseUntil: now.Add(time.Minute)})
	})
}

func (s *Service) reportAdmittedExecution(ctx context.Context, request workerExecutionRequest) (*execution, error) {
	switch request.Outcome {
	case "", "success", "failure", "cancelled", "timed_out":
	default:
		return nil, errExecutionRequest
	}
	return s.withExecutionAdmission(ctx, request, func(tx pgx.Tx, admission executionAdmission) (*execution, error) {
		now := time.Now()
		return observeExecution(ctx, tx, executionObservation{Identity: admission.Identity, At: now, LeaseUntil: now.Add(time.Minute), Outcome: request.Outcome})
	})
}

func (s *Service) withExecutionAdmission(ctx context.Context, request workerExecutionRequest, action func(pgx.Tx, executionAdmission) (*execution, error)) (*execution, error) {
	for _, value := range []string{request.AdmissionID, request.JobID, request.RunID, request.WorkerHost} {
		if strings.TrimSpace(value) == "" || len(value) > 255 {
			return nil, errExecutionRequest
		}
	}
	ctx, cancel := context.WithTimeout(ctx, 10*time.Second)
	defer cancel()
	var result *execution
	err := pgx.BeginFunc(ctx, s.pool, func(tx pgx.Tx) error {
		var admission executionAdmission
		var teamID, host, latestRun *string
		var status string
		err := tx.QueryRow(ctx, `SELECT team_id, worker_host, latest_run_id, status FROM build_jobs WHERE id = $1 FOR UPDATE`, request.JobID).Scan(&teamID, &host, &latestRun, &status)
		if errors.Is(err, pgx.ErrNoRows) {
			return errAdmissionNotCurrent
		}
		if err != nil {
			return err
		}
		if teamID == nil || host == nil || *host != request.WorkerHost || latestRun == nil || *latestRun != request.RunID {
			return errAdmissionNotCurrent
		}
		var accountID string
		if err := tx.QueryRow(ctx, `SELECT team_id FROM billing_accounts WHERE team_id = $1 FOR UPDATE`, *teamID).Scan(&accountID); err != nil {
			return err
		}
		var startBy int64
		err = tx.QueryRow(ctx, `
			SELECT period_id, start_by_ms, closed_at_ms IS NOT NULL FROM billing_admissions
			WHERE id = $1 AND job_id = $2 AND run_id = $3 AND worker_host = $4 AND team_id = $5
				AND EXISTS (SELECT 1 FROM build_runs r WHERE r.id = $3 AND r.build_job_id = $2)
			FOR UPDATE
		`, request.AdmissionID, request.JobID, request.RunID, request.WorkerHost, *teamID).Scan(&admission.Identity.PeriodID, &startBy, &admission.Closed)
		if errors.Is(err, pgx.ErrNoRows) {
			return errAdmissionNotCurrent
		}
		if err != nil {
			return err
		}
		admission.Identity.RunID, admission.Identity.JobID = request.RunID, request.JobID
		admission.Identity.TeamID, admission.Identity.WorkerHost = *teamID, request.WorkerHost
		admission.StartBy, admission.Running = time.UnixMilli(startBy), status == "IN_PROGRESS"
		result, err = action(tx, admission)
		if err != nil {
			return err
		}
		if result.FinishedAt != nil {
			_, err = tx.Exec(ctx, `UPDATE billing_admissions SET closed_at_ms = COALESCE(closed_at_ms, GREATEST(claimed_at_ms, $2)) WHERE id = $1`, request.AdmissionID, result.FinishedAt.UnixMilli())
		}
		return err
	})
	if err != nil {
		return nil, err
	}
	return result, nil
}
