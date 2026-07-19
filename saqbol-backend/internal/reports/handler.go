package reports

import (
	"net/http"

	"github.com/gin-gonic/gin"

	"github.com/saqbol/backend/internal/httpx"
	"github.com/saqbol/backend/internal/store"
)

const (
	feedbackConfirmed     = "confirmed"
	feedbackFalsePositive = "false_positive"
	reputationStep        = 0.15
)

type CreateRequest struct {
	MessageID string `json:"message_id" binding:"required"`
	Feedback  string `json:"feedback" binding:"required,oneof=confirmed false_positive"`
}

type Handler struct {
	store *store.Store
}

func NewHandler(dataStore *store.Store) *Handler {
	return &Handler{store: dataStore}
}

func (h *Handler) Register(router gin.IRoutes) {
	router.POST("/reports", h.create)
}

func (h *Handler) create(c *gin.Context) {
	var req CreateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		httpx.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	ctx := c.Request.Context()
	userID := httpx.UserID(c)

	owns, err := h.store.Messages.BelongsToUser(ctx, req.MessageID, userID)
	if err != nil {
		httpx.Error(c, http.StatusInternalServerError, "failed to save report")
		return
	}
	if !owns {
		httpx.Error(c, http.StatusNotFound, "message not found")
		return
	}

	reportID, err := h.store.Reports.Create(ctx, userID, req.MessageID, req.Feedback)
	if err != nil {
		httpx.Error(c, http.StatusInternalServerError, "failed to save report")
		return
	}

	number, err := h.store.Messages.SourceNumber(ctx, req.MessageID)
	if err == nil && number != "" {
		switch req.Feedback {
		case feedbackConfirmed:
			_ = h.store.Numbers.RegisterScam(ctx, number, reputationStep)
		case feedbackFalsePositive:
			_ = h.store.Numbers.RegisterFalsePositive(ctx, number, reputationStep)
		}
	}

	httpx.Created(c, gin.H{"id": reportID})
}
