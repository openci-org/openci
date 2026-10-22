package stripeapi_test

import (
	"context"
	"errors"
	"net/http"
	"testing"
	"time"

	"github.com/openci-org/openci/apps/genuineci_server/internal/billing/stripeapi"
	"github.com/openci-org/openci/apps/genuineci_server/internal/testutil"
	"github.com/stripe/stripe-go/v87"
)

func TestGetStripeCheckoutSession(t *testing.T) {
	client := testutil.NewStripeClient(t, func(request *http.Request) (*http.Response, error) {
		if request.Method != http.MethodGet || request.URL.Path != "/v1/checkout/sessions/cs_test_checkout" {
			t.Errorf("unexpected request: %s %s", request.Method, request.URL.Path)
		}
		deadline, ok := request.Context().Deadline()
		if !ok || time.Until(deadline) <= 0 || time.Until(deadline) > 10*time.Second {
			t.Error("Stripe reads must have a deadline within ten seconds")
		}
		return testutil.StripeResponse(http.StatusOK, `{"id":"cs_test_checkout","object":"checkout.session","status":"open","customer":"cus_team","subscription":"sub_team"}`), nil
	})

	session, err := stripeapi.GetCheckoutSession(t.Context(), client, "cs_test_checkout")

	if err != nil {
		t.Fatal(err)
	}
	if session.ID != "cs_test_checkout" || session.Status != stripe.CheckoutSessionStatusOpen {
		t.Fatal("expected the requested Checkout Session")
	}
	if session.Customer == nil || session.Customer.ID != "cus_team" || session.Subscription == nil || session.Subscription.ID != "sub_team" {
		t.Fatal("expected the customer and subscription references")
	}
}

func TestGetStripeCheckoutSessionSanitizesFailures(t *testing.T) {
	for _, tc := range []struct {
		name   string
		status int
		body   string
	}{
		{"Stripe error", http.StatusUnauthorized, `{"error":{"type":"invalid_request_error","message":"invalid sk_test_sensitive"}}`},
		{"invalid JSON", http.StatusOK, `upstream body with sk_test_sensitive`},
		{"transport error", 0, "transport failure containing sk_test_sensitive"},
	} {
		t.Run(tc.name, func(t *testing.T) {
			client := testutil.NewStripeClient(t, func(*http.Request) (*http.Response, error) {
				if tc.status == 0 {
					return nil, errors.New(tc.body)
				}
				return testutil.StripeResponse(tc.status, tc.body), nil
			})

			session, err := stripeapi.GetCheckoutSession(t.Context(), client, "cs_test_checkout")

			if session != nil || err == nil || err.Error() != "Stripe Checkout Session retrieval failed" {
				t.Fatalf("expected no session and a sanitized error, got err=%v", err)
			}
		})
	}
}

func TestGetStripeCheckoutSessionHonorsCancellation(t *testing.T) {
	ctx, cancel := context.WithCancel(t.Context())
	defer cancel()
	client := testutil.NewStripeClient(t, func(request *http.Request) (*http.Response, error) {
		cancel()
		<-request.Context().Done()
		return nil, request.Context().Err()
	})

	session, err := stripeapi.GetCheckoutSession(ctx, client, "cs_test_checkout")

	if session != nil || !errors.Is(err, context.Canceled) {
		t.Fatalf("expected cancellation with no session, got err=%v", err)
	}
}

func TestGetStripeCheckoutSessionHonorsEarlierDeadline(t *testing.T) {
	ctx, cancel := context.WithTimeout(t.Context(), 100*time.Millisecond)
	defer cancel()
	wantDeadline, _ := ctx.Deadline()
	client := testutil.NewStripeClient(t, func(request *http.Request) (*http.Response, error) {
		if deadline, ok := request.Context().Deadline(); !ok || !deadline.Equal(wantDeadline) {
			t.Error("must preserve the caller's earlier deadline")
		}
		<-request.Context().Done()
		return nil, request.Context().Err()
	})

	session, err := stripeapi.GetCheckoutSession(ctx, client, "cs_test_checkout")

	if session != nil || !errors.Is(err, context.DeadlineExceeded) {
		t.Fatalf("expected deadline exceeded with no session, got err=%v", err)
	}
}

func TestGetStripeCheckoutSessionRejectsMissingConfigurationOrID(t *testing.T) {
	client := testutil.NewStripeClient(t, func(*http.Request) (*http.Response, error) {
		t.Error("invalid input must not make a Stripe request")
		return nil, errors.New("unexpected request")
	})
	for _, tc := range []struct {
		name      string
		client    *stripe.Client
		sessionID string
		want      string
	}{
		{"disabled billing", nil, "cs_test_checkout", "Stripe billing is not configured"},
		{"empty ID", client, "", "Stripe Checkout Session ID must be set"},
		{"blank ID", client, " \t", "Stripe Checkout Session ID must be set"},
	} {
		t.Run(tc.name, func(t *testing.T) {
			session, err := stripeapi.GetCheckoutSession(t.Context(), tc.client, tc.sessionID)

			if session != nil || err == nil || err.Error() != tc.want {
				t.Fatalf("expected no session and error %q, got %v", tc.want, err)
			}
		})
	}
}
