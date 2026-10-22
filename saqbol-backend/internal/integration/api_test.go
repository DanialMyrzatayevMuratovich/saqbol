package integration

import (
	"context"
	"net/http"
	"strings"
	"testing"
	"time"

	"github.com/gorilla/websocket"
)

func TestHealth(t *testing.T) {
	a := newAPI(t, 0)
	body := a.expect(a.call("GET", "/health", "", nil), http.StatusOK)
	if body["status"] != "ok" {
		t.Fatalf("expected status ok, got %v", body)
	}
}

func TestRegisterAndLogin(t *testing.T) {
	a := newAPI(t, 0)

	access, refresh := a.register("+77000000101")
	if access == "" || refresh == "" {
		t.Fatal("expected both tokens")
	}

	a.expect(a.call("POST", "/api/v1/auth/register", "", map[string]string{"phone": "+77000000101", "password": "secret123"}), http.StatusConflict)
	a.expect(a.call("POST", "/api/v1/auth/register", "", map[string]string{"phone": "+77000000102", "password": "short"}), http.StatusBadRequest)
	a.expect(a.call("POST", "/api/v1/auth/register", "", map[string]string{"password": "secret123"}), http.StatusBadRequest)

	a.expect(a.call("POST", "/api/v1/auth/login", "", map[string]string{"phone": "+77000000101", "password": "secret123"}), http.StatusOK)
	a.expect(a.call("POST", "/api/v1/auth/login", "", map[string]string{"phone": "+77000000101", "password": "wrong-pass"}), http.StatusUnauthorized)
	a.expect(a.call("POST", "/api/v1/auth/login", "", map[string]string{"phone": "+77000000199", "password": "secret123"}), http.StatusUnauthorized)
	a.expect(a.call("POST", "/api/v1/auth/login", "", map[string]string{"phone": "+77000000101"}), http.StatusBadRequest)
}

func TestRefreshRotatesTheSession(t *testing.T) {
	a := newAPI(t, 0)
	access, refresh := a.register("+77000000111")

	body := a.expect(a.call("POST", "/api/v1/auth/refresh", "", map[string]string{"refresh_token": refresh}), http.StatusOK)
	if body["refresh_token"] == refresh {
		t.Fatal("expected a new refresh token")
	}

	// A refresh token works once; replaying it must fail.
	a.expect(a.call("POST", "/api/v1/auth/refresh", "", map[string]string{"refresh_token": refresh}), http.StatusUnauthorized)
	// An access token is signed with another secret and is not a refresh token.
	a.expect(a.call("POST", "/api/v1/auth/refresh", "", map[string]string{"refresh_token": access}), http.StatusUnauthorized)
	a.expect(a.call("POST", "/api/v1/auth/refresh", "", map[string]string{"refresh_token": "garbage"}), http.StatusUnauthorized)
	a.expect(a.call("POST", "/api/v1/auth/refresh", "", map[string]string{}), http.StatusBadRequest)
}

func TestProtectedEndpointsNeedAValidToken(t *testing.T) {
	a := newAPI(t, 0)
	routes := []struct{ method, path string }{
		{"POST", "/api/v1/sms/check"},
		{"POST", "/api/v1/sms/check/batch"},
		{"GET", "/api/v1/numbers/+77015550111/risk"},
		{"POST", "/api/v1/reports"},
		{"GET", "/api/v1/history"},
		{"POST", "/api/v1/call/analyze"},
		{"GET", "/api/v1/admin/metrics"},
		{"GET", "/api/v1/admin/messages"},
		{"GET", "/api/v1/admin/model-versions"},
		{"POST", "/api/v1/admin/model-versions"},
	}
	for _, route := range routes {
		a.expect(a.call(route.method, route.path, "", nil), http.StatusUnauthorized)
		a.expect(a.call(route.method, route.path, "not-a-jwt", nil), http.StatusUnauthorized)
	}
}

