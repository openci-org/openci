package billing

import (
	"encoding/json"
	"errors"
	"net/http"
	"testing"

	"github.com/stripe/stripe-go/v87"
)

func TestExpireCheckoutCreation(t *testing.T) {
	for _, lostResponse := range []bool{false, true} {
		t.Run(map[bool]string{false: "normal expiry", true: "lost expiry response"}[lostResponse], func(t *testing.T) {
			ctx, pool, creation := newCheckoutCreationResultTestDB(t, false)
			session := recoverableCheckoutSession(t, creation)
			session.PaymentStatus = stripe.CheckoutSessionPaymentStatusUnpaid
			if err := recordStripeCheckoutSession(ctx, pool, creation, session); err != nil {
				t.Fatal(err)
			}
			creation.StripeCheckoutSessionID = &session.ID
			posts := 0
			client := newStripeReadTestClient(t, func(r *http.Request) (*http.Response, error) {
				if r.Method == http.MethodPost {
					posts++
					if r.URL.Path != "/v1/checkout/sessions/cs_checkout/expire" || r.Header.Get("Idempotency-Key") != creation.IdempotencyKey+":expire" {
						t.Error("must expire the original Session with a stable operation key")
					}
					session.Status = stripe.CheckoutSessionStatusExpired
					session.URL = ""
					if lostResponse {
						return nil, errors.New("expiry succeeded but the response was lost")
					}
				}
				body, err := json.Marshal(session)
				if err != nil {
					t.Fatal(err)
				}
				return stripeTestResponse(http.StatusOK, string(body)), nil
			})
			if err := expireCheckoutCreation(ctx, pool, client, creation); err != nil {
				t.Fatal(err)
			}
			var closed bool
			if err := pool.QueryRow(ctx, "SELECT closed_at IS NOT NULL FROM billing_checkout_creations").Scan(&closed); err != nil || !closed {
				t.Fatalf("confirmed expiry must close the intent: closed=%v, err=%v", closed, err)
			}
			want := checkoutCreationRecords(t, ctx, pool)
			if err := expireCheckoutCreation(ctx, pool, client, creation); err != nil {
				t.Fatal(err)
			}
			if posts != 1 || checkoutCreationRecords(t, ctx, pool) != want {
				t.Fatal("retry must preserve the original closure without expiring again")
			}
		})
	}
}

func TestExpireCheckoutCreationBlocksCompletedOrUnknownOutcomes(t *testing.T) {
	for _, outcome := range []string{"completed before expiry", "payment wins the race", "expiry failed", "wrong Session"} {
		t.Run(outcome, func(t *testing.T) {
			ctx, pool, creation := newCheckoutCreationResultTestDB(t, false)
			session := recoverableCheckoutSession(t, creation)
			session.PaymentStatus = stripe.CheckoutSessionPaymentStatusUnpaid
			if err := recordStripeCheckoutSession(ctx, pool, creation, session); err != nil {
				t.Fatal(err)
			}
			creation.StripeCheckoutSessionID = &session.ID
			want := checkoutCreationRecords(t, ctx, pool)
			if outcome == "completed before expiry" {
				session.Status = stripe.CheckoutSessionStatusComplete
			}
			client := newStripeReadTestClient(t, func(r *http.Request) (*http.Response, error) {
				if r.Method == http.MethodPost {
					if outcome == "completed before expiry" || outcome == "wrong Session" {
						t.Error("must reject invalid/completed Sessions before attempting expiry")
					}
					if outcome == "payment wins the race" {
						session.Status = stripe.CheckoutSessionStatusComplete
					}
					return stripeTestResponse(http.StatusBadRequest, `{"error":{"message":"cannot expire"}}`), nil
				}
				response := *session
				if outcome == "wrong Session" {
					response.ID = "cs_another"
				}
				body, err := json.Marshal(response)
				if err != nil {
					t.Fatal(err)
				}
				return stripeTestResponse(http.StatusOK, string(body)), nil
			})
			if err := expireCheckoutCreation(ctx, pool, client, creation); err == nil {
				t.Fatal("completed or uncertain purchases must not be closed")
			}
			if checkoutCreationRecords(t, ctx, pool) != want {
				t.Fatal("failed expiry must keep the original intent blocking another purchase")
			}
		})
	}
}
