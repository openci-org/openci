package billing

import (
	"context"
	"crypto/rand"
	"errors"
	"os"
	"testing"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
	billingschema "github.com/openci-org/openci/apps/genuineci_server/internal/billing/schema"
	"github.com/openci-org/openci/apps/genuineci_server/internal/testutil"
)

func TestCreateTrialClaim(t *testing.T) {
	ctx, pool := newTrialClaimTestDB(t, "team-1")
	claim := trialClaim{
		UserID:    "user-1",
		TeamID:    "team-1",
		ClaimedAt: time.Date(2040, 10, 1, 9, 0, 0, 123456789, time.FixedZone("JST", 9*60*60)),
	}

	created, err := commitTrialClaim(ctx, pool, claim)

	if err != nil || !created {
		t.Fatalf("want a new claim: created=%v, err=%v", created, err)
	}
	assertOnlyTrialClaim(t, ctx, pool, claim)
}

func TestCreateTrialClaimDuplicate(t *testing.T) {
	for _, tc := range []struct {
		name, userID, teamID string
	}{
		{"same user and team", "user-1", "team-1"},
		{"same user in another team", "user-1", "team-2"},
		{"another user in the same team", "user-2", "team-1"},
	} {
		t.Run(tc.name, func(t *testing.T) {
			ctx, pool := newTrialClaimTestDB(t, "team-1", "team-2")
			original := trialClaim{UserID: "user-1", TeamID: "team-1", ClaimedAt: time.Unix(1000, 0)}
			if created, err := commitTrialClaim(ctx, pool, original); err != nil || !created {
				t.Fatalf("seed original claim: created=%v, err=%v", created, err)
			}
			duplicate := trialClaim{
				UserID:    tc.userID,
				TeamID:    tc.teamID,
				ClaimedAt: original.ClaimedAt.Add(24 * time.Hour),
			}

			created, err := commitTrialClaim(ctx, pool, duplicate)

			if err != nil || created {
				t.Fatalf("must reject duplicate claim: created=%v, err=%v", created, err)
			}
			assertOnlyTrialClaim(t, ctx, pool, original)

			// A rejected attempt must leave the unused user and team eligible.
			unused := trialClaim{UserID: "user-2", TeamID: "team-2", ClaimedAt: original.ClaimedAt}
			if created, err := commitTrialClaim(ctx, pool, unused); err != nil || !created {
				t.Fatalf("rejected claim must not consume user-2 or team-2: created=%v, err=%v", created, err)
			}
		})
	}
}

func TestCreateTrialClaimRollback(t *testing.T) {
	ctx, pool := newTrialClaimTestDB(t, "team-1")
	claim := trialClaim{UserID: "user-1", TeamID: "team-1", ClaimedAt: time.Unix(1000, 0)}
	abort := errors.New("abort after claim creation")

	err := pgx.BeginFunc(ctx, pool, func(tx pgx.Tx) error {
		created, err := createTrialClaim(ctx, tx, claim)
		if err != nil {
			return err
		}
		if !created {
			return errors.New("expected a new claim")
		}
		return abort
	})

	if !errors.Is(err, abort) {
		t.Fatalf("want rollback error, got %v", err)
	}
	if created, err := commitTrialClaim(ctx, pool, claim); err != nil || !created {
		t.Fatalf("must allow retry after rollback: created=%v, err=%v", created, err)
	}
	assertOnlyTrialClaim(t, ctx, pool, claim)
}

func TestCreateTrialClaimConcurrent(t *testing.T) {
	for _, tc := range []struct {
		name, userID, teamID string
	}{
		{"same user", "user-1", "team-2"},
		{"same team", "user-2", "team-1"},
	} {
		t.Run(tc.name, func(t *testing.T) {
			ctx, pool := newTrialClaimTestDB(t, "team-1", "team-2")
			original := trialClaim{UserID: "user-1", TeamID: "team-1", ClaimedAt: time.Unix(1000, 0)}
			tx, err := pool.Begin(ctx)
			if err != nil {
				t.Fatal(err)
			}
			defer tx.Rollback(ctx)
			if created, err := createTrialClaim(ctx, tx, original); err != nil || !created {
				t.Fatalf("want first claim: created=%v, err=%v", created, err)
			}
			type result struct {
				created bool
				err     error
			}
			results := make(chan result, 1)

			go func() {
				competing := trialClaim{
					UserID:    tc.userID,
					TeamID:    tc.teamID,
					ClaimedAt: original.ClaimedAt.Add(time.Hour),
				}
				created, err := commitTrialClaim(ctx, pool, competing)
				results <- result{created, err}
			}()
			testutil.WaitForLocks(t, ctx, pool, 1)
			if err := tx.Commit(ctx); err != nil {
				t.Fatal(err)
			}

			if got := <-results; got.err != nil || got.created {
				t.Fatalf("must reject the competing claim: created=%v, err=%v", got.created, got.err)
			}
			assertOnlyTrialClaim(t, ctx, pool, original)
		})
	}
}

