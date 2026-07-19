package store

import (
	"context"

	"github.com/jackc/pgx/v5/pgxpool"
)

type MetricsRepo struct {
	pool *pgxpool.Pool
}

type CategoryCount struct {
	Name  string `json:"name"`
	Count int    `json:"count"`
}

type Overview struct {
	TotalUsers          int             `json:"total_users"`
	TotalMessages       int             `json:"total_messages"`
	ScamMessages        int             `json:"scam_messages"`
	SuspiciousMessages  int             `json:"suspicious_messages"`
	AlertedCallSessions int             `json:"alerted_call_sessions"`
	CategoryDistribution []CategoryCount `json:"category_distribution"`
}

func (r *MetricsRepo) GetOverview(ctx context.Context) (Overview, error) {
	var overview Overview
	err := r.pool.QueryRow(ctx, `
		SELECT
			(SELECT count(*) FROM users),
			(SELECT count(*) FROM messages),
			(SELECT count(*) FROM messages WHERE verdict = 'scam'),
			(SELECT count(*) FROM messages WHERE verdict = 'suspicious'),
			(SELECT count(*) FROM call_sessions WHERE alert_triggered)`,
	).Scan(
		&overview.TotalUsers, &overview.TotalMessages, &overview.ScamMessages,
		&overview.SuspiciousMessages, &overview.AlertedCallSessions,
	)
	if err != nil {
		return Overview{}, err
	}

	rows, err := r.pool.Query(ctx, `
		SELECT c.name, count(d.id)
		FROM scam_categories c
		LEFT JOIN detections d ON d.category_id = c.id
		GROUP BY c.name
		ORDER BY count(d.id) DESC`,
	)
	if err != nil {
		return Overview{}, err
	}
	defer rows.Close()

	overview.CategoryDistribution = make([]CategoryCount, 0)
	for rows.Next() {
		var item CategoryCount
		if err := rows.Scan(&item.Name, &item.Count); err != nil {
			return Overview{}, err
		}
		overview.CategoryDistribution = append(overview.CategoryDistribution, item)
	}
	return overview, rows.Err()
}
