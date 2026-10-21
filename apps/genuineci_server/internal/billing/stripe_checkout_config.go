package billing

import (
	"errors"
	"fmt"
	"os"
	"strings"
)

func stripeCheckoutPriceID(planID string) (string, error) {
	enabled, err := Enabled()
	if err != nil || !enabled {
		return "", err
	}

	var key string
	switch planID {
	case "light":
		key = "STRIPE_LIGHT_PRICE_ID"
	case "pro":
		key = "STRIPE_PRO_PRICE_ID"
	default:
		return "", errors.New("unknown paid billing plan")
	}

	priceID := strings.TrimSpace(os.Getenv(key))
	if priceID == "" {
		return "", fmt.Errorf("%s must be set when billing is enabled", key)
	}
	return priceID, nil
}
