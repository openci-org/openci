package billing

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
)

func TestWorkerBillingHTTPAuthorizationAndInput(t *testing.T) {
	config := &ServiceConfig{InternalToken: strings.Repeat("x", 32)}
	mux := http.NewServeMux()
	RegisterRoutes(mux, nil, nil, config)
	for _, path := range []string{"claim", "start", "report"} {
		path = "/internal/billing/worker/" + path
		for _, token := range []string{"", "wrong"} {
			response := billingHTTPRequest(mux, ServiceConfig{InternalToken: token}, http.MethodPost, path, `{}`, "user-1")
			if response.Code != http.StatusUnauthorized {
				t.Fatalf("worker endpoint must require service authentication: %d", response.Code)
			}
		}
		for _, body := range []string{`{}`, `{"userId":"user-1"}`, `null`, `{} {}`, strings.Repeat("x", 5000)} {
			response := billingHTTPRequest(mux, *config, http.MethodPost, path, body, "")
			if response.Code != http.StatusBadRequest || response.Header().Get("Cache-Control") != "no-store" {
				t.Fatalf("invalid worker request must fail before DB access: %d", response.Code)
			}
		}
		disabled := http.NewServeMux()
		RegisterRoutes(disabled, nil, nil, nil)
		response := httptest.NewRecorder()
		disabled.ServeHTTP(response, httptest.NewRequest(http.MethodPost, path, nil))
		if response.Code != http.StatusNotFound {
			t.Fatal("billing disabled must not expose worker billing")
		}
	}
}

func TestWorkerBillingHTTPClaim(t *testing.T) {
	ctx, service := newJobClaimTestDB(t)
	service.config.InternalToken = strings.Repeat("x", 32)
	mux := http.NewServeMux()
	RegisterRoutes(mux, service.pool, nil, &service.config)
	response := billingHTTPRequest(mux, service.config, http.MethodPost, "/internal/billing/worker/claim", `{"workerHost":"worker-1"}`, "")
	var result struct {
		Claim *workerClaim `json:"claim"`
	}
	if err := json.Unmarshal(response.Body.Bytes(), &result); err != nil || response.Code != http.StatusOK || result.Claim == nil || result.Claim.JobID != "job-1" {
		t.Fatalf("unexpected claim response: %d %s", response.Code, response.Body)
	}
	execCheckoutCreationSQL(t, ctx, service.pool, `UPDATE billing_stripe_state SET subscription_status = 'canceled'`)
	response = billingHTTPRequest(mux, service.config, http.MethodPost, "/internal/billing/worker/claim", `{"workerHost":"worker-1"}`, "")
	if response.Code != http.StatusOK || response.Body.String() != "{\"claim\":null}\n" {
		t.Fatal("no eligible work must return an empty claim")
	}
}

func TestWorkerBillingHTTPExecutionLifecycle(t *testing.T) {
	_, service, request := newAdmittedExecutionTest(t)
	service.config.InternalToken = strings.Repeat("x", 32)
	mux := http.NewServeMux()
	RegisterRoutes(mux, service.pool, nil, &service.config)
	for _, step := range []struct {
		path, outcome string
		active        bool
	}{{"start", "", true}, {"report", "", true}, {"report", "success", false}} {
		request.Outcome = step.outcome
		body, err := json.Marshal(request)
		if err != nil {
			t.Fatal(err)
		}
		response := billingHTTPRequest(mux, service.config, http.MethodPost, "/internal/billing/worker/"+step.path, string(body), "")
		var result map[string]bool
		if err := json.Unmarshal(response.Body.Bytes(), &result); err != nil || response.Code != http.StatusOK || result["active"] != step.active || result["measurementIncomplete"] || len(result) != 2 {
			t.Fatalf("unexpected lifecycle response: %d %s", response.Code, response.Body)
		}
	}
	request.WorkerHost = "wrong-worker"
	body, _ := json.Marshal(request)
	response := billingHTTPRequest(mux, service.config, http.MethodPost, "/internal/billing/worker/report", string(body), "")
	if response.Code != http.StatusConflict || response.Body.String() != "{\"error\":\"admission_not_current\"}\n" {
		t.Fatal("stale identity must return a sanitized conflict")
	}
}
