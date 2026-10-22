package stripeapi_test

import (
	"context"
	"errors"
	"net/http"
	"net/url"
	"reflect"
	"testing"
	"time"

	"github.com/openci-org/openci/apps/genuineci_server/internal/billing/stripeapi"
	"github.com/openci-org/openci/apps/genuineci_server/internal/testutil"
)

func TestCreateStripeCheckoutSession(t *testing.T) {
	creation := stripeCheckoutTestCreation()
	client := testutil.NewStripeClient(t, func(request *http.Request) (*http.Response, error) {
		if request.Method != http.MethodPost || request.URL.Path != "/v1/checkout/sessions" {
			t.Errorf("unexpected request: %s %s", request.Method, request.URL.Path)
		}
		if request.Header.Get("Idempotency-Key") != creation.IdempotencyKey {
			t.Error("must send the provided Checkout key unchanged")
		}
		if err := request.ParseForm(); err != nil {
			t.Fatal(err)
		}
		want := url.Values{
			"mode":                                 {"subscription"},
			"ui_mode":                              {"hosted_page"},
			"customer":                             {creation.CustomerID},
			"client_reference_id":                  {creation.TeamID},
			"success_url":                          {creation.SuccessURL},
			"cancel_url":                           {creation.CancelURL},
			"allowed_payment_method_types[0]":      {"card"},
			"adaptive_pricing[enabled]":            {"false"},
			"line_items[0][price]":                 {creation.PriceID},
			"line_items[0][quantity]":              {"1"},
			"metadata[team_id]":                    {creation.TeamID},
			"metadata[checkout_creation_key]":      {creation.IdempotencyKey},
			"subscription_data[metadata][team_id]": {creation.TeamID},
		}
		if !reflect.DeepEqual(request.PostForm, want) {
			t.Errorf("unexpected Checkout parameters: got %v, want %v", request.PostForm, want)
		}
		deadline, ok := request.Context().Deadline()
		if !ok || time.Until(deadline) <= 0 || time.Until(deadline) > 10*time.Second {
			t.Error("Stripe creation must have a deadline within ten seconds")
		}
		return testutil.StripeResponse(http.StatusOK, stripeCheckoutCreatedResponse), nil
	})

	session, err := stripeapi.CreateCheckoutSession(t.Context(), client, creation)

	if err != nil {
		t.Fatal(err)
	}
	if session == nil || session.ID != "cs_test_checkout" || session.URL != "https://checkout.stripe.com/c/pay/cs_test_checkout" {
		t.Fatal("expected the Session ID and hosted payment URL returned by Stripe")
	}
}

func TestCreateStripeCheckoutSessionReusesRequestAfterLostResponse(t *testing.T) {
	creation := stripeCheckoutTestCreation()
	requests := 0
	var firstBody string
	client := testutil.NewStripeClient(t, func(request *http.Request) (*http.Response, error) {
		requests++
		if request.Header.Get("Idempotency-Key") != creation.IdempotencyKey {
			t.Error("every attempt must reuse the persisted Checkout key")
		}
		if err := request.ParseForm(); err != nil {
			t.Fatal(err)
		}
		if requests == 1 {
			firstBody = request.PostForm.Encode()
			return nil, errors.New("connection closed after creating Checkout Session")
		}
		if request.PostForm.Encode() != firstBody {
			t.Error("retries must send identical Checkout parameters")
		}
		return testutil.StripeResponse(http.StatusOK, stripeCheckoutCreatedResponse), nil
	})

	session, err := stripeapi.CreateCheckoutSession(t.Context(), client, creation)
	if session != nil || err == nil || err.Error() != "Stripe Checkout Session creation failed" {
		t.Fatalf("lost response must return no Session and a sanitized error, got err=%v", err)
	}

	session, err = stripeapi.CreateCheckoutSession(t.Context(), client, creation)
	if err != nil || session == nil || session.ID != "cs_test_checkout" {
		t.Fatalf("expected the Session on retry, got err=%v", err)
	}
	if requests != 2 {
		t.Fatalf("want one initial request and one retry, got %d", requests)
	}
}

