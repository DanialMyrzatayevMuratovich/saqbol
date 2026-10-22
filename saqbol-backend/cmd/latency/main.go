// Command latency measures the API latency behind NFR-1 (docs/09-verification-plan.md §9.6):
// SMS checks one after another and in parallel, a 100-message batch, and the server part of
// the call alert over the WebSocket. It prints a Markdown report.
//
// Run it against a started stack with rate limiting off, otherwise the limiter answers 429:
//
//	go run ./cmd/latency -api http://localhost:8080 -n 100 -workers 10
package main

import (
	"bytes"
	"encoding/json"
	"flag"
	"fmt"
	"math/rand"
	"net/http"
	"os"
	"runtime"
	"sort"
	"strings"
	"sync"
	"time"

	"github.com/gorilla/websocket"
)

// messages mixes Russian and Kazakh scams with ordinary texts, so the classifier does its
// usual amount of work.
var messages = []string{
	"Здравствуйте, служба безопасности банка. По вашей карте подозрительная операция, назовите код из смс",
	"Следователь прокуратуры: на вас оформлен кредит, срочно переведите деньги на безопасный счёт",
	"Поздравляем! Вы выиграли приз, для получения оплатите комиссию по ссылке",
	"Ваша посылка задержана на складе. Уточните адрес доставки: kazpost-delivery.info",
	"Привет, встречаемся завтра в 7 у кафе",
	"Ваш заказ доставлен в постамат, код получения 5521",
	"Құрметті клиент! Картаңыз бұғатталды. Бұғаттан шығару үшін смс кодын айтыңыз",
	"Құттықтаймыз! Сізге Kaspi арқылы 50 000 ₸ сыйлық түсті. Алу үшін kaspii.kz сілтемесіне өтіңіз",
	"Анам, кешке 7-де келемін, нан алып келейін бе?",
	"Ертең сабақ сағат 9-да басталады",
}

// A call script is what speech recognition would deliver: one final phrase at a time.
// trigger is the 1-based phrase after which a careful listener should be alarmed; 0 means
// the call is benign and should not alert.
type callScript struct {
	name    string
	trigger int
	phrases []string
}

var calls = []callScript{
	{"RU fake bank", 4, []string{
		"Алло, здравствуйте",
		"Вас беспокоит служба безопасности банка",
		"По вашей карте прошла подозрительная операция",
		"Чтобы её отменить, назовите код из смс",
		"Это нужно сделать прямо сейчас",
	}},
	{"RU fake police", 3, []string{
		"Добрый день, вас беспокоят из полиции",
		"Это следователь, по вашему делу есть вопросы",
		"На вас оформлен кредит, переведите деньги на безопасный счёт",
		"Никому не говорите о нашем разговоре",
	}},
	{"KK fake bank", 3, []string{
		"Сәлеметсіз бе",
		"Банктің қауіпсіздік қызметінен хабарласып тұрмыз",
		"Картаңыз бұғатталды, смс кодын айтыңыз",
		"Бұл өте шұғыл",
	}},
	{"RU courier (benign)", 0, []string{
		"Здравствуйте, это курьер",
		"Ваш заказ привезу завтра с десяти до двенадцати",
		"Будете дома?",
		"Хорошо, до свидания",
	}},
	{"RU bank reminder (benign)", 0, []string{
		"Здравствуйте, это ваш банк",
		"Напоминаем о платеже по кредиту до пятнадцатого числа",
		"Оплатить можно в приложении",
		"Хорошего дня",
	}},
}

type checkResponse struct {
	Verdict string `json:"verdict"`
}

type alertFrame struct {
	Verdict     string  `json:"verdict"`
	Probability float64 `json:"probability"`
	Alert       bool    `json:"alert"`
}

