// Read-only parser probe. No connection, migration or SQL execution occurs.
package main

import (
	"fmt"
	"net/url"
	"strings"

	"github.com/jackc/pgx/v5/pgxpool"
)

// Exact logic copied from PR21 integration/setup_test.go:87-96.
func requireTestDatabase(databaseURL string) error {
	parsed, err := url.Parse(databaseURL)
	if err != nil {
		return fmt.Errorf("TEST_DATABASE_URL: %w", err)
	}
	if name := strings.TrimPrefix(parsed.Path, "/"); !strings.Contains(name, "test") {
		return fmt.Errorf("TEST_DATABASE_URL points at %q; the integration tests truncate every table, so the database name must contain \"test\"", name)
	}
	return nil
}

func main() {
	for _, raw := range []string{
		"postgres://probe@127.0.0.1/saqbol_test?sslmode=disable",
		"postgres://probe@127.0.0.1/saqbol_test?dbname=saqbol&sslmode=disable",
		"postgres://probe@127.0.0.1/saqbol_test?database=saqbol&sslmode=disable",
	} {
		parsed, err := pgxpool.ParseConfig(raw)
		if err != nil {
			panic(err)
		}
		fmt.Printf("guard_accepted=%t actual_pgx_database=%q\n", requireTestDatabase(raw) == nil, parsed.ConnConfig.Database)
	}
}
