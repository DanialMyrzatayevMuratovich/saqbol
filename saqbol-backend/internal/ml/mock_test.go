package ml

import (
	"context"
	"testing"
)

func TestMockClassifyScam(t *testing.T) {
	classifier := NewMock(0.8, 0.45)

	result, err := classifier.Classify(context.Background(), Request{
		Text:    "Служба безопасности банка, ваша карта заблокирована, назовите код из смс",
		Channel: ChannelSMS,
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if result.Verdict != VerdictScam {
		t.Fatalf("expected scam verdict, got %q", result.Verdict)
	}
	if result.Category != "fake_bank" {
		t.Fatalf("expected fake_bank category, got %q", result.Category)
	}
	if len(result.Triggers) == 0 {
		t.Fatal("expected triggers for a scam message")
	}
}

func TestMockClassifySafe(t *testing.T) {
	classifier := NewMock(0.8, 0.45)

	result, err := classifier.Classify(context.Background(), Request{
		Text:    "Привет, во сколько завтра встречаемся на обеде?",
		Channel: ChannelSMS,
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if result.Verdict != VerdictSafe {
		t.Fatalf("expected safe verdict, got %q", result.Verdict)
	}
	if result.Category != "" {
		t.Fatalf("expected empty category for safe message, got %q", result.Category)
	}
	if len(result.Triggers) != 0 {
		t.Fatalf("expected no triggers for safe message, got %v", result.Triggers)
	}
}

func TestMockClassifySuspicious(t *testing.T) {
	classifier := NewMock(0.8, 0.45)

	result, err := classifier.Classify(context.Background(), Request{
		Text:    "перейдите по ссылке для подтверждения",
		Channel: ChannelSMS,
	})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if result.Verdict != VerdictSuspicious {
		t.Fatalf("expected suspicious verdict, got %q", result.Verdict)
	}
}