func main() {
	api := flag.String("api", "http://localhost:8080", "backend base URL")
	n := flag.Int("n", 100, "requests in the sequential and in the parallel run")
	workers := flag.Int("workers", 10, "parallel workers")
	flag.Parse()

	client := &http.Client{Timeout: 30 * time.Second}
	token := mustRegister(client, *api)

	// Warm-up: connections, model and caches. Not counted.
	for i := 0; i < 5; i++ {
		_, _ = checkOnce(client, *api, token, messages[i%len(messages)])
	}

	sequential, seqErrors := measureSequential(client, *api, token, *n)
	parallel, parErrors, wall := measureParallel(client, *api, token, *n, *workers)
	batches := measureBatches(client, *api, token, 3)

	fmt.Printf("## Latency run %s\n\n", time.Now().Format("2006-01-02 15:04 MST"))
	fmt.Printf("Client: %s/%s, %d CPUs, Go %s. API: %s\n\n", runtime.GOOS, runtime.GOARCH, runtime.NumCPU(), runtime.Version(), *api)

	fmt.Println("### SMS check (`POST /api/v1/sms/check`), client side")
	fmt.Println()
	fmt.Println("| Run | Requests | Errors | p50 | p95 | p99 | max |")
	fmt.Println("|---|---|---|---|---|---|---|")
	printRow("Sequential", sequential, seqErrors)
	printRow(fmt.Sprintf("Parallel, %d workers", *workers), parallel, parErrors)
	fmt.Printf("\nParallel run: %d requests in %s (%.0f req/s).\n\n", *n, wall.Round(time.Millisecond), float64(*n)/wall.Seconds())

	fmt.Println("### Inbox scan (`POST /api/v1/sms/check/batch`, 100 messages)")
	fmt.Println()
	for i, d := range batches {
		fmt.Printf("- Run %d: %s\n", i+1, d.Round(time.Millisecond))
	}
	fmt.Println()

	fmt.Println("### Call alert, server part (`/ws/call`)")
	fmt.Println()
	fmt.Println("Time from sending a recognised phrase to the server's answer for it. Speech recognition and the phone are not included.")
	fmt.Println()
	fmt.Println("| Script | Trigger phrase | Alert at phrase | Answer time at alert | Slowest answer | Result |")
	fmt.Println("|---|---|---|---|---|---|")
	for _, script := range calls {
		runCall(*api, token, script)
	}
}

func mustRegister(client *http.Client, api string) string {
	phone := fmt.Sprintf("+7709%07d", rand.Intn(10_000_000))
	body, _ := json.Marshal(map[string]string{"phone": phone, "password": "bench-" + phone[5:], "name": "Latency bench"})
	resp, err := client.Post(api+"/api/v1/auth/register", "application/json", bytes.NewReader(body))
	if err != nil {
		fail("register: %v", err)
	}
	defer resp.Body.Close()
	var tokens struct {
		AccessToken string `json:"access_token"`
	}
	if resp.StatusCode != http.StatusCreated || json.NewDecoder(resp.Body).Decode(&tokens) != nil {
		fail("register: HTTP %d", resp.StatusCode)
	}
	return tokens.AccessToken
}

