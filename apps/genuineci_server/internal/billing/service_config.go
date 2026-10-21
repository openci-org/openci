package billing

import (
	"errors"
	"net/url"
	"os"
	"strings"
)

type ServiceConfig struct {
	Livemode              bool
	DashboardOrigin       string
	PortalConfigurationID string
	InternalToken         string
	WebhookSecret         string
	LightPriceID          string
	ProPriceID            string
}

func LoadServiceConfig() (*ServiceConfig, error) {
	enabled, err := Enabled()
	if err != nil || !enabled {
		return nil, err
	}
	mode := os.Getenv("STRIPE_LIVEMODE")
	if mode != "true" && mode != "false" {
		return nil, errors.New("STRIPE_LIVEMODE must be true or false when billing is enabled")
	}
	config := &ServiceConfig{
		Livemode:              mode == "true",
		DashboardOrigin:       strings.TrimSpace(os.Getenv("BILLING_DASHBOARD_ORIGIN")),
		PortalConfigurationID: strings.TrimSpace(os.Getenv("STRIPE_PORTAL_CONFIGURATION_ID")),
		InternalToken:         strings.TrimSpace(os.Getenv("BILLING_INTERNAL_TOKEN")),
		WebhookSecret:         strings.TrimSpace(os.Getenv("STRIPE_WEBHOOK_SECRET")),
	}
	origin, err := url.Parse(config.DashboardOrigin)
	if err != nil || origin.Hostname() == "" || origin.User != nil || origin.RawQuery != "" || origin.ForceQuery ||
		strings.Contains(config.DashboardOrigin, "#") || origin.Path != "" && origin.Path != "/" {
		return nil, errors.New("BILLING_DASHBOARD_ORIGIN must be an origin without credentials, path, query, or fragment")
	}
	localHTTP := origin.Scheme == "http" && (origin.Hostname() == "localhost" || origin.Hostname() == "127.0.0.1" || origin.Hostname() == "::1")
	if origin.Scheme != "https" && !localHTTP {
		return nil, errors.New("BILLING_DASHBOARD_ORIGIN requires HTTPS or a loopback HTTP address")
	}
	config.DashboardOrigin = origin.Scheme + "://" + origin.Host
	if config.PortalConfigurationID == "" {
		return nil, errors.New("STRIPE_PORTAL_CONFIGURATION_ID must be set")
	}
	if len(config.InternalToken) < 32 {
		return nil, errors.New("BILLING_INTERNAL_TOKEN must contain at least 32 characters")
	}
	if !strings.HasPrefix(config.WebhookSecret, "whsec_") || len(config.WebhookSecret) <= len("whsec_") {
		return nil, errors.New("STRIPE_WEBHOOK_SECRET must be an endpoint signing secret")
	}
	config.LightPriceID, err = stripeCheckoutPriceID("light")
	if err != nil {
		return nil, err
	}
	config.ProPriceID, err = stripeCheckoutPriceID("pro")
	if err != nil {
		return nil, err
	}
	if config.LightPriceID == config.ProPriceID {
		return nil, errors.New("Light and Pro require distinct Stripe Price IDs")
	}
	return config, nil
}

func (config ServiceConfig) returnURL(teamID, result string) string {
	query := url.Values{"teamId": {teamID}, "result": {result}}
	return config.DashboardOrigin + "/billing?" + query.Encode()
}
