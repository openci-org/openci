// Package stripeapi wraps Stripe SDK calls with bounded requests and sanitized errors.
package stripeapi

import (
	"errors"
	"os"
	"strings"

	billingconfig "github.com/openci-org/openci/apps/genuineci_server/internal/billing/config"
	"github.com/stripe/stripe-go/v87"
)

// NewClient constructs a Stripe client without making requests, or returns nil when billing is disabled.
func NewClient() (*stripe.Client, error) {
	enabled, err := billingconfig.Enabled()
	if err != nil || !enabled {
		return nil, err
	}

	key := strings.TrimSpace(os.Getenv("STRIPE_SECRET_KEY"))
	if key == "" {
		return nil, errors.New("STRIPE_SECRET_KEY must be set when billing is enabled")
	}

	backends := stripe.NewBackendsWithConfig(&stripe.BackendConfig{
		// Request failures are sanitized by the billing operations before logging.
		LeveledLogger: &stripe.LeveledLogger{Level: stripe.LevelNull},
	})
	return stripe.NewClient(key, stripe.WithBackends(backends)), nil
}
