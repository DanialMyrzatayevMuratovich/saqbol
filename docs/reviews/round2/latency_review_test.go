package main

import (
	"io"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"
)

func TestReviewNearestRankPercentiles(t *testing.T) {
	samples := make([]time.Duration, 100)
	for i := range samples {
		samples[i] = time.Duration(i+1) * time.Millisecond
	}
	for _, p := range []int{50, 95, 99} {
		if got := percentile(samples, p); got != time.Duration(p)*time.Millisecond {
			t.Fatalf("p%d=%v", p, got)
		}
	}
}

func TestReviewFailedChecksAreCountedSeparately(t *testing.T) {
	cases := []struct {
		name      string
		status    int
		body      string
		wantError bool
	}{
		{"valid", 200, `{"verdict":"safe"}`, false},
		{"rate_limit", 429, `{"error":"rate limited"}`, true},
		{"empty_verdict", 200, `{}`, true},
		{"broken_json", 200, `not json`, true},
	}
	for _, c := range cases {
		t.Run(c.name, func(t *testing.T) {
			server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) { w.WriteHeader(c.status); io.WriteString(w, c.body) }))
			defer server.Close()
			_, err := checkOnce(server.Client(), server.URL, "test-only", "fictional test message")
			if (err != nil) != c.wantError {
				t.Fatalf("error=%v, expected error=%v", err, c.wantError)
			}
			durations, errors := measureSequential(server.Client(), server.URL, "test-only", 3)
			if c.wantError && (len(durations) != 0 || errors != 3) {
				t.Fatalf("successes=%d errors=%d", len(durations), errors)
			}
		})
	}
}
