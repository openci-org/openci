package billing

import (
	"context"
	"errors"

	"github.com/jackc/pgx/v5"
	"github.com/openci-org/openci/apps/genuineci_server/internal/billing/stripeapi"
)

var errBillingCustomerMissing = errors.New("the team does not have a Stripe Customer yet")

func (s *Service) portal(ctx context.Context, member billingMember) (string, error) {
	var customerID *string
	var livemode bool
	err := withBillingMemberLock(ctx, s.pool, member, func(tx pgx.Tx) error {
		err := tx.QueryRow(ctx, `
			SELECT stripe_customer_id, livemode FROM billing_customer_creations WHERE team_id = $1
		`, member.TeamID).Scan(&customerID, &livemode)
		if errors.Is(err, pgx.ErrNoRows) {
			return errBillingCustomerMissing
		}
		return err
	})
	if err != nil {
		return "", err
	}
	if customerID == nil {
		return "", errBillingCustomerMissing
	}
	if livemode != s.config.Livemode {
		return "", errors.New("Stripe Customer mode does not match the configured mode")
	}
	owner := stripeCustomerRequest{TeamID: member.TeamID, Livemode: livemode}
	if _, err := getOwnedStripeCustomer(ctx, s.stripe, owner, *customerID); err != nil {
		return "", err
	}
	if err := authorizeBillingMember(ctx, s.pool, member); err != nil {
		return "", err
	}
	session, err := stripeapi.CreatePortalSession(ctx, s.stripe, stripeapi.PortalRequest{
		CustomerID: *customerID, ConfigurationID: s.config.PortalConfigurationID,
		ReturnURL: s.config.ReturnURL(member.TeamID, "portal"), Livemode: livemode,
	})
	if err != nil {
		return "", err
	}
	return session.URL, nil
}
