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

func ensureBillingAccount(ctx context.Context, pool *pgxpool.Pool, teamID string) (*billingAccount, error) {
	var account billingAccount
	err := pgx.BeginFunc(ctx, pool, func(tx pgx.Tx) error {
		if err := tx.QueryRow(ctx,
			"SELECT id FROM teams WHERE id = $1 FOR UPDATE", teamID,
		).Scan(&account.TeamID); err != nil {
			return err
		}
		_, err := tx.Exec(ctx,
			"INSERT INTO billing_accounts (team_id) VALUES ($1) ON CONFLICT (team_id) DO NOTHING",
			teamID,
		)
		return err
	})
	if err != nil {
		return nil, err
	}
	return &account, nil
}

func withBillingAccountLock(ctx context.Context, pool *pgxpool.Pool, teamID string, action func(pgx.Tx, *billingAccount) error) error {
	return pgx.BeginFunc(ctx, pool, func(tx pgx.Tx) error {
		var account billingAccount
		if err := tx.QueryRow(ctx,
			"SELECT id FROM teams WHERE id = $1 FOR UPDATE", teamID,
		).Scan(&account.TeamID); err != nil {
			return err
		}
		if err := tx.QueryRow(ctx,
			"SELECT team_id FROM billing_accounts WHERE team_id = $1 FOR UPDATE", teamID,
		).Scan(&account.TeamID); err != nil {
			return err
		}
		return action(tx, &account)
	})
}