func TestSMSCheck(t *testing.T) {
	a := newAPI(t, 0)
	token, _ := a.register("+77000000121")

	body := a.expect(a.call("POST", "/api/v1/sms/check", token, map[string]string{
		"text": scamText, "source_number": "+77015550111",
	}), http.StatusOK)
	if body["verdict"] != "scam" || body["category"] != "fake_bank" {
		t.Fatalf("expected a fake_bank scam, got %v", body)
	}
	if triggers, _ := body["triggers"].([]any); len(triggers) == 0 {
		t.Fatalf("expected triggers, got %v", body)
	}
	if body["message_id"] == "" || body["advice"] == "" || body["model_version"] != "mock-rules-v1" {
		t.Fatalf("expected message id, advice and model version, got %v", body)
	}

	var detections int
	if err := pool.QueryRow(context.Background(),
		`SELECT count(*) FROM detections WHERE message_id = $1`, body["message_id"]).Scan(&detections); err != nil || detections != 1 {
		t.Fatalf("expected one stored detection, got %d (%v)", detections, err)
	}

	safe := a.expect(a.call("POST", "/api/v1/sms/check", token, map[string]string{"text": safeText}), http.StatusOK)
	if safe["verdict"] != "safe" {
		t.Fatalf("expected safe, got %v", safe)
	}

	a.expect(a.call("POST", "/api/v1/sms/check", token, map[string]string{"text": ""}), http.StatusBadRequest)
	a.expect(a.call("POST", "/api/v1/sms/check", token, map[string]string{"text": strings.Repeat("а", 4001)}), http.StatusBadRequest)
	a.expect(a.call("POST", "/api/v1/sms/check", token, map[string]string{"text": safeText, "source_number": strings.Repeat("7", 33)}), http.StatusBadRequest)
}

func TestSMSBatch(t *testing.T) {
	a := newAPI(t, 0)
	token, _ := a.register("+77000000131")

	body := a.expect(a.call("POST", "/api/v1/sms/check/batch", token, map[string]any{
		"messages": []map[string]string{
			{"external_id": "41", "text": scamText, "source_number": "+77015550112"},
			{"external_id": "42", "text": safeText},
		},
	}), http.StatusOK)
	results, _ := body["results"].([]any)
	if len(results) != 2 {
		t.Fatalf("expected two results, got %v", body)
	}
	first, second := results[0].(map[string]any), results[1].(map[string]any)
	if first["external_id"] != "41" || first["verdict"] != "scam" || second["external_id"] != "42" || second["verdict"] != "safe" {
		t.Fatalf("unexpected batch results: %v", results)
	}

	a.expect(a.call("POST", "/api/v1/sms/check/batch", token, map[string]any{"messages": []any{}}), http.StatusBadRequest)
	tooMany := make([]map[string]string, 101)
	for i := range tooMany {
		tooMany[i] = map[string]string{"text": safeText}
	}
	a.expect(a.call("POST", "/api/v1/sms/check/batch", token, map[string]any{"messages": tooMany}), http.StatusBadRequest)
}

func TestNumberReputation(t *testing.T) {
	a := newAPI(t, 0)
	token, _ := a.register("+77000000141")

	unknown := a.expect(a.call("GET", "/api/v1/numbers/+77015550113/risk", token, nil), http.StatusOK)
	if unknown["known"] != false || unknown["risk_score"] != 0.0 {
		t.Fatalf("expected an unknown number, got %v", unknown)
	}

	a.expect(a.call("POST", "/api/v1/sms/check", token, map[string]string{"text": scamText, "source_number": "+77015550113"}), http.StatusOK)
	known := a.expect(a.call("GET", "/api/v1/numbers/+77015550113/risk", token, nil), http.StatusOK)
	if known["known"] != true || known["risk_score"].(float64) <= 0 {
		t.Fatalf("expected a raised risk after a scam, got %v", known)
	}
}

func TestReports(t *testing.T) {
	a := newAPI(t, 0)
	owner, _ := a.register("+77000000151")
	stranger, _ := a.register("+77000000152")

	check := a.expect(a.call("POST", "/api/v1/sms/check", owner, map[string]string{"text": scamText, "source_number": "+77015550114"}), http.StatusOK)
	messageID := check["message_id"].(string)
	before := a.expect(a.call("GET", "/api/v1/numbers/+77015550114/risk", owner, nil), http.StatusOK)["risk_score"].(float64)

	created := a.expect(a.call("POST", "/api/v1/reports", owner, map[string]string{"message_id": messageID, "feedback": "confirmed"}), http.StatusCreated)
	if created["id"] == "" {
		t.Fatalf("expected a report id, got %v", created)
	}
	after := a.expect(a.call("GET", "/api/v1/numbers/+77015550114/risk", owner, nil), http.StatusOK)["risk_score"].(float64)
	if after <= before {
		t.Fatalf("expected a confirmed report to raise the risk: %v -> %v", before, after)
	}

	// Someone else's message looks exactly like a missing one.
	a.expect(a.call("POST", "/api/v1/reports", stranger, map[string]string{"message_id": messageID, "feedback": "confirmed"}), http.StatusNotFound)
	a.expect(a.call("POST", "/api/v1/reports", owner, map[string]string{"message_id": "00000000-0000-0000-0000-000000000000", "feedback": "confirmed"}), http.StatusNotFound)
	a.expect(a.call("POST", "/api/v1/reports", owner, map[string]string{"message_id": "not-a-uuid", "feedback": "confirmed"}), http.StatusBadRequest)
	a.expect(a.call("POST", "/api/v1/reports", owner, map[string]string{"message_id": messageID, "feedback": "maybe"}), http.StatusBadRequest)
}

