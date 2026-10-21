package billing

import (
	"os"
	"testing"
)

func TestStartTrialDisabled(t *testing.T) {
	for _, tc := range []struct {
		name string
		env  map[string]string
	}{
		{"unset", nil},
		{"flag without cloud mode", map[string]string{"BILLING_ENABLED": "true"}},
		{"self hosted with billing enabled", map[string]string{"SERVER_ACCESS_MODE": "self_hosted", "BILLING_ENABLED": "true"}},
		{"self hosted with invalid flag", map[string]string{"SERVER_ACCESS_MODE": "self_hosted", "BILLING_ENABLED": "invalid"}},
		{"cloud without billing flag", map[string]string{"SERVER_ACCESS_MODE": "cloud"}},
		{"disabled cloud", map[string]string{"SERVER_ACCESS_MODE": "cloud", "BILLING_ENABLED": "false"}},
	} {
		t.Run(tc.name, func(t *testing.T) {
			for _, key := range []string{"SERVER_ACCESS_MODE", "BILLING_ENABLED"} {
				value, set := tc.env[key]
				t.Setenv(key, value)
				if !set {
					if err := os.Unsetenv(key); err != nil {
						t.Fatal(err)
					}
				}
			}
			t.Setenv("BILLING_TRIAL_ALLOWANCE_SECONDS", "invalid")

			// A nil pool ensures disabled billing never accesses the database.
			started, err := StartTrial(t.Context(), nil, TrialStartRequest{})

			if err != nil || started {
				t.Fatalf("disabled billing must not start a trial: started=%v, err=%v", started, err)
			}
		})
	}
}

func TestStartTrialInvalidConfig(t *testing.T) {
	for _, tc := range []struct {
		name, mode, flag, wantErr string
	}{
		{"invalid mode", "invalid", "true", "SERVER_ACCESS_MODE must be self_hosted or cloud"},
		{"invalid flag", "cloud", "invalid", "BILLING_ENABLED must be true or false"},
	} {
		t.Run(tc.name, func(t *testing.T) {
			t.Setenv("SERVER_ACCESS_MODE", tc.mode)
			t.Setenv("BILLING_ENABLED", tc.flag)

			started, err := StartTrial(t.Context(), nil, TrialStartRequest{})

			if started || err == nil || err.Error() != tc.wantErr {
				t.Fatalf("want error %q before accessing the database, got started=%v, err=%v", tc.wantErr, started, err)
			}
		})
	}
}

func TestStartTrialInvalidAllowance(t *testing.T) {
	t.Setenv("SERVER_ACCESS_MODE", "cloud")
	t.Setenv("BILLING_ENABLED", "true")
	t.Setenv("BILLING_TRIAL_ALLOWANCE_SECONDS", "-1")

	started, err := StartTrial(t.Context(), nil, TrialStartRequest{})

	const wantErr = "BILLING_TRIAL_ALLOWANCE_SECONDS must be a non-negative integer"
	if started || err == nil || err.Error() != wantErr {
		t.Fatalf("want error %q before accessing the database, got started=%v, err=%v", wantErr, started, err)
	}
}
