package billing

import (
	"errors"
	"os"
	"strconv"
)

// Enabled reports whether billing is enabled in a Cloud environment.
func Enabled() (bool, error) {
	mode, set := os.LookupEnv("SERVER_ACCESS_MODE")
	if !set || mode == "self_hosted" {
		return false, nil
	}
	if mode != "cloud" {
		return false, errors.New("SERVER_ACCESS_MODE must be self_hosted or cloud")
	}

	enabled, set := os.LookupEnv("BILLING_ENABLED")
	if !set || enabled == "false" {
		return false, nil
	}
	if enabled != "true" {
		return false, errors.New("BILLING_ENABLED must be true or false")
	}
	return true, nil
}

// TrialAllowanceSeconds returns the configured trial allowance, or nil when
// billing is disabled or the allowance is unset.
func TrialAllowanceSeconds() (*int64, error) {
	enabled, err := Enabled()
	if err != nil || !enabled {
		return nil, err
	}

	value, set := os.LookupEnv("BILLING_TRIAL_ALLOWANCE_SECONDS")
	if !set {
		return nil, nil
	}
	seconds, err := strconv.ParseInt(value, 10, 64)
	if err != nil || seconds < 0 {
		return nil, errors.New("BILLING_TRIAL_ALLOWANCE_SECONDS must be a non-negative integer")
	}
	return &seconds, nil
}
