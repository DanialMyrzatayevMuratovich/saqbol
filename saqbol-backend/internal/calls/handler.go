package calls

import (
	"net/http"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/gorilla/websocket"

	"github.com/saqbol/backend/internal/auth"
	"github.com/saqbol/backend/internal/httpx"
)

type AnalyzeRequest struct {
	Transcript string `json:"transcript" binding:"required,max=20000"`
}

type Handler struct {
	service  *Service
	tokens   *auth.TokenManager
	upgrader websocket.Upgrader
}

func NewHandler(service *Service, tokens *auth.TokenManager) *Handler {
	return &Handler{
		service: service,
		tokens:  tokens,
		upgrader: websocket.Upgrader{
			CheckOrigin: func(r *http.Request) bool { return true },
		},
	}
}

func (h *Handler) RegisterHTTP(router gin.IRoutes) {
	router.POST("/call/analyze", h.analyze)
}

func (h *Handler) RegisterWS(engine *gin.Engine) {
	engine.GET("/ws/call", h.stream)
}

func (h *Handler) analyze(c *gin.Context) {
	var req AnalyzeRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		httpx.Error(c, http.StatusBadRequest, err.Error())
		return
	}

	ctx := c.Request.Context()
	result, err := h.service.Classify(ctx, req.Transcript)
	if err != nil {
		httpx.Error(c, http.StatusInternalServerError, "failed to analyze transcript")
		return
	}

	alert := result.Probability >= h.service.ScamThreshold()
	sessionID, err := h.service.SaveSession(ctx, httpx.UserID(c), req.Transcript, result.Probability, alert)
	if err != nil {
		httpx.Error(c, http.StatusInternalServerError, "failed to save session")
		return
	}

	httpx.OK(c, gin.H{
		"session_id":  sessionID,
		"verdict":     result.Verdict,
		"probability": result.Probability,
		"category":    result.Category,
		"triggers":    result.Triggers,
		"advice":      result.Advice,
		"alert":       alert,
	})
}

type streamFrame struct {
	Text string `json:"text"`
}

type streamAlert struct {
	Verdict     string   `json:"verdict"`
	Probability float64  `json:"probability"`
	Category    string   `json:"category"`
	Triggers    []string `json:"triggers"`
	Advice      string   `json:"advice"`
	Alert       bool     `json:"alert"`
}

func (h *Handler) stream(c *gin.Context) {
	userID := h.authenticate(c)
	if userID == "" {
		httpx.Error(c, http.StatusUnauthorized, "invalid or expired token")
		return
	}

	conn, err := h.upgrader.Upgrade(c.Writer, c.Request, nil)
	if err != nil {
		return
	}
	defer conn.Close()

	ctx := c.Request.Context()
	var transcript strings.Builder
	maxProbability := 0.0
	alertTriggered := false

	for {
		var frame streamFrame
		if err := conn.ReadJSON(&frame); err != nil {
			break
		}
		if frame.Text == "" {
			continue
		}

		transcript.WriteString(frame.Text)
		transcript.WriteString(" ")

		result, err := h.service.Classify(ctx, window(transcript.String()))
		if err != nil {
			continue
		}

		if result.Probability > maxProbability {
			maxProbability = result.Probability
		}
		alert := result.Probability >= h.service.ScamThreshold()
		if alert {
			alertTriggered = true
		}

		if err := conn.WriteJSON(streamAlert{
			Verdict:     result.Verdict,
			Probability: result.Probability,
			Category:    result.Category,
			Triggers:    result.Triggers,
			Advice:      result.Advice,
			Alert:       alert,
		}); err != nil {
			break
		}
	}

	_, _ = h.service.SaveSession(ctx, userID, transcript.String(), maxProbability, alertTriggered)
}

func (h *Handler) authenticate(c *gin.Context) string {
	token := c.Query("token")
	if token == "" {
		header := c.GetHeader("Authorization")
		token = strings.TrimPrefix(header, "Bearer ")
	}
	if token == "" {
		return ""
	}
	claims, err := h.tokens.ParseAccess(token)
	if err != nil {
		return ""
	}
	return claims.UserID
}

func window(text string) string {
	const maxRunes = 600
	runes := []rune(text)
	if len(runes) <= maxRunes {
		return text
	}
	return string(runes[len(runes)-maxRunes:])
}
