package middleware

import (
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"

	"github.com/saqbol/backend/internal/auth"
	"github.com/saqbol/backend/internal/httpx"
)

func Auth(tokens *auth.TokenManager) gin.HandlerFunc {
	return func(c *gin.Context) {
		header := c.GetHeader("Authorization")
		prefix := "Bearer "
		if !strings.HasPrefix(header, prefix) {
			httpx.Error(c, http.StatusUnauthorized, "missing bearer token")
			return
		}

		claims, err := tokens.ParseAccess(strings.TrimPrefix(header, prefix))
		if err != nil {
			httpx.Error(c, http.StatusUnauthorized, "invalid or expired token")
			return
		}

		httpx.SetUserID(c, claims.UserID)
		httpx.SetRole(c, claims.Role)
		c.Next()
	}
}
