package billing

import (
	"encoding/json"
	"errors"
	"net/http"
	"testing"

	"github.com/openci-org/openci/apps/genuineci_server/internal/testutil"
	"github.com/stripe/stripe-go/v87"
)

func TestPortalFlowUsesRecordedTeamCustomer(t *testing.T) {
	ctx, service, _ := newCheckoutFlowTest(t)
	member := billingMember{TeamID: "team-1", UserID: "user-1"}
	if _, err := service.checkout(ctx, member, "light"); err != nil {
		t.Fatal(err)
	}
	created := 0
	service.stripe = testutil.NewStripeClient(t, func(r *http.Request) (*http.Response, error) {
		switch r.URL.Path {
		case "/v1/customers/cus_team":
			return testutil.StripeResponse(http.StatusOK, `{"id":"cus_team","metadata":{"team_id":"team-1"}}`), nil
		case "/v1/billing_portal/configurations/bpc_team":
			return testutil.PortalConfigurationResponse(t, testutil.PortalConfiguration()), nil
		case "/v1/billing_portal/sessions":
			created++
			if err := r.ParseForm(); err != nil {
				t.Fatal(err)
			}
			if r.Form.Get("customer") != "cus_team" || r.Form.Get("return_url") != service.config.ReturnURL("team-1", "portal") {
				t.Fatal("Customer and return URL must come from server state")
			}
			body, err := json.Marshal(&stripe.BillingPortalSession{
				ID: "bps_team", Customer: "cus_team", Configuration: &stripe.BillingPortalConfiguration{ID: "bpc_team"},
				ReturnURL: r.Form.Get("return_url"), URL: "https://billing.stripe.com/p/session/test",
			})
			if err != nil {
				t.Fatal(err)
			}
			return testutil.StripeResponse(http.StatusOK, string(body)), nil
		default:
			t.Fatalf("unexpected request: %s", r.URL.Path)
			return nil, nil
		}
	})
	for _, user := range []string{"user-1", "user-2"} {
		member.UserID = user
		if got, err := service.portal(ctx, member); err != nil || got != "https://billing.stripe.com/p/session/test" {
			t.Fatalf("every current member must be able to manage billing: %v", err)
		}
	}
	if created != 2 {
		t.Fatal("Portal sessions should be created per authorized visit")
	}
}

func TestPortalFlowRejectsMissingCustomerAndNonmember(t *testing.T) {
	for _, tc := range []struct {
		user string
		want error
	}{
		{"user-1", errBillingCustomerMissing}, {"outsider", errBillingForbidden},
	} {
		t.Run(tc.user, func(t *testing.T) {
			ctx, service, gateway := newCheckoutFlowTest(t)
			got, err := service.portal(ctx, billingMember{TeamID: "team-1", UserID: tc.user})
			if got != "" || !errors.Is(err, tc.want) || gateway.calls != 0 {
				t.Fatalf("must not create a Customer or access Stripe: %v", err)
			}
		})
	}
}
