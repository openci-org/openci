package billing

import (
	"context"
	"errors"
	"reflect"
	"testing"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/openci-org/openci/apps/genuineci_server/internal/testutil"
)

func TestEnsureCheckoutCreationPersistsIntent(t *testing.T) {
	ctx, pool := testutil.NewCheckoutCreationDB(t)
	var previousKey string
	for _, teamID := range []string{"team-1", "team-2"} {
		request := checkoutCreationTestRequest()
		request.TeamID = teamID
		request.CustomerID = "cus_" + teamID
		request.Livemode = teamID == "team-2"
		before := time.Now().UTC().Truncate(time.Second)

		got, err := ensureCheckoutCreation(ctx, pool, request)

		if err != nil || got == nil {
			t.Fatalf("want a saved intent: got=%+v, err=%v", got, err)
		}
		if got.Request != request || got.StripeCheckoutSessionID != nil {
			t.Fatalf("must persist the original parameters without a Session: got=%+v", got)
		}
		if got.IdempotencyKey == "" || got.IdempotencyKey == previousKey {
			t.Fatal("each intent must receive a distinct nonempty key")
		}
		if got.CreatedAt.Before(before) || got.CreatedAt.After(time.Now()) || got.CreatedAt.Nanosecond() != 0 {
			t.Fatalf("want the current time in Unix seconds, got %v", got.CreatedAt)
		}
		stored := readCheckoutCreation(t, ctx, pool, got.IdempotencyKey)
		if !reflect.DeepEqual(got, stored) {
			t.Fatalf("intent must be committed before returning: got=%+v, stored=%+v", got, stored)
		}
		previousKey = got.IdempotencyKey
	}
	assertCheckoutCreationCount(t, ctx, pool, 2)
}

func TestEnsureCheckoutCreationReusesOriginalParameters(t *testing.T) {
	for _, sessionID := range []string{"", "cs_recorded"} {
		t.Run("Session="+sessionID, func(t *testing.T) {
			ctx, pool := testutil.NewCheckoutCreationDB(t)
			request := checkoutCreationTestRequest()
			original, err := ensureCheckoutCreation(ctx, pool, request)
			if err != nil {
				t.Fatal(err)
			}
			testutil.ExecSQL(t, ctx, pool, `
				UPDATE billing_checkout_creations SET created_at = 1000, stripe_checkout_session_id = NULLIF($1, '')
			`, sessionID)
			want := readCheckoutCreation(t, ctx, pool, original.IdempotencyKey)
			pool.Reset()
			request.PriceID = "price_reconfigured"
			request.SuccessURL = "https://new.example.com/billing?success"
			request.CancelURL = "https://new.example.com/billing?cancel"

			got, err := ensureCheckoutCreation(ctx, pool, request)

			if err != nil || !reflect.DeepEqual(got, want) {
				t.Fatalf("must reuse the original key, time, and parameters after reconnect: want=%+v, got=%+v, err=%v", want, got, err)
			}
			assertCheckoutCreationCount(t, ctx, pool, 1)
			if stored := readCheckoutCreation(t, ctx, pool, want.IdempotencyKey); !reflect.DeepEqual(stored, want) {
				t.Fatalf("must preserve the original intent: want=%+v, got=%+v", want, stored)
			}
		})
	}
}

func TestEnsureCheckoutCreationRejectsPurchaseChanges(t *testing.T) {
	for _, tc := range []struct {
		name   string
		change func(*checkoutCreationRequest)
	}{
		{"plan", func(r *checkoutCreationRequest) { r.PlanID = "pro" }},
		{"Customer", func(r *checkoutCreationRequest) { r.CustomerID = "cus_other" }},
		{"mode", func(r *checkoutCreationRequest) { r.Livemode = true }},
	} {
		t.Run(tc.name, func(t *testing.T) {
			ctx, pool := testutil.NewCheckoutCreationDB(t)
			request := checkoutCreationTestRequest()
			if _, err := ensureCheckoutCreation(ctx, pool, request); err != nil {
				t.Fatal(err)
			}
			want := testutil.CheckoutCreationRecords(t, ctx, pool)
			tc.change(&request)

			got, err := ensureCheckoutCreation(ctx, pool, request)

			if got != nil || !errors.Is(err, errCheckoutCreationConflict) {
				t.Fatalf("purchase changes must return a conflict without an intent: got=%+v, err=%v", got, err)
			}
			if stored := testutil.CheckoutCreationRecords(t, ctx, pool); stored != want {
				t.Fatalf("conflict must leave the unfinished intent unchanged: want=%s, got=%s", want, stored)
			}
		})
	}
}

