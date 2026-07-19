package store

import (
	"context"

	"github.com/jackc/pgx/v5/pgxpool"
)

type ModelVersionRepo struct {
	pool *pgxpool.Pool
}

func (r *ModelVersionRepo) List(ctx context.Context) ([]ModelVersion, error) {
	rows, err := r.pool.Query(ctx, `
		SELECT id::text, name, COALESCE(metrics::text, '{}'), trained_at
		FROM model_versions
		ORDER BY trained_at DESC`)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	items := make([]ModelVersion, 0)
	for rows.Next() {
		var item ModelVersion
		if err := rows.Scan(&item.ID, &item.Name, &item.Metrics, &item.TrainedAt); err != nil {
			return nil, err
		}
		items = append(items, item)
	}
	return items, rows.Err()
}

func (r *ModelVersionRepo) Create(ctx context.Context, name, metrics string) (ModelVersion, error) {
	if metrics == "" {
		metrics = "{}"
	}
	var item ModelVersion
	err := r.pool.QueryRow(ctx, `
		INSERT INTO model_versions (name, metrics)
		VALUES ($1, $2::jsonb)
		RETURNING id::text, name, COALESCE(metrics::text, '{}'), trained_at`,
		name, metrics,
	).Scan(&item.ID, &item.Name, &item.Metrics, &item.TrainedAt)
	return item, err
}
