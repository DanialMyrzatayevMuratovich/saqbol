# Prototype screenshots

Screenshots of the key scenarios in [08-prototype.md](../08-prototype.md) (task SAQ-35), taken on
2026-10-22.

**Setup:** full stack started with `docker compose up -d --build` on a MacBook. The mobile app is
a release build (arm64) on the Android emulator (API 36) with `API_BASE_URL=http://10.0.2.2:8080`.
The model is `baseline-tfidf-logreg-v1`. Only a demo account (`+77000000001`) and fictional
sender numbers (`+7701555xxxx`, `+7701123xxxx`) are used. The scam texts are written after the
schemes in the [relevance evidence](../02-relevance-evidence.md).

## Mobile app

| Screenshot | Scenario | What it shows |
|---|---|---|
| [mobile-01-login.png](mobile-01-login.png) | S1 Login | Login with "remember me" and the language menu (Русский / Қазақша / English) |
| [mobile-02-sms-scam-ru.png](mobile-02-sms-scam-ru.png) | S2 Check a Russian SMS | Fake bank: *scam 94%*, category, trigger phrases highlighted, advice, feedback buttons |
| [mobile-03-sms-scam-kk.png](mobile-03-sms-scam-kk.png) | S2 Check a Kazakh SMS | Kazakh interface; fake prize with a look-alike `kaspii.kz` link: *Алаяқтық 82%*, advice in Kazakh |
| [mobile-04-sms-safe.png](mobile-04-sms-safe.png) | S2 Safe message | English interface; a personal message classified as safe |
| [mobile-05-guard.png](mobile-05-guard.png) | S3 Protection | Automatic SMS check and call screening switched on; inbox scan results |
| [mobile-07-voice.png](mobile-07-voice.png) | S4 Live call analysis | Start screen of a session. The live alert is not shown because the emulator has no microphone input |
| [mobile-08-history.png](mobile-08-history.png) | S5 History | Checks in Kazakh and Russian with verdict, category and time |

Not captured:

| Planned | Why | Task |
|---|---|---|
| `mobile-06-guard-notification.png` | In the release build an incoming scam SMS is not checked in the background, and the call warning for a high-risk number is not shown | [SAQ-36](https://saqbol.youtrack.cloud/issue/SAQ-36), [SAQ-37](https://saqbol.youtrack.cloud/issue/SAQ-37) |
| Live-call alert | Needs a real phone with a microphone | SAQ-23 |

Usability problems noticed while capturing are listed in
[SAQ-38](https://saqbol.youtrack.cloud/issue/SAQ-38).

## Web dashboard (admin)

| Screenshot | Scenario | What it shows |
|---|---|---|
| [web-01-dashboard.png](web-01-dashboard.png) | W1 Metrics | Users, checks, scam / suspicious counts, call alerts, categories chart, verdict split |
| [web-02-messages.png](web-02-messages.png) | W2 Flagged messages | Latest checks of the demo account (rows of older test accounts were hidden before capturing) |
| [web-03-models.png](web-03-models.png) | W3 Model versions | The baseline registered with its real-only metrics from [verification plan §9.3](../09-verification-plan.md#93-current-baseline) |

The dashboard totals include earlier test data in the local database.
