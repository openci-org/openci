package billing

import (
	"context"
	"errors"
	"fmt"
	"net/http"
	"testing"
	"time"

	"github.com/jackc/pgx/v5/pgconn"
	"github.com/openci-org/openci/apps/genuineci_server/internal/testutil"
)

func TestEnsureStripeCustomer(t *testing.T) {
	for _, tc := range []struct {
		name     string
		livemode bool
	}{
		{"test mode", false},
		{"live mode", true},
	} {
		t.Run(tc.name, func(t *testing.T) {
			ctx, pool := newCustomerCreationTestDB(t)
			input := stripeCustomerRequest{TeamID: "team-1", Livemode: tc.livemode}
			requests := 0
			var intent customerCreation
			client := testutil.NewStripeClient(t, func(request *http.Request) (*http.Response, error) {
				requests++
				intent = *readCustomerCreation(t, ctx, pool, input.TeamID)
				if request.Method != http.MethodPost || request.URL.Path != "/v1/customers" ||
					request.Header.Get("Idempotency-Key") != intent.IdempotencyKey {
					t.Error("must create a Customer using the committed intent's key")
				}
				if err := request.ParseForm(); err != nil || request.PostForm.Get("metadata[team_id]") != intent.TeamID {
					t.Errorf("must send the stored team identity: err=%v", err)
				}
				if _, err := pool.Exec(ctx, "SELECT team_id FROM billing_accounts WHERE team_id = 'team-1' FOR UPDATE NOWAIT"); err != nil {
					t.Fatalf("the account lock must be released before calling Stripe: %v", err)
				}
				body := fmt.Sprintf(`{"id":"cus_team1","object":"customer","metadata":{"team_id":"team-1"},"livemode":%t}`, tc.livemode)
				return testutil.StripeResponse(http.StatusOK, body), nil
			})

			id, err := ensureStripeCustomer(ctx, pool, client, input)

			if err != nil || id != "cus_team1" {
				t.Fatalf("want a saved Customer ID: id=%q, err=%v", id, err)
			}
			intent.StripeCustomerID = &id
			assertStoredCustomerCreation(t, ctx, pool, intent)
			pool.Reset()
			if again, err := ensureStripeCustomer(ctx, pool, client, input); err != nil || again != id {
				t.Fatalf("must reuse the saved Customer after reconnect: id=%q, err=%v", again, err)
			}
			if requests != 1 {
				t.Fatalf("a recorded Customer must not require another Stripe request, got %d requests", requests)
			}
		})
	}
}

func TestEnsureStripeCustomerRetriesLostResponse(t *testing.T) {
	ctx, pool := newCustomerCreationTestDB(t)
	input := stripeCustomerRequest{TeamID: "team-1"}
	requests := 0
	var originalKey string
	client := testutil.NewStripeClient(t, func(request *http.Request) (*http.Response, error) {
		requests++
		key := request.Header.Get("Idempotency-Key")
		if requests == 1 {
			originalKey = key
			return nil, errors.New("connection closed after Customer creation")
		}
		if key != originalKey || key == "" {
			t.Error("a lost response must not cause a new creation key")
		}
		return testutil.StripeResponse(http.StatusOK, `{"id":"cus_team1","metadata":{"team_id":"team-1"}}`), nil
	})

	id, err := ensureStripeCustomer(ctx, pool, client, input)
	if id != "" || err == nil || err.Error() != "Stripe Customer creation failed" {
		t.Fatalf("uncertain outcome must return no ID and a sanitized error: id=%q, err=%v", id, err)
	}
	intent := *readCustomerCreation(t, ctx, pool, input.TeamID)
	if intent.StripeCustomerID != nil || intent.IdempotencyKey != originalKey {
		t.Fatal("the original pending intent must survive a lost response")
	}
	pool.Reset()

	id, err = ensureStripeCustomer(ctx, pool, client, input)

	if err != nil || id != "cus_team1" || requests != 2 {
		t.Fatalf("retry must recover the same Customer: id=%q, requests=%d, err=%v", id, requests, err)
	}
	intent.StripeCustomerID = &id
	assertStoredCustomerCreation(t, ctx, pool, intent)
}

