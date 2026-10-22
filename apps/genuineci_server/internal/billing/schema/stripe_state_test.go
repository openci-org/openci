package schema_test

import (
	"errors"
	"testing"

	"github.com/jackc/pgx/v5/pgconn"
	billingschema "github.com/openci-org/openci/apps/genuineci_server/internal/billing/schema"
	"github.com/openci-org/openci/apps/genuineci_server/internal/testutil"
)

func TestStripeStateSchemaPreservesStateAndProcessedEvents(t *testing.T) {
	ctx, pool := testutil.NewStripeStateDB(t)
	testutil.ExecSQL(t, ctx, pool, `
		INSERT INTO billing_stripe_state
			(team_id, stripe_customer_id, livemode, stripe_subscription_id, subscription_status, synced_at)
		VALUES ('team-1', 'cus_team', false, 'sub_team', 'active', 100);
		INSERT INTO billing_stripe_events VALUES ('evt_paid', 'invoice.paid', 90, 100)
	`)
	if err := billingschema.EnsureStripeStateTables(ctx, pool); err != nil {
		t.Fatal(err)
	}
	var records int
	if err := pool.QueryRow(ctx, `
		SELECT (SELECT count(*) FROM billing_stripe_state WHERE stripe_subscription_id = 'sub_team') +
		       (SELECT count(*) FROM billing_stripe_events WHERE event_id = 'evt_paid')
	`).Scan(&records); err != nil || records != 2 {
		t.Fatal("schema reinitialization must preserve state and delivery deduplication")
	}
	for _, sql := range []string{
		"INSERT INTO billing_stripe_events VALUES ('evt_paid', 'invoice.paid', 90, 101)",
		"INSERT INTO billing_stripe_state (team_id, stripe_customer_id, livemode, stripe_subscription_id, subscription_status, synced_at) VALUES ('team-2', 'cus_team', false, 'sub_other', 'active', 101)",
		"INSERT INTO billing_stripe_state (team_id, stripe_customer_id, livemode, stripe_subscription_id, subscription_status, synced_at) VALUES ('team-2', 'cus_other', false, 'sub_team', 'active', 101)",
	} {
		_, err := pool.Exec(ctx, sql)
		var pgErr *pgconn.PgError
		if !errors.As(err, &pgErr) || pgErr.Code != "23505" {
			t.Fatalf("must enforce unique external identities: %v", err)
		}
	}
}

func TestStripeStateSchemaRollsBackMissingDependency(t *testing.T) {
	ctx, pool := testutil.NewCheckoutCreationSchemaDB(t)
	if err := billingschema.EnsureStripeStateTables(ctx, pool); err == nil {
		t.Fatal("billing periods are required")
	}
	var absent bool
	if err := pool.QueryRow(ctx, "SELECT to_regclass('billing_stripe_state') IS NULL AND to_regclass('billing_stripe_events') IS NULL").Scan(&absent); err != nil || !absent {
		t.Fatal("failed migration must not leave partial tables")
	}
}
