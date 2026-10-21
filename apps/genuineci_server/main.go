package main

import (
	"context"
	"log"
	"net/http"
	"os"
	"strings"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

func main() {
	enabled, err := billingEnabled()
	if err != nil {
		log.Fatal(err)
	}
	if _, err := trialAllowanceSeconds(); err != nil {
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
		err = ensureBillingTrialClaimsTable(ctx, pool)
		cancel()
		if err != nil {
			pool.Close()
			log.Fatal("Billing trial claim table initialization failed: ", err)
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
