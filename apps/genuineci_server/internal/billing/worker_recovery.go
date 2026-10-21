package billing

import (
	"context"
	"errors"
	"time"

	"github.com/jackc/pgx/v5"
)

func (s *Service) recoverWorkerExecutions(ctx context.Context) error {
	if err := pgx.BeginFunc(ctx, s.pool, func(tx pgx.Tx) error {
		_, err := expireExecutions(ctx, tx, time.Now())
		return err
	}); err != nil {
		return err
	}
	rows, err := s.pool.Query(ctx, `
		SELECT a.id, a.job_id FROM billing_admissions a
		LEFT JOIN billing_executions e ON e.run_id = a.run_id
		WHERE a.closed_at_ms IS NULL AND
			(e.finished_at_ms IS NOT NULL OR (e.run_id IS NULL AND a.start_by_ms <= $1))
		ORDER BY a.start_by_ms, a.id LIMIT 100
	`, time.Now().UnixMilli())
	if err != nil {
		return err
	}
	type candidate struct{ admissionID, jobID string }
	candidates, err := pgx.CollectRows(rows, func(row pgx.CollectableRow) (candidate, error) {
		var result candidate
		err := row.Scan(&result.admissionID, &result.jobID)
		return result, err
	})
	if err != nil {
		return err
	}
	for _, candidate := range candidates {
		if err := pgx.BeginFunc(ctx, s.pool, func(tx pgx.Tx) error {
			return recoverWorkerAdmission(ctx, tx, candidate.admissionID, candidate.jobID)
		}); err != nil {
			return err
		}
	}
	return nil
}

func recoverWorkerAdmission(ctx context.Context, tx pgx.Tx, admissionID, jobID string) error {
	var locked string
	err := tx.QueryRow(ctx, `SELECT id FROM build_jobs WHERE id = $1 FOR UPDATE SKIP LOCKED`, jobID).Scan(&locked)
	if errors.Is(err, pgx.ErrNoRows) {
		var exists bool
		if err := tx.QueryRow(ctx, `SELECT EXISTS (SELECT 1 FROM build_jobs WHERE id = $1)`, jobID).Scan(&exists); err != nil {
			return err
		}
		if exists {
			return nil
		}
	} else if err != nil {
		return err
	}
	var teamID string
	err = tx.QueryRow(ctx, `
		SELECT b.team_id FROM billing_accounts b JOIN billing_admissions a ON a.team_id = b.team_id
		WHERE a.id = $1 AND a.closed_at_ms IS NULL FOR UPDATE OF b SKIP LOCKED
	`, admissionID).Scan(&teamID)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil
	}
	if err != nil {
		return err
	}
	var runID *string
	var workerHost string
	var startBy int64
	err = tx.QueryRow(ctx, `
		SELECT run_id, worker_host, start_by_ms FROM billing_admissions
		WHERE id = $1 AND job_id = $2 AND closed_at_ms IS NULL FOR UPDATE
	`, admissionID, jobID).Scan(&runID, &workerHost, &startBy)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil
	}
	if err != nil {
		return err
	}
	var started, finished bool
	if err := tx.QueryRow(ctx, `
		SELECT EXISTS (SELECT 1 FROM billing_executions WHERE run_id = $1),
			EXISTS (SELECT 1 FROM billing_executions WHERE run_id = $1 AND finished_at_ms IS NOT NULL)
	`, runID).Scan(&started, &finished); err != nil {
		return err
	}
	now := time.Now()
	if started && !finished || !started && now.UnixMilli() < startBy {
		return nil
	}
	if !started {
		if _, err := tx.Exec(ctx, `
			UPDATE build_jobs SET status = 'QUEUED', latest_run_id = NULL,
				worker_host = NULL, vm_name = NULL, updated_at = $5
			WHERE id = $1 AND team_id = $2 AND worker_host = $3 AND status = 'IN_PROGRESS'
				AND latest_run_id IS NOT DISTINCT FROM $4::text
		`, jobID, teamID, workerHost, runID, now.Unix()); err != nil {
			return err
		}
		if runID != nil {
			if _, err := tx.Exec(ctx, `
				UPDATE build_runs SET status = 'completed', conclusion = 'failure', updated_at = $3
				WHERE id = $1 AND build_job_id = $2 AND status = 'in_progress'
			`, *runID, jobID, now.Unix()); err != nil {
				return err
			}
		}
	}
	_, err = tx.Exec(ctx, `
		UPDATE billing_admissions SET closed_at_ms = GREATEST(claimed_at_ms, $2)
		WHERE id = $1 AND closed_at_ms IS NULL
	`, admissionID, now.UnixMilli())
	return err
}
