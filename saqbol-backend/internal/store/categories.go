package store

import (
	"context"
	"errors"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type CategoryRepo struct {
	pool *pgxpool.Pool
}

func (r *CategoryRepo) IDByName(ctx context.Context, name string) (*int, error) {
	if name == "" {
		return nil, nil
	}
	var id int
	err := r.pool.QueryRow(ctx, `SELECT id FROM scam_categories WHERE name = $1`, name).Scan(&id)
	if errors.Is(err, pgx.ErrNoRows) {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	return &id, nil
}
