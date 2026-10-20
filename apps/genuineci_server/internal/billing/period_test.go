package billing

import (
	"context"
	"errors"
	"os"
	"reflect"
	"testing"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

func TestGetBillingPeriod(t *testing.T) {
	databaseURL := os.Getenv("OPENCI_TEST_DATABASE_URL")
	if databaseURL == "" {
		t.Skip("Set OPENCI_TEST_DATABASE_URL to run PostgreSQL tests")
	}
	ctx, cancel := context.WithTimeout(t.Context(), 10*time.Second)
	defer cancel()
	config, err := pgxpool.ParseConfig(databaseURL)
	if err != nil {
		t.Fatal(err)
	}
	// Keep the temporary table on one connection and exclude persistent schemas.
	config.MaxConns = 1
	config.ConnConfig.RuntimeParams["search_path"] = "pg_temp"
	pool, err := pgxpool.NewWithConfig(ctx, config)
	if err != nil {
		t.Fatal(err)
	}
	defer pool.Close()
	_, err = pool.Exec(ctx, `
		CREATE TEMP TABLE billing_periods (
			id text PRIMARY KEY, team_id text NOT NULL,
			plan_id text NOT NULL, period_type text NOT NULL,
			starts_at bigint NOT NULL, ends_at bigint NOT NULL,
			allowance_seconds bigint
		)
	`)
	if err != nil {
		t.Fatal(err)
	}
	startsAt := time.Date(2040, 10, 1, 0, 0, 0, 0, time.UTC)
	endsAt := startsAt.Add(7 * 24 * time.Hour)
	_, err = pool.Exec(ctx, `
		INSERT INTO billing_periods VALUES
			('trial-1', 'team-1', 'pro', 'trial', $1, $2, NULL),
			('paid-1', 'team-1', 'light', 'paid', $1, $2, 36000),
			('trial-zero', 'team-2', 'pro', 'trial', $1, $2, 0)
	`, startsAt.Unix(), endsAt.Unix())
	if err != nil {
		t.Fatal(err)
	}

	allowance, zero := int64(36000), int64(0)
	for _, want := range []billingPeriod{
		{"trial-1", "team-1", "pro", "trial", startsAt, endsAt, nil},
		{"paid-1", "team-1", "light", "paid", startsAt, endsAt, &allowance},
		{"trial-zero", "team-2", "pro", "trial", startsAt, endsAt, &zero},
	} {
		t.Run(want.ID, func(t *testing.T) {
			period, err := getBillingPeriod(ctx, pool, want.TeamID, want.ID)
			if err != nil {
				t.Fatal(err)
			}
			if period == nil || !reflect.DeepEqual(*period, want) {
				t.Fatalf("want %+v, got %+v", want, period)
			}
		})
	}
	for _, tc := range []struct{ name, teamID, periodID string }{
		{"missing period", "team-1", "missing"},
		{"other team", "team-2", "trial-1"},
		{"missing team", "missing", "trial-1"},
		{"team input", "team-1' OR true --", "trial-1"},
		{"period input", "team-1", "trial-1' OR true --"},
	} {
		t.Run(tc.name, func(t *testing.T) {
			period, err := getBillingPeriod(ctx, pool, tc.teamID, tc.periodID)
			if err != nil || period != nil {
				t.Fatalf("want no period, got period=%+v, err=%v", period, err)
			}
		})
	}
	var count int
	if err := pool.QueryRow(ctx, "SELECT count(*) FROM billing_periods").Scan(&count); err != nil || count != 3 {
		t.Fatalf("reads must not create periods: count=%d, err=%v", count, err)
	}

	canceled, stop := context.WithCancel(ctx)
	stop()
	if period, err := getBillingPeriod(canceled, pool, "team-1", "trial-1"); period != nil || !errors.Is(err, context.Canceled) {
		t.Fatalf("want cancellation error, got period=%+v, err=%v", period, err)
	}
	if _, err := pool.Exec(ctx, "DROP TABLE pg_temp.billing_periods"); err != nil {
		t.Fatal(err)
	}
	if period, err := getBillingPeriod(ctx, pool, "team-1", "trial-1"); period != nil || err == nil {
		t.Fatalf("want database error, got period=%+v, err=%v", period, err)
	}
}
