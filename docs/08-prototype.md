# 8. Prototype

This page inventories prototype screens and API examples from `main` at `91862dc`.
Implemented code is distinguished from a successful device demonstration: Kazakh speech
recognition and the real-call scenario are not verified. See
[implementation evidence](implementation-evidence.md) for current support and pending work.

- **Run it:** `docker compose up -d --build` (see the [README](../README.md#quick-start)), then open
  http://localhost:3000 for the web dashboard. The mobile app is built from `saqbol-mobile/` with
  `--dart-define=API_BASE_URL=…`.
- **Screenshots:** proposed in [PR #16](https://github.com/DanialMyrzatayevMuratovich/saqbol/pull/16)
  (task SAQ-35); they are not part of this `main` snapshot.

## 8.1 Key user scenarios and screens

### Mobile app (Flutter)

| # | Scenario | Screen(s) | What the user sees |
|---|---|---|---|
| S1 | Register / log in (UC-1) | `login_screen.dart` | Phone + password; language switch (ҚАЗ / РУС) |
| S2 | Check a suspicious SMS and give feedback (UC-2, UC-3, UC-9) | `sms_check_screen.dart`, `verdict_card.dart`, `highlighted_message.dart` | Verdict card (safe / suspicious / scam, probability, category), highlighted trigger phrases and advice; "confirmed scam" / "false alarm" buttons when the result has a message ID |
| S3 | Turn on protection (UC-5, UC-6) | `guard_screen.dart` | Permission and inbox-scan UI, intended SMS/call warnings; Android permission, background and call-screening behavior still require device verification |
| S4 | Live call analysis (UC-7) | `voice_screen.dart` | Recognised or manually entered transcript, risk indicator and inline alert; the controller requests Russian recognition (`ru_RU`) and calls haptic/sound APIs. Real-call behavior is unverified; the full-screen alert is a separate PR #20 change. |
| S5 | History (UC-10) | `history_screen.dart` | Read-only list of previously checked SMS with verdict, category, date and probability. Feedback is on the SMS verdict card; stored call sessions are not returned by the current history endpoint. |

### Web dashboard (Next.js, admin only)

| # | Scenario | Page | What the admin sees |
|---|---|---|---|
| W1 | Monitor detection (UC-12) | `/` | Totals, verdict split, scam categories chart |
| W2 | Review flagged messages (UC-13) | `/messages` | Latest checks filtered by verdict, with category and triggers |
| W3 | Track model versions (UC-14) | `/models` | Registered model versions and their metrics |

## 8.2 API examples

The original prototype documentation records the SMS outputs below for the development
baseline (`baseline-tfidf-logreg-v1`, trained on 2026-10-10), with a run date of 2026-10-22.
They were not rerun as part of this documentation correction and are examples, not a held-out
quality evaluation or evidence that the input texts are authentic received SMS. The backend
contract adds `message_id` and stores the result.

### Register

```http
POST /api/v1/auth/register
Content-Type: application/json

{"phone": "+77000000001", "password": "secret123", "name": "Demo", "locale": "kk"}
```

```json
{"access_token": "eyJ…", "refresh_token": "eyJ…", "expires_in": 900}
```

### Check an SMS (Russian, fake bank)

```http
POST /api/v1/sms/check
Authorization: Bearer <access_token>
Content-Type: application/json

{"text": "Служба безопасности банка. По вашей карте подозрительная операция, назовите код из смс для отмены",
 "source_number": "+77770001100"}
```

```json
{
  "message_id": "…",
  "verdict": "scam",
  "probability": 0.94,
  "category": "fake_bank",
  "triggers": ["код из смс", "служба безопасности", "назовите код", "банка", "служба", "безопасности", "код из"],
  "advice": "Банк никогда не просит код из СМС. Не отвечайте, позвоните в банк сами по номеру с карты.",
  "model_version": "baseline-tfidf-logreg-v1"
}
```

### Check an SMS (Kazakh, fake prize with a look-alike Kaspi domain)

Input: `"Сізге Kaspi арқылы 50000 тг ұтыс түсті! Алу үшін kaspii.kz сілтемесіне өтіп, деректерді растаңыз"`

```json
{
  "verdict": "scam",
  "probability": 0.857,
  "category": "phishing",
  "triggers": ["kaspii.kz", "kaspi", "сізге", "ұтыс", "растаңыз", "деректерді"],
  "advice": "Не переходите по ссылке. Проверьте домен вручную, мошенники подделывают адреса банков.",
  "model_version": "baseline-tfidf-logreg-v1"
}
```

### Check an SMS (Russian, legitimate)

Input: `"Мама, я завтра в 7 заеду, купи хлеба пожалуйста"`

```json
{"verdict": "safe", "probability": 0.1796, "category": "", "triggers": [],
 "advice": "Сообщение выглядит безопасным, но всегда сверяйте отправителя.",
 "model_version": "baseline-tfidf-logreg-v1"}
```

### Batch check (inbox scan, up to 100 messages)

```http
POST /api/v1/sms/check/batch
{"messages": [{"external_id": "inbox-42", "text": "…", "source_number": "+7…"}, …]}
```

```json
{"results": [{"external_id": "inbox-42", "verdict": "scam", "probability": 0.91, …},
             {"external_id": "inbox-43", "error": "…"}]}
```

One bad message returns a per-item `error` and does not fail the whole batch.

### Number reputation (used by Android call screening)

```http
GET /api/v1/numbers/%2B77770001100/risk
```

```json
{"number": "+77770001100", "reports_count": 1, "risk_score": 0.2, "last_reported": "…"}
```

### Live call analysis (WebSocket)

```text
→ connect  ws://<host>:8080/ws/call?token=<access_token>
→ {"text": "Сәлеметсіз бе, сізге банктің қауіпсіздік қызметінен хабарласып тұрмыз"}
← {"verdict": "suspicious", "probability": 0.6, "category": "fake_bank", "triggers": ["қауіпсіздік қызметі"], "advice": "…", "alert": false}
→ {"text": "картаңызды бұғаттамау үшін смс кодын айтыңыз"}
← {"verdict": "scam", "probability": 0.93, "category": "fake_bank", "triggers": ["смс кодын", "қауіпсіздік қызметі"], "advice": "…", "alert": true}
```

The WebSocket exchange shows manually supplied Kazakh text and the message shape. Its
probabilities are illustrative; actual values depend on the model version. This is not a
recorded speech-recognition test and does not demonstrate Kazakh STT. The current controller
requests `ru_RU`; even PR #20 at `f361a8f` maps the Kazakh UI setting to `ru_RU`.

### Feedback

```http
POST /api/v1/reports
{"message_id": "…", "feedback": "false_positive"}
```

## 8.3 Limitations visible in the prototype

- Kazakh speech recognition is planned, not implemented. Device tests for Russian recognition,
  microphone access during calls, word error rate and alert latency are still pending.
- SaqBol receives transcript text, not microphone audio. The OS speech service may process
  audio locally or through its provider; the app does not enforce local-only recognition.
- Call transcripts are stored in `call_sessions`, but the history screen/API exposes checked
  SMS only. Call-history integration remains pending.
- Advice texts come from the rule engine and are in Russian even when the message is in Kazakh.
  Kazakh advice is planned together with FR-18.
- The single-token triggers produced by the model ("банка", "служба") are less useful to the
  user than the rule phrases. Filtering them is part of the explainability work.
- iOS: no automatic SMS check and no call screening (platform limits; see the proposal's scope).
