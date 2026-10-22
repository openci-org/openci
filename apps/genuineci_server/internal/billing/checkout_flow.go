package billing

import (
	"context"
	"errors"
	"net/url"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/openci-org/openci/apps/genuineci_server/internal/billing/stripeapi"
	"github.com/stripe/stripe-go/v87"
)

var errBillingPlan = errors.New("choose a supported paid billing plan")

func (s *Service) checkout(ctx context.Context, member billingMember, planID string) (string, error) {
	if err := authorizeBillingMember(ctx, s.pool, member); err != nil {
		return "", err
	}
	if s.config.HasComplimentaryPro(member.TeamID) {
		return "", errComplimentaryPro
	}
	priceID := s.config.LightPriceID
	switch planID {
	case "light":
	case "pro":
		priceID = s.config.ProPriceID
	default:
		return "", errBillingPlan
	}
	price, err := stripeapi.GetPrice(ctx, s.stripe, priceID)
	if err != nil {
		return "", err
	}
	if err := validateStripeCheckoutPrice(price, planID, s.config.Livemode); err != nil {
		return "", err
	}
	if price.ID != priceID {
		return "", errors.New("Stripe Price does not match the configured ID")
	}
	owner := stripeCustomerRequest{TeamID: member.TeamID, Livemode: s.config.Livemode}
	customerID, err := ensureStripeCustomer(ctx, s.pool, s.stripe, owner)
	if err != nil {
		return "", err
	}
	customer, err := getOwnedStripeCustomer(ctx, s.stripe, owner, customerID)
	if err != nil {
		return "", err
	}
	if err := requireNoStripeSubscription(ctx, s.stripe, customer); err != nil {
		return "", err
	}
	var previous *checkoutCreation
	err = withBillingMemberLock(ctx, s.pool, member, func(tx pgx.Tx) error {
		var err error
		previous, err = getOpenCheckoutCreation(ctx, tx, member.TeamID)
		return err
	})
	if err != nil {
		return "", err
	}
	if previous != nil {
		if previous.Request.CustomerID != customerID || previous.Request.Livemode != s.config.Livemode {
			return "", errStripeCheckoutReconciliationRequired
		}
		session, err := ensureStripeCheckoutSession(ctx, s.pool, s.stripe, previous.Request)
		if err != nil {
			return "", err
		}
		previous.StripeCheckoutSessionID = &session.ID
		if previous.Request.PlanID == planID && session.Status == stripe.CheckoutSessionStatusOpen {
			return checkoutURL(session)
		}
		if session.Status == stripe.CheckoutSessionStatusComplete {
			if err := s.retireCompletedCheckout(ctx, member, *previous, session); err != nil {
				return "", err
			}
		} else if err := expireCheckoutCreation(ctx, s.pool, s.stripe, *previous); err != nil {
			return "", err
		}
	}
	if err := authorizeBillingMember(ctx, s.pool, member); err != nil {
		return "", err
	}
	if err := requireNoStripeSubscription(ctx, s.stripe, customer); err != nil {
		return "", err
	}
	session, err := ensureStripeCheckoutSession(ctx, s.pool, s.stripe, checkoutCreationRequest{
		TeamID: member.TeamID, PlanID: planID, CustomerID: customerID, PriceID: priceID,
		SuccessURL: s.config.ReturnURL(member.TeamID, "success"),
		CancelURL:  s.config.ReturnURL(member.TeamID, "cancel"), Livemode: s.config.Livemode,
	})
	if err != nil {
		return "", err
	}
	return checkoutURL(session)
}

func checkoutURL(session *stripe.CheckoutSession) (string, error) {
	if session == nil {
		return "", errStripeCheckoutReconciliationRequired
	}
	if session.Status == stripe.CheckoutSessionStatusComplete || session.Subscription != nil {
		return "", errStripeCheckoutCompleted
	}
	location, err := url.Parse(session.URL)
	if err != nil || location.Scheme != "https" || location.Hostname() == "" || location.User != nil ||
		session.Status != stripe.CheckoutSessionStatusOpen || session.ExpiresAt <= time.Now().Unix() {
		return "", errStripeCheckoutReconciliationRequired
	}
	return session.URL, nil
}

func (s *Service) retireCompletedCheckout(ctx context.Context, member billingMember, creation checkoutCreation, session *stripe.CheckoutSession) error {
	if err := requireEndedCheckoutSubscription(ctx, s.stripe, creation, session); err != nil {
		return err
	}
	return withBillingMemberLock(ctx, s.pool, member, func(tx pgx.Tx) error {
		result, err := tx.Exec(ctx, `
			UPDATE billing_checkout_creations SET closed_at = COALESCE(closed_at, $4)
			WHERE team_id = $1 AND idempotency_key = $2 AND stripe_checkout_session_id = $3
		`, member.TeamID, creation.IdempotencyKey, session.ID, time.Now().Unix())
		if err != nil {
			return err
		}
		if result.RowsAffected() != 1 {
			return errStripeCheckoutReconciliationRequired
		}
		return nil
	})
}

func requireEndedCheckoutSubscription(ctx context.Context, client *stripe.Client, creation checkoutCreation, session *stripe.CheckoutSession) error {
	if session.Subscription == nil || session.Subscription.ID == "" {
		return errStripeCheckoutReconciliationRequired
	}
	subscription, err := stripeapi.GetSubscription(ctx, client, session.Subscription.ID)
	if err != nil {
		return err
	}
	if subscription == nil || subscription.ID != session.Subscription.ID || subscription.Customer == nil ||
		subscription.Customer.ID != creation.Request.CustomerID || subscription.Livemode != creation.Request.Livemode ||
		subscription.Metadata["team_id"] != creation.Request.TeamID {
		return errStripeCheckoutReconciliationRequired
	}
	if subscription.Status != stripe.SubscriptionStatusCanceled && subscription.Status != stripe.SubscriptionStatusIncompleteExpired {
		return errStripeSubscriptionExists
	}
	return nil
}
