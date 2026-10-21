package billing

import (
	"context"
	"crypto/subtle"
	"encoding/json"
	"errors"
	"io"
	"net/http"
	"strings"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/stripe/stripe-go/v87"
)

func RegisterRoutes(mux *http.ServeMux, pool *pgxpool.Pool, client *stripe.Client, config *ServiceConfig) {
	if config == nil {
		return
	}
	s := &Service{pool: pool, stripe: client, config: *config}
	mux.HandleFunc("POST /stripe/webhook", s.webhook)
	mux.Handle("GET /internal/billing/teams/{teamID}", s.internal(s.handleStatus))
	mux.Handle("DELETE /internal/billing/teams/{teamID}", s.internal(s.handleTeamDeletion))
	mux.Handle("POST /internal/billing/teams/{teamID}/checkout", s.internal(s.handleCheckout))
	mux.Handle("POST /internal/billing/teams/{teamID}/portal", s.internal(s.handlePortal))
}

func (s *Service) internal(action func(http.ResponseWriter, *http.Request, billingMember)) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Cache-Control", "no-store")
		w.Header().Set("Content-Type", "application/json")
		expected := "Bearer " + s.config.InternalToken
		if len(s.config.InternalToken) < 32 || subtle.ConstantTimeCompare([]byte(r.Header.Get("Authorization")), []byte(expected)) != 1 {
			writeBillingJSON(w, http.StatusUnauthorized, map[string]string{"error": "unauthorized"})
			return
		}
		member := billingMember{TeamID: r.PathValue("teamID"), UserID: strings.TrimSpace(r.Header.Get("X-GenuineCI-User-ID"))}
		if member.UserID == "" {
			writeBillingJSON(w, http.StatusUnauthorized, map[string]string{"error": "unauthorized"})
			return
		}
		ctx, cancel := context.WithTimeout(r.Context(), 55*time.Second)
		defer cancel()
		action(w, r.WithContext(ctx), member)
	})
}

func (s *Service) handleStatus(w http.ResponseWriter, r *http.Request, member billingMember) {
	status, err := s.status(r.Context(), member)
	if err != nil {
		writeBillingError(w, err)
		return
	}
	writeBillingJSON(w, http.StatusOK, status)
}

func (s *Service) handleTeamDeletion(w http.ResponseWriter, r *http.Request, member billingMember) {
	if !readBillingJSON(w, r, &struct{}{}, true) {
		return
	}
	if err := s.deleteTeam(r.Context(), member); err != nil {
		writeBillingError(w, err)
		return
	}
	writeBillingJSON(w, http.StatusOK, map[string]bool{"success": true})
}

func (s *Service) handleCheckout(w http.ResponseWriter, r *http.Request, member billingMember) {
	var request struct {
		PlanID string `json:"planId"`
	}
	if !readBillingJSON(w, r, &request, false) {
		return
	}
	url, err := s.checkout(r.Context(), member, request.PlanID)
	if err != nil {
		writeBillingError(w, err)
		return
	}
	writeBillingJSON(w, http.StatusOK, map[string]string{"url": url})
}

func (s *Service) handlePortal(w http.ResponseWriter, r *http.Request, member billingMember) {
	if !readBillingJSON(w, r, &struct{}{}, true) {
		return
	}
	url, err := s.portal(r.Context(), member)
	if err != nil {
		writeBillingError(w, err)
		return
	}
	writeBillingJSON(w, http.StatusOK, map[string]string{"url": url})
}

func readBillingJSON(w http.ResponseWriter, r *http.Request, value any, allowEmpty bool) bool {
	decoder := json.NewDecoder(http.MaxBytesReader(w, r.Body, 4096))
	decoder.DisallowUnknownFields()
	err := decoder.Decode(value)
	if allowEmpty && errors.Is(err, io.EOF) {
		return true
	}
	if err != nil || decoder.Decode(&struct{}{}) != io.EOF {
		writeBillingJSON(w, http.StatusBadRequest, map[string]string{"error": "invalid_request"})
		return false
	}
	return true
}

func writeBillingError(w http.ResponseWriter, err error) {
	status, code := http.StatusServiceUnavailable, "billing_unavailable"
	switch {
	case errors.Is(err, errBillingForbidden):
		status, code = http.StatusForbidden, "forbidden"
	case errors.Is(err, errBillingPlan):
		status, code = http.StatusBadRequest, "invalid_plan"
	case errors.Is(err, errBillingCustomerMissing):
		status, code = http.StatusConflict, "customer_missing"
	case errors.Is(err, errStripeSubscriptionExists), errors.Is(err, errStripeCheckoutCompleted):
		status, code = http.StatusConflict, "subscription_exists"
	case errors.Is(err, errCheckoutCreationConflict):
		status, code = http.StatusConflict, "checkout_conflict"
	case errors.Is(err, errStripeCustomerReconciliationRequired), errors.Is(err, errStripeCheckoutReconciliationRequired):
		status, code = http.StatusConflict, "payment_pending"
	case errors.Is(err, context.DeadlineExceeded):
		status, code = http.StatusGatewayTimeout, "billing_timeout"
	}
	writeBillingJSON(w, status, map[string]string{"error": code})
}

func writeBillingJSON(w http.ResponseWriter, status int, body any) {
	w.WriteHeader(status)
	_ = json.NewEncoder(w).Encode(body)
}
