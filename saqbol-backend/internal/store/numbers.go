package store

import (
	"context"
	"errors"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type NumberRepo struct {
	pool *pgxpool.Pool
}

func (r *NumberRepo) Get(ctx context.Context, number string) (NumberReputation, error) {
	var rep NumberReputation
	err := r.pool.QueryRow(ctx, `
		SELECT number, reports_count, risk_score, last_reported
		FROM numbers WHERE number = $1`, number,
	).Scan(&rep.Number, &rep.ReportsCount, &rep.RiskScore, &rep.LastReported)
	if errors.Is(err, pgx.ErrNoRows) {
		return NumberReputation{}, ErrNotFound
	}
	if err != nil {
		return NumberReputation{}, err
	}
	return rep, nil
}

func (r *NumberRepo) RegisterScam(ctx context.Context, number string, increment float64) error {
	if number == "" {
		return nil
	}
	_, err := r.pool.Exec(ctx, `
		INSERT INTO numbers (number, reports_count, risk_score, last_reported)
		VALUES ($1, 1, LEAST(1.0, $2), now())
		ON CONFLICT (number) DO UPDATE SET
			reports_count = numbers.reports_count + 1,
			risk_score = LEAST(1.0, numbers.risk_score + $2),
			last_reported = now()`,
		number, increment,
	)
	return err
}

func (r *NumberRepo) RegisterFalsePositive(ctx context.Context, number string, decrement float64) error {
	if number == "" {
		return nil
	}
	_, err := r.pool.Exec(ctx, `
		UPDATE numbers SET
			risk_score = GREATEST(0.0, risk_score - $2),
			last_reported = now()
		WHERE number = $1`,
		number, decrement,
	)
	return err
}