func checkOnce(client *http.Client, api, token, text string) (time.Duration, error) {
	body, _ := json.Marshal(map[string]string{"text": text})
	req, _ := http.NewRequest("POST", api+"/api/v1/sms/check", bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Authorization", "Bearer "+token)

	start := time.Now()
	resp, err := client.Do(req)
	if err != nil {
		return 0, err
	}
	defer resp.Body.Close()
	var decoded checkResponse
	if err := json.NewDecoder(resp.Body).Decode(&decoded); err != nil {
		return 0, err
	}
	elapsed := time.Since(start)
	if resp.StatusCode != http.StatusOK || decoded.Verdict == "" {
		return 0, fmt.Errorf("HTTP %d", resp.StatusCode)
	}
	return elapsed, nil
}

func measureSequential(client *http.Client, api, token string, n int) ([]time.Duration, int) {
	durations := make([]time.Duration, 0, n)
	errors := 0
	for i := 0; i < n; i++ {
		d, err := checkOnce(client, api, token, messages[i%len(messages)])
		if err != nil {
			errors++
			continue
		}
		durations = append(durations, d)
	}
	return durations, errors
}

func measureParallel(client *http.Client, api, token string, n, workers int) ([]time.Duration, int, time.Duration) {
	jobs := make(chan int)
	var mu sync.Mutex
	var wg sync.WaitGroup
	durations := make([]time.Duration, 0, n)
	errors := 0

	start := time.Now()
	for w := 0; w < workers; w++ {
		wg.Add(1)
		go func() {
			defer wg.Done()
			for i := range jobs {
				d, err := checkOnce(client, api, token, messages[i%len(messages)])
				mu.Lock()
				if err != nil {
					errors++
				} else {
					durations = append(durations, d)
				}
				mu.Unlock()
			}
		}()
	}
	for i := 0; i < n; i++ {
		jobs <- i
	}
	close(jobs)
	wg.Wait()
	return durations, errors, time.Since(start)
}

func measureBatches(client *http.Client, api, token string, runs int) []time.Duration {
	items := make([]map[string]string, 100)
	for i := range items {
		items[i] = map[string]string{"external_id": fmt.Sprint(i), "text": messages[i%len(messages)]}
	}
	body, _ := json.Marshal(map[string]any{"messages": items})

	results := make([]time.Duration, 0, runs)
	for r := 0; r < runs; r++ {
		req, _ := http.NewRequest("POST", api+"/api/v1/sms/check/batch", bytes.NewReader(body))
		req.Header.Set("Content-Type", "application/json")
		req.Header.Set("Authorization", "Bearer "+token)
		start := time.Now()
		resp, err := client.Do(req)
		if err != nil {
			fail("batch: %v", err)
		}
		var decoded struct {
			Results []json.RawMessage `json:"results"`
		}
		_ = json.NewDecoder(resp.Body).Decode(&decoded)
		resp.Body.Close()
		if resp.StatusCode != http.StatusOK || len(decoded.Results) != 100 {
			fail("batch: HTTP %d, %d results", resp.StatusCode, len(decoded.Results))
		}
		results = append(results, time.Since(start))
	}
	return results
}

func runCall(api, token string, script callScript) {
	wsURL := "ws" + strings.TrimPrefix(api, "http") + "/ws/call?token=" + token
	conn, _, err := websocket.DefaultDialer.Dial(wsURL, nil)
	if err != nil {
		fail("dial %s: %v", script.name, err)
	}
	defer conn.Close()

	alertAt := 0
	var alertTime, slowest time.Duration
	for i, phrase := range script.phrases {
		start := time.Now()
		if err := conn.WriteJSON(map[string]string{"text": phrase}); err != nil {
			fail("send: %v", err)
		}
		var frame alertFrame
		_ = conn.SetReadDeadline(time.Now().Add(10 * time.Second))
		if err := conn.ReadJSON(&frame); err != nil {
			fail("read: %v", err)
		}
		elapsed := time.Since(start)
		if elapsed > slowest {
			slowest = elapsed
		}
		if frame.Alert && alertAt == 0 {
			alertAt, alertTime = i+1, elapsed
		}
	}

	trigger, at, answer := "—", "no alert", "—"
	if script.trigger > 0 {
		trigger = fmt.Sprint(script.trigger)
	}
	if alertAt > 0 {
		at, answer = fmt.Sprint(alertAt), ms(alertTime)
	}
	result := "correct"
	switch {
	case script.trigger == 0 && alertAt > 0:
		result = "false alarm"
	case script.trigger > 0 && alertAt == 0:
		result = "missed"
	case script.trigger > 0 && alertAt > script.trigger:
		result = fmt.Sprintf("late by %d phrase(s)", alertAt-script.trigger)
	}
	fmt.Printf("| %s | %s | %s | %s | %s | %s |\n", script.name, trigger, at, answer, ms(slowest), result)
}

func printRow(name string, durations []time.Duration, errors int) {
	if len(durations) == 0 {
		fmt.Printf("| %s | 0 | %d | — | — | — | — |\n", name, errors)
		return
	}
	sort.Slice(durations, func(i, j int) bool { return durations[i] < durations[j] })
	fmt.Printf("| %s | %d | %d | %s | %s | %s | %s |\n", name, len(durations)+errors, errors,
		ms(percentile(durations, 50)), ms(percentile(durations, 95)), ms(percentile(durations, 99)), ms(durations[len(durations)-1]))
}

// percentile uses the nearest-rank method on sorted durations.
func percentile(sorted []time.Duration, p int) time.Duration {
	rank := (p*len(sorted) + 99) / 100
	if rank < 1 {
		rank = 1
	}
	return sorted[rank-1]
}

func ms(d time.Duration) string {
	return fmt.Sprintf("%.1f ms", float64(d.Microseconds())/1000)
}

func fail(format string, args ...any) {
	fmt.Fprintf(os.Stderr, "latency: "+format+"\n", args...)
	os.Exit(1)
}
