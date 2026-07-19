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
