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
)

func main() {
	enabled, err := billing.Enabled()
	if err != nil {
		log.Fatal(err)
	}
	if _, err := billing.TrialAllowanceSeconds(); err != nil {
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
		err = billing.EnsureTrialClaimsTable(ctx, pool)
		if err == nil {
			err = billing.EnsureCustomerCreationsTable(ctx, pool)
		}
		if err == nil {
			err = billing.EnsureCheckoutCreationsTable(ctx, pool)
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

	log.Println("Starting GenuineCI server on :8081")
	err = http.ListenAndServe(":8081", mux)
	pool.Close()
	log.Fatal(err)
}