func TestCreateStripeCheckoutSessionRejectsMissingInput(t *testing.T) {
	client := testutil.NewStripeClient(t, func(*http.Request) (*http.Response, error) {
		t.Error("missing input must not make a Stripe request")
		return nil, errors.New("unexpected request")
	})
	t.Run("missing client", func(t *testing.T) {
		session, err := stripeapi.CreateCheckoutSession(t.Context(), nil, stripeCheckoutTestCreation())
		if session != nil || err == nil {
			t.Fatal("missing client must return an error without a Session")
		}
	})
	for _, tc := range []struct {
		name string
		set  func(*stripeapi.CheckoutCreateRequest, string)
	}{
		{"team ID", func(r *stripeapi.CheckoutCreateRequest, value string) { r.TeamID = value }},
		{"Customer ID", func(r *stripeapi.CheckoutCreateRequest, value string) { r.CustomerID = value }},
		{"Price ID", func(r *stripeapi.CheckoutCreateRequest, value string) { r.PriceID = value }},
		{"success URL", func(r *stripeapi.CheckoutCreateRequest, value string) { r.SuccessURL = value }},
		{"cancel URL", func(r *stripeapi.CheckoutCreateRequest, value string) { r.CancelURL = value }},
		{"idempotency key", func(r *stripeapi.CheckoutCreateRequest, value string) { r.IdempotencyKey = value }},
	} {
		t.Run(tc.name, func(t *testing.T) {
			for _, value := range []string{"", " \t"} {
				creation := stripeCheckoutTestCreation()
				tc.set(&creation, value)

				session, err := stripeapi.CreateCheckoutSession(t.Context(), client, creation)

				if session != nil || err == nil {
					t.Fatalf("missing input %q must return an error without a Session", value)
				}
			}
		})
	}
}

func TestCreateStripeCheckoutSessionSanitizesFailures(t *testing.T) {
	for _, tc := range []struct {
		name   string
		status int
		body   string
	}{
		{"Stripe error", http.StatusUnauthorized, `{"error":{"message":"invalid sk_test_sensitive"}}`},
		{"invalid JSON", http.StatusOK, "upstream body with sk_test_sensitive"},
		{"missing Session ID", http.StatusOK, `{"url":"https://checkout.stripe.com/c/pay/cs_test_checkout"}`},
		{"missing payment URL", http.StatusOK, `{"id":"cs_test_checkout"}`},
	} {
		t.Run(tc.name, func(t *testing.T) {
			client := testutil.NewStripeClient(t, func(*http.Request) (*http.Response, error) {
				return testutil.StripeResponse(tc.status, tc.body), nil
			})

			session, err := stripeapi.CreateCheckoutSession(t.Context(), client, stripeCheckoutTestCreation())

			if session != nil || err == nil || err.Error() != "Stripe Checkout Session creation failed" {
				t.Fatalf("want no Session and a sanitized error, got err=%v", err)
			}
		})
	}
}

func TestCreateStripeCheckoutSessionHonorsCancellation(t *testing.T) {
	ctx, cancel := context.WithCancel(t.Context())
	defer cancel()
	client := testutil.NewStripeClient(t, func(request *http.Request) (*http.Response, error) {
		cancel()
		<-request.Context().Done()
		return nil, request.Context().Err()
	})

	session, err := stripeapi.CreateCheckoutSession(ctx, client, stripeCheckoutTestCreation())

	if session != nil || !errors.Is(err, context.Canceled) {
		t.Fatalf("want no Session and cancellation, got err=%v", err)
	}
}

func TestCreateStripeCheckoutSessionHonorsEarlierDeadline(t *testing.T) {
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

	session, err := stripeapi.CreateCheckoutSession(ctx, client, stripeCheckoutTestCreation())

	if session != nil || !errors.Is(err, context.DeadlineExceeded) {
		t.Fatalf("want no Session and deadline exceeded, got err=%v", err)
	}
}

func stripeCheckoutTestCreation() stripeapi.CheckoutCreateRequest {
	return stripeapi.CheckoutCreateRequest{
		TeamID:         "team-1",
		CustomerID:     "cus_team",
		PriceID:        "price_light",
		SuccessURL:     "https://app.example.com/teams/team-1/billing?checkout=success&session_id={CHECKOUT_SESSION_ID}",
		CancelURL:      "https://app.example.com/teams/team-1/billing?checkout=cancel",
		IdempotencyKey: "persisted-checkout-key",
	}
}

const stripeCheckoutCreatedResponse = `{"id":"cs_test_checkout","object":"checkout.session","url":"https://checkout.stripe.com/c/pay/cs_test_checkout"}`