func TestCreateTrialClaimMissingAccount(t *testing.T) {
	ctx, pool := newTrialClaimTestDB(t)
	claim := trialClaim{UserID: "user-1", TeamID: "missing", ClaimedAt: time.Unix(1000, 0)}

	created, err := commitTrialClaim(ctx, pool, claim)

	var pgErr *pgconn.PgError
	if created || !errors.As(err, &pgErr) || pgErr.Code != "23503" {
		t.Fatalf("must propagate foreign key error: created=%v, err=%v", created, err)
	}
	var count int
	if err := pool.QueryRow(ctx, "SELECT count(*) FROM billing_trial_claims").Scan(&count); err != nil || count != 0 {
		t.Fatalf("failed claim must leave no rows: count=%d, err=%v", count, err)
	}
}

func newTrialClaimTestDB(t *testing.T, teamIDs ...string) (context.Context, *pgxpool.Pool) {
	t.Helper()
	databaseURL := os.Getenv("OPENCI_TEST_DATABASE_URL")
	if databaseURL == "" {
		t.Skip("Set OPENCI_TEST_DATABASE_URL to run PostgreSQL tests")
	}
	ctx, cancel := context.WithTimeout(t.Context(), 15*time.Second)
	t.Cleanup(cancel)
	config, err := pgxpool.ParseConfig(databaseURL)
	if err != nil {
		t.Fatal(err)
	}
	schema := pgx.Identifier{"billing_claim_create_" + rand.Text()}.Sanitize()
	config.MaxConns = 4
	config.ConnConfig.RuntimeParams["search_path"] = schema
	config.ConnConfig.RuntimeParams["application_name"] = schema
	pool, err := pgxpool.NewWithConfig(ctx, config)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(pool.Close)
	if _, err := pool.Exec(ctx, "CREATE SCHEMA "+schema); err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() {
		cancel()
		cleanup, stop := context.WithTimeout(context.Background(), 5*time.Second)
		defer stop()
		if _, err := pool.Exec(cleanup, "DROP SCHEMA "+schema+" CASCADE"); err != nil {
			t.Error(err)
		}
	})
	if _, err := pool.Exec(ctx, "CREATE TABLE billing_accounts (team_id text PRIMARY KEY)"); err != nil {
		t.Fatal(err)
	}
	for _, teamID := range teamIDs {
		if _, err := pool.Exec(ctx, "INSERT INTO billing_accounts (team_id) VALUES ($1)", teamID); err != nil {
			t.Fatal(err)
		}
	}
	if err := billingschema.EnsureTrialClaimsTable(ctx, pool); err != nil {
		t.Fatal(err)
	}
	return ctx, pool
}

func commitTrialClaim(ctx context.Context, pool *pgxpool.Pool, claim trialClaim) (bool, error) {
	var created bool
	err := pgx.BeginFunc(ctx, pool, func(tx pgx.Tx) error {
		var err error
		created, err = createTrialClaim(ctx, tx, claim)
		return err
	})
	return created, err
}

func assertOnlyTrialClaim(t *testing.T, ctx context.Context, pool *pgxpool.Pool, want trialClaim) {
	t.Helper()
	var count int
	if err := pool.QueryRow(ctx, "SELECT count(*) FROM billing_trial_claims").Scan(&count); err != nil || count != 1 {
		t.Fatalf("want exactly one claim: count=%d, err=%v", count, err)
	}
	var userID, teamID string
	var timestamp int64
	err := pool.QueryRow(ctx, "SELECT user_id, team_id, claimed_at FROM billing_trial_claims").Scan(&userID, &teamID, &timestamp)
	if err != nil || userID != want.UserID || teamID != want.TeamID || timestamp != want.ClaimedAt.Unix() {
		t.Fatalf("want claim %+v, got user=%q, team=%q, timestamp=%d, err=%v", want, userID, teamID, timestamp, err)
	}
}
