package store

import (
	"context"
	"errors"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"
)

type UserRepo struct {
	pool *pgxpool.Pool
}

func (r *UserRepo) Create(ctx context.Context, phone, name, locale, passwordHash string) (User, error) {
	var user User
	err := r.pool.QueryRow(ctx, `
		INSERT INTO users (phone, name, locale, password_hash)
		VALUES ($1, NULLIF($2, ''), $3, $4)
		RETURNING id::text, phone, COALESCE(name, ''), locale, password_hash, role::text, created_at`,
		phone, name, locale, passwordHash,
	).Scan(&user.ID, &user.Phone, &user.Name, &user.Locale, &user.PasswordHash, &user.Role, &user.CreatedAt)
	if err != nil {
		return User{}, err
	}
	return user, nil
}

func (r *UserRepo) GetByPhone(ctx context.Context, phone string) (User, error) {
	var user User
	err := r.pool.QueryRow(ctx, `
		SELECT id::text, phone, COALESCE(name, ''), locale, password_hash, role::text, created_at
		FROM users WHERE phone = $1`, phone,
	).Scan(&user.ID, &user.Phone, &user.Name, &user.Locale, &user.PasswordHash, &user.Role, &user.CreatedAt)
	if errors.Is(err, pgx.ErrNoRows) {
		return User{}, ErrNotFound
	}
	if err != nil {
		return User{}, err
	}
	return user, nil
}

func (r *UserRepo) GetRole(ctx context.Context, userID string) (string, error) {
	var role string
	err := r.pool.QueryRow(ctx, `SELECT role::text FROM users WHERE id = $1`, userID).Scan(&role)
	if errors.Is(err, pgx.ErrNoRows) {
		return "", ErrNotFound
	}
	return role, err
}

func (r *UserRepo) ExistsByPhone(ctx context.Context, phone string) (bool, error) {
	var exists bool
	err := r.pool.QueryRow(ctx, `SELECT EXISTS(SELECT 1 FROM users WHERE phone = $1)`, phone).Scan(&exists)
	return exists, err
}

func (r *UserRepo) PromoteToAdmin(ctx context.Context, phones []string) error {
	if len(phones) == 0 {
		return nil
	}
	_, err := r.pool.Exec(ctx, `UPDATE users SET role = 'admin' WHERE phone = ANY($1)`, phones)
	return err
}
