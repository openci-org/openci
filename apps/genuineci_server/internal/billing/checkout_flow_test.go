package billing

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"strings"
	"sync"
	"testing"
	"time"

	billingconfig "github.com/openci-org/openci/apps/genuineci_server/internal/billing/config"
	billingschema "github.com/openci-org/openci/apps/genuineci_server/internal/billing/schema"
	"github.com/openci-org/openci/apps/genuineci_server/internal/testutil"
	"github.com/stripe/stripe-go/v87"
)

func TestCheckoutFlowReusesAndReplacesUnpaidSession(t *testing.T) {
	ctx, service, gateway := newCheckoutFlowTest(t)
	member := billingMember{TeamID: "team-1", UserID: "user-1"}
	first, err := service.checkout(ctx, member, "light")
	if err != nil || first == "" {
		t.Fatalf("first purchase must return a saved Checkout: %v", err)
	}
	member.UserID = "user-2"
	if got, err := service.checkout(ctx, member, "light"); err != nil || got != first {
		t.Fatalf("another member must reuse the team's Checkout: %v", err)
	}
	second, err := service.checkout(ctx, member, "pro")
	if err != nil || second == first || gateway.sessions["cs_1"].Status != stripe.CheckoutSessionStatusExpired {
		t.Fatalf("plan reselection must expire the old Session before replacement: %v", err)
	}
	if gateway.creates != 2 {
		t.Fatalf("want two Sessions, got %d", gateway.creates)
	}
	var active, closed int
	err = service.pool.QueryRow(ctx, `
		SELECT count(*) FILTER (WHERE closed_at IS NULL), count(*) FILTER (WHERE closed_at IS NOT NULL)
		FROM billing_checkout_creations
	`).Scan(&active, &closed)
	if err != nil || active != 1 || closed != 1 {
		t.Fatalf("must retain one current intent and its history: active=%d, closed=%d, err=%v", active, closed, err)
	}
}

func TestCheckoutFlowRejectsUnauthorizedAndUnknownPlan(t *testing.T) {
	for _, tc := range []struct {
		userID, planID string
		want           error
	}{
		{"outsider", "light", errBillingForbidden},
		{"", "light", errBillingForbidden},
		{"user-1", "enterprise", errBillingPlan},
	} {
		t.Run(tc.userID+tc.planID, func(t *testing.T) {
			ctx, service, gateway := newCheckoutFlowTest(t)
			got, err := service.checkout(ctx, billingMember{TeamID: "team-1", UserID: tc.userID}, tc.planID)
			if got != "" || !errors.Is(err, tc.want) || gateway.calls != 0 {
				t.Fatalf("must reject before Stripe access: err=%v, calls=%d", err, gateway.calls)
			}
		})
	}
}

func TestCheckoutFlowBlocksCompletedOrActivePurchase(t *testing.T) {
	for _, state := range []string{"active subscription", "completed during expiry", "completed without subscription"} {
		t.Run(state, func(t *testing.T) {
			ctx, service, gateway := newCheckoutFlowTest(t)
			member := billingMember{TeamID: "team-1", UserID: "user-1"}
			if _, err := service.checkout(ctx, member, "light"); err != nil {
				t.Fatal(err)
			}
			switch state {
			case "active subscription":
				gateway.subscription = checkoutFlowSubscription(stripe.SubscriptionStatusActive)
			case "completed during expiry":
				gateway.completeOnExpiry = true
			case "completed without subscription":
				gateway.sessions["cs_1"].Status = stripe.CheckoutSessionStatusComplete
			}
			if got, err := service.checkout(ctx, member, "pro"); got != "" || err == nil {
				t.Fatal("a completed or existing purchase must block a new Session")
			}
			if gateway.creates != 1 {
				t.Fatal("must not create a competing purchase")
			}
			var open int
			if err := service.pool.QueryRow(ctx, "SELECT count(*) FROM billing_checkout_creations WHERE closed_at IS NULL").Scan(&open); err != nil || open != 1 {
				t.Fatal("the original intent must remain protected")
			}
		})
	}
}

func TestCheckoutFlowAllowsResubscriptionAfterTerminalContract(t *testing.T) {
	for _, status := range []stripe.SubscriptionStatus{stripe.SubscriptionStatusCanceled, stripe.SubscriptionStatusIncompleteExpired} {
		t.Run(string(status), func(t *testing.T) {
			ctx, service, gateway := newCheckoutFlowTest(t)
			member := billingMember{TeamID: "team-1", UserID: "user-1"}
			if _, err := service.checkout(ctx, member, "light"); err != nil {
				t.Fatal(err)
			}
			gateway.subscription = checkoutFlowSubscription(status)
			gateway.sessions["cs_1"].Status = stripe.CheckoutSessionStatusComplete
			gateway.sessions["cs_1"].Subscription = &stripe.Subscription{ID: "sub_team"}
			if got, err := service.checkout(ctx, member, "pro"); got == "" || err != nil || gateway.creates != 2 {
				t.Fatalf("confirmed terminal subscription must allow a new purchase: %v", err)
			}
		})
	}
}

