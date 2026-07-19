package sms

import (
	"net/http"

	"github.com/gin-gonic/gin"

	"github.com/saqbol/backend/internal/httpx"
)

type Handler struct {
	service *Service
}

func NewHandler(service *Service) *Handler {
	return &Handler{service: service}
}

func (h *Handler) Register(router gin.IRoutes) {
	router.POST("/sms/check", h.check)
	router.POST("/sms/check/batch", h.checkBatch)
}

func (h *Handler) check(c *gin.Context) {
	var req CheckRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		httpx.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	response, err := h.service.Check(c.Request.Context(), httpx.UserID(c), req)
	if err != nil {
		httpx.Error(c, http.StatusInternalServerError, "failed to check message")
		return
	}

	httpx.OK(c, response)
}

func (h *Handler) checkBatch(c *gin.Context) {
	var req BatchCheckRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		httpx.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	httpx.OK(c, h.service.CheckBatch(c.Request.Context(), httpx.UserID(c), req))
}
