package billing

import (
	"encoding/json"
	"errors"
	"io"
	"net/http"

	"github.com/stripe/stripe-go/v87"
	"github.com/stripe/stripe-go/v87/webhook"
)

func (s *Service) webhook(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		w.Header().Set("Allow", http.MethodPost)
		http.Error(w, "method_not_allowed", http.StatusMethodNotAllowed)
		return
	}
	body, err := io.ReadAll(http.MaxBytesReader(w, r.Body, 1<<20))
	if err != nil {
		var tooLarge *http.MaxBytesError
		if errors.As(err, &tooLarge) {
			http.Error(w, "body_too_large", http.StatusRequestEntityTooLarge)
		} else {
			http.Error(w, "invalid_webhook", http.StatusBadRequest)
		}
		return
	}
	event, err := webhook.ConstructEvent(body, r.Header.Get("Stripe-Signature"), s.config.WebhookSecret)
	if err != nil || event.ID == "" || event.Livemode != s.config.Livemode || event.Account != "" {
		http.Error(w, "invalid_webhook", http.StatusBadRequest)
		return
	}
	if !isBillingStripeEvent(event.Type) {
		w.WriteHeader(http.StatusNoContent)
		return
	}
	var object struct {
		ID       string           `json:"id"`
		Customer *stripe.Customer `json:"customer"`
	}
	if event.Data == nil || json.Unmarshal(event.Data.Raw, &object) != nil {
		http.Error(w, "invalid_webhook", http.StatusBadRequest)
		return
	}
	customerID := ""
	if object.Customer != nil {
		customerID = object.Customer.ID
	}
	if event.Type == stripe.EventTypeCustomerDeleted {
		customerID = object.ID
	}
	if customerID == "" {
		http.Error(w, "invalid_webhook", http.StatusBadRequest)
		return
	}
	if err := s.reconcileStripeEvent(r.Context(), event, customerID); err != nil {
		http.Error(w, "billing_sync_failed", http.StatusInternalServerError)
		return
	}
	w.WriteHeader(http.StatusNoContent)
}

func isBillingStripeEvent(eventType stripe.EventType) bool {
	switch eventType {
	case stripe.EventTypeCheckoutSessionCompleted, stripe.EventTypeCheckoutSessionExpired,
		stripe.EventTypeCustomerSubscriptionCreated, stripe.EventTypeCustomerSubscriptionUpdated,
		stripe.EventTypeCustomerSubscriptionDeleted, stripe.EventTypeCustomerSubscriptionPaused,
		stripe.EventTypeCustomerSubscriptionResumed, stripe.EventTypeInvoicePaid,
		stripe.EventTypeInvoicePaymentFailed, stripe.EventTypeInvoicePaymentActionRequired,
		stripe.EventTypeInvoiceMarkedUncollectible, stripe.EventTypeInvoiceVoided, stripe.EventTypeCustomerDeleted:
		return true
	default:
		return false
	}
}