func TestEnsureStripeCustomerRetriesFailedResultCommit(t *testing.T) {
	ctx, pool := newCustomerCreationTestDB(t)
	testutil.ExecSQL(t, ctx, pool, `
		CREATE TABLE allowed_customers (id text PRIMARY KEY);
		ALTER TABLE billing_customer_creations ADD CONSTRAINT reject_result_at_commit
			FOREIGN KEY (stripe_customer_id) REFERENCES allowed_customers(id)
			DEFERRABLE INITIALLY DEFERRED
	`)
	input := stripeCustomerRequest{TeamID: "team-1"}
	var keys []string
	client := testutil.NewStripeClient(t, func(request *http.Request) (*http.Response, error) {
		keys = append(keys, request.Header.Get("Idempotency-Key"))
		return testutil.StripeResponse(http.StatusOK, `{"id":"cus_team1","metadata":{"team_id":"team-1"}}`), nil
	})

	id, err := ensureStripeCustomer(ctx, pool, client, input)

	var pgErr *pgconn.PgError
	if id != "" || !errors.As(err, &pgErr) || pgErr.Code != "23503" {
		t.Fatalf("failed result commit must return no Customer ID: id=%q, err=%v", id, err)
	}
	intent := *readCustomerCreation(t, ctx, pool, input.TeamID)
	if intent.StripeCustomerID != nil {
		t.Fatal("failed result commit must leave the intent pending")
	}
	testutil.ExecSQL(t, ctx, pool, "ALTER TABLE billing_customer_creations DROP CONSTRAINT reject_result_at_commit")

	id, err = ensureStripeCustomer(ctx, pool, client, input)

	if err != nil || id != "cus_team1" || len(keys) != 2 || keys[0] != intent.IdempotencyKey || keys[1] != keys[0] {
		t.Fatalf("retry must reuse the original intent: id=%q, keys=%v, err=%v", id, keys, err)
	}
	intent.StripeCustomerID = &id
	assertStoredCustomerCreation(t, ctx, pool, intent)
}

func TestEnsureStripeCustomerRequiresCommittedIntent(t *testing.T) {
	ctx, pool := newCustomerCreationTestDB(t)
	testutil.ExecSQL(t, ctx, pool, `
		CREATE TABLE allowed_keys (key text PRIMARY KEY);
		ALTER TABLE billing_customer_creations ADD CONSTRAINT reject_intent_at_commit
			FOREIGN KEY (idempotency_key) REFERENCES allowed_keys(key)
			DEFERRABLE INITIALLY DEFERRED
	`)
	client := testutil.NewStripeClient(t, func(*http.Request) (*http.Response, error) {
		t.Error("Stripe must not be called before the intent commits")
		return nil, errors.New("unexpected request")
	})

	id, err := ensureStripeCustomer(ctx, pool, client, stripeCustomerRequest{TeamID: "team-1"})

	var pgErr *pgconn.PgError
	if id != "" || !errors.As(err, &pgErr) || pgErr.Code != "23503" {
		t.Fatalf("want the intent commit failure: id=%q, err=%v", id, err)
	}
	assertNoCustomerCreations(t, ctx, pool)
}

func TestEnsureStripeCustomerRejectsInvalidResult(t *testing.T) {
	ctx, pool := newCustomerCreationTestDB(t)
	client := testutil.NewStripeClient(t, func(*http.Request) (*http.Response, error) {
		return testutil.StripeResponse(http.StatusOK, `{"id":"cus_another","metadata":{"team_id":"another-team"}}`), nil
	})

	id, err := ensureStripeCustomer(ctx, pool, client, stripeCustomerRequest{TeamID: "team-1"})

	if id != "" || err == nil {
		t.Fatalf("must not return an unverified Customer: id=%q, err=%v", id, err)
	}
	if intent := readCustomerCreation(t, ctx, pool, "team-1"); intent.StripeCustomerID != nil {
		t.Fatal("invalid Customer must not be recorded")
	}
}

