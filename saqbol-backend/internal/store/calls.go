package store

import (
	"context"

	"github.com/jackc/pgx/v5/pgxpool"
)

type CallRepo struct {
	pool *pgxpool.Pool
}

type CreateCallParams struct {
	UserID         string
	Transcript     string
	MaxProbability float64
	AlertTriggered bool
}

func (r *CallRepo) Create(ctx context.Context, params CreateCallParams) (string, error) {
	var id string
	err := r.pool.QueryRow(ctx, `
		INSERT INTO call_sessions (user_id, transcript, max_probability, alert_triggered, ended_at)
		VALUES ($1, NULLIF($2, ''), $3, $4, now())
		RETURNING id::text`,
		params.UserID, params.Transcript, params.MaxProbability, params.AlertTriggered,
	).Scan(&id)
	return id, err
}
