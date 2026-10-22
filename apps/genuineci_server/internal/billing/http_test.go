package billing

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	billingconfig "github.com/openci-org/openci/apps/genuineci_server/internal/billing/config"
	billingschema "github.com/openci-org/openci/apps/genuineci_server/internal/billing/schema"
	"github.com/openci-org/openci/apps/genuineci_server/internal/testutil"
	"github.com/stripe/stripe-go/v87"
)

func TestBillingHTTPRequiresInternalTokenAndVerifiedUser(t *testing.T) {
	for _, tc := range []struct{ token, user string }{{"", "user-1"}, {"wrong", "user-1"}, {strings.Repeat("x", 32), ""}} {
		mux := http.NewServeMux()
		config := &billingconfig.Config{InternalToken: strings.Repeat("x", 32)}
		RegisterRoutes(mux, nil, nil, config)
		request := httptest.NewRequest(http.MethodGet, "/internal/billing/teams/team-1", nil)
		request.Header.Set("Authorization", "Bearer "+tc.token)
		request.Header.Set("X-GenuineCI-User-ID", tc.user)
		response := httptest.NewRecorder()
		mux.ServeHTTP(response, request)
		if response.Code != http.StatusUnauthorized || response.Header().Get("Cache-Control") != "no-store" {
			t.Fatal("must reject before DB access")
		}
	}
}

func TestBillingHTTPRejectsClientOwnedIdentityAndReturnURLs(t *testing.T) {
	_, service, _ := newCheckoutFlowTest(t)
	mux := http.NewServeMux()
	RegisterRoutes(mux, service.pool, service.stripe, &service.config)
	for _, body := range []string{`{"planId":"light","userId":"user-1"}`, `{"planId":"light","successUrl":"https://evil.example"}`, `{"planId":"light"} {}`, `not json`} {
		response := billingHTTPRequest(mux, service.config, http.MethodPost, "/internal/billing/teams/team-1/checkout", body, "user-1")
		if response.Code != http.StatusBadRequest {
			t.Fatalf("must reject unsupported request fields: %d", response.Code)
		}
	}
}

func TestBillingHTTPCheckoutAndStatus(t *testing.T) {
	_, service, _ := newCheckoutFlowTest(t)
	testutil.ExecSQL(t, t.Context(), service.pool, "CREATE TABLE billing_periods (id text PRIMARY KEY, team_id text, period_type text, starts_at bigint, ends_at bigint)")
	if err := billingschema.EnsureStripeStateTables(t.Context(), service.pool); err != nil {
		t.Fatal(err)
	}
	mux := http.NewServeMux()
	RegisterRoutes(mux, service.pool, service.stripe, &service.config)
	response := billingHTTPRequest(mux, service.config, http.MethodPost, "/internal/billing/teams/team-1/checkout", `{"planId":"light"}`, "user-1")
	var action map[string]string
	if err := json.Unmarshal(response.Body.Bytes(), &action); err != nil || response.Code != http.StatusOK || action["url"] == "" {
		t.Fatalf("expected Checkout URL: %d %s", response.Code, response.Body)
	}
	response = billingHTTPRequest(mux, service.config, http.MethodGet, "/internal/billing/teams/team-1", "", "user-2")
	var status billingStatus
	if err := json.Unmarshal(response.Body.Bytes(), &status); err != nil || response.Code != http.StatusOK || status.CanStartCI || status.BlockReason != "payment_pending" {
		t.Fatalf("unpaid Checkout must not grant access: %d %s", response.Code, response.Body)
	}
	response = billingHTTPRequest(mux, service.config, http.MethodGet, "/internal/billing/teams/team-1", "", "outsider")
	if response.Code != http.StatusForbidden {
		t.Fatal("internal identity still requires team membership")
	}
}

func TestBillingHTTPDisabledHasNoRoutes(t *testing.T) {
	mux := http.NewServeMux()
	RegisterRoutes(mux, nil, nil, nil)
	for _, path := range []string{"/stripe/webhook", "/internal/billing/teams/team-1", "/internal/billing/teams/team-1/checkout"} {
		response := httptest.NewRecorder()
		mux.ServeHTTP(response, httptest.NewRequest(http.MethodPost, path, nil))
		if response.Code != http.StatusNotFound {
			t.Fatal("disabled billing must not expose endpoints")
		}
	}
}

func TestBillingHTTPTeamDeletion(t *testing.T) {
	ctx, service, gateway := newCheckoutFlowTest(t)
	mux := http.NewServeMux()
	RegisterRoutes(mux, service.pool, service.stripe, &service.config)
	path := "/internal/billing/teams/team-1"
	response := httptest.NewRecorder()
	mux.ServeHTTP(response, httptest.NewRequest(http.MethodDelete, path, nil))
	if response.Code != http.StatusUnauthorized {
		t.Fatal("deletion requires the internal token and verified user")
	}
	for _, tc := range []struct {
		user, body string
		status     int
	}{
		{"outsider", "", http.StatusForbidden},
		{"user-1", `{"userId":"user-2"}`, http.StatusBadRequest},
	} {
		response = billingHTTPRequest(mux, service.config, http.MethodDelete, path, tc.body, tc.user)
		if response.Code != tc.status {
			t.Fatalf("unexpected authorization result: %d", response.Code)
		}
	}
	if _, err := service.checkout(ctx, billingMember{TeamID: "team-1", UserID: "user-1"}, "light"); err != nil {
		t.Fatal(err)
	}
	response = billingHTTPRequest(mux, service.config, http.MethodDelete, path, "", "user-2")
	if response.Code != http.StatusConflict || !strings.Contains(response.Body.String(), "payment_pending") {
		t.Fatal("pending Checkout must prevent deletion through HTTP")
	}
	gateway.sessions["cs_1"].Status = stripe.CheckoutSessionStatusExpired
	response = billingHTTPRequest(mux, service.config, http.MethodDelete, path, "", "user-2")
	if response.Code != http.StatusOK || response.Body.String() != "{\"success\":true}\n" || response.Header().Get("Cache-Control") != "no-store" {
		t.Fatalf("unexpected successful deletion: %d %s", response.Code, response.Body)
	}
	assertTeamDeleted(t, ctx, service, true)
}

func billingHTTPRequest(handler http.Handler, config billingconfig.Config, method, path, body, user string) *httptest.ResponseRecorder {
	request := httptest.NewRequest(method, path, strings.NewReader(body))
	request.Header.Set("Authorization", "Bearer "+config.InternalToken)
	request.Header.Set("X-GenuineCI-User-ID", user)
	response := httptest.NewRecorder()
	handler.ServeHTTP(response, request)
	return response
}
