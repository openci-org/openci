package billing

import (
	"encoding/json"
	"errors"
	"net/http"
	"testing"
	"time"

	"github.com/stripe/stripe-go/v87"
)

func TestEnsureStripeCheckoutSession(t *testing.T) {
	ctx, pool := newCheckoutCreationTestDB(t)
	request := checkoutCreationTestRequest()
	var creation *checkoutCreation
	posts, gets := 0, 0
	client := newStripeReadTestClient(t, func(r *http.Request) (*http.Response, error) {
		if r.Method == http.MethodPost {
			posts++
			creation = readCheckoutCreation(t, ctx, pool, r.Header.Get("Idempotency-Key"))
			if creation.Request != request {
				t.Error("must commit the original request before calling Stripe")
			}
		} else {
			gets++
			if r.URL.Path != "/v1/checkout/sessions/cs_checkout" {
				t.Errorf("must retrieve the recorded Session, got %s", r.URL.Path)
			}
		}
		return stripeTestResponse(http.StatusOK, checkoutSessionResponse(t, *creation)), nil
	})

	session, err := ensureStripeCheckoutSession(ctx, pool, client, request)
	if err != nil || session == nil || session.ID != "cs_checkout" {
		t.Fatalf("want a persisted Session: session=%v, err=%v", session, err)
	}
	stored := readCheckoutCreation(t, ctx, pool, creation.IdempotencyKey)
	if stored.StripeCheckoutSessionID == nil || *stored.StripeCheckoutSessionID != session.ID {
		t.Fatal("Session must be saved before returning it")
	}
	pool.Reset()
	request.PriceID = "price_changed"
	if _, err := ensureStripeCheckoutSession(ctx, pool, client, request); err != nil {
		t.Fatal(err)
	}
	if posts != 1 || gets != 1 {
		t.Fatalf("retry must retrieve without creating another Session: posts=%d, gets=%d", posts, gets)
	}
}

func TestEnsureStripeCheckoutSessionRecoversRetry(t *testing.T) {
	for _, fail := range []string{"lost response", "failed result commit"} {
		t.Run(fail, func(t *testing.T) {
			ctx, pool := newCheckoutCreationTestDB(t)
			if fail == "failed result commit" {
				execCheckoutCreationSQL(t, ctx, pool, `
					CREATE TABLE allowed_sessions (id text PRIMARY KEY);
					ALTER TABLE billing_checkout_creations ADD CONSTRAINT reject_result
					FOREIGN KEY (stripe_checkout_session_id) REFERENCES allowed_sessions(id)
					DEFERRABLE INITIALLY DEFERRED
				`)
			}
			var key, body string
			calls := 0
			client := newStripeReadTestClient(t, func(r *http.Request) (*http.Response, error) {
				calls++
				if err := r.ParseForm(); err != nil {
					t.Fatal(err)
				}
				if calls == 1 {
					key, body = r.Header.Get("Idempotency-Key"), r.PostForm.Encode()
					if fail == "lost response" {
						return nil, errors.New("response lost after Stripe accepted the request")
					}
				} else if r.Header.Get("Idempotency-Key") != key || r.PostForm.Encode() != body {
					t.Error("retry must preserve both key and original parameters")
				}
				creation := readCheckoutCreation(t, ctx, pool, key)
				return stripeTestResponse(http.StatusOK, checkoutSessionResponse(t, *creation)), nil
			})
			request := checkoutCreationTestRequest()
			if session, err := ensureStripeCheckoutSession(ctx, pool, client, request); session != nil || err == nil {
				t.Fatal("an uncertain outcome must return no usable Session")
			}
			if stored := readCheckoutCreation(t, ctx, pool, key); stored.StripeCheckoutSessionID != nil {
				t.Fatal("failed attempt must remain pending")
			}
			if fail == "failed result commit" {
				execCheckoutCreationSQL(t, ctx, pool, "ALTER TABLE billing_checkout_creations DROP CONSTRAINT reject_result")
			}
			pool.Reset()
			request.PriceID, request.SuccessURL = "price_new", "https://new.example/success"
			if session, err := ensureStripeCheckoutSession(ctx, pool, client, request); err != nil || session == nil || session.ID != "cs_checkout" {
				t.Fatalf("retry must recover the original Session: session=%v, err=%v", session, err)
			}
		})
	}
}

func TestEnsureStripeCheckoutSessionBlocksUnsafeReplay(t *testing.T) {
	for _, offset := range []time.Duration{-24 * time.Hour, time.Hour} {
		t.Run(offset.String(), func(t *testing.T) {
			ctx, pool, creation := newCheckoutCreationResultTestDB(t, false)
			execCheckoutCreationSQL(t, ctx, pool, "UPDATE billing_checkout_creations SET created_at = $1", time.Now().Add(offset).Unix())
			client := newStripeReadTestClient(t, func(*http.Request) (*http.Response, error) {
				t.Error("unsafe intent must not be replayed")
				return nil, errors.New("unexpected request")
			})
			session, err := ensureStripeCheckoutSession(ctx, pool, client, creation.Request)
			if session != nil || !errors.Is(err, errStripeCheckoutReconciliationRequired) {
				t.Fatalf("unsafe intent must require reconciliation, got %v", err)
			}
		})
	}
}

func TestEnsureStripeCheckoutSessionRejectsWrongCreationKey(t *testing.T) {
	ctx, pool, creation := newCheckoutCreationResultTestDB(t, false)
	client := newStripeReadTestClient(t, func(*http.Request) (*http.Response, error) {
		creation.IdempotencyKey = "another-intent"
		return stripeTestResponse(http.StatusOK, checkoutSessionResponse(t, creation)), nil
	})
	if session, err := ensureStripeCheckoutSession(ctx, pool, client, creation.Request); session != nil || !errors.Is(err, errStripeCheckoutReconciliationRequired) {
		t.Fatalf("another intent's result must not be returned: %v", err)
	}
}

func TestEnsureStripeCheckoutSessionDisabled(t *testing.T) {
	t.Setenv("SERVER_ACCESS_MODE", "self_hosted")
	t.Setenv("BILLING_ENABLED", "true")
	if session, err := ensureStripeCheckoutSession(t.Context(), nil, nil, checkoutCreationRequest{}); session != nil || err == nil {
		t.Fatal("Self-hosted must not access Stripe or the database")
	}
}

func checkoutSessionResponse(t *testing.T, creation checkoutCreation) string {
	t.Helper()
	session := checkoutSessionForCreation(creation, "cs_checkout")
	session.Metadata["checkout_creation_key"] = creation.IdempotencyKey
	session.Status = stripe.CheckoutSessionStatusOpen
	session.URL = "https://checkout.stripe.com/c/pay/cs_checkout"
	session.ExpiresAt = time.Now().Add(24 * time.Hour).Unix()
	body, err := json.Marshal(session)
	if err != nil {
		t.Fatal(err)
	}
	return string(body)
}
