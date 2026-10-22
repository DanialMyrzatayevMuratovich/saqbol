package main

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"net/http/httptest"
	"os"
	"os/exec"
	"testing"
	"time"
)

// The reviewed function can call os.Exit, so invoke it in a child process.
// Either an empty successful-sample list or an explicit batch error is a rejection.
// This diagnostic assumes the reviewed measureBatches signature; see README.md.
func TestReviewBatchItemFailuresRejected(t *testing.T) {
	if os.Getenv("SAQ23_REVIEW_BATCH_ERROR_CHILD") == "1" {
		server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			results := make([]map[string]string, 100)
			for i := range results {
				results[i] = map[string]string{
					"external_id": fmt.Sprint(i), "error": "ML service unavailable",
				}
			}
			w.Header().Set("Content-Type", "application/json")
			if err := json.NewEncoder(w).Encode(map[string]any{"results": results}); err != nil {
				t.Errorf("write fake response: %v", err)
			}
		}))
		defer server.Close()
		samples := measureBatches(server.Client(), server.URL, "test-only", 1)
		if len(samples) == 0 {
			fmt.Println("SAQ23_BATCH_REJECTED_EMPTY")
		} else {
			fmt.Printf("SAQ23_BATCH_ACCEPTED:%d\n", len(samples))
		}
		return
	}

	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()
	child := exec.CommandContext(ctx, os.Args[0], "-test.run=^TestReviewBatchItemFailuresRejected$", "-test.v")
	child.Env = append(os.Environ(), "SAQ23_REVIEW_BATCH_ERROR_CHILD=1")
	output, err := child.CombinedOutput()
	if ctx.Err() != nil {
		t.Fatalf("probe timed out; rejection was not established: %v\n%s", ctx.Err(), output)
	}
	for _, marker := range []string{"panic:", "fatal error:", "runtime error:"} {
		if bytes.Contains(output, []byte(marker)) {
			t.Fatalf("unexpected crash is not a valid batch rejection:\n%s", output)
		}
	}
	if bytes.Contains(output, []byte("SAQ23_BATCH_ACCEPTED:")) {
		t.Fatalf("100 failed items produced a successful scan sample:\n%s", output)
	}
	if err == nil && bytes.Contains(output, []byte("SAQ23_BATCH_REJECTED_EMPTY")) {
		return
	}
	if exit, ok := err.(*exec.ExitError); ok && exit.ExitCode() == 1 &&
		bytes.Contains(output, []byte("latency: batch:")) {
		return // Existing fail("batch: ...") convention, without a panic.
	}
	t.Fatalf("unrecognised probe outcome; inspect before treating as rejection: %v\n%s", err, output)
}
