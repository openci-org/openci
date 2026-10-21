package billing

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/stripe/stripe-go/v87"
	"github.com/stripe/stripe-go/v87/webhook"
)

func TestWebhookVerifiesSignatureBeforeReconciliation(t *testing.T) {
	for _, scenario := range []string{"missing signature", "wrong secret", "changed body", "expired signature", "wrong mode", "wrong version", "connected account", "oversized body"} {
		t.Run(scenario, func(t *testing.T) {
			service := &Service{config: ServiceConfig{WebhookSecret: "whsec_endpoint"}}
			body := billingWebhookBody(t, "cus_team", "invoice.paid")
			secret, timestamp := service.config.WebhookSecret, time.Now()
			switch scenario {
			case "wrong secret":
				secret = "whsec_other"
			case "expired signature":
				timestamp = timestamp.Add(-6 * time.Minute)
			case "wrong mode":
				body = bytes.Replace(body, []byte(`"livemode":false`), []byte(`"livemode":true`), 1)
			case "wrong version":
				body = bytes.Replace(body, []byte(stripe.APIVersion), []byte("2020-08-27"), 1)
			case "connected account":
				body = bytes.Replace(body, []byte(`"object":"event"`), []byte(`"account":"acct_other","object":"event"`), 1)
			case "oversized body":
				body = bytes.Repeat([]byte("x"), (1<<20)+1)
			}
			signed := webhook.GenerateTestSignedPayload(&webhook.UnsignedPayload{Payload: body, Secret: secret, Timestamp: timestamp})
			if scenario == "changed body" {
				body = append(body, ' ')
			}
			request := httptest.NewRequest(http.MethodPost, "/stripe/webhook", bytes.NewReader(body))
			if scenario != "missing signature" {
				request.Header.Set("Stripe-Signature", signed.Header)
			}
			response := httptest.NewRecorder()
			service.webhook(response, request)
			want := http.StatusBadRequest
			if scenario == "oversized body" {
				want = http.StatusRequestEntityTooLarge
			}
			if response.Code != want || strings.Contains(response.Body.String(), "whsec_") {
				t.Fatalf("must reject without DB access or secret disclosure: code=%d, body=%s", response.Code, response.Body)
			}
		})
	}
}

func TestWebhookCommitsAndAcknowledgesReplay(t *testing.T) {
	ctx, service, gateway := newReconciliationTest(t)
	for range 2 {
		response := sendBillingWebhook(t, service, billingWebhookBody(t, gateway.customer.ID, "invoice.paid"))
		if response.Code != http.StatusNoContent {
			t.Fatalf("unexpected response: %d %s", response.Code, response.Body)
		}
	}
	assertStripeState(t, ctx, service, "active", "stripe:in_paid", 1, 1)
}

func TestWebhookReturnsRetryableFailure(t *testing.T) {
	ctx, service, gateway := newReconciliationTest(t)
	gateway.fail = true
	response := sendBillingWebhook(t, service, billingWebhookBody(t, gateway.customer.ID, "invoice.paid"))
	if response.Code != http.StatusInternalServerError || response.Body.String() != "billing_sync_failed\n" {
		t.Fatal("upstream failure must be retryable without exposing provider data")
	}
	gateway.fail = false
	if response := sendBillingWebhook(t, service, billingWebhookBody(t, gateway.customer.ID, "invoice.paid")); response.Code != http.StatusNoContent {
		t.Fatal("retry must succeed")
	}
	assertStripeState(t, ctx, service, "active", "stripe:in_paid", 1, 1)
}

func TestWebhookIgnoresUnrelatedEventTypes(t *testing.T) {
	service := &Service{config: ServiceConfig{WebhookSecret: "whsec_endpoint"}}
	if response := sendBillingWebhook(t, service, billingWebhookBody(t, "cus_other", "product.created")); response.Code != http.StatusNoContent {
		t.Fatal("unrelated signed events must be ignored without database access")
	}
}

func billingWebhookBody(t *testing.T, customerID, eventType string) []byte {
	t.Helper()
	body, err := json.Marshal(map[string]any{
		"id": "evt_webhook", "object": "event", "api_version": stripe.APIVersion, "livemode": false,
		"type": eventType, "created": time.Now().Unix(), "data": map[string]any{"object": map[string]any{"id": "in_paid", "customer": customerID}},
	})
	if err != nil {
		t.Fatal(err)
	}
	return body
}

func sendBillingWebhook(t *testing.T, service *Service, body []byte) *httptest.ResponseRecorder {
	t.Helper()
	signed := webhook.GenerateTestSignedPayload(&webhook.UnsignedPayload{Payload: body, Secret: service.config.WebhookSecret})
	request := httptest.NewRequest(http.MethodPost, "/stripe/webhook", bytes.NewReader(body))
	request.Header.Set("Stripe-Signature", signed.Header)
	response := httptest.NewRecorder()
	service.webhook(response, request)
	return response
}
