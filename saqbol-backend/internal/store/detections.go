package store

import (
	"context"
	"encoding/json"

	"github.com/jackc/pgx/v5/pgxpool"
)

type DetectionRepo struct {
	pool *pgxpool.Pool
}

func (r *DetectionRepo) Create(ctx context.Context, params CreateDetectionParams) (string, error) {
	triggers, err := json.Marshal(params.Triggers)
	if err != nil {
		return "", err
	}

	var id string
	err = r.pool.QueryRow(ctx, `
		INSERT INTO detections (message_id, category_id, probability, triggers, latency_ms)
		VALUES ($1, $2, $3, $4::jsonb, $5)
		RETURNING id::text`,
		params.MessageID, params.CategoryID, params.Probability, string(triggers), params.LatencyMs,
	).Scan(&id)
	return id, err
}
