package admin

import (
	"net/http"
	"strconv"

	"github.com/gin-gonic/gin"

	"github.com/saqbol/backend/internal/httpx"
	"github.com/saqbol/backend/internal/store"
)

const defaultMessageLimit = 50

type Handler struct {
	store *store.Store
}

func NewHandler(dataStore *store.Store) *Handler {
	return &Handler{store: dataStore}
}

func (h *Handler) Register(router gin.IRoutes) {
	router.GET("/admin/metrics", h.metrics)
	router.GET("/admin/messages", h.messages)
	router.GET("/admin/model-versions", h.listModelVersions)
	router.POST("/admin/model-versions", h.createModelVersion)
}

func (h *Handler) metrics(c *gin.Context) {
	overview, err := h.store.Metrics.GetOverview(c.Request.Context())
	if err != nil {
		httpx.Error(c, http.StatusInternalServerError, "failed to load metrics")
		return
	}
	httpx.OK(c, overview)
}

func (h *Handler) messages(c *gin.Context) {
	verdict := c.Query("verdict")
	limit := defaultMessageLimit
	if raw := c.Query("limit"); raw != "" {
		if parsed, err := strconv.Atoi(raw); err == nil && parsed > 0 && parsed <= 200 {
			limit = parsed
		}
	}

	items, err := h.store.Messages.ListAll(c.Request.Context(), verdict, limit)
	if err != nil {
		httpx.Error(c, http.StatusInternalServerError, "failed to load messages")
		return
	}
	httpx.OK(c, gin.H{"items": items})
}

func (h *Handler) listModelVersions(c *gin.Context) {
	items, err := h.store.ModelVersions.List(c.Request.Context())
	if err != nil {
		httpx.Error(c, http.StatusInternalServerError, "failed to load model versions")
		return
	}
	httpx.OK(c, gin.H{"items": items})
}

type createModelVersionRequest struct {
	Name    string `json:"name" binding:"required,max=120"`
	Metrics string `json:"metrics"`
}

func (h *Handler) createModelVersion(c *gin.Context) {
	var req createModelVersionRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		httpx.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	version, err := h.store.ModelVersions.Create(c.Request.Context(), req.Name, req.Metrics)
	if err != nil {
		httpx.Error(c, http.StatusInternalServerError, "failed to create model version")
		return
	}
	httpx.Created(c, version)
}
