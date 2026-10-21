package billing

import (
	"context"
	"errors"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

var errBillingForbidden = errors.New("billing requires a current team member")

type billingMember struct {
	TeamID string
	UserID string
}

func withBillingMemberLock(ctx context.Context, pool *pgxpool.Pool, member billingMember, action func(pgx.Tx) error) error {
	if member.UserID == "" || member.TeamID == "" {
		return errBillingForbidden
	}
	return pgx.BeginFunc(ctx, pool, func(tx pgx.Tx) error {
		var id string
		if err := tx.QueryRow(ctx, "SELECT id FROM teams WHERE id = $1 FOR UPDATE", member.TeamID).Scan(&id); err != nil {
			if errors.Is(err, pgx.ErrNoRows) {
				return errBillingForbidden
			}
			return err
		}
		if _, err := tx.Exec(ctx, "INSERT INTO billing_accounts (team_id) VALUES ($1) ON CONFLICT DO NOTHING", member.TeamID); err != nil {
			return err
		}
		if err := tx.QueryRow(ctx, "SELECT team_id FROM billing_accounts WHERE team_id = $1 FOR UPDATE", member.TeamID).Scan(&id); err != nil {
			return err
		}
		if err := tx.QueryRow(ctx, `
			SELECT user_id FROM team_members WHERE team_id = $1 AND user_id = $2 FOR KEY SHARE
		`, member.TeamID, member.UserID).Scan(&id); err != nil {
			if errors.Is(err, pgx.ErrNoRows) {
				return errBillingForbidden
			}
			return err
		}
		return action(tx)
	})
}

func authorizeBillingMember(ctx context.Context, pool *pgxpool.Pool, member billingMember) error {
	return withBillingMemberLock(ctx, pool, member, func(pgx.Tx) error { return nil })
}
