package main

import (
	"context"
	"errors"
	"log/slog"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/gin-gonic/gin"

	"github.com/saqbol/backend/internal/admin"
	"github.com/saqbol/backend/internal/auth"
	"github.com/saqbol/backend/internal/cache"
	"github.com/saqbol/backend/internal/calls"
	"github.com/saqbol/backend/internal/config"
	"github.com/saqbol/backend/internal/history"
	"github.com/saqbol/backend/internal/httpserver"
	"github.com/saqbol/backend/internal/ml"
	"github.com/saqbol/backend/internal/numbers"
	"github.com/saqbol/backend/internal/reports"
	"github.com/saqbol/backend/internal/sms"
	"github.com/saqbol/backend/internal/store"
)

func main() {
	if err := run(); err != nil {
		slog.Error("fatal", "error", err)
		os.Exit(1)
	}
}

func run() error {
	cfg, err := config.Load()
	if err != nil {
		return err
	}

	gin.SetMode(cfg.GinMode)

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	pool, err := store.Connect(ctx, cfg.DatabaseURL)
	if err != nil {
		return err
	}
	defer pool.Close()

	if err := store.Migrate(ctx, pool); err != nil {
		return err
	}

	dataStore := store.New(pool)

	if err := dataStore.Users.PromoteToAdmin(ctx, cfg.AdminPhones); err != nil {
		return err
	}

	redisClient, err := cache.Connect(ctx, cfg.RedisURL)
	if err != nil {
		return err
	}
	defer redisClient.Close()

	var classifier ml.Classifier
	if cfg.MLMock {
		classifier = ml.NewMock(cfg.ScamThreshold, cfg.SuspiciousThreshold)
	} else {
		grpcClassifier, err := ml.NewGRPC(cfg.MLGRPCAddr)
		if err != nil {
			return err
		}
		defer grpcClassifier.Close()
		classifier = grpcClassifier
	}

	tokens := auth.NewTokenManager(cfg.AccessSecret, cfg.RefreshSecret, cfg.AccessTTL, cfg.RefreshTTL)
	authService := auth.NewService(dataStore.Users, redisClient, tokens, cfg.AccessTTL, cfg.RefreshTTL)
	callsService := calls.NewService(classifier, dataStore, cfg.ScamThreshold)

	handlers := httpserver.Handlers{
		Auth:    auth.NewHandler(authService),
		SMS:     sms.NewHandler(sms.NewService(classifier, dataStore)),
		Numbers: numbers.NewHandler(dataStore),
		Reports: reports.NewHandler(dataStore),
		History: history.NewHandler(dataStore),
		Calls:   calls.NewHandler(callsService, tokens),
		Admin:   admin.NewHandler(dataStore),
	}

	engine := httpserver.New(pool, redisClient, tokens, cfg.RateLimitPerMin, handlers)

	server := &http.Server{
		Addr:              ":" + cfg.HTTPPort,
		Handler:           engine,
		ReadHeaderTimeout: 10 * time.Second,
	}

	go func() {
		slog.Info("http server listening", "port", cfg.HTTPPort)
		if err := server.ListenAndServe(); err != nil && !errors.Is(err, http.ErrServerClosed) {
			slog.Error("server error", "error", err)
			cancel()
		}
	}()

	stop := make(chan os.Signal, 1)
	signal.Notify(stop, syscall.SIGINT, syscall.SIGTERM)

	select {
	case <-stop:
	case <-ctx.Done():
	}

	slog.Info("shutting down")
	shutdownCtx, shutdownCancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer shutdownCancel()
	return server.Shutdown(shutdownCtx)
}
