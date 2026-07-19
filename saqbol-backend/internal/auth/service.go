package auth

import (
	"context"
	"errors"
	"time"

	"github.com/redis/go-redis/v9"
	"golang.org/x/crypto/bcrypt"

	"github.com/saqbol/backend/internal/store"
)

var (
	ErrPhoneTaken         = errors.New("phone already registered")
	ErrInvalidCredentials = errors.New("invalid phone or password")
	ErrSessionExpired     = errors.New("refresh session expired")
)

type Service struct {
	users      *store.UserRepo
	redis      *redis.Client
	tokens     *TokenManager
	accessTTL  time.Duration
	refreshTTL time.Duration
}

func NewService(users *store.UserRepo, redisClient *redis.Client, tokens *TokenManager, accessTTL, refreshTTL time.Duration) *Service {
	return &Service{
		users:      users,
		redis:      redisClient,
		tokens:     tokens,
		accessTTL:  accessTTL,
		refreshTTL: refreshTTL,
	}
}

func (s *Service) Register(ctx context.Context, req RegisterRequest) (TokenResponse, error) {
	exists, err := s.users.ExistsByPhone(ctx, req.Phone)
	if err != nil {
		return TokenResponse{}, err
	}
	if exists {
		return TokenResponse{}, ErrPhoneTaken
	}

	hash, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		return TokenResponse{}, err
	}

	locale := req.Locale
	if locale == "" {
		locale = "ru"
	}

	user, err := s.users.Create(ctx, req.Phone, req.Name, locale, string(hash))
	if err != nil {
		return TokenResponse{}, err
	}

	return s.issueTokens(ctx, user.ID, user.Role)
}

func (s *Service) Login(ctx context.Context, req LoginRequest) (TokenResponse, error) {
	user, err := s.users.GetByPhone(ctx, req.Phone)
	if errors.Is(err, store.ErrNotFound) {
		return TokenResponse{}, ErrInvalidCredentials
	}
	if err != nil {
		return TokenResponse{}, err
	}

	if bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(req.Password)) != nil {
		return TokenResponse{}, ErrInvalidCredentials
	}

	return s.issueTokens(ctx, user.ID, user.Role)
}

func (s *Service) Refresh(ctx context.Context, req RefreshRequest) (TokenResponse, error) {
	claims, err := s.tokens.ParseRefresh(req.RefreshToken)
	if err != nil {
		return TokenResponse{}, ErrInvalidToken
	}

	key := sessionKey(claims.ID)
	storedUserID, err := s.redis.Get(ctx, key).Result()
	if errors.Is(err, redis.Nil) || storedUserID != claims.UserID {
		return TokenResponse{}, ErrSessionExpired
	}
	if err != nil {
		return TokenResponse{}, err
	}

	if err := s.redis.Del(ctx, key).Err(); err != nil {
		return TokenResponse{}, err
	}

	role, err := s.users.GetRole(ctx, claims.UserID)
	if err != nil {
		return TokenResponse{}, err
	}

	return s.issueTokens(ctx, claims.UserID, role)
}

func (s *Service) issueTokens(ctx context.Context, userID, role string) (TokenResponse, error) {
	accessToken, err := s.tokens.GenerateAccess(userID, role)
	if err != nil {
		return TokenResponse{}, err
	}

	refreshToken, jti, err := s.tokens.GenerateRefresh(userID)
	if err != nil {
		return TokenResponse{}, err
	}

	if err := s.redis.Set(ctx, sessionKey(jti), userID, s.refreshTTL).Err(); err != nil {
		return TokenResponse{}, err
	}

	return TokenResponse{
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
		ExpiresIn:    int(s.accessTTL.Seconds()),
	}, nil
}

func sessionKey(jti string) string {
	return "refresh:" + jti
}
