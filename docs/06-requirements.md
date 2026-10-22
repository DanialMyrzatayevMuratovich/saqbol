# 6. Requirements Specification (initial)

Version 1.0, pre-defense 1. This supersedes the requirement lists in the original
Russian draft `SaqBol_TZ.md` (§6–7).

**Priority (MoSCoW):** **M** = Must (needed to reach the project aim), **S** = Should,
**C** = Could, **W** = Won't in this diploma.
**Verification:** T = automated test, D = demonstration, E = experiment / measurement,
I = inspection (code or document review).
**Status:** ✅ implemented, 🟡 partial, ⬜ not started. "T" marks the intended verification;
which automated tests exist today is listed in the [verification plan](09-verification-plan.md#92-test-levels).

Implementation status is assessed against `main` at `91862dcca5d218887db7fd57fc1e88c4f3d2bf21` unless a row names a pending PR. An implemented code path is not evidence of a successful device test. Interface language, transcript classification language, and speech-recognition language are separate capabilities. A pending experiment or candidate recognizer is not an implemented fallback.

For NFR-2, the current 228-row diagnostic subset is selected by `source` not starting with `synthetic`: 44 seed rows and 184 rows tagged as imported from `Yerassyl04/Spam-kazakh`. It contains 47 scam-labelled rows, 75 suspicious and 106 safe. This metadata rule does not establish human authorship or receipt by an actual SMS recipient. It is not the future provenance-verified received-SMS acceptance set. Dataset composition and pending evaluation changes are described in the verification plan; PR #25 adds the dataset card.

Use-case IDs (UC-n) refer to the [use case diagram](../diagrams/export/use-case.svg).

## 6.1 Functional requirements

### SMS module

| ID | Requirement | Pri. | Acceptance criteria | Verif. | Status |
|---|---|---|---|---|---|
| FR-1 | The system classifies an SMS text as *safe*, *suspicious* or *scam* and returns a probability (UC-2) | M | `POST /api/v1/sms/check` with a non-empty text ≤ 4,000 chars returns 200 with `verdict` ∈ {safe, suspicious, scam} and `probability` ∈ [0, 1]; scam if p ≥ 0.80, suspicious if 0.45 ≤ p < 0.80 (configurable thresholds) | T, D | ✅ |
| FR-2 | For a non-safe verdict the system names the scam category | M | `category` ∈ {fake_bank, phishing, fake_prize, fake_police, kaspi_scam, other}; for each category, at least one reference message in the test suite is assigned to it | T | 🟡 all six categories are produced; on `main` the tests cover `fake_bank` only, tests for the other categories come with PR #14 (SAQ-17) |
| FR-3 | The system highlights trigger phrases and dangerous links and gives advice (UC-3) | M | Non-safe responses contain 1–8 `triggers` and a non-empty `advice`; the app highlights every trigger that occurs in the text | T, D | 🟡 rule-based verdicts carry triggers; a scam decided by the model alone can come with an empty `triggers` list, so the app has nothing to highlight. We do not invent triggers: the gap is open (SAQ-25) |
| FR-4 | The system keeps a reputation score for sender numbers | M | A scam verdict or a "confirmed" report raises `risk_score` of the sender number; a "false alarm" report lowers it; the score stays in [0, 1]; `GET /api/v1/numbers/{n}/risk` returns it | T, D | ✅ |
| FR-5 | The user can paste or share a message for manual check | M | From the SMS screen the user gets a verdict card within 1 s on the demo server (see NFR-1) | D | 🟡 paste ✅; sharing from other apps not yet (SAQ-52); 1 s not yet measured on the demo server (local p95 3 ms, PR #23) |
| FR-6 | (Android) With the user's permission the app scans the SMS inbox and checks incoming SMS automatically (UC-5) | S | After granting SMS permission, an inbox scan sends messages in batches of ≤ 100 (`/sms/check/batch`); an incoming scam SMS raises a local notification | D | 🟡 inbox scan ✅; the automatic check of incoming SMS never ran because the SMS receiver was not declared. Fixed in PR #26 and verified on the emulator; real phone pending (SAQ-36, SAQ-46) |
| FR-7 | (iOS) SMS from unknown senders are filtered with an `ILMessageFilterExtension` | C | Extension marks a known scam text from an unknown sender as junk on a test device | D | ⬜ |
| FR-8 | The user can give feedback on a verdict: "confirmed scam" or "false alarm" (UC-9) | M | `POST /api/v1/reports` stores the feedback, linked to the message; a report on another user's message is rejected with 404 | T, D | ✅ |
| FR-20 | (Android 10+) On an incoming call from a high-risk number the app warns the user (UC-6) | S | With the call-screening role granted, a call from a number with `risk_score` ≥ threshold shows a warning notification with the risk and the number of reports | D | 🟡 implemented; on a device the warning can be lost because the lookup is cancelled after `respondToCall` (SAQ-37; fix in PR #18 not yet checked on a phone) |

### Voice (call) module

| ID | Requirement | Pri. | Acceptance criteria | Verif. | Status |
|---|---|---|---|---|---|
| FR-9 | The user can start a live analysis session during a call on speakerphone (UC-7) | M | Session opens an authenticated WebSocket to `/ws/call`; without a valid token the connection is refused | T, D | ✅ |
| FR-10 | Speech is transcribed in Kazakh or Russian while the call goes on | M | For each required language, demonstrate microphone recognition and display of recognised text on a recorded test-device configuration; record device/OS, recognition service, available and requested locale, network mode, test utterances and language-specific WER under the verification plan. Selecting Russian recognition in the Kazakh interface does not satisfy Kazakh STT acceptance; classify manually supplied Kazakh/Russian transcripts under FR-11 separately | D, E | 🟡 Russian recognition code path configured on `main` (`ru_RU`); device behaviour and WER are not verified by this document. Kazakh STT is not implemented/verified. Pending PR #15 selects `en_US` for English UI and `ru_RU` for Russian/Kazakh UI; this does not add Kazakh STT. Whisper evaluation using KSC2 data is a candidate experiment (SAQ-23), not an implemented fallback |
| FR-11 | The transcript is classified in real time with a sliding window | M | Every received fragment triggers classification of the last 600 characters; the server answers each fragment with probability, category and triggers | T | ✅ |
| FR-12 | When the risk passes the threshold the app alerts the user (screen + vibration) | M | p ≥ 0.80 → red alert with advice and haptic feedback; alert latency per NFR-1 | D, E | ✅ |
| FR-13 | A recorded or pasted call transcript can be analysed offline (UC-8) | S | `POST /api/v1/call/analyze` with a transcript ≤ 20,000 chars returns verdict and alert flag and stores a call session. Audio upload is **not** included | T | 🟡 transcript only |
| FR-14 | Call transcript, maximum probability and alert flag are saved to history | M | After a session closes, a `call_sessions` row exists with transcript, `max_probability`, `alert_triggered` | T | ✅ saved in `call_sessions`. Not visible in the user's history yet, see FR-16 |

### Common

| ID | Requirement | Pri. | Acceptance criteria | Verif. | Status |
|---|---|---|---|---|---|
| FR-15 | Registration and login by phone number and password (UC-1) | M | Register → login → access token (short-lived) + refresh token; refresh issues a new pair; protected endpoints return 401 without a valid token | T | ✅ |
| FR-16 | The user sees a history of checks with filters (UC-10) | S | `GET /api/v1/history` returns only the caller's checks, newest first, filterable by channel (sms / call) | T, D | 🟡 lists SMS checks only: call sessions (FR-14) are not returned by `/history`, so `channel=call` is always empty; verdict and date filters pending (SAQ-32) |
| FR-17 | Notifications about detected threats | S | Local notifications for guard events ✅; remote push (FCM) for server-side events ⬜ | D | 🟡 |
| FR-18 | Interface in Kazakh and Russian, switchable in the app (UC-11) | M | Every user-visible string exists in both languages (checked by `strings_test.dart`); the choice persists across restarts | T, D | 🟡 in progress |
| FR-19 | Web dashboard for administrators: metrics, flagged messages, model versions (UC-12…14) | M | Only users with the admin role can open `/admin/*` (403 otherwise); dashboard shows totals per verdict and category; messages can be filtered by verdict; a model version with metrics can be registered | T, D | ✅ |
| FR-21 | Retraining from user feedback | C | Confirmed reports can be exported to the training set with a script | I | ⬜ |

## 6.2 Non-functional requirements

| ID | Requirement | Pri. | Acceptance criteria (measurable) | Verif. | Status |
|---|---|---|---|---|---|
| NFR-1 | **Latency** | M | SMS check: p95 < 1 s end-to-end on the demo server for 100 sequential requests. Call: alert < 3 s from the moment the trigger phrase is recognised to the alert on screen | E | 🟡 measured locally (SMS p95 3 ms, server part of the call alert < 2 ms; PR #23); demo server and phones not yet |
| NFR-2 | **Detection quality** | M | On a frozen, provenance-verified test set of received SMS, independent of training and threshold selection: recall (scam) ≥ 0.90 and false-positive rate ≤ 0.10 for the selected model; report precision, F1 and ROC-AUC with the test-set version and split protocol. Templates and translations must not be counted as received-SMS test examples, and duplicates/derived variants must not cross the train/test boundary | E | 🟡 acceptance not demonstrated: the current 228-row source-selected diagnostic subset has no verified receipt provenance and is not this acceptance set. Its reported baseline results are preliminary corpus diagnostics; received-SMS collection and the frozen evaluation remain pending (SAQ-19, SAQ-22) |
| NFR-3 | **Privacy** | M | Message text and transcripts are processed only after explicit consent in the app. SaqBol's client-to-backend call-analysis requests contain transcript text, not audio. Before microphone use, disclose that the selected platform speech-recognition service may process audio remotely; any claim of exclusively on-device recognition requires verification on the specified device/service configuration. Inspect request payloads and the consent flow; keep secrets out of Git and use TLS on every public deployment | I, D | 🟡 text-only SaqBol call-analysis payload is implemented; platform STT audio processing has not been verified as exclusively on-device. Explicit app consent and public-deployment TLS remain pending on `main`; the consent UI in pending PR #20 does not prove platform STT privacy |
| NFR-4 | **Security** | M | Passwords hashed (bcrypt); JWT secrets required at start-up; admin endpoints role-protected; rate limit 60 req/min per client by default; input length validated | T, I | ✅ |
| NFR-5 | **Scalability** | S | Backend and ML service are stateless; both can run with ≥ 2 replicas behind the Kubernetes service without errors | D | 🟡 manifests exist, not load-tested |
| NFR-6 | **Portability** | M | One Flutter codebase builds for Android and iOS; Android-only features (SMS access, call screening) degrade gracefully on iOS | D | ✅ |
| NFR-7 | **Observability** | S | Backend exposes Prometheus metrics at `/metrics` (request count, latency); ML service reports latency per prediction | I | ✅ |
| NFR-8 | **Deployability** | M | A fresh clone starts the full stack with `docker compose up -d --build` following the README; health endpoints return 200 | D | ✅ |
| NFR-9 | **Maintainability** | S | CI runs build, vet / lint **and the unit tests** for all four apps on every push and pull request | I | 🟡 build / lint only; tests not yet in CI (SAQ-33) |
| NFR-10 | **Usability** | S | Usability test with ≥ 5 participants: every participant completes the "check an SMS" task without help; SUS score ≥ 68 | E | ⬜ |

## 6.3 Traceability

| Objective ([proposal](01-project-proposal.md)) | Requirements |
|---|---|
| O1 Corpus | NFR-2 (provenance-verified received-SMS test set) |
| O2 Models | FR-1, FR-2, FR-3, NFR-2 |
| O3 Backend + ML service | FR-1, FR-4, FR-8, FR-15, NFR-1, NFR-4, NFR-8 |
| O4 Real-time calls | FR-9 … FR-14, NFR-1 |
| O5 Mobile app | FR-5, FR-6, FR-17, FR-18, FR-20, NFR-6 |
| O6 Web dashboard | FR-19 |
| O7 Evaluation | NFR-1, NFR-2, NFR-10 |
