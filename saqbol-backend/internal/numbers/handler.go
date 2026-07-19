package numbers

import (
	"errors"
	"net/http"

	"github.com/gin-gonic/gin"

	"github.com/saqbol/backend/internal/httpx"
	"github.com/saqbol/backend/internal/store"
)

type Handler struct {
	store *store.Store
}

func NewHandler(dataStore *store.Store) *Handler {
	return &Handler{store: dataStore}
}

func (h *Handler) Register(router gin.IRoutes) {
	router.GET("/numbers/:number/risk", h.risk)
}

func (h *Handler) risk(c *gin.Context) {
	number := c.Param("number")

	reputation, err := h.store.Numbers.Get(c.Request.Context(), number)
	if errors.Is(err, store.ErrNotFound) {
		httpx.OK(c, gin.H{
			"number":        number,
			"reports_count": 0,
			"risk_score":    0,
			"known":         false,
		})
		return
	}
	if err != nil {
		httpx.Error(c, http.StatusInternalServerError, "failed to load reputation")
		return
	}

	httpx.OK(c, gin.H{
		"number":        reputation.Number,
		"reports_count": reputation.ReportsCount,
		"risk_score":    reputation.RiskScore,
		"last_reported": reputation.LastReported,
		"known":         true,
	})
}