func TestHistoryShowsOnlyOwnMessages(t *testing.T) {
	a := newAPI(t, 0)
	first, _ := a.register("+77000000161")
	second, _ := a.register("+77000000162")

	a.expect(a.call("POST", "/api/v1/sms/check", first, map[string]string{"text": safeText}), http.StatusOK)
	a.expect(a.call("POST", "/api/v1/sms/check", first, map[string]string{"text": scamText}), http.StatusOK)

	list := items(t, a.expect(a.call("GET", "/api/v1/history", first, nil), http.StatusOK))
	if len(list) != 2 || list[0].(map[string]any)["text"] != scamText {
		t.Fatalf("expected two messages, newest first, got %v", list)
	}
	if got := items(t, a.expect(a.call("GET", "/api/v1/history", second, nil), http.StatusOK)); len(got) != 0 {
		t.Fatalf("another user's history must be empty, got %v", got)
	}
	if got := items(t, a.expect(a.call("GET", "/api/v1/history?limit=1", first, nil), http.StatusOK)); len(got) != 1 {
		t.Fatalf("expected limit=1 to return one item, got %v", got)
	}
	if got := items(t, a.expect(a.call("GET", "/api/v1/history?channel=call", first, nil), http.StatusOK)); len(got) != 0 {
		t.Fatalf("expected no call items, got %v", got)
	}
}

func TestCallAnalyze(t *testing.T) {
	a := newAPI(t, 0)
	token, _ := a.register("+77000000171")

	body := a.expect(a.call("POST", "/api/v1/call/analyze", token, map[string]string{"transcript": scamText}), http.StatusOK)
	if body["alert"] != true || body["session_id"] == "" {
		t.Fatalf("expected an alert and a saved session, got %v", body)
	}
	var alerted bool
	if err := pool.QueryRow(context.Background(),
		`SELECT alert_triggered FROM call_sessions WHERE id = $1`, body["session_id"]).Scan(&alerted); err != nil || !alerted {
		t.Fatalf("expected the session to be stored with alert_triggered, got %v (%v)", alerted, err)
	}

	a.expect(a.call("POST", "/api/v1/call/analyze", token, map[string]string{"transcript": ""}), http.StatusBadRequest)
	a.expect(a.call("POST", "/api/v1/call/analyze", token, map[string]string{"transcript": strings.Repeat("а", 20001)}), http.StatusBadRequest)
}

func TestCallWebSocket(t *testing.T) {
	a := newAPI(t, 0)
	token, _ := a.register("+77000000181")
	wsURL := "ws" + strings.TrimPrefix(a.server.URL, "http") + "/ws/call"

	_, resp, err := websocket.DefaultDialer.Dial(wsURL, nil)
	if err == nil || resp == nil || resp.StatusCode != http.StatusUnauthorized {
		t.Fatalf("expected 401 without a token, got %v (%v)", resp, err)
	}

	conn, _, err := websocket.DefaultDialer.Dial(wsURL+"?token="+token, nil)
	if err != nil {
		t.Fatalf("dial: %v", err)
	}
	if err := conn.WriteJSON(map[string]string{"text": scamText}); err != nil {
		t.Fatalf("send fragment: %v", err)
	}
	var frame map[string]any
	_ = conn.SetReadDeadline(time.Now().Add(5 * time.Second))
	if err := conn.ReadJSON(&frame); err != nil {
		t.Fatalf("read alert: %v", err)
	}
	if frame["alert"] != true || frame["verdict"] != "scam" {
		t.Fatalf("expected a scam alert, got %v", frame)
	}
	conn.Close()

	// The session is saved after the socket closes.
	deadline := time.Now().Add(3 * time.Second)
	for {
		var count int
		if err := pool.QueryRow(context.Background(),
			`SELECT count(*) FROM call_sessions WHERE alert_triggered AND transcript LIKE '%код из смс%'`).Scan(&count); err == nil && count == 1 {
			return
		}
		if time.Now().After(deadline) {
			t.Fatal("expected the call session to be saved after the socket closed")
		}
		time.Sleep(50 * time.Millisecond)
	}
}

