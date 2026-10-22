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

func TestCreateStripeCustomerReusesKeyAfterLostResponse(t *testing.T) {
	creation := stripeapi.CustomerCreateRequest{TeamID: "team-1", IdempotencyKey: "persisted-creation-key"}
	requests := 0
	client := testutil.NewStripeClient(t, func(request *http.Request) (*http.Response, error) {
		requests++
		if request.Method != http.MethodPost || request.URL.Path != "/v1/customers" {
			t.Errorf("unexpected request: %s %s", request.Method, request.URL.Path)
		}
		if request.Header.Get("Idempotency-Key") != creation.IdempotencyKey {
			t.Error("every attempt must send the provided creation key unchanged")
		}
		if err := request.ParseForm(); err != nil {
			t.Fatal(err)
		}
		if len(request.PostForm) != 1 || request.PostForm.Get("metadata[team_id]") != creation.TeamID {
			t.Errorf("expected only the server-owned team metadata, got %v", request.PostForm)
		}
		deadline, ok := request.Context().Deadline()
		if !ok || time.Until(deadline) <= 0 || time.Until(deadline) > 10*time.Second {
			t.Error("Stripe creation must have a deadline within ten seconds")
		}
		if requests == 1 {
			return nil, errors.New("connection closed after creating customer")
		}
		return testutil.StripeResponse(http.StatusOK, `{"id":"cus_team","object":"customer","metadata":{"team_id":"team-1"}}`), nil
	})

	customer, err := stripeapi.CreateCustomer(t.Context(), client, creation)
	if customer != nil || err == nil || err.Error() != "Stripe Customer creation failed" {
		t.Fatalf("lost response must return no Customer and a sanitized error, got err=%v", err)
	}

	customer, err = stripeapi.CreateCustomer(t.Context(), client, creation)
	if err != nil {
		t.Fatal(err)
	}
	if customer == nil || customer.ID != "cus_team" || customer.Metadata["team_id"] != creation.TeamID {
		t.Fatal("expected the Customer returned by Stripe")
	}
	if requests != 2 {
		t.Fatalf("want one initial request and one retry, got %d", requests)
	}
}

func TestCreateStripeCustomerRejectsMissingInput(t *testing.T) {
	client := testutil.NewStripeClient(t, func(*http.Request) (*http.Response, error) {
		t.Error("missing input must not make a Stripe request")
		return nil, errors.New("unexpected request")
	})
	for _, tc := range []struct {
		name, teamID, key string
		client            *stripe.Client
	}{
		{"missing client", "team-1", "persisted-key", nil},
		{"empty team", "", "persisted-key", client},
		{"blank team", " \t", "persisted-key", client},
		{"empty key", "team-1", "", client},
		{"blank key", "team-1", " \t", client},
	} {
		t.Run(tc.name, func(t *testing.T) {
			creation := stripeapi.CustomerCreateRequest{TeamID: tc.teamID, IdempotencyKey: tc.key}

			customer, err := stripeapi.CreateCustomer(t.Context(), tc.client, creation)

			if customer != nil || err == nil {
				t.Fatal("missing input must return an error without a Customer")
			}
		})
	}
}

func TestCreateStripeCustomerSanitizesFailures(t *testing.T) {
	for _, tc := range []struct {
		name   string
		status int
		body   string
	}{
		{"Stripe error", http.StatusUnauthorized, `{"error":{"message":"invalid sk_test_sensitive"}}`},
		{"invalid JSON", http.StatusOK, "upstream body with sk_test_sensitive"},
		{"missing Customer ID", http.StatusOK, `{}`},
	} {
		t.Run(tc.name, func(t *testing.T) {
			client := testutil.NewStripeClient(t, func(*http.Request) (*http.Response, error) {
				return testutil.StripeResponse(tc.status, tc.body), nil
			})
			creation := stripeapi.CustomerCreateRequest{TeamID: "team-1", IdempotencyKey: "persisted-key"}

			customer, err := stripeapi.CreateCustomer(t.Context(), client, creation)

			if customer != nil || err == nil || err.Error() != "Stripe Customer creation failed" {
				t.Fatalf("want no Customer and a sanitized error, got err=%v", err)
			}
		})
	}
}

func TestCreateStripeCustomerHonorsCancellation(t *testing.T) {
	ctx, cancel := context.WithCancel(t.Context())
	defer cancel()
	client := testutil.NewStripeClient(t, func(request *http.Request) (*http.Response, error) {
		cancel()
		<-request.Context().Done()
		return nil, request.Context().Err()
	})
	creation := stripeapi.CustomerCreateRequest{TeamID: "team-1", IdempotencyKey: "persisted-key"}

	customer, err := stripeapi.CreateCustomer(ctx, client, creation)

	if customer != nil || !errors.Is(err, context.Canceled) {
		t.Fatalf("want no Customer and cancellation, got err=%v", err)
	}
}

func TestCreateStripeCustomerHonorsEarlierDeadline(t *testing.T) {
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
	creation := stripeapi.CustomerCreateRequest{TeamID: "team-1", IdempotencyKey: "persisted-key"}

	customer, err := stripeapi.CreateCustomer(ctx, client, creation)

	if customer != nil || !errors.Is(err, context.DeadlineExceeded) {
		t.Fatalf("want no Customer and deadline exceeded, got err=%v", err)
	}
}
