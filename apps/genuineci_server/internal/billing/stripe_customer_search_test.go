package billing

import (
	"context"
	"errors"
	"fmt"
	"net/http"
	"testing"
	"time"

	"github.com/openci-org/openci/apps/genuineci_server/internal/testutil"
	"github.com/stripe/stripe-go/v87"
)

func TestFindStripeCustomer(t *testing.T) {
	for _, tc := range []struct {
		name     string
		livemode bool
	}{
		{"test mode", false},
		{"live mode", true},
	} {
		t.Run(tc.name, func(t *testing.T) {
			input := stripeCustomerRequest{TeamID: "team-1", Livemode: tc.livemode}
			client := testutil.NewStripeClient(t, func(request *http.Request) (*http.Response, error) {
				if request.Method != http.MethodGet || request.URL.Path != "/v1/customers/search" {
					t.Errorf("unexpected request: %s %s", request.Method, request.URL.Path)
				}
				query := request.URL.Query()
				if query.Get("query") != `metadata["team_id"]:"team-1"` || query.Get("limit") != "2" {
					t.Errorf("must search the team's metadata with at most two results: %v", query)
				}
				deadline, ok := request.Context().Deadline()
				if !ok || time.Until(deadline) <= 0 || time.Until(deadline) > 10*time.Second {
					t.Error("Stripe search must have a deadline within ten seconds")
				}
				body := fmt.Sprintf(`{
					"object":"search_result", "has_more":false,
					"data":[{"id":"cus_team","metadata":{"team_id":"team-1"},"livemode":%t}]
				}`, tc.livemode)
				return testutil.StripeResponse(http.StatusOK, body), nil
			})

			customer, err := findStripeCustomer(t.Context(), client, input)

			if err != nil {
				t.Fatal(err)
			}
			if customer == nil || customer.ID != "cus_team" ||
				customer.Metadata["team_id"] != input.TeamID || customer.Livemode != input.Livemode {
				t.Fatal("must return the Customer matching the requested team and mode")
			}
		})
	}
}

func TestFindStripeCustomerEscapesTeamID(t *testing.T) {
	for _, tc := range []struct{ name, teamID, query string }{
		{"quotes", `team" OR metadata["team_id"]:"other`, `metadata["team_id"]:"team\" OR metadata[\"team_id\"]:\"other"`},
		{"backslashes", `team\id`, `metadata["team_id"]:"team\\id"`},
		{"backslash before quote", `team\"`, `metadata["team_id"]:"team\\\""`},
	} {
		t.Run(tc.name, func(t *testing.T) {
			client := testutil.NewStripeClient(t, func(request *http.Request) (*http.Response, error) {
				if got := request.URL.Query().Get("query"); got != tc.query {
					t.Errorf("team ID must remain one quoted metadata value: want=%q, got=%q", tc.query, got)
				}
				return testutil.StripeResponse(http.StatusOK, `{"data":[],"has_more":false}`), nil
			})

			customer, err := findStripeCustomer(t.Context(), client, stripeCustomerRequest{TeamID: tc.teamID})

			if customer != nil || !errors.Is(err, errStripeCustomerReconciliationRequired) {
				t.Fatalf("empty search must remain unresolved: err=%v", err)
			}
		})
	}
}

