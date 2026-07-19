package config

import (
	"fmt"
	"os"
	"strconv"
	"strings"
	"time"
)

type Config struct {
	HTTPPort            string
	GinMode             string
	DatabaseURL         string
	RedisURL            string
	AccessSecret        string
	RefreshSecret       string
	AccessTTL           time.Duration
	RefreshTTL          time.Duration
	MLMock              bool
	MLGRPCAddr          string
	ScamThreshold       float64
	SuspiciousThreshold float64
	AdminPhones         []string
	RateLimitPerMin     int
}

func Load() (*Config, error) {
	cfg := &Config{
		HTTPPort:            getEnv("HTTP_PORT", "8080"),
		GinMode:             getEnv("GIN_MODE", "debug"),
		DatabaseURL:         getEnv("DATABASE_URL", ""),
		RedisURL:            getEnv("REDIS_URL", ""),
		AccessSecret:        getEnv("JWT_ACCESS_SECRET", ""),
		RefreshSecret:       getEnv("JWT_REFRESH_SECRET", ""),
		AccessTTL:           getEnvDuration("ACCESS_TOKEN_TTL", 15*time.Minute),
		RefreshTTL:          getEnvDuration("REFRESH_TOKEN_TTL", 168*time.Hour),
		MLMock:              getEnvBool("ML_MOCK", true),
		MLGRPCAddr:          getEnv("ML_GRPC_ADDR", "localhost:9090"),
		ScamThreshold:       getEnvFloat("SCAM_THRESHOLD", 0.8),
		SuspiciousThreshold: getEnvFloat("SUSPICIOUS_THRESHOLD", 0.45),
		AdminPhones:         getEnvList("ADMIN_PHONES"),
		RateLimitPerMin:     getEnvInt("RATE_LIMIT_PER_MIN", 60),
	}

	if cfg.DatabaseURL == "" {
		return nil, fmt.Errorf("DATABASE_URL is required")
	}
	if cfg.RedisURL == "" {
		return nil, fmt.Errorf("REDIS_URL is required")
	}
	if cfg.AccessSecret == "" || cfg.RefreshSecret == "" {
		return nil, fmt.Errorf("JWT secrets are required")
	}

	return cfg, nil
}

func getEnv(key, fallback string) string {
	if value, ok := os.LookupEnv(key); ok && value != "" {
		return value
	}
	return fallback
}

func getEnvInt(key string, fallback int) int {
	if value, ok := os.LookupEnv(key); ok {
		parsed, err := strconv.Atoi(value)
		if err == nil {
			return parsed
		}
	}
	return fallback
}

func getEnvList(key string) []string {
	value, ok := os.LookupEnv(key)
	if !ok || value == "" {
		return nil
	}
	parts := strings.Split(value, ",")
	result := make([]string, 0, len(parts))
	for _, part := range parts {
		trimmed := strings.TrimSpace(part)
		if trimmed != "" {
			result = append(result, trimmed)
		}
	}
	return result
}

func getEnvBool(key string, fallback bool) bool {
	if value, ok := os.LookupEnv(key); ok {
		parsed, err := strconv.ParseBool(value)
		if err == nil {
			return parsed
		}
	}
	return fallback
}

func getEnvFloat(key string, fallback float64) float64 {
	if value, ok := os.LookupEnv(key); ok {
		parsed, err := strconv.ParseFloat(value, 64)
		if err == nil {
			return parsed
		}
	}
	return fallback
}

func getEnvDuration(key string, fallback time.Duration) time.Duration {
	if value, ok := os.LookupEnv(key); ok {
		parsed, err := time.ParseDuration(value)
		if err == nil {
			return parsed
		}
	}
	return fallback
}
