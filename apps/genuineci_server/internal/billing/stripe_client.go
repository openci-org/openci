package billing

import (
	"errors"
	"os"
	"strings"

	"github.com/stripe/stripe-go/v87"
)

func NewStripeClient() (*stripe.Client, error) {
	enabled, err := Enabled()
	if err != nil || !enabled {
		return nil, err
	}

	key := strings.TrimSpace(os.Getenv("STRIPE_SECRET_KEY"))
	if key == "" {
		return nil, errors.New("STRIPE_SECRET_KEY must be set when billing is enabled")
	}

	return stripe.NewClient(key), nil
}
