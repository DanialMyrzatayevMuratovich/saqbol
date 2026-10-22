package history

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/gin-gonic/gin"
)

func TestParseDays(t *testing.T) {
	cases := []struct {
		raw  string
		days int
		ok   bool
	}{
		{"", 7, true},
		{"1", 1, true},
		{"7", 7, true},
		{"90", 90, true},
		{"0", 0, false},
		{"-7", 0, false},
		{"91", 0, false},
		{"7.5", 0, false},
		{"week", 0, false},
	}
	for _, tc := range cases {
		days, ok := parseDays(tc.raw)
		if days != tc.days || ok != tc.ok {
			t.Errorf("parseDays(%q) = %d, %v; want %d, %v", tc.raw, days, ok, tc.days, tc.ok)
		}
	}
}

func TestSummarySinceIsWholeDaysBack(t *testing.T) {
	now := time.Date(2026, 10, 22, 15, 30, 0, 0, time.UTC)
	want := time.Date(2026, 10, 15, 15, 30, 0, 0, time.UTC)
	if got := summarySince(now, 7); !got.Equal(want) {
		t.Fatalf("summarySince = %v, want %v", got, want)
	}
}

// A bad period is answered before the database is touched: the handler here
// has no store at all.
func TestSummaryRejectsBadDays(t *testing.T) {
	gin.SetMode(gin.TestMode)
	router := gin.New()
	NewHandler(nil).Register(router)

	for _, query := range []string{"days=0", "days=91", "days=abc"} {
		recorder := httptest.NewRecorder()
		request := httptest.NewRequest(http.MethodGet, "/history/summary?"+query, nil)
		router.ServeHTTP(recorder, request)

		if recorder.Code != http.StatusBadRequest {
			t.Fatalf("%s: status %d, want 400", query, recorder.Code)
		}
		var body map[string]string
		if err := json.Unmarshal(recorder.Body.Bytes(), &body); err != nil || body["error"] == "" {
			t.Fatalf("%s: want a JSON error, got %q", query, recorder.Body.String())
		}
	}
}
