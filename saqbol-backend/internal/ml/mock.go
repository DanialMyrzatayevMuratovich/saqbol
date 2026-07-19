package ml

import (
	"context"
	"sort"
	"strings"
	"time"
)

type categoryRule struct {
	name     string
	triggers []string
	advice   string
}

type MockClassifier struct {
	scamThreshold       float64
	suspiciousThreshold float64
	rules               []categoryRule
	safeAdvice          string
}

func NewMock(scamThreshold, suspiciousThreshold float64) *MockClassifier {
	return &MockClassifier{
		scamThreshold:       scamThreshold,
		suspiciousThreshold: suspiciousThreshold,
		safeAdvice:          "Сообщение выглядит безопасным, но всегда сверяйте отправителя.",
		rules: []categoryRule{
			{
				name:   "fake_bank",
				advice: "Банк никогда не просит код из СМС. Не отвечайте, позвоните в банк сами по номеру с карты.",
				triggers: []string{
					"код из смс", "код из sms", "карта заблокирована", "служба безопасности",
					"продиктуйте код", "назовите код", "карта бұғатталды", "қауіпсіздік қызметі",
					"смс код", "одноразовый код",
				},
			},
			{
				name:   "phishing",
				advice: "Не переходите по ссылке. Проверьте домен вручную, мошенники подделывают адреса банков.",
				triggers: []string{
					"перейдите по ссылке", "kaspii.kz", "kaspi-kz", "egov-kz", "срочно перейдите",
					"подтвердите данные", "сілтеме", "http://", "войдите по ссылке",
				},
			},
			{
				name:   "fake_prize",
				advice: "Настоящие розыгрыши не требуют комиссию заранее. Не переводите деньги за «приз».",
				triggers: []string{
					"вы выиграли", "поздравляем", "ваш приз", "компенсация", "выплата положена",
					"оплатите комиссию", "сыйлық", "ұтып алдыңыз", "получите выплату",
				},
			},
			{
				name:   "fake_police",
				advice: "Полиция и прокуратура не требуют переводить деньги на «безопасный счёт». Это мошенничество.",
				triggers: []string{
					"полиция", "прокуратура", "уголовное дело", "на вас оформлен кредит",
					"безопасный счёт", "переведите деньги", "следователь", "возбуждено дело",
				},
			},
			{
				name:   "kaspi_scam",
				advice: "Оплату и переводы делайте только в официальном приложении Kaspi, не по присланным ссылкам.",
				triggers: []string{
					"kaspi.link", "оплата kaspi", "перевод kaspi", "каспи перевод", "оплатите через каспи",
				},
			},
		},
	}
}

func (m *MockClassifier) Classify(ctx context.Context, req Request) (Result, error) {
	start := time.Now()
	lowered := strings.ToLower(req.Text)

	bestCategory := ""
	bestAdvice := m.safeAdvice
	matched := make([]string, 0)
	bestCount := 0

	for _, rule := range m.rules {
		hits := make([]string, 0)
		for _, trigger := range rule.triggers {
			if strings.Contains(lowered, trigger) {
				hits = append(hits, trigger)
			}
		}
		if len(hits) > bestCount {
			bestCount = len(hits)
			bestCategory = rule.name
			bestAdvice = rule.advice
			matched = hits
		}
	}

	probability := scoreFromMatches(bestCount)
	verdict := VerdictSafe
	switch {
	case probability >= m.scamThreshold:
		verdict = VerdictScam
	case probability >= m.suspiciousThreshold:
		verdict = VerdictSuspicious
	}

	if verdict == VerdictSafe {
		bestCategory = ""
		bestAdvice = m.safeAdvice
		matched = make([]string, 0)
	}

	sort.Strings(matched)

	return Result{
		Verdict:      verdict,
		Probability:  probability,
		Category:     bestCategory,
		Triggers:     matched,
		Advice:       bestAdvice,
		LatencyMs:    int(time.Since(start).Milliseconds()),
		ModelVersion: "mock-rules-v1",
	}, nil
}

func scoreFromMatches(count int) float64 {
	switch {
	case count == 0:
		return 0.05
	case count == 1:
		return 0.55
	case count == 2:
		return 0.82
	default:
		return 0.94
	}
}
