package billing

import (
	"context"
	"errors"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/stripe/stripe-go/v87"
)

type stripeObservation struct {
	SubscriptionID    string
	Status            string
	PlanID            string
	CancelAtPeriodEnd bool
	Period            *billingPeriod
}

func (s *Service) reconcileStripeEvent(ctx context.Context, event stripe.Event, customerID string) error {
	ctx, cancel := context.WithTimeout(ctx, 40*time.Second)
	defer cancel()
	return pgx.BeginFunc(ctx, s.pool, func(tx pgx.Tx) error {
		var teamID string
		err := tx.QueryRow(ctx, `
			SELECT team_id FROM billing_customer_creations WHERE stripe_customer_id = $1 AND livemode = $2
		`, customerID, s.config.Livemode).Scan(&teamID)
		if errors.Is(err, pgx.ErrNoRows) {
			return nil
		}
		if err != nil {
			return err
		}
		if err := tx.QueryRow(ctx, "SELECT team_id FROM billing_accounts WHERE team_id = $1 FOR UPDATE", teamID).Scan(&teamID); err != nil {
			return err
		}
		var processed bool
		if err := tx.QueryRow(ctx, "SELECT EXISTS (SELECT 1 FROM billing_stripe_events WHERE event_id = $1)", event.ID).Scan(&processed); err != nil {
			return err
		}
		if processed {
			return nil
		}
		observation, err := s.observeStripePurchase(ctx, tx, teamID, customerID)
		if errors.Is(err, errStripePaymentUnverified) || errors.Is(err, errStripeCustomerOwnership) {
			observation, err = stripeObservation{Status: "unverified"}, nil
		}
		if err != nil {
			return err
		}
		if err := s.persistStripeObservation(ctx, tx, teamID, customerID, observation); err != nil {
			return err
		}
		_, err = tx.Exec(ctx, `
			INSERT INTO billing_stripe_events (event_id, event_type, event_created, processed_at) VALUES ($1, $2, $3, $4)
		`, event.ID, string(event.Type), event.Created, time.Now().Unix())
		return err
	})
}

func (s *Service) observeStripePurchase(ctx context.Context, tx pgx.Tx, teamID, customerID string) (stripeObservation, error) {
	observation := stripeObservation{Status: "none"}
	customer, err := getOwnedStripeCustomer(ctx, s.stripe, stripeCustomerRequest{TeamID: teamID, Livemode: s.config.Livemode}, customerID)
	if err != nil {
		return observation, err
	}
	subscription, err := currentStripeSubscription(ctx, s.stripe, customer)
	if err != nil || subscription == nil {
		return observation, err
	}
	if subscription.Metadata["team_id"] != teamID {
		return observation, errStripePaymentUnverified
	}
	observation.SubscriptionID, observation.Status = subscription.ID, string(subscription.Status)
	observation.CancelAtPeriodEnd = subscription.CancelAtPeriodEnd
	if subscription.Status != stripe.SubscriptionStatusActive && subscription.Status != stripe.SubscriptionStatusPastDue {
		return observation, nil
	}
	session, err := subscriptionCheckout(ctx, s.stripe, subscription)
	if err != nil {
		return observation, err
	}
	creation, err := checkoutCreationForWebhook(ctx, tx, teamID, session)
	if err != nil {
		return observation, err
	}
	if err := validateStripePurchase(*creation, subscription); err != nil {
		return observation, err
	}
	observation.PlanID = creation.Request.PlanID
	if subscription.LatestInvoice == nil {
		return observation, errStripePaymentUnverified
	}
	invoice, err := getStripeInvoice(ctx, s.stripe, subscription.LatestInvoice.ID)
	if err != nil {
		return observation, err
	}
	if invoice.Customer == nil || invoice.Customer.ID != customerID || invoice.Livemode != s.config.Livemode ||
		invoice.Parent == nil || invoice.Parent.SubscriptionDetails == nil || invoice.Parent.SubscriptionDetails.Subscription == nil ||
		invoice.Parent.SubscriptionDetails.Subscription.ID != subscription.ID {
		return observation, errStripePaymentUnverified
	}
	if invoice.Status != stripe.InvoiceStatusPaid {
		return observation, nil
	}
	observation.Period, err = verifiedStripePaidPeriod(*creation, subscription, invoice)
	return observation, err
}

