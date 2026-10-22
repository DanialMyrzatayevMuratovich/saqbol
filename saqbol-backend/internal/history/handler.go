package history

import (
	"net/http"
	"strconv"
	"time"

	"github.com/gin-gonic/gin"

	"github.com/saqbol/backend/internal/httpx"
	"github.com/saqbol/backend/internal/store"
)

const (
	defaultLimit = 50

	defaultSummaryDays = 7
	maxSummaryDays     = 90
	summaryThreats     = 3
)

type Handler struct {
	store *store.Store
}

func NewHandler(dataStore *store.Store) *Handler {
	return &Handler{store: dataStore}
}

func (h *Handler) Register(router gin.IRoutes) {
	router.GET("/history", h.list)
	router.GET("/history/summary", h.summary)
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

// summary counts the caller's checks of the last `days` days in the database,
// so the totals stay right however many checks there were, and adds the
// newest threats.
func (h *Handler) summary(c *gin.Context) {
	days, ok := parseDays(c.Query("days"))
	if !ok {
		httpx.Error(c, http.StatusBadRequest, "days must be a whole number from 1 to 90")
		return
	}

	since := summarySince(time.Now(), days)
	summary, err := h.store.Messages.SummaryByUser(c.Request.Context(), httpx.UserID(c), since, summaryThreats)
	if err != nil {
		httpx.Error(c, http.StatusInternalServerError, "failed to load history summary")
		return
	}

	httpx.OK(c, summary)
}

// parseDays reads the summary period; no value means a week.
func parseDays(raw string) (int, bool) {
	if raw == "" {
		return defaultSummaryDays, true
	}
	days, err := strconv.Atoi(raw)
	if err != nil || days < 1 || days > maxSummaryDays {
		return 0, false
	}
	return days, true
}

// summarySince is the start of a period of whole 24-hour days ending now.
func summarySince(now time.Time, days int) time.Time {
	return now.Add(-time.Duration(days) * 24 * time.Hour)
}