func TestEnsureCheckoutCreationAfterClosedIntent(t *testing.T) {
	ctx, pool := testutil.NewCheckoutCreationDB(t)
	request := checkoutCreationTestRequest()
	original, err := ensureCheckoutCreation(ctx, pool, request)
	if err != nil {
		t.Fatal(err)
	}
	testutil.ExecSQL(t, ctx, pool, `
		UPDATE billing_checkout_creations SET closed_at = 1800000100, stripe_checkout_session_id = 'cs_closed'
	`)
	want := readCheckoutCreation(t, ctx, pool, original.IdempotencyKey)
	request.PlanID, request.PriceID = "pro", "price_pro"

	got, err := ensureCheckoutCreation(ctx, pool, request)

	if err != nil || got == nil || got.IdempotencyKey == original.IdempotencyKey || got.Request != request || got.StripeCheckoutSessionID != nil {
		t.Fatalf("want a new intent with its own key: got=%+v, err=%v", got, err)
	}
	assertCheckoutCreationCount(t, ctx, pool, 2)
	if stored := readCheckoutCreation(t, ctx, pool, original.IdempotencyKey); !reflect.DeepEqual(stored, want) {
		t.Fatalf("must retain the closed intent: want=%+v, got=%+v", want, stored)
	}
}

func TestEnsureCheckoutCreationRequiresLiveBillingAccount(t *testing.T) {
	for _, tc := range []struct{ name, sql string }{
		{"deleted team", "DELETE FROM teams WHERE id = 'team-1'"},
		{"uninitialized account", "DELETE FROM billing_accounts WHERE team_id = 'team-1'"},
	} {
		t.Run(tc.name, func(t *testing.T) {
			ctx, pool := testutil.NewCheckoutCreationDB(t)
			testutil.ExecSQL(t, ctx, pool, tc.sql)

			got, err := ensureCheckoutCreation(ctx, pool, checkoutCreationTestRequest())

			if got != nil || !errors.Is(err, pgx.ErrNoRows) {
				t.Fatalf("must require a current team and billing account: got=%+v, err=%v", got, err)
			}
			assertCheckoutCreationCount(t, ctx, pool, 0)
		})
	}
}

func TestEnsureCheckoutCreationConcurrent(t *testing.T) {
	for _, planID := range []string{"light", "pro"} {
		t.Run("competing plan="+planID, func(t *testing.T) {
			ctx, pool := testutil.NewCheckoutCreationDB(t)
			blocker, err := pool.Begin(ctx)
			if err != nil {
				t.Fatal(err)
			}
			defer blocker.Rollback(ctx)
			if _, err := blocker.Exec(ctx, "SELECT team_id FROM billing_accounts WHERE team_id = 'team-1' FOR UPDATE"); err != nil {
				t.Fatal(err)
			}
			type result struct {
				creation *checkoutCreation
				err      error
			}
			results := make(chan result, 2)
			for _, plan := range []string{"light", planID} {
				request := checkoutCreationTestRequest()
				request.PlanID, request.PriceID = plan, "price_"+plan
				go func() {
					creation, err := ensureCheckoutCreation(ctx, pool, request)
					results <- result{creation, err}
				}()
			}
			testutil.WaitForLocks(t, ctx, pool, 2)
			if err := blocker.Commit(ctx); err != nil {
				t.Fatal(err)
			}
			var first *checkoutCreation
			conflicts := 0
			for range 2 {
				got := <-results
				if got.creation == nil && errors.Is(got.err, errCheckoutCreationConflict) {
					conflicts++
					continue
				}
				if got.err != nil || got.creation == nil {
					t.Fatalf("unexpected concurrent result: got=%+v, err=%v", got.creation, got.err)
				}
				if first != nil && !reflect.DeepEqual(got.creation, first) {
					t.Fatalf("same-plan calls must return the same intent: first=%+v, other=%+v", first, got.creation)
				}
				first = got.creation
			}
			wantConflicts := 0
			if planID == "pro" {
				wantConflicts = 1
			}
			if first == nil || conflicts != wantConflicts {
				t.Fatalf("want one saved intent and %d conflicts, got %d conflicts", wantConflicts, conflicts)
			}
			assertCheckoutCreationCount(t, ctx, pool, 1)
			if stored := readCheckoutCreation(t, ctx, pool, first.IdempotencyKey); !reflect.DeepEqual(stored, first) {
				t.Fatalf("successful callers must use the committed intent: got=%+v, stored=%+v", first, stored)
			}
		})
	}
}

