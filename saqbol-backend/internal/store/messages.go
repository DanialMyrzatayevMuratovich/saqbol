package store

import (
	"context"

	"github.com/jackc/pgx/v5/pgxpool"
)

type MessageRepo struct {
	pool *pgxpool.Pool
}

func (r *MessageRepo) Create(ctx context.Context, params CreateMessageParams) (string, error) {
	var id string
	err := r.pool.QueryRow(ctx, `
		INSERT INTO messages (user_id, channel, raw_text, source_number, scam_probability, verdict)
		VALUES ($1, $2::channel, $3, NULLIF($4, ''), $5, NULLIF($6, '')::verdict)
		RETURNING id::text`,
		params.UserID, params.Channel, params.RawText, params.SourceNumber,
		params.ScamProbability, params.Verdict,
	).Scan(&id)
	return id, err
}

func (r *MessageRepo) ListAll(ctx context.Context, verdict string, limit int) ([]AdminMessageItem, error) {
	rows, err := r.pool.Query(ctx, `
		SELECT m.id::text,
		       u.phone,
		       m.channel::text,
		       m.raw_text,
		       COALESCE(m.source_number, ''),
		       COALESCE(m.scam_probability, 0),
		       COALESCE(m.verdict::text, ''),
		       COALESCE(c.name, ''),
		       COALESCE(d.triggers::text, '[]'),
		       m.created_at
		FROM messages m
		JOIN users u ON u.id = m.user_id
		LEFT JOIN LATERAL (
			SELECT * FROM detections d
			WHERE d.message_id = m.id
			ORDER BY d.created_at DESC
			LIMIT 1
		) d ON true
		LEFT JOIN scam_categories c ON c.id = d.category_id
		WHERE ($1 = '' OR m.verdict::text = $1)
		ORDER BY m.created_at DESC
		LIMIT $2`,
		verdict, limit,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	items := make([]AdminMessageItem, 0)
	for rows.Next() {
		var item AdminMessageItem
		if err := rows.Scan(
			&item.ID, &item.Phone, &item.Channel, &item.RawText, &item.SourceNumber,
			&item.ScamProbability, &item.Verdict, &item.Category, &item.Triggers, &item.CreatedAt,
		); err != nil {
			return nil, err
		}
		items = append(items, item)
	}
	return items, rows.Err()
}

func (r *MessageRepo) BelongsToUser(ctx context.Context, messageID, userID string) (bool, error) {
	var exists bool
	err := r.pool.QueryRow(ctx, `
		SELECT EXISTS(SELECT 1 FROM messages WHERE id = $1 AND user_id = $2)`,
		messageID, userID,
	).Scan(&exists)
	return exists, err
}

func (r *MessageRepo) SourceNumber(ctx context.Context, messageID string) (string, error) {
	var number string
	err := r.pool.QueryRow(ctx, `
		SELECT COALESCE(source_number, '') FROM messages WHERE id = $1`, messageID,
	).Scan(&number)
	return number, err
}

func (r *MessageRepo) ListByUser(ctx context.Context, userID, channel string, limit int) ([]MessageHistoryItem, error) {
	rows, err := r.pool.Query(ctx, `
		SELECT m.id::text,
		       m.channel::text,
		       m.raw_text,
		       COALESCE(m.source_number, ''),
		       COALESCE(m.scam_probability, 0),
		       COALESCE(m.verdict::text, ''),
		       COALESCE(c.name, ''),
		       COALESCE(d.triggers::text, '[]'),
		       m.created_at
		FROM messages m
		LEFT JOIN LATERAL (
			SELECT * FROM detections d
			WHERE d.message_id = m.id
			ORDER BY d.created_at DESC
			LIMIT 1
		) d ON true
		LEFT JOIN scam_categories c ON c.id = d.category_id
		WHERE m.user_id = $1 AND ($2 = '' OR m.channel::text = $2)
		ORDER BY m.created_at DESC
		LIMIT $3`,
		userID, channel, limit,
	)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	items := make([]MessageHistoryItem, 0)
	for rows.Next() {
		var item MessageHistoryItem
		if err := rows.Scan(
			&item.ID, &item.Channel, &item.RawText, &item.SourceNumber,
			&item.ScamProbability, &item.Verdict, &item.Category, &item.Triggers, &item.CreatedAt,
		); err != nil {
			return nil, err
		}
		items = append(items, item)
	}
	return items, rows.Err()
}
