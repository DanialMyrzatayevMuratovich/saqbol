package sms

type CheckRequest struct {
	Text         string `json:"text" binding:"required,max=4000"`
	SourceNumber string `json:"source_number" binding:"max=32"`
}

type CheckResponse struct {
	MessageID    string   `json:"message_id"`
	Verdict      string   `json:"verdict"`
	Probability  float64  `json:"probability"`
	Category     string   `json:"category"`
	Triggers     []string `json:"triggers"`
	Advice       string   `json:"advice"`
	ModelVersion string   `json:"model_version"`
}

// BatchCheckRequest carries messages collected from the device inbox in one
// call, so a full-inbox scan does not burn one rate-limit slot per message.
type BatchCheckRequest struct {
	Messages []BatchCheckItem `json:"messages" binding:"required,min=1,max=100,dive"`
}

type BatchCheckItem struct {
	// ExternalID is the device-side message id, echoed back so the client can
	// match results without relying on ordering.
	ExternalID   string `json:"external_id" binding:"max=64"`
	Text         string `json:"text" binding:"required,max=4000"`
	SourceNumber string `json:"source_number" binding:"max=32"`
}

type BatchCheckResponse struct {
	Results []BatchCheckResult `json:"results"`
}

// BatchCheckResult holds either a verdict or a per-item error: one bad message
// must not fail the whole batch.
type BatchCheckResult struct {
	ExternalID string `json:"external_id,omitempty"`
	Error      string `json:"error,omitempty"`
	CheckResponse
}