func TestFindStripeCustomerRequiresUnambiguousMatch(t *testing.T) {
	for _, tc := range []struct{ name, body string }{
		{"no matches", `{"data":[],"has_more":false}`},
		{"two matches", `{"data":[{"id":"cus_one","metadata":{"team_id":"team-1"}},{"id":"cus_two","metadata":{"team_id":"team-1"}}],"has_more":false}`},
		{"more results", `{"data":[{"id":"cus_team","metadata":{"team_id":"team-1"}}],"has_more":true,"next_page":"next"}`},
		{"missing ID", `{"data":[{"metadata":{"team_id":"team-1"}}]}`},
		{"deleted Customer", `{"data":[{"id":"cus_team","deleted":true,"metadata":{"team_id":"team-1"}}]}`},
		{"another team", `{"data":[{"id":"cus_team","metadata":{"team_id":"team-2"}}]}`},
		{"different team ID case", `{"data":[{"id":"cus_team","metadata":{"team_id":"TEAM-1"}}]}`},
		{"missing team metadata", `{"data":[{"id":"cus_team"}]}`},
		{"different mode", `{"data":[{"id":"cus_team","metadata":{"team_id":"team-1"},"livemode":true}]}`},
	} {
		t.Run(tc.name, func(t *testing.T) {
			requests := 0
			client := testutil.NewStripeClient(t, func(request *http.Request) (*http.Response, error) {
				requests++
				if request.Method != http.MethodGet || request.URL.Path != "/v1/customers/search" {
					t.Error("an unresolved search must only read Stripe")
				}
				return testutil.StripeResponse(http.StatusOK, tc.body), nil
			})

			customer, err := findStripeCustomer(t.Context(), client, stripeCustomerRequest{TeamID: "team-1"})

			if customer != nil || !errors.Is(err, errStripeCustomerReconciliationRequired) {
				t.Fatalf("must leave reconciliation unresolved without a Customer: err=%v", err)
			}
			if requests != 1 {
				t.Fatalf("must stop after the first search page, got %d requests", requests)
			}
		})
	}
}

func TestFindStripeCustomerSanitizesFailures(t *testing.T) {
	for _, tc := range []struct {
		name   string
		status int
		body   string
	}{
		{"Stripe error", http.StatusUnauthorized, `{"error":{"message":"invalid sk_test_sensitive"}}`},
		{"rate limit", http.StatusTooManyRequests, `{"error":{"message":"private Stripe details"}}`},
		{"invalid JSON", http.StatusOK, "upstream body with sk_test_sensitive"},
		{"transport error", 0, "connection error with sk_test_sensitive"},
	} {
		t.Run(tc.name, func(t *testing.T) {
			client := testutil.NewStripeClient(t, func(*http.Request) (*http.Response, error) {
				if tc.status == 0 {
					return nil, errors.New(tc.body)
				}
				return testutil.StripeResponse(tc.status, tc.body), nil
			})

			customer, err := findStripeCustomer(t.Context(), client, stripeCustomerRequest{TeamID: "team-1"})

			if customer != nil || err == nil || err.Error() != "Stripe Customer search failed" {
				t.Fatalf("must return no Customer and a sanitized error: err=%v", err)
			}
		})
	}
}

func TestFindStripeCustomerRequiresClientAndTeam(t *testing.T) {
	client := testutil.NewStripeClient(t, func(*http.Request) (*http.Response, error) {
		t.Error("invalid input must not call Stripe")
		return nil, errors.New("unexpected request")
	})
	for _, tc := range []struct {
		name, teamID string
		client       *stripe.Client
	}{
		{"missing client", "team-1", nil},
		{"empty team", "", client},
		{"blank team", " \t", client},
	} {
		t.Run(tc.name, func(t *testing.T) {
			customer, err := findStripeCustomer(t.Context(), tc.client, stripeCustomerRequest{TeamID: tc.teamID})

			if customer != nil || err == nil {
				t.Fatal("invalid input must return an error without a Customer")
			}
		})
	}
}

func TestFindStripeCustomerHonorsCancellation(t *testing.T) {
	ctx, cancel := context.WithCancel(t.Context())
	defer cancel()
	client := testutil.NewStripeClient(t, func(request *http.Request) (*http.Response, error) {
		cancel()
		<-request.Context().Done()
		return nil, request.Context().Err()
	})

	customer, err := findStripeCustomer(ctx, client, stripeCustomerRequest{TeamID: "team-1"})

	if customer != nil || !errors.Is(err, context.Canceled) {
		t.Fatalf("must preserve cancellation without a Customer: err=%v", err)
	}
}

func TestFindStripeCustomerHonorsEarlierDeadline(t *testing.T) {
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

	customer, err := findStripeCustomer(ctx, client, stripeCustomerRequest{TeamID: "team-1"})

	if customer != nil || !errors.Is(err, context.DeadlineExceeded) {
		t.Fatalf("must preserve the earlier deadline without a Customer: err=%v", err)
	}
}