func TestEnsureStripeCustomerRequiresConfiguration(t *testing.T) {
	for _, tc := range []struct {
		name, mode, enabled string
		missingClient       bool
	}{
		{"Self-hosted", "self_hosted", "invalid", false},
		{"disabled Cloud", "cloud", "false", false},
		{"invalid configuration", "cloud", "invalid", false},
		{"missing client", "cloud", "true", true},
	} {
		t.Run(tc.name, func(t *testing.T) {
			client := testutil.NewStripeClient(t, func(*http.Request) (*http.Response, error) {
				t.Error("invalid configuration must not call Stripe")
				return nil, errors.New("unexpected request")
			})
			t.Setenv("SERVER_ACCESS_MODE", tc.mode)
			t.Setenv("BILLING_ENABLED", tc.enabled)
			if tc.missingClient {
				client = nil
			}

			id, err := ensureStripeCustomer(t.Context(), nil, client, stripeCustomerRequest{TeamID: "team-1"})

			if id != "" || err == nil {
				t.Fatalf("configuration must be checked before accessing the DB: id=%q, err=%v", id, err)
			}
		})
	}
}

func TestEnsureStripeCustomerRequiresReconciliation(t *testing.T) {
	for _, tc := range []struct {
		name         string
		offset       time.Duration
		wantRequests int
	}{
		{"at retry boundary", -23 * time.Hour, 1},
		{"past Stripe retention", -25 * time.Hour, 1},
		{"future timestamp", time.Hour, 0},
	} {
		t.Run(tc.name, func(t *testing.T) {
			ctx, pool, intent := newCustomerCreationResultTestDB(t, false)
			intent.CreatedAt = time.Now().UTC().Truncate(time.Second).Add(tc.offset)
			if _, err := pool.Exec(ctx, "UPDATE billing_customer_creations SET created_at = $1", intent.CreatedAt.Unix()); err != nil {
				t.Fatal(err)
			}
			requests := 0
			client := testutil.NewStripeClient(t, func(request *http.Request) (*http.Response, error) {
				requests++
				if request.Method != http.MethodGet || request.URL.Path != "/v1/customers/search" {
					t.Error("an expired intent must only search for an existing Customer")
				}
				return testutil.StripeResponse(http.StatusOK, `{"data":[],"has_more":false}`), nil
			})

			id, err := ensureStripeCustomer(ctx, pool, client, stripeCustomerRequest{TeamID: intent.TeamID})

			if id != "" || !errors.Is(err, errStripeCustomerReconciliationRequired) {
				t.Fatalf("want reconciliation without a Customer ID: id=%q, err=%v", id, err)
			}
			if requests != tc.wantRequests {
				t.Fatalf("want %d Stripe requests, got %d", tc.wantRequests, requests)
			}
			assertStoredCustomerCreation(t, ctx, pool, intent)
		})
	}
}

func TestEnsureStripeCustomerReusesOldRecordedCustomer(t *testing.T) {
	ctx, pool := newCustomerCreationTestDB(t)
	testutil.ExecSQL(t, ctx, pool, `
		INSERT INTO billing_customer_creations VALUES ('team-1', 'old-key', false, 1000, 'cus_team1')
	`)
	client := testutil.NewStripeClient(t, func(*http.Request) (*http.Response, error) {
		t.Error("recorded Customers must be reused regardless of intent age")
		return nil, errors.New("unexpected request")
	})

	id, err := ensureStripeCustomer(ctx, pool, client, stripeCustomerRequest{TeamID: "team-1"})

	if err != nil || id != "cus_team1" {
		t.Fatalf("want the recorded Customer: id=%q, err=%v", id, err)
	}
}

