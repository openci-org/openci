package billing

import (
	"encoding/json"
	"errors"
	"net/http"
	"strings"
	"testing"
	"time"

	"github.com/openci-org/openci/apps/genuineci_server/internal/testutil"
	"github.com/stripe/stripe-go/v87"
)

func TestEnsureStripeCheckoutSessionRecoversOldIntent(t *testing.T) {
	for _, status := range []stripe.CheckoutSessionStatus{
		stripe.CheckoutSessionStatusOpen, stripe.CheckoutSessionStatusComplete, stripe.CheckoutSessionStatusExpired,
	} {
		t.Run(string(status), func(t *testing.T) {
			ctx, pool, creation := newCheckoutCreationResultTestDB(t, false)
			testutil.ExecSQL(t, ctx, pool, "UPDATE billing_checkout_creations SET created_at = $1", time.Now().Add(-48*time.Hour).Unix())
			creation = *readCheckoutCreation(t, ctx, pool, creation.IdempotencyKey)
			session := recoverableCheckoutSession(t, creation)
			session.Status = status
			if status != stripe.CheckoutSessionStatusOpen {
				session.URL = ""
			}
			client := testutil.NewStripeClient(t, func(r *http.Request) (*http.Response, error) {
				if r.Method != http.MethodGet || r.URL.Path != "/v1/checkout/sessions" ||
					r.URL.Query().Get("customer") != creation.Request.CustomerID ||
					r.URL.Query().Get("expand[0]") != "data.line_items" {
					t.Errorf("must recover through a Customer-scoped expanded read: %s %s", r.Method, r.URL)
				}
				return checkoutSessionListResponse(t, []*stripe.CheckoutSession{session}, false), nil
			})
			pool.Reset()

			got, err := ensureStripeCheckoutSession(ctx, pool, client, creation.Request)

			if err != nil || got == nil || got.ID != session.ID || got.Status != status {
				t.Fatalf("must recover the existing Session without another purchase: got=%v, err=%v", got, err)
			}
			if stored := readCheckoutCreation(t, ctx, pool, creation.IdempotencyKey); stored.StripeCheckoutSessionID == nil || *stored.StripeCheckoutSessionID != session.ID {
				t.Fatal("recovery must commit the Session ID")
			}
		})
	}
}

func TestFindStripeCheckoutSessionRejectsUncertainMatches(t *testing.T) {
	for _, tc := range []struct {
		name   string
		change func(*stripe.CheckoutSession)
	}{
		{"wrong creation key", func(s *stripe.CheckoutSession) { s.Metadata["checkout_creation_key"] = "other" }},
		{"another team", func(s *stripe.CheckoutSession) { s.Metadata["team_id"] = "other" }},
		{"another Customer", func(s *stripe.CheckoutSession) { s.Customer.ID = "cus_other" }},
		{"another mode", func(s *stripe.CheckoutSession) { s.Livemode = true }},
		{"missing line items", func(s *stripe.CheckoutSession) { s.LineItems = nil }},
		{"truncated line items", func(s *stripe.CheckoutSession) { s.LineItems.HasMore = true }},
		{"another Price", func(s *stripe.CheckoutSession) { s.LineItems.Data[0].Price.ID = "price_other" }},
		{"quantity two", func(s *stripe.CheckoutSession) { s.LineItems.Data[0].Quantity = 2 }},
		{"unknown status", func(s *stripe.CheckoutSession) { s.Status = "future_status" }},
	} {
		t.Run(tc.name, func(t *testing.T) {
			creation := checkoutCreation{Request: checkoutCreationTestRequest(), IdempotencyKey: "original-key", CreatedAt: time.Now()}
			session := recoverableCheckoutSession(t, creation)
			tc.change(session)
			client := testutil.NewStripeClient(t, func(*http.Request) (*http.Response, error) {
				return checkoutSessionListResponse(t, []*stripe.CheckoutSession{session}, false), nil
			})
			if got, err := findStripeCheckoutSession(t.Context(), client, creation); got != nil || !errors.Is(err, errStripeCheckoutReconciliationRequired) {
				t.Fatalf("uncertain match must stay blocked: got=%v, err=%v", got, err)
			}
		})
	}
}

func TestFindStripeCheckoutSessionPaginatesAndDetectsAmbiguity(t *testing.T) {
	for _, duplicate := range []bool{false, true} {
		t.Run(map[bool]string{false: "match on next page", true: "duplicate on next page"}[duplicate], func(t *testing.T) {
			creation := checkoutCreation{Request: checkoutCreationTestRequest(), IdempotencyKey: "original-key", CreatedAt: time.Now()}
			first := recoverableCheckoutSession(t, creation)
			first.ID = "cs_first"
			if !duplicate {
				first.Metadata["checkout_creation_key"] = "another-key"
			}
			calls := 0
			client := testutil.NewStripeClient(t, func(r *http.Request) (*http.Response, error) {
				calls++
				if calls == 1 {
					return checkoutSessionListResponse(t, []*stripe.CheckoutSession{first}, true), nil
				}
				if r.URL.Query().Get("starting_after") != first.ID {
					t.Error("must follow the Stripe pagination cursor")
				}
				return checkoutSessionListResponse(t, []*stripe.CheckoutSession{recoverableCheckoutSession(t, creation)}, false), nil
			})
			got, err := findStripeCheckoutSession(t.Context(), client, creation)
			if calls != 2 {
				t.Fatalf("must examine both pages, got %d requests", calls)
			}
			if duplicate {
				if got != nil || !errors.Is(err, errStripeCheckoutReconciliationRequired) {
					t.Fatal("ambiguous matches must stay blocked")
				}
			} else if err != nil || got == nil || got.ID != "cs_checkout" {
				t.Fatalf("must recover the match from the next page: got=%v, err=%v", got, err)
			}
		})
	}
}

func TestFindStripeCheckoutSessionSanitizesFailure(t *testing.T) {
	creation := checkoutCreation{Request: checkoutCreationTestRequest(), IdempotencyKey: "original-key"}
	client := testutil.NewStripeClient(t, func(*http.Request) (*http.Response, error) {
		return nil, errors.New("sk_test_sensitive upstream failure")
	})
	got, err := findStripeCheckoutSession(t.Context(), client, creation)
	if got != nil || err == nil || strings.Contains(err.Error(), "sensitive") {
		t.Fatalf("must sanitize lookup failures: got=%v, err=%v", got, err)
	}
}

func recoverableCheckoutSession(t *testing.T, creation checkoutCreation) *stripe.CheckoutSession {
	t.Helper()
	var session stripe.CheckoutSession
	if err := json.Unmarshal([]byte(checkoutSessionResponse(t, creation)), &session); err != nil {
		t.Fatal(err)
	}
	session.LineItems = &stripe.LineItemList{Data: []*stripe.LineItem{{
		ID: "li_checkout", Quantity: 1, Price: &stripe.Price{ID: creation.Request.PriceID},
	}}}
	return &session
}

func checkoutSessionListResponse(t *testing.T, sessions []*stripe.CheckoutSession, more bool) *http.Response {
	t.Helper()
	body, err := json.Marshal(map[string]any{"object": "list", "data": sessions, "has_more": more})
	if err != nil {
		t.Fatal(err)
	}
	return testutil.StripeResponse(http.StatusOK, string(body))
}
