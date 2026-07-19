package store

import (
	"context"
	"errors"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

var ErrNotFound = errors.New("record not found")

type Store struct {
	pool *pgxpool.Pool

	Users      *UserRepo
	Messages   *MessageRepo
	Detections *DetectionRepo
	Numbers    *NumberRepo
	Reports    *ReportRepo
	Calls      *CallRepo
	Categories    *CategoryRepo
	Metrics       *MetricsRepo
	ModelVersions *ModelVersionRepo
}

func New(pool *pgxpool.Pool) *Store {
	return &Store{
		pool:       pool,
		Users:      &UserRepo{pool: pool},
		Messages:   &MessageRepo{pool: pool},
		Detections: &DetectionRepo{pool: pool},
		Numbers:    &NumberRepo{pool: pool},
		Reports:    &ReportRepo{pool: pool},
		Calls:      &CallRepo{pool: pool},
		Categories:    &CategoryRepo{pool: pool},
		Metrics:       &MetricsRepo{pool: pool},
		ModelVersions: &ModelVersionRepo{pool: pool},
	}
}

func Connect(ctx context.Context, databaseURL string) (*pgxpool.Pool, error) {
	poolConfig, err := pgxpool.ParseConfig(databaseURL)
	if err != nil {
		return nil, err
	}
	poolConfig.MaxConns = 10
	poolConfig.MaxConnLifetime = time.Hour

	pool, err := pgxpool.NewWithConfig(ctx, poolConfig)
	if err != nil {
		return nil, err
	}
	if err := pool.Ping(ctx); err != nil {
		pool.Close()
		return nil, err
	}
	return pool, nil
}

type User struct {
	ID           string
	Phone        string
	Name         string
	Locale       string
	PasswordHash string
	Role         string
	CreatedAt    time.Time
}

type Message struct {
	ID              string
	UserID          string
	Channel         string
	RawText         string
	SourceNumber    string
	ScamProbability float64
	Verdict         string
	CreatedAt       time.Time
}

type MessageHistoryItem struct {
	ID              string    `json:"id"`
	Channel         string    `json:"channel"`
	RawText         string    `json:"text"`
	SourceNumber    string    `json:"source_number"`
	ScamProbability float64   `json:"probability"`
	Verdict         string    `json:"verdict"`
	Category        string    `json:"category"`
	Triggers        string    `json:"triggers"`
	CreatedAt       time.Time `json:"created_at"`
}

type AdminMessageItem struct {
	ID              string    `json:"id"`
	Phone           string    `json:"phone"`
	Channel         string    `json:"channel"`
	RawText         string    `json:"text"`
	SourceNumber    string    `json:"source_number"`
	ScamProbability float64   `json:"probability"`
	Verdict         string    `json:"verdict"`
	Category        string    `json:"category"`
	Triggers        string    `json:"triggers"`
	CreatedAt       time.Time `json:"created_at"`
}

type ModelVersion struct {
	ID        string    `json:"id"`
	Name      string    `json:"name"`
	Metrics   string    `json:"metrics"`
	TrainedAt time.Time `json:"trained_at"`
}

type NumberReputation struct {
	Number       string     `json:"number"`
	ReportsCount int        `json:"reports_count"`
	RiskScore    float64    `json:"risk_score"`
	LastReported *time.Time `json:"last_reported"`
}

type CreateMessageParams struct {
	UserID          string
	Channel         string
	RawText         string
	SourceNumber    string
	ScamProbability float64
	Verdict         string
}

type CreateDetectionParams struct {
	MessageID  string
	CategoryID *int
	Probability float64
	Triggers   []string
	LatencyMs  int
}
