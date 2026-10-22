// Package integration runs the HTTP API end to end against real PostgreSQL and
// Redis with the mock classifier. It needs TEST_DATABASE_URL and
// TEST_REDIS_URL; without them the tests are skipped. Every test wipes both
// stores, so the database name must contain "test".
package integration

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/http/httptest"
	"net/url"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/redis/go-redis/v9"

	"github.com/saqbol/backend/internal/admin"
	"github.com/saqbol/backend/internal/auth"
	"github.com/saqbol/backend/internal/cache"
	"github.com/saqbol/backend/internal/calls"
	"github.com/saqbol/backend/internal/history"
	"github.com/saqbol/backend/internal/httpserver"
	"github.com/saqbol/backend/internal/ml"
	"github.com/saqbol/backend/internal/numbers"
	"github.com/saqbol/backend/internal/reports"
	"github.com/saqbol/backend/internal/sms"
	"github.com/saqbol/backend/internal/store"
)

const (
	scamThreshold       = 0.8
	suspiciousThreshold = 0.45
	scamText            = "Служба безопасности банка: ваша карта заблокирована, назовите код из смс"
	safeText            = "Привет, встречаемся завтра в 7 у кафе"
)

var (
	pool        *pgxpool.Pool
	redisClient *redis.Client
	dataStore   *store.Store
)

func TestMain(m *testing.M) {
	databaseURL, redisURL := os.Getenv("TEST_DATABASE_URL"), os.Getenv("TEST_REDIS_URL")
	if databaseURL == "" || redisURL == "" {
		fmt.Println("integration tests skipped: set TEST_DATABASE_URL and TEST_REDIS_URL")
		os.Exit(0)
	}
	if err := requireTestDatabase(databaseURL); err != nil {
		fmt.Println(err)
		os.Exit(1)
	}

	ctx := context.Background()
	var err error
	if pool, err = store.Connect(ctx, databaseURL); err != nil {
		fmt.Println("connect postgres:", err)
		os.Exit(1)
	}
	if err = store.Migrate(ctx, pool); err != nil {
		fmt.Println("migrate:", err)
		os.Exit(1)
	}
	if redisClient, err = cache.Connect(ctx, redisURL); err != nil {
		fmt.Println("connect redis:", err)
		os.Exit(1)
	}
	dataStore = store.New(pool)
	gin.SetMode(gin.TestMode)

	code := m.Run()
	redisClient.Close()
	pool.Close()
	os.Exit(code)
}

// requireTestDatabase refuses to wipe a database whose name does not say it is
// for tests, so a dev or demo database cannot be truncated by accident.
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

type api struct {
	t      *testing.T
	server *httptest.Server
}

// newAPI starts the full router on a clean database. rateLimit 0 disables the
// limiter, as in a local run with RATE_LIMIT_PER_MIN=0.
func newAPI(t *testing.T, rateLimit int) *api {
	t.Helper()
	ctx := context.Background()
	if _, err := pool.Exec(ctx, `TRUNCATE users, messages, detections, call_sessions, reports, numbers, model_versions CASCADE`); err != nil {
		t.Fatalf("truncate: %v", err)
	}
	if err := redisClient.FlushDB(ctx).Err(); err != nil {
		t.Fatalf("flush redis: %v", err)
	}

	tokens := auth.NewTokenManager("test-access-secret", "test-refresh-secret", 15*time.Minute, time.Hour)
	classifier := ml.NewMock(scamThreshold, suspiciousThreshold)
	callsService := calls.NewService(classifier, dataStore, scamThreshold)
	handlers := httpserver.Handlers{
		Auth:    auth.NewHandler(auth.NewService(dataStore.Users, redisClient, tokens, 15*time.Minute, time.Hour)),
		SMS:     sms.NewHandler(sms.NewService(classifier, dataStore)),
		Numbers: numbers.NewHandler(dataStore),
		Reports: reports.NewHandler(dataStore),
		History: history.NewHandler(dataStore),
		Calls:   calls.NewHandler(callsService, tokens),
		Admin:   admin.NewHandler(dataStore),
	}

	server := httptest.NewServer(httpserver.New(pool, redisClient, tokens, rateLimit, handlers))
	t.Cleanup(server.Close)
	return &api{t: t, server: server}
}

type response struct {
	status int
	body   map[string]any
}

func (a *api) call(method, path, token string, body any) response {
	a.t.Helper()
	var reader io.Reader
	if body != nil {
		encoded, err := json.Marshal(body)
		if err != nil {
			a.t.Fatalf("encode body: %v", err)
		}
		reader = bytes.NewReader(encoded)
	}
	req, err := http.NewRequest(method, a.server.URL+path, reader)
	if err != nil {
		a.t.Fatalf("build request: %v", err)
	}
	req.Header.Set("Content-Type", "application/json")
	if token != "" {
		req.Header.Set("Authorization", "Bearer "+token)
	}
	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		a.t.Fatalf("%s %s: %v", method, path, err)
	}
	defer resp.Body.Close()

	decoded := map[string]any{}
	raw, _ := io.ReadAll(resp.Body)
	if len(raw) > 0 {
		_ = json.Unmarshal(raw, &decoded)
	}
	return response{status: resp.StatusCode, body: decoded}
}

func (a *api) expect(r response, status int) map[string]any {
	a.t.Helper()
	if r.status != status {
		a.t.Fatalf("expected HTTP %d, got %d: %v", status, r.status, r.body)
	}
	return r.body
}

// register creates a user and returns its access and refresh tokens.
func (a *api) register(phone string) (access, refresh string) {
	a.t.Helper()
	body := a.expect(a.call("POST", "/api/v1/auth/register", "", map[string]string{
		"phone": phone, "password": "secret123", "name": "Test",
	}), http.StatusCreated)
	return body["access_token"].(string), body["refresh_token"].(string)
}

// admin registers a user, promotes it and logs in again, because the role is
// read into the access token at login.
func (a *api) admin(phone string) string {
	a.t.Helper()
	a.register(phone)
	if err := dataStore.Users.PromoteToAdmin(context.Background(), []string{phone}); err != nil {
		a.t.Fatalf("promote: %v", err)
	}
	body := a.expect(a.call("POST", "/api/v1/auth/login", "", map[string]string{
		"phone": phone, "password": "secret123",
	}), http.StatusOK)
	return body["access_token"].(string)
}

func items(t *testing.T, body map[string]any) []any {
	t.Helper()
	list, ok := body["items"].([]any)
	if !ok {
		t.Fatalf("expected an items list, got %v", body)
	}
	return list
}
