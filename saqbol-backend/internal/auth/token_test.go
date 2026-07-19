package auth

import (
	"testing"
	"time"
)

func newManager() *TokenManager {
	return NewTokenManager("access-secret", "refresh-secret", 15*time.Minute, 24*time.Hour)
}

func TestAccessTokenRoundTrip(t *testing.T) {
	manager := newManager()

	token, err := manager.GenerateAccess("user-1", "admin")
	if err != nil {
		t.Fatalf("generate: %v", err)
	}

	claims, err := manager.ParseAccess(token)
	if err != nil {
		t.Fatalf("parse: %v", err)
	}
	if claims.UserID != "user-1" {
		t.Fatalf("expected user-1, got %q", claims.UserID)
	}
	if claims.Role != "admin" {
		t.Fatalf("expected admin role, got %q", claims.Role)
	}
}

func TestAccessTokenRejectsRefresh(t *testing.T) {
	manager := newManager()

	refresh, _, err := manager.GenerateRefresh("user-1")
	if err != nil {
		t.Fatalf("generate refresh: %v", err)
	}

	if _, err := manager.ParseAccess(refresh); err == nil {
		t.Fatal("expected access parse to reject a refresh token")
	}
}

func TestRefreshTokenHasJTI(t *testing.T) {
	manager := newManager()

	refresh, jti, err := manager.GenerateRefresh("user-1")
	if err != nil {
		t.Fatalf("generate: %v", err)
	}
	if jti == "" {
		t.Fatal("expected non-empty jti")
	}

	claims, err := manager.ParseRefresh(refresh)
	if err != nil {
		t.Fatalf("parse refresh: %v", err)
	}
	if claims.ID != jti {
		t.Fatalf("expected jti %q in claims, got %q", jti, claims.ID)
	}
}

func TestTokenRejectsWrongSecret(t *testing.T) {
	manager := newManager()
	other := NewTokenManager("different-secret", "refresh-secret", time.Minute, time.Hour)

	token, err := manager.GenerateAccess("user-1", "user")
	if err != nil {
		t.Fatalf("generate: %v", err)
	}

	if _, err := other.ParseAccess(token); err == nil {
		t.Fatal("expected parse to fail with a different secret")
	}
}
