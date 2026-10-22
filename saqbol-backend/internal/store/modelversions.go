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

// IDByName returns the newest model_versions row with this name. A version the
// ML service reports but nobody registered yet is added with empty metrics, so
// every detection can point at the model that produced it.
func (r *ModelVersionRepo) IDByName(ctx context.Context, name string) (string, error) {
	var id string
	err := r.pool.QueryRow(ctx, `
		WITH existing AS (
			SELECT id FROM model_versions WHERE name = $1 ORDER BY trained_at DESC LIMIT 1
		), created AS (
			INSERT INTO model_versions (name, metrics)
			SELECT $1, '{}'::jsonb
			WHERE NOT EXISTS (SELECT 1 FROM existing)
			RETURNING id
		)
		SELECT id::text FROM existing
		UNION ALL
		SELECT id::text FROM created`,
		name,
	).Scan(&id)
	return id, err
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