func TestCheckoutFlowConcurrentMembersShareSession(t *testing.T) {
	ctx, service, gateway := newCheckoutFlowTest(t)
	type result struct {
		url string
		err error
	}
	results := make(chan result, 2)
	for _, user := range []string{"user-1", "user-2"} {
		go func() {
			url, err := service.checkout(ctx, billingMember{TeamID: "team-1", UserID: user}, "light")
			results <- result{url, err}
		}()
	}
	for range 2 {
		got := <-results
		if got.err != nil || got.url != "https://checkout.stripe.com/c/pay/cs_1" {
			t.Fatalf("concurrent members must receive the same Session: %v", got)
		}
	}
	if gateway.creates != 1 {
		t.Fatal("concurrent requests must share one Stripe idempotency key")
	}
}

type checkoutFlowGateway struct {
	mu               sync.Mutex
	sessions         map[string]*stripe.CheckoutSession
	keys             map[string]string
	subscription     *stripe.Subscription
	completeOnExpiry bool
	creates, calls   int
}

func newCheckoutFlowTest(t *testing.T) (context.Context, *Service, *checkoutFlowGateway) {
	t.Helper()
	ctx, pool := testutil.NewBillingMemberDB(t)
	if err := billingschema.EnsureCustomerCreationsTable(ctx, pool); err != nil {
		t.Fatal(err)
	}
	testutil.SetBillingEnvironment(t)
	config, err := billingconfig.Load()
	if err != nil {
		t.Fatal(err)
	}
	gateway := &checkoutFlowGateway{sessions: map[string]*stripe.CheckoutSession{}, keys: map[string]string{}}
	client := testutil.NewStripeClient(t, gateway.request)
	return ctx, &Service{pool: pool, stripe: client, config: *config}, gateway
}

func (g *checkoutFlowGateway) request(r *http.Request) (*http.Response, error) {
	g.mu.Lock()
	defer g.mu.Unlock()
	g.calls++
	if err := r.ParseForm(); err != nil {
		return nil, err
	}
	var value any
	switch {
	case strings.HasPrefix(r.URL.Path, "/v1/prices/"):
		price := validStripeCheckoutPrice()
		price.ID = strings.TrimPrefix(r.URL.Path, "/v1/prices/")
		if price.ID == "price_pro" {
			price.UnitAmount = 10000
		}
		value = price
	case strings.HasPrefix(r.URL.Path, "/v1/customers"):
		value = &stripe.Customer{ID: "cus_team", Metadata: map[string]string{"team_id": "team-1"}}
	case r.URL.Path == "/v1/subscriptions":
		data := []*stripe.Subscription{}
		if g.subscription != nil {
			data = append(data, g.subscription)
		}
		value = map[string]any{"object": "list", "data": data, "has_more": false}
	case r.URL.Path == "/v1/subscriptions/sub_team":
		value = g.subscription
	case r.URL.Path == "/v1/checkout/sessions" && r.Method == http.MethodPost:
		key := r.Header.Get("Idempotency-Key")
		if id := g.keys[key]; id != "" {
			value = g.sessions[id]
			break
		}
		g.creates++
		id := fmt.Sprintf("cs_%d", g.creates)
		g.keys[key] = id
		g.sessions[id] = &stripe.CheckoutSession{
			ID: id, Mode: stripe.CheckoutSessionModeSubscription, UIMode: stripe.CheckoutSessionUIModeHostedPage,
			Customer: &stripe.Customer{ID: r.Form.Get("customer")}, ClientReferenceID: r.Form.Get("client_reference_id"),
			Metadata:   map[string]string{"team_id": r.Form.Get("metadata[team_id]"), "checkout_creation_key": key},
			SuccessURL: r.Form.Get("success_url"), CancelURL: r.Form.Get("cancel_url"),
			URL: "https://checkout.stripe.com/c/pay/" + id, Status: stripe.CheckoutSessionStatusOpen,
			PaymentStatus: stripe.CheckoutSessionPaymentStatusUnpaid, ExpiresAt: time.Now().Add(time.Hour).Unix(),
		}
		value = g.sessions[id]
	case strings.HasPrefix(r.URL.Path, "/v1/checkout/sessions/"):
		id := strings.TrimSuffix(strings.TrimPrefix(r.URL.Path, "/v1/checkout/sessions/"), "/expire")
		session := g.sessions[id]
		if session == nil {
			return nil, errors.New("unknown test Session")
		}
		if strings.HasSuffix(r.URL.Path, "/expire") {
			if g.completeOnExpiry {
				session.Status = stripe.CheckoutSessionStatusComplete
			} else {
				session.Status = stripe.CheckoutSessionStatusExpired
			}
		}
		value = session
	default:
		return nil, fmt.Errorf("unexpected Stripe test request %s %s", r.Method, r.URL.Path)
	}
	body, err := json.Marshal(value)
	if err != nil {
		return nil, err
	}
	return testutil.StripeResponse(http.StatusOK, string(body)), nil
}

func checkoutFlowSubscription(status stripe.SubscriptionStatus) *stripe.Subscription {
	return &stripe.Subscription{ID: "sub_team", Customer: &stripe.Customer{ID: "cus_team"},
		Metadata: map[string]string{"team_id": "team-1"}, Status: status}
}
