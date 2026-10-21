package billing

import (
	"context"
	"errors"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/stripe/stripe-go/v87"
)

func (s *Service) deleteTeam(ctx context.Context, member billingMember) error {
	ctx, cancel := context.WithTimeout(ctx, 40*time.Second)
	defer cancel()
	return withBillingMemberLock(ctx, s.pool, member, func(tx pgx.Tx) error {
		var customerID *string
		var livemode bool
		err := tx.QueryRow(ctx, `
			SELECT stripe_customer_id, livemode FROM billing_customer_creations WHERE team_id = $1
		`, member.TeamID).Scan(&customerID, &livemode)
		if err != nil && !errors.Is(err, pgx.ErrNoRows) {
			return err
		}
		if err == nil {
			if customerID == nil || livemode != s.config.Livemode {
				return errStripeCustomerReconciliationRequired
			}
			customer, err := getOwnedStripeCustomer(ctx, s.stripe, stripeCustomerRequest{
				TeamID: member.TeamID, Livemode: livemode,
			}, *customerID)
			if err != nil {
				return err
			}
			if err := requireNoStripeSubscription(ctx, s.stripe, customer); err != nil {
				return err
			}
		}
		creation, err := getOpenCheckoutCreation(ctx, tx, member.TeamID)
		if err != nil {
			return err
		}
		if creation != nil {
			if customerID == nil || creation.Request.CustomerID != *customerID ||
				creation.Request.Livemode != s.config.Livemode {
				return errStripeCheckoutReconciliationRequired
			}
			if err := s.requireCheckoutEnded(ctx, *creation); err != nil {
				return err
			}
			if _, err := tx.Exec(ctx, `
				UPDATE billing_checkout_creations SET closed_at = $2 WHERE idempotency_key = $1
			`, creation.IdempotencyKey, time.Now().Unix()); err != nil {
				return err
			}
		}
		if _, err := tx.Exec(ctx, "DELETE FROM team_members WHERE team_id = $1", member.TeamID); err != nil {
			return err
		}
		_, err = tx.Exec(ctx, "DELETE FROM teams WHERE id = $1", member.TeamID)
		return err
	})
}

func (s *Service) requireCheckoutEnded(ctx context.Context, creation checkoutCreation) error {
	if creation.StripeCheckoutSessionID == nil {
		return errStripeCheckoutReconciliationRequired
	}
	session, err := getStripeCheckoutSession(ctx, s.stripe, *creation.StripeCheckoutSessionID)
	if err != nil {
		return err
	}
	if err := validateStripeCheckoutIdentity(creation, session); err != nil {
		return err
	}
	if session.ID != *creation.StripeCheckoutSessionID || session.Metadata["checkout_creation_key"] != creation.IdempotencyKey {
		return errStripeCheckoutReconciliationRequired
	}
	switch session.Status {
	case stripe.CheckoutSessionStatusExpired:
		if session.PaymentStatus == stripe.CheckoutSessionPaymentStatusUnpaid && session.Subscription == nil {
			return nil
		}
	case stripe.CheckoutSessionStatusComplete:
		return requireEndedCheckoutSubscription(ctx, s.stripe, creation, session)
	}
	return errStripeCheckoutReconciliationRequired
}
