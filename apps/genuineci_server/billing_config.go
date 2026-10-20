package main

import (
	"errors"
	"os"
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
