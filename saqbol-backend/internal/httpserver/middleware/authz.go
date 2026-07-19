package middleware

import (
	"net/http"

	"github.com/gin-gonic/gin"

	"github.com/saqbol/backend/internal/httpx"
)

const roleAdmin = "admin"

func RequireAdmin() gin.HandlerFunc {
	return func(c *gin.Context) {
		if httpx.Role(c) != roleAdmin {
			httpx.Error(c, http.StatusForbidden, "admin access required")
			return
		}
		c.Next()
	}
}
