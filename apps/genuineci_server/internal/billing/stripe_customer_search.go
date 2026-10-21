package billing

import (
	"context"
	"errors"
	"strings"
	"time"

	"github.com/stripe/stripe-go/v87"
)

func findStripeCustomer(ctx context.Context, client *stripe.Client, request stripeCustomerRequest) (*stripe.Customer, error) {
	if client == nil {
		return nil, errors.New("Stripe billing is not configured")
	}
	if strings.TrimSpace(request.TeamID) == "" {
		return nil, errors.New("Stripe Customer team ID must be set")
	}

	ctx, cancel := context.WithTimeout(ctx, 10*time.Second)
	defer cancel()

	teamID := strings.NewReplacer(`\`, `\\`, `"`, `\"`).Replace(request.TeamID)
	params := &stripe.CustomerSearchParams{
		SearchParams: stripe.SearchParams{
			Query: `metadata["team_id"]:"` + teamID + `"`,
			// Two results are enough to detect an ambiguous match.
			Limit: stripe.Int64(2),
		},
	}
	results := client.V1Customers.Search(ctx, params)
	if err := results.Err(); err != nil {
		if ctx.Err() != nil {
			return nil, ctx.Err()
		}
		return nil, errors.New("Stripe Customer search failed")
	}

	// Search is eventually consistent; an empty result cannot authorize creation.
	customers := results.Data()
	if results.Meta().HasMore || len(customers) != 1 {
		return nil, errStripeCustomerReconciliationRequired
	}
	customer := customers[0]
	available := customer != nil && customer.ID != "" && !customer.Deleted
	if !available {
		return nil, errStripeCustomerReconciliationRequired
	}
	matchesTeam := customer.Metadata["team_id"] == request.TeamID &&
		customer.Livemode == request.Livemode
	if !matchesTeam {
		return nil, errStripeCustomerReconciliationRequired
	}
	return customer, nil
}
