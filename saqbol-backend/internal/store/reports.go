package store

import (
	"context"

	"github.com/jackc/pgx/v5/pgxpool"
)

type ReportRepo struct {
	pool *pgxpool.Pool
}

func (r *ReportRepo) Create(ctx context.Context, userID, messageID, feedback string) (string, error) {
	var id string
	err := r.pool.QueryRow(ctx, `
		INSERT INTO reports (user_id, message_id, feedback)
		VALUES ($1, $2, $3::report_feedback)
		RETURNING id::text`,
		userID, messageID, feedback,
	).Scan(&id)
	return id, err
}
