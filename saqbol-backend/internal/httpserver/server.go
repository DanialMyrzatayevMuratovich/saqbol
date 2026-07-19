package httpserver

import (
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/prometheus/client_golang/prometheus/promhttp"
	"github.com/redis/go-redis/v9"

	"github.com/saqbol/backend/internal/admin"
	"github.com/saqbol/backend/internal/auth"
	"github.com/saqbol/backend/internal/calls"
	"github.com/saqbol/backend/internal/history"
	"github.com/saqbol/backend/internal/httpserver/middleware"
	"github.com/saqbol/backend/internal/numbers"
	"github.com/saqbol/backend/internal/reports"
	"github.com/saqbol/backend/internal/sms"
)

type Handlers struct {
	Auth    *auth.Handler
	SMS     *sms.Handler
	Numbers *numbers.Handler
	Reports *reports.Handler
	History *history.Handler
	Calls   *calls.Handler
	Admin   *admin.Handler
}

func New(pool *pgxpool.Pool, redisClient *redis.Client, tokens *auth.TokenManager, rateLimitPerMin int, handlers Handlers) *gin.Engine {
	engine := gin.New()
	engine.Use(middleware.Recover(), middleware.Logger(), middleware.CORS(), middleware.Metrics())

	engine.GET("/health", healthCheck(pool))
	engine.GET("/metrics", gin.WrapH(promhttp.Handler()))

	rateLimit := middleware.RateLimit(redisClient, rateLimitPerMin)

	api := engine.Group("/api/v1")
	api.Use(rateLimit)
	handlers.Auth.Register(api)

	protected := api.Group("")
	protected.Use(middleware.Auth(tokens))
	handlers.SMS.Register(protected)
	handlers.Numbers.Register(protected)
	handlers.Reports.Register(protected)
	handlers.History.Register(protected)
	handlers.Calls.RegisterHTTP(protected)

	adminGroup := protected.Group("")
	adminGroup.Use(middleware.RequireAdmin())
	handlers.Admin.Register(adminGroup)

	handlers.Calls.RegisterWS(engine)

	return engine
}

func healthCheck(pool *pgxpool.Pool) gin.HandlerFunc {
	return func(c *gin.Context) {
		if err := pool.Ping(c.Request.Context()); err != nil {
			c.JSON(http.StatusServiceUnavailable, gin.H{"status": "degraded", "database": "down"})
			return
		}
		c.JSON(http.StatusOK, gin.H{"status": "ok"})
	}
}