func TestAdminEndpointsNeedTheAdminRole(t *testing.T) {
	a := newAPI(t, 0)
	user, _ := a.register("+77000000191")
	admin := a.admin("+77000000192")

	for _, path := range []string{"/api/v1/admin/metrics", "/api/v1/admin/messages", "/api/v1/admin/model-versions"} {
		a.expect(a.call("GET", path, user, nil), http.StatusForbidden)
	}
	a.expect(a.call("POST", "/api/v1/admin/model-versions", user, map[string]string{"name": "x"}), http.StatusForbidden)

	a.expect(a.call("POST", "/api/v1/sms/check", user, map[string]string{"text": scamText}), http.StatusOK)

	metrics := a.expect(a.call("GET", "/api/v1/admin/metrics", admin, nil), http.StatusOK)
	if metrics["total_users"] != 2.0 || metrics["scam_messages"] != 1.0 {
		t.Fatalf("unexpected metrics: %v", metrics)
	}
	messages := items(t, a.expect(a.call("GET", "/api/v1/admin/messages?verdict=scam", admin, nil), http.StatusOK))
	if len(messages) != 1 || messages[0].(map[string]any)["phone"] != "+77000000191" {
		t.Fatalf("expected the user's scam message, got %v", messages)
	}

	created := a.expect(a.call("POST", "/api/v1/admin/model-versions", admin, map[string]string{
		"name": "xlm-roberta-v1", "metrics": `{"f1": 0.9}`,
	}), http.StatusCreated)
	if created["name"] != "xlm-roberta-v1" {
		t.Fatalf("unexpected model version: %v", created)
	}
	a.expect(a.call("POST", "/api/v1/admin/model-versions", admin, map[string]string{}), http.StatusBadRequest)
	versions := items(t, a.expect(a.call("GET", "/api/v1/admin/model-versions", admin, nil), http.StatusOK))
	found := false
	for _, v := range versions {
		if v.(map[string]any)["name"] == "xlm-roberta-v1" {
			found = true
		}
	}
	if !found {
		t.Fatalf("expected the new version in the list, got %v", versions)
	}
}

func TestRateLimit(t *testing.T) {
	a := newAPI(t, 3)
	login := map[string]string{"phone": "+77000000201", "password": "secret123"}
	for i := 0; i < 3; i++ {
		a.expect(a.call("POST", "/api/v1/auth/login", "", login), http.StatusUnauthorized)
	}
	a.expect(a.call("POST", "/api/v1/auth/login", "", login), http.StatusTooManyRequests)
}

func TestDetectionsReferenceTheModelVersion(t *testing.T) {
	a := newAPI(t, 0)
	token, _ := a.register("+77000000211")
	admin := a.admin("+77000000212")

	// A version registered by an administrator is reused, not duplicated.
	registered := a.expect(a.call("POST", "/api/v1/admin/model-versions", admin, map[string]string{
		"name": "mock-rules-v1", "metrics": `{"note": "registered before the first check"}`,
	}), http.StatusCreated)

	first := a.expect(a.call("POST", "/api/v1/sms/check", token, map[string]string{"text": scamText}), http.StatusOK)
	second := a.expect(a.call("POST", "/api/v1/sms/check", token, map[string]string{"text": safeText}), http.StatusOK)

	for _, check := range []map[string]any{first, second} {
		var versionID, versionName string
		err := pool.QueryRow(context.Background(), `
			SELECT d.model_version_id::text, v.name
			FROM detections d JOIN model_versions v ON v.id = d.model_version_id
			WHERE d.message_id = $1`, check["message_id"]).Scan(&versionID, &versionName)
		if err != nil {
			t.Fatalf("expected the detection to reference a model version: %v", err)
		}
		if versionID != registered["id"] || versionName != "mock-rules-v1" {
			t.Fatalf("expected the registered version %v, got %s (%s)", registered["id"], versionID, versionName)
		}
	}
}

func TestUnknownModelVersionIsRegisteredOnFirstUse(t *testing.T) {
	a := newAPI(t, 0)
	token, _ := a.register("+77000000221")

	a.expect(a.call("POST", "/api/v1/sms/check", token, map[string]string{"text": scamText}), http.StatusOK)
	a.expect(a.call("POST", "/api/v1/sms/check", token, map[string]string{"text": scamText}), http.StatusOK)

	var versions, linked int
	if err := pool.QueryRow(context.Background(),
		`SELECT count(*) FROM model_versions WHERE name = 'mock-rules-v1'`).Scan(&versions); err != nil {
		t.Fatal(err)
	}
	if err := pool.QueryRow(context.Background(),
		`SELECT count(*) FROM detections WHERE model_version_id IS NOT NULL`).Scan(&linked); err != nil {
		t.Fatal(err)
	}
	if versions != 1 || linked != 2 {
		t.Fatalf("expected one registered version used by both detections, got %d versions and %d linked detections", versions, linked)
	}
}
