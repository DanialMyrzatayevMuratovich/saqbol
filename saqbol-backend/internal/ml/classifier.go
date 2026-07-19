package ml

import "context"

const (
	VerdictSafe       = "safe"
	VerdictSuspicious = "suspicious"
	VerdictScam       = "scam"

	ChannelSMS  = "sms"
	ChannelCall = "call"
)

type Request struct {
	Text    string
	Channel string
}

type Result struct {
	Verdict      string   `json:"verdict"`
	Probability  float64  `json:"probability"`
	Category     string   `json:"category"`
	Triggers     []string `json:"triggers"`
	Advice       string   `json:"advice"`
	LatencyMs    int      `json:"-"`
	ModelVersion string   `json:"-"`
}

type Classifier interface {
	Classify(ctx context.Context, req Request) (Result, error)
}
