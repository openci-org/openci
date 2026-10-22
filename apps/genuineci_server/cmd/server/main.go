package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"strings"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/openci-org/openci/apps/genuineci_server/internal/billing"
	billingconfig "github.com/openci-org/openci/apps/genuineci_server/internal/billing/config"
	billingschema "github.com/openci-org/openci/apps/genuineci_server/internal/billing/schema"
	"github.com/openci-org/openci/apps/genuineci_server/internal/billing/stripeapi"
)

func main() {
	enabled, err := billingconfig.Enabled()
	if err != nil {
		log.Fatal(err)
	}
	if _, err := billingconfig.TrialAllowanceSeconds(); err != nil {
		log.Fatal(err)
	}
	config, err := billingconfig.Load()
	if err != nil {
		log.Fatal(err)
	}
	stripeClient, err := stripeapi.NewClient()
	if err != nil {
		log.Fatal(err)
	}

	databaseURL := strings.TrimSpace(os.Getenv("DATABASE_URL"))
	if databaseURL == "" {
		log.Fatal("DATABASE_URL must be set")
	}

	pool, err := pgxpool.New(context.Background(), databaseURL)
	if err != nil {
		log.Fatal("Invalid DATABASE_URL")
	}

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	err = pool.Ping(ctx)
	cancel()
	if err != nil {
		pool.Close()
		log.Fatal("PostgreSQL connection check failed")
	}

	if enabled {
		ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
		err = billingschema.EnsureTrialClaimsTable(ctx, pool)
		if err == nil {
			err = billingschema.EnsureCustomerCreationsTable(ctx, pool)
		}
		if err == nil {
			err = billingschema.EnsureCheckoutCreationsTable(ctx, pool)
		}
		if err == nil {
			err = billingschema.EnsureStripeStateTables(ctx, pool)
		}
		if err == nil {
			err = billingschema.EnsureExecutionsTable(ctx, pool)
		}
		if err == nil {
			err = billingschema.EnsureAdmissionsTable(ctx, pool)
		}
		cancel()
		if err != nil {
			pool.Close()
			log.Fatal("Billing table initialization failed: ", err)
		}
	}

	mux := http.NewServeMux()
	mux.HandleFunc("GET /healthz", func(w http.ResponseWriter, _ *http.Request) {
		w.Header().Set("Content-Type", "application/json")
		_, _ = w.Write([]byte("{\"status\":\"ok\"}\n"))
	})
	billing.RegisterRoutes(mux, pool, stripeClient, config)

	log.Println("Starting GenuineCI server on :8081")
	server := &http.Server{
		Addr: ":8081", Handler: mux, ReadHeaderTimeout: 5 * time.Second,
		ReadTimeout: 10 * time.Second, WriteTimeout: 60 * time.Second, IdleTimeout: 60 * time.Second,
	}
	err = server.ListenAndServe()
	pool.Close()
	log.Fatal(err)
}
