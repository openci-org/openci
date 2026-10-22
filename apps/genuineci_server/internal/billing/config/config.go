// Package config reads and validates the server-owned billing configuration.
package config

import (
	"errors"
	"net/url"
	"os"
	"slices"
	"strings"
	"unicode"
)

// Config contains the settings required by an enabled billing service.
type Config struct {
	Livemode                bool
	DashboardOrigin         string
	PortalConfigurationID   string
	InternalToken           string
	WebhookSecret           string
	LightPriceID            string
	ProPriceID              string
	ComplimentaryProTeamIDs []string
}

// Load validates billing settings, returning nil when billing is disabled.
func Load() (*Config, error) {
	enabled, err := Enabled()
	if err != nil || !enabled {
		return nil, err
	}
	mode := os.Getenv("STRIPE_LIVEMODE")
	if mode != "true" && mode != "false" {
		return nil, errors.New("STRIPE_LIVEMODE must be true or false when billing is enabled")
	}
	config := &Config{
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
	config.LightPriceID, err = CheckoutPriceID("light")
	if err != nil {
		return nil, err
	}
	config.ProPriceID, err = CheckoutPriceID("pro")
	if err != nil {
		return nil, err
	}
	if config.LightPriceID == config.ProPriceID {
		return nil, errors.New("Light and Pro require distinct Stripe Price IDs")
	}
	if value := strings.TrimSpace(os.Getenv("BILLING_COMPLIMENTARY_PRO_TEAM_IDS")); value != "" {
		for _, value := range strings.Split(value, ",") {
			teamID := strings.TrimSpace(value)
			if teamID == "" || strings.ContainsFunc(teamID, func(r rune) bool { return unicode.IsSpace(r) || unicode.IsControl(r) }) {
				return nil, errors.New("BILLING_COMPLIMENTARY_PRO_TEAM_IDS must contain comma-separated nonempty team IDs")
			}
			config.ComplimentaryProTeamIDs = append(config.ComplimentaryProTeamIDs, teamID)
		}
	}
	return config, nil
}

// HasComplimentaryPro reports whether the team is explicitly configured for complimentary Pro.
func (config Config) HasComplimentaryPro(teamID string) bool {
	return teamID != "" && slices.Contains(config.ComplimentaryProTeamIDs, teamID)
}

// ReturnURL encodes the team and result under the configured dashboard origin.
func (config Config) ReturnURL(teamID, result string) string {
	query := url.Values{"teamId": {teamID}, "result": {result}}
	return config.DashboardOrigin + "/billing?" + query.Encode()
}
