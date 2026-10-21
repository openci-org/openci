package main

import (
	"context"
	"errors"
	"fmt"
	"log"
	"net"
	"net/http"
	"os"
	"strings"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/openci-org/openci/apps/genuineci_server/internal/billing"
)

func main() {
	if err := run(); err != nil {
		log.Fatal(err)
	}
}

func run() error {
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()
	pool, err := pgxpool.New(ctx, os.Getenv("OPENCI_TEST_DATABASE_URL"))
	if err != nil {
		return errors.New("invalid test database configuration")
	}
	defer pool.Close()
	var schema string
	if err := pool.QueryRow(ctx, `SELECT current_schema()`).Scan(&schema); err != nil || !strings.HasPrefix(schema, "billing_bridge_") {
		return errors.New("an isolated billing_bridge_ schema is required")
	}
	for _, ensure := range []func(context.Context, *pgxpool.Pool) error{
		billing.EnsureCustomerCreationsTable, billing.EnsureCheckoutCreationsTable,
		billing.EnsureStripeStateTables, billing.EnsureExecutionsTable, billing.EnsureAdmissionsTable,
	} {
		if err := ensure(ctx, pool); err != nil {
			return err
		}
	}
	listener, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		return err
	}
	defer listener.Close()
	mux := http.NewServeMux()
	billing.RegisterRoutes(mux, pool, nil, &billing.ServiceConfig{InternalToken: os.Getenv("BILLING_INTERNAL_TOKEN")})
	fmt.Println("http://" + listener.Addr().String())
	server := &http.Server{Handler: mux, ReadHeaderTimeout: 5 * time.Second}
	return server.Serve(listener)
}
