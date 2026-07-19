package history

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"

	"github.com/saqbol/backend/internal/httpx"
	"github.com/saqbol/backend/internal/store"
)

const defaultLimit = 50

type Handler struct {
	store *store.Store
}

func NewHandler(dataStore *store.Store) *Handler {
	return &Handler{store: dataStore}
}

func (h *Handler) Register(router gin.IRoutes) {
	router.GET("/history", h.list)
}

func (h *Handler) list(c *gin.Context) {
	channel := c.Query("channel")
	limit := defaultLimit
	if raw := c.Query("limit"); raw != "" {
		if parsed, err := strconv.Atoi(raw); err == nil && parsed > 0 && parsed <= 200 {
			limit = parsed
		}
	}

	items, err := h.store.Messages.ListByUser(c.Request.Context(), httpx.UserID(c), channel, limit)
	if err != nil {
		httpx.Error(c, http.StatusInternalServerError, "failed to load history")
		return
	}

	httpx.OK(c, gin.H{"items": items})
}
