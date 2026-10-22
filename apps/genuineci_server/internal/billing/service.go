package billing

import (
	"github.com/jackc/pgx/v5/pgxpool"
	billingconfig "github.com/openci-org/openci/apps/genuineci_server/internal/billing/config"
	"github.com/stripe/stripe-go/v87"
)

type Service struct {
	pool   *pgxpool.Pool
	stripe *stripe.Client
	config billingconfig.Config
}
