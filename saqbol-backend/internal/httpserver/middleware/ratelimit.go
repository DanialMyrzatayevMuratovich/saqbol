package middleware

import (
	"context"
	"fmt"
	"net/http"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/redis/go-redis/v9"

	"github.com/saqbol/backend/internal/httpx"
)

func RateLimit(client *redis.Client, perMinute int) gin.HandlerFunc {
	window := time.Minute

	return func(c *gin.Context) {
		if perMinute <= 0 {
			c.Next()
			return
		}

		identity := httpx.UserID(c)
		if identity == "" {
			identity = c.ClientIP()
		}

		minute := time.Now().Unix() / 60
		key := fmt.Sprintf("ratelimit:%s:%d", identity, minute)

		ctx := context.Background()
		count, err := client.Incr(ctx, key).Result()
		if err != nil {
			c.Next()
			return
		}
		if count == 1 {
			client.Expire(ctx, key, window)
		}

		if count > int64(perMinute) {
			httpx.Error(c, http.StatusTooManyRequests, "rate limit exceeded")
			return
		}

		c.Next()
	}
}
