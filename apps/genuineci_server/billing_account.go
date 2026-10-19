package main

import (
	"context"
	"errors"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type billingAccount struct {
	TeamID string
}

func getBillingAccount(ctx context.Context, pool *pgxpool.Pool, teamID string) (*billingAccount, error) {
	var account billingAccount
	err := pool.QueryRow(ctx,
		"SELECT team_id FROM billing_accounts WHERE team_id = $1", teamID,
	).Scan(&account.TeamID)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	return &account, nil
}
