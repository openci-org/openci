package billing

import (
	"context"
	"time"

	"github.com/jackc/pgx/v5"
)

type trialClaim struct {
	UserID    string
	TeamID    string
	ClaimedAt time.Time
}

func createTrialClaim(ctx context.Context, tx pgx.Tx, claim trialClaim) (bool, error) {
	result, err := tx.Exec(ctx, `
		INSERT INTO billing_trial_claims (user_id, team_id, claimed_at)
		VALUES ($1, $2, $3)
		ON CONFLICT DO NOTHING
	`, claim.UserID, claim.TeamID, claim.ClaimedAt.Unix())
	if err != nil {
		return false, err
	}
	return result.RowsAffected() == 1, nil
}