func TestEnsureCheckoutCreationCommitFailure(t *testing.T) {
	ctx, pool := testutil.NewCheckoutCreationDB(t)
	testutil.ExecSQL(t, ctx, pool, `
		CREATE TABLE allowed_checkout_keys (key text PRIMARY KEY);
		ALTER TABLE billing_checkout_creations ADD CONSTRAINT reject_key_at_commit
			FOREIGN KEY (idempotency_key) REFERENCES allowed_checkout_keys(key)
			DEFERRABLE INITIALLY DEFERRED
	`)

	got, err := ensureCheckoutCreation(ctx, pool, checkoutCreationTestRequest())

	var pgErr *pgconn.PgError
	if got != nil || !errors.As(err, &pgErr) || pgErr.Code != "23503" {
		t.Fatalf("failed commit must return no usable intent: got=%+v, err=%v", got, err)
	}
	assertCheckoutCreationCount(t, ctx, pool, 0)
	testutil.ExecSQL(t, ctx, pool, "ALTER TABLE billing_checkout_creations DROP CONSTRAINT reject_key_at_commit")
	if got, err := ensureCheckoutCreation(ctx, pool, checkoutCreationTestRequest()); err != nil || got == nil {
		t.Fatalf("must allow retry after rollback: got=%+v, err=%v", got, err)
	}
}

func TestEnsureCheckoutCreationCanceled(t *testing.T) {
	ctx, pool := testutil.NewCheckoutCreationDB(t)
	canceled, cancel := context.WithCancel(ctx)
	cancel()

	got, err := ensureCheckoutCreation(canceled, pool, checkoutCreationTestRequest())

	if got != nil || !errors.Is(err, context.Canceled) {
		t.Fatalf("canceled operation must return no intent: got=%+v, err=%v", got, err)
	}
	assertCheckoutCreationCount(t, ctx, pool, 0)
}

func TestEnsureCheckoutCreationRejectsInvalidInput(t *testing.T) {
	for _, tc := range []struct {
		name   string
		change func(*checkoutCreationRequest)
	}{
		{"unknown plan", func(r *checkoutCreationRequest) { r.PlanID = "starter" }},
		{"missing plan", func(r *checkoutCreationRequest) { r.PlanID = "" }},
		{"blank team", func(r *checkoutCreationRequest) { r.TeamID = " \t" }},
		{"missing Customer", func(r *checkoutCreationRequest) { r.CustomerID = "" }},
		{"blank Price", func(r *checkoutCreationRequest) { r.PriceID = " \t" }},
		{"missing success URL", func(r *checkoutCreationRequest) { r.SuccessURL = "" }},
		{"blank cancel URL", func(r *checkoutCreationRequest) { r.CancelURL = " \t" }},
	} {
		t.Run(tc.name, func(t *testing.T) {
			request := checkoutCreationTestRequest()
			tc.change(&request)

			got, err := ensureCheckoutCreation(t.Context(), nil, request)

			if got != nil || err == nil {
				t.Fatal("invalid input must be rejected before accessing the database")
			}
		})
	}
}

func checkoutCreationTestRequest() checkoutCreationRequest {
	return checkoutCreationRequest{
		TeamID: "team-1", PlanID: "light", CustomerID: "cus_team-1", PriceID: "price_light",
		SuccessURL: "https://app.example.com/billing?checkout=success&session_id={CHECKOUT_SESSION_ID}",
		CancelURL:  "https://app.example.com/billing?checkout=cancel",
	}
}

func readCheckoutCreation(t *testing.T, ctx context.Context, pool *pgxpool.Pool, key string) *checkoutCreation {
	t.Helper()
	var creation checkoutCreation
	var createdAt int64
	err := pool.QueryRow(ctx, `
		SELECT team_id, plan_id, stripe_customer_id, stripe_price_id, success_url, cancel_url,
			livemode, idempotency_key, created_at, stripe_checkout_session_id
		FROM billing_checkout_creations WHERE idempotency_key = $1
	`, key).Scan(
		&creation.Request.TeamID, &creation.Request.PlanID, &creation.Request.CustomerID,
		&creation.Request.PriceID, &creation.Request.SuccessURL, &creation.Request.CancelURL,
		&creation.Request.Livemode, &creation.IdempotencyKey, &createdAt, &creation.StripeCheckoutSessionID,
	)
	if err != nil {
		t.Fatal(err)
	}
	creation.CreatedAt = time.Unix(createdAt, 0).UTC()
	return &creation
}

func assertCheckoutCreationCount(t *testing.T, ctx context.Context, pool *pgxpool.Pool, want int) {
	t.Helper()
	var count int
	if err := pool.QueryRow(ctx, "SELECT count(*) FROM billing_checkout_creations").Scan(&count); err != nil || count != want {
		t.Fatalf("want %d intents, got count=%d, err=%v", want, count, err)
	}
}
