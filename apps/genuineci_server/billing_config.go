package main

import (
	"errors"
	"os"
	"strconv"
)

func billingEnabled() (bool, error) {
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

func trialAllowanceSeconds() (*int64, error) {
	enabled, err := billingEnabled()
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
