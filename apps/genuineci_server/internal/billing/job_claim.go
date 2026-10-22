package billing

import (
	"context"
	"crypto/rand"
	"errors"
	"strings"
	"time"
	"unicode"

	"github.com/jackc/pgx/v5"
)

var errWorkerClaim = errors.New("invalid worker claim request")
var errTeamNotEligible = errors.New("team has no available paid allowance")

type workerClaimRequest struct {
	WorkerHost        string  `json:"workerHost"`
	VMName            *string `json:"vmName,omitempty"`
	MaxConcurrentJobs *int    `json:"maxConcurrentJobs,omitempty"`
}

type workerClaim struct {
	JobID       string `json:"jobId"`
	AdmissionID string `json:"admissionId"`
}

func (s *Service) claimJob(ctx context.Context, request workerClaimRequest) (*workerClaim, error) {
	if request.WorkerHost == "" || len(request.WorkerHost) > 255 ||
		strings.ContainsFunc(request.WorkerHost, func(r rune) bool { return unicode.IsSpace(r) || unicode.IsControl(r) }) ||
		request.MaxConcurrentJobs != nil && *request.MaxConcurrentJobs < 1 ||
		request.VMName != nil && (strings.TrimSpace(*request.VMName) == "" || len(*request.VMName) > 255) {
		return nil, errWorkerClaim
	}
	ctx, cancel := context.WithTimeout(ctx, 10*time.Second)
	defer cancel()
	if err := s.recoverWorkerExecutions(ctx); err != nil {
		return nil, err
	}
	var result *workerClaim
	err := pgx.BeginFunc(ctx, s.pool, func(tx pgx.Tx) error {
		if request.MaxConcurrentJobs != nil {
			if _, err := tx.Exec(ctx, `SELECT pg_advisory_xact_lock(hashtext('build_job_claim'), hashtext($1))`, request.WorkerHost); err != nil {
				return err
			}
			var running int
			if err := tx.QueryRow(ctx, `SELECT count(*) FROM build_jobs WHERE status = 'IN_PROGRESS' AND worker_host = $1`, request.WorkerHost).Scan(&running); err != nil {
				return err
			}
			if running >= *request.MaxConcurrentJobs {
				return nil
			}
		}
		excludedTeams := []string{}
		for {
			var teamID string
			err := pgx.BeginFunc(ctx, tx, func(candidate pgx.Tx) error {
				var jobID string
				err := candidate.QueryRow(ctx, `
					SELECT j.id, j.team_id FROM build_jobs j
					WHERE j.status = 'QUEUED' AND j.team_id IS NOT NULL AND NOT (j.team_id = ANY($1::text[]))
						AND NOT EXISTS (SELECT 1 FROM billing_admissions a WHERE a.job_id = j.id AND a.closed_at_ms IS NULL)
					ORDER BY j.created_at, j.id LIMIT 1 FOR UPDATE OF j SKIP LOCKED
				`, excludedTeams).Scan(&jobID, &teamID)
				if errors.Is(err, pgx.ErrNoRows) {
					return nil
				}
				if err != nil {
					return err
				}
				var lockedID string
				if err := candidate.QueryRow(ctx, `SELECT id FROM teams WHERE id = $1 FOR UPDATE`, teamID).Scan(&lockedID); err != nil {
					if errors.Is(err, pgx.ErrNoRows) {
						return errTeamNotEligible
					}
					return err
				}
				if s.config.HasComplimentaryPro(teamID) {
					if _, err := candidate.Exec(ctx, `INSERT INTO billing_accounts (team_id) VALUES ($1) ON CONFLICT DO NOTHING`, teamID); err != nil {
						return err
					}
				}
				if err := candidate.QueryRow(ctx, `SELECT team_id FROM billing_accounts WHERE team_id = $1 FOR UPDATE`, teamID).Scan(&lockedID); err != nil {
					if errors.Is(err, pgx.ErrNoRows) {
						return errTeamNotEligible
					}
					return err
				}
				now := time.Now()
				periodID, available, err := s.availableClaimBudget(ctx, candidate, teamID, now)
				if err != nil {
					return err
				}
				admissionID := rand.Text()
				if _, err := candidate.Exec(ctx, `
					INSERT INTO billing_admissions
						(id, job_id, team_id, worker_host, period_id, claimed_at_ms, start_by_ms, reserved_millis)
					VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
				`, admissionID, jobID, teamID, request.WorkerHost, periodID, now.UnixMilli(),
					now.Add(2*time.Minute).UnixMilli(), min(available, int64(time.Minute/time.Millisecond))); err != nil {
					return err
				}
				if _, err := candidate.Exec(ctx, `
					UPDATE build_jobs SET status = 'IN_PROGRESS', worker_host = $2, vm_name = $3,
						updated_at = $4, latest_run_id = NULL WHERE id = $1
				`, jobID, request.WorkerHost, request.VMName, now.Unix()); err != nil {
					return err
				}
				result = &workerClaim{JobID: jobID, AdmissionID: admissionID}
				return nil
			})
			if errors.Is(err, errTeamNotEligible) {
				excludedTeams = append(excludedTeams, teamID)
				continue
			}
			return err
		}
	})
	if err != nil {
		return nil, err
	}
	return result, nil
}

func (s *Service) availableClaimBudget(ctx context.Context, tx pgx.Tx, teamID string, now time.Time) (string, int64, error) {
	var periodID string
	if s.config.HasComplimentaryPro(teamID) {
		period, err := ensureComplimentaryProPeriod(ctx, tx, teamID, now)
		if err != nil {
			return "", 0, err
		}
		periodID = period.ID
	} else {
		err := tx.QueryRow(ctx, `
		SELECT p.id FROM billing_stripe_state s
		JOIN billing_customer_creations c ON c.team_id = s.team_id AND c.stripe_customer_id = s.stripe_customer_id
		JOIN billing_periods p ON p.id = s.paid_period_id AND p.team_id = s.team_id AND p.plan_id = s.plan_id
		WHERE s.team_id = $1 AND s.livemode = $2 AND c.livemode = $2
			AND s.stripe_subscription_id IS NOT NULL AND s.stripe_subscription_id <> ''
			AND s.subscription_status IN ('active', 'past_due') AND p.period_type = 'paid'
			AND p.starts_at <= $3 AND $3 < p.ends_at
	`, teamID, s.config.Livemode, now.Unix()).Scan(&periodID)
		if errors.Is(err, pgx.ErrNoRows) {
			return "", 0, errTeamNotEligible
		}
		if err != nil {
			return "", 0, err
		}
	}
	usage, err := getPeriodExecutionUsage(ctx, tx, periodExecutionUsageQuery{TeamID: teamID, PeriodID: periodID, At: now})
	if err != nil {
		return "", 0, err
	}
	available, err := usage.availableMillis()
	if err != nil {
		return "", 0, err
	}
	if available == 0 {
		return "", 0, errTeamNotEligible
	}
	return periodID, available, nil
}