func checkoutCreationForWebhook(ctx context.Context, tx pgx.Tx, teamID string, session *stripe.CheckoutSession) (*checkoutCreation, error) {
	var creation checkoutCreation
	var createdAt int64
	err := tx.QueryRow(ctx, `
		SELECT team_id, plan_id, stripe_customer_id, stripe_price_id, success_url, cancel_url,
			livemode, idempotency_key, created_at, stripe_checkout_session_id
		FROM billing_checkout_creations WHERE team_id = $1 AND idempotency_key = $2
	`, teamID, session.Metadata["checkout_creation_key"]).Scan(
		&creation.Request.TeamID, &creation.Request.PlanID, &creation.Request.CustomerID,
		&creation.Request.PriceID, &creation.Request.SuccessURL, &creation.Request.CancelURL,
		&creation.Request.Livemode, &creation.IdempotencyKey, &createdAt, &creation.StripeCheckoutSessionID,
	)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, errStripePaymentUnverified
	}
	if err != nil {
		return nil, err
	}
	creation.CreatedAt = time.Unix(createdAt, 0).UTC()
	if err := validateStripeCheckoutIdentity(creation, session); err != nil {
		return nil, errStripePaymentUnverified
	}
	if creation.StripeCheckoutSessionID != nil && *creation.StripeCheckoutSessionID != session.ID {
		return nil, errStripePaymentUnverified
	}
	_, err = tx.Exec(ctx, "UPDATE billing_checkout_creations SET stripe_checkout_session_id = $2 WHERE idempotency_key = $1", creation.IdempotencyKey, session.ID)
	return &creation, err
}

func (s *Service) persistStripeObservation(ctx context.Context, tx pgx.Tx, teamID, customerID string, observation stripeObservation) error {
	var previousSubscription, previousStatus, previousPlan string
	var previousPeriod *string
	var previousEnd *int64
	err := tx.QueryRow(ctx, `
		SELECT COALESCE(s.stripe_subscription_id, ''), s.subscription_status, COALESCE(s.plan_id, ''), s.paid_period_id, p.ends_at
		FROM billing_stripe_state s LEFT JOIN billing_periods p ON p.id = s.paid_period_id
		WHERE s.team_id = $1
	`, teamID).Scan(&previousSubscription, &previousStatus, &previousPlan, &previousPeriod, &previousEnd)
	if err != nil && !errors.Is(err, pgx.ErrNoRows) {
		return err
	}
	sameSubscription := previousSubscription != "" && previousSubscription == observation.SubscriptionID
	terminal := previousStatus == "canceled" || previousStatus == "incomplete_expired"
	if terminal && (sameSubscription || observation.SubscriptionID == "") && observation.Status != previousStatus {
		return nil
	}
	var periodID *string
	if sameSubscription && observation.Status != "unverified" {
		periodID = previousPeriod
		if observation.PlanID == "" {
			observation.PlanID = previousPlan
		}
	}
	if observation.Period != nil {
		period := *observation.Period
		if err := recordVerifiedPaidPeriod(ctx, tx, period); err != nil {
			return err
		}
		if periodID == nil || previousEnd == nil || period.EndsAt.Unix() >= *previousEnd {
			periodID = &period.ID
		}
	}
	_, err = tx.Exec(ctx, `
		INSERT INTO billing_stripe_state
			(team_id, stripe_customer_id, livemode, stripe_subscription_id, subscription_status, plan_id, paid_period_id, cancel_at_period_end, synced_at)
		VALUES ($1, $2, $3, NULLIF($4, ''), $5, NULLIF($6, ''), $7, $8, $9)
		ON CONFLICT (team_id) DO UPDATE SET
			stripe_customer_id = EXCLUDED.stripe_customer_id, livemode = EXCLUDED.livemode,
			stripe_subscription_id = EXCLUDED.stripe_subscription_id, subscription_status = EXCLUDED.subscription_status,
			plan_id = EXCLUDED.plan_id, paid_period_id = EXCLUDED.paid_period_id,
			cancel_at_period_end = EXCLUDED.cancel_at_period_end, synced_at = EXCLUDED.synced_at
	`, teamID, customerID, s.config.Livemode, observation.SubscriptionID, observation.Status,
		observation.PlanID, periodID, observation.CancelAtPeriodEnd, time.Now().Unix())
	return err
}

func recordVerifiedPaidPeriod(ctx context.Context, tx pgx.Tx, period billingPeriod) error {
	if err := createBillingPeriod(ctx, tx, period); err != nil {
		return err
	}
	var matches bool
	err := tx.QueryRow(ctx, `
		SELECT team_id = $2 AND plan_id = $3 AND period_type = 'paid' AND starts_at = $4 AND ends_at = $5 AND allowance_seconds = $6
		FROM billing_periods WHERE id = $1
	`, period.ID, period.TeamID, period.PlanID, period.StartsAt.Unix(), period.EndsAt.Unix(), period.AllowanceSeconds).Scan(&matches)
	if err != nil {
		return err
	}
	if !matches {
		return errStripePaymentUnverified
	}
	return nil
}