func TestEnsureStripeCustomerCapsRequestAtRetryBoundary(t *testing.T) {
	ctx, pool, intent := newCustomerCreationResultTestDB(t, false)
	intent.CreatedAt = time.Now().UTC().Truncate(time.Second).Add(-23*time.Hour + 5*time.Second)
	if _, err := pool.Exec(ctx, "UPDATE billing_customer_creations SET created_at = $1", intent.CreatedAt.Unix()); err != nil {
		t.Fatal(err)
	}
	wantDeadline := intent.CreatedAt.Add(23 * time.Hour)
	client := testutil.NewStripeClient(t, func(request *http.Request) (*http.Response, error) {
		if deadline, ok := request.Context().Deadline(); !ok || !deadline.Equal(wantDeadline) {
			t.Errorf("request must end at the retry boundary: want=%v, got=%v", wantDeadline, deadline)
		}
		return testutil.StripeResponse(http.StatusOK, `{"id":"cus_team1","metadata":{"team_id":"team-1"}}`), nil
	})

	id, err := ensureStripeCustomer(ctx, pool, client, stripeCustomerRequest{TeamID: intent.TeamID})

	if err != nil || id != "cus_team1" {
		t.Fatalf("an intent still within the window must succeed: id=%q, err=%v", id, err)
	}
}

func TestEnsureStripeCustomerConcurrent(t *testing.T) {
	ctx, pool := newCustomerCreationTestDB(t)
	ctx, cancel := context.WithCancel(ctx)
	defer cancel()
	requests := make(chan string, 2)
	releaseResponses := make(chan struct{})
	client := testutil.NewStripeClient(t, func(request *http.Request) (*http.Response, error) {
		requests <- request.Header.Get("Idempotency-Key")
		select {
		case <-releaseResponses:
			return testutil.StripeResponse(http.StatusOK, `{"id":"cus_team1","metadata":{"team_id":"team-1"}}`), nil
		case <-request.Context().Done():
			return nil, request.Context().Err()
		}
	})
	type result struct {
		id  string
		err error
	}
	results := make(chan result, 2)
	for range 2 {
		go func() {
			id, err := ensureStripeCustomer(ctx, pool, client, stripeCustomerRequest{TeamID: "team-1"})
			results <- result{id, err}
		}()
	}
	var key string
	for range 2 {
		select {
		case got := <-requests:
			if got == "" || (key != "" && got != key) {
				t.Fatal("concurrent requests must send the same persisted key")
			}
			key = got
		case <-ctx.Done():
			t.Fatal("both requests must reach Stripe without holding the account lock")
		}
	}
	close(releaseResponses)
	for range 2 {
		got := <-results
		if got.err != nil || got.id != "cus_team1" {
			t.Fatalf("both callers must reuse the same Customer: id=%q, err=%v", got.id, got.err)
		}
	}
	intent := readCustomerCreation(t, ctx, pool, "team-1")
	if intent.IdempotencyKey != key || intent.StripeCustomerID == nil || *intent.StripeCustomerID != "cus_team1" {
		t.Fatal("concurrent callers must preserve one intent and Customer link")
	}
}

func TestEnsureStripeCustomerCanceledDuringRequest(t *testing.T) {
	ctx, pool := newCustomerCreationTestDB(t)
	requestCtx, cancel := context.WithCancel(ctx)
	defer cancel()
	client := testutil.NewStripeClient(t, func(request *http.Request) (*http.Response, error) {
		cancel()
		return nil, request.Context().Err()
	})

	id, err := ensureStripeCustomer(requestCtx, pool, client, stripeCustomerRequest{TeamID: "team-1"})

	if id != "" || !errors.Is(err, context.Canceled) {
		t.Fatalf("want cancellation without a Customer ID: id=%q, err=%v", id, err)
	}
	if intent := readCustomerCreation(t, ctx, pool, "team-1"); intent.StripeCustomerID != nil {
		t.Fatal("cancellation must leave the committed intent pending")
	}
}
