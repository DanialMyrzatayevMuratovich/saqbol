package auth

import (
	"errors"
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
	router.POST("/auth/register", h.register)
	router.POST("/auth/login", h.login)
	router.POST("/auth/refresh", h.refresh)
}

func (h *Handler) register(c *gin.Context) {
	var req RegisterRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		httpx.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	tokens, err := h.service.Register(c.Request.Context(), req)
	if errors.Is(err, ErrPhoneTaken) {
		httpx.Error(c, http.StatusConflict, err.Error())
		return
	}
	if err != nil {
		httpx.Error(c, http.StatusInternalServerError, "failed to register")
		return
	}

	httpx.Created(c, tokens)
}

func (h *Handler) login(c *gin.Context) {
	var req LoginRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		httpx.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	tokens, err := h.service.Login(c.Request.Context(), req)
	if errors.Is(err, ErrInvalidCredentials) {
		httpx.Error(c, http.StatusUnauthorized, err.Error())
		return
	}
	if err != nil {
		httpx.Error(c, http.StatusInternalServerError, "failed to login")
		return
	}

	httpx.OK(c, tokens)
}

func (h *Handler) refresh(c *gin.Context) {
	var req RefreshRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		httpx.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	tokens, err := h.service.Refresh(c.Request.Context(), req)
	if errors.Is(err, ErrInvalidToken) || errors.Is(err, ErrSessionExpired) {
		httpx.Error(c, http.StatusUnauthorized, err.Error())
		return
	}
	if err != nil {
		httpx.Error(c, http.StatusInternalServerError, "failed to refresh")
		return
	}

	httpx.OK(c, tokens)
}
