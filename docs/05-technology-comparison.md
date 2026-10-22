# 5. Technology Comparison

Each key decision is compared against criteria from the proposed requirements
([PR #8, under review](https://github.com/DanialMyrzatayevMuratovich/saqbol/pull/8)).
Scores: ●●● strong, ●● adequate, ● weak.
The chosen option is marked **✔**.

Selection does not establish measured performance or completed language support. Current
implementation evidence and pending work are recorded in [the status note](implementation-evidence.md).

## 5.1 Backend platform

Drivers: many concurrent WebSocket call sessions (FR-9…FR-12), SMS check < 1 s (NFR-1),
stateless horizontal scaling (NFR-4), a typed gRPC client to the ML service.

| Criterion | **Go (Gin) ✔** | Node.js (NestJS) | Python (FastAPI) |
|---|---|---|---|
| Concurrency model for long-lived WebSocket connections | ●●● goroutines, blocking code style | ●● single-threaded event loop; CPU work blocks other connections | ●● asyncio; the GIL limits CPU-bound work |
| Latency and memory per instance | ●●● compiled, low memory | ●● | ● highest per request of the three |
| gRPC support | ●●● first-class (`grpc-go`, `protoc-gen-go`) | ●● `@grpc/grpc-js` | ●●● `grpcio` |
| Deployment footprint | ●●● one static binary, small image | ● Node runtime + `node_modules` | ● Python runtime + dependencies |
| Type safety | ●●● static | ●●● TypeScript | ●● type hints, not enforced |
| Team experience | ●● | ●●● (used in earlier projects) | ●●● |

**Decision:** Go. The first draft of the specification (`SaqBol_TZ.md`) proposed NestJS because
of the team's TypeScript experience. We changed it to Go because the backend's hardest job is
holding many concurrent call streams with a tight latency budget and calling the ML service
over gRPC. Python stays where its ecosystem matters, in the ML service.

## 5.2 Backend ↔ ML service communication

Drivers: low per-call overhead (NFR-1), a strict contract between a Go and a Python codebase,
streaming for call analysis (FR-11).

| Criterion | **gRPC + Protocol Buffers ✔** | REST + JSON | Message queue (Redis Streams / RabbitMQ) |
|---|---|---|---|
| Contract between languages | ●●● `.proto` file, generated stubs for Go and Python | ● hand-written DTOs on both sides, drift risk | ●● message schema, not enforced |
| Overhead per request | ●●● binary, HTTP/2, persistent connection | ●● text JSON, HTTP/1.1 | ● extra hop through the broker |
| Streaming | ●●● bidirectional streaming (`ClassifyStream`) | ● needs WebSocket or SSE | ●●● |
| Synchronous request/response | ●●● | ●●● | ● needs a reply queue and correlation IDs |
| Debuggability | ●● needs `grpcurl` | ●●● `curl` | ●● |

**Decision:** gRPC for the production path (`proto/ml/v1/ml.proto`). The ML service also exposes
a small FastAPI REST interface (`/health`, `/classify`) for debugging and health checks.
A queue would only pay off for asynchronous jobs such as retraining, which we do not need yet.

## 5.3 Client ↔ backend real-time channel for live call analysis

Drivers: a transcript fragment every ~1–2 s and an alert pushed back within 3 s (NFR-1);
must work from Flutter on Android and iOS.

These are target timings. The current mobile controller forwards only final recognition
results; their timing depends on the OS speech service and has not been validated on a device.

| Criterion | **WebSocket ✔** | HTTP polling / repeated POST | gRPC streaming from the mobile app |
|---|---|---|---|
| Server → client push (alert) | ●●● | ● only on the next poll | ●●● |
| Overhead per fragment | ●●● one connection | ● new request + auth each time | ●●● |
| Flutter support | ●●● `web_socket_channel` | ●●● Dio | ●● `grpc-dart`, more setup; HTTP/2 through proxies is harder |
| Works through ordinary reverse proxies / ingress | ●●● | ●●● | ● |

**Decision:** WebSocket (`/ws/call`). The client sends recognised text, and the server replies
with probability, category, triggers and an alert flag.

## 5.4 Scam-detection model

Drivers: Kazakh, Russian and code-switched text (FR-1); recall ≥ 0.90 (NFR-2); an explanation
of the verdict (FR-3); CPU inference < 1 s (NFR-1); authentic labelled SMS collection is pending.

| Criterion | TF-IDF + Logistic Regression **✔ baseline** | Fine-tuned XLM-RoBERTa-base **✔ main candidate** | Prompted LLM (hosted API) |
|---|---|---|---|
| Kazakh / Russian support | ●● word and character n-grams, language-agnostic but no semantics | ●●● Kazakh and Russian are in its CC-100 pre-training data (Conneau et al., 2020) | ●● varies by model; Kazakh quality not guaranteed |
| Data needed | ●●● works with hundreds of examples | ●● thousands for stable fine-tuning | ●●● zero/few-shot |
| CPU inference latency | ●●● ~1 ms | ●● tens of ms (ONNX Runtime helps) | ● network round trip, seconds |
| Explainability | ●●● feature weights → trigger phrases | ●● needs attribution (SHAP / attention) | ● free-text rationale, not faithful |
| Privacy (message text leaves our server?) | ●●● no | ●●● no | ● yes, to a third party |
| Running cost | ●●● none | ●● GPU only for training (Google Colab) | ● pay per request |

**Decision:** keep both models. TF-IDF + LogReg is the production baseline and the reference
point for the experiments (LinearSVM and Naive Bayes are compared in `training/evaluate.py`).
XLM-RoBERTa is the main research candidate; fine-tuning in Google Colab is planned, not a
validated deployed capability of the reviewed `main` snapshot. A hosted LLM is rejected for
the production path because of privacy (NFR-3), latency and cost. A rule engine
(`app/classifier/rules.py`) adds the scam
category, explicit triggers and advice on top of either model.

## 5.5 Speech-to-text for live call analysis

Drivers: Kazakh and Russian speech as a target (FR-10), alert < 3 s as a target (NFR-1),
privacy (NFR-3), zero budget. This comparison distinguishes the selected integration from
unvalidated alternatives; it is not a language-quality or latency benchmark.

| Criterion | **OS speech service via `speech_to_text` ✔ current integration** | Self-hosted Whisper (`faster-whisper`), candidate | Cloud STT, candidate |
|---|---|---|---|
| Kazakh / Russian | Current code requests `ru_RU`; Kazakh recognition is not configured. Language availability and accuracy require device tests. | Select a multilingual model and measure Kazakh/Russian WER before choosing it. | Verify Kazakh/Russian support for the exact provider, model and region before choosing it. |
| Latency | Only final recognition results reach the backend; device timing is unmeasured. | Audio upload, inference hardware and chunking need a measured prototype. | Audio streaming and network latency need a measured prototype. |
| Audio processing and privacy | Delegated to the OS recogniser, which may use local or provider processing; locality is not enforced. SaqBol receives transcript text only. | Would require sending audio to infrastructure operated by the team; retention and access controls would need design. | Would require sending audio to the provider and checking its processing and retention terms. |
| Cost | Reuses the device's speech service; no separate STT billing integration in SaqBol. | Additional inference hosting and resource costs to estimate. | Provider pricing and expected audio volume to estimate. |
| Implementation effort | Flutter plugin is integrated; language, device and privacy validation remain. | Add audio capture/transport, inference deployment and evaluation. | Add provider integration, consent/disclosure and billing configuration. |

**Decision:** keep the OS speech-service integration for the prototype. In `main` at
`91862dc`, [`voice_controller.dart`](../saqbol-mobile/lib/src/features/voice/voice_controller.dart)
hardcodes `ru_RU` and forwards final recognised text through
[`call_socket.dart`](../saqbol-mobile/lib/src/features/voice/call_socket.dart).
The app does not upload audio to the SaqBol backend, but this does **not** establish that audio
stays on the phone: the OS recogniser's processing location is not controlled by this code.

Kazakh STT remains planned and unvalidated. The separately reviewed PR #20 at `f361a8f`
also maps the Kazakh UI locale to `ru_RU`; a Kazakh interface or a manually submitted Kazakh
transcript is not evidence of Kazakh speech recognition. Before claiming FR-10 or local-only
processing, record the available recogniser locales and processing settings on the chosen
device, measure Kazakh/Russian word error rate and alert latency, and document the result.
This is risk R3 in [Project management](10-project-management.md). Whisper and cloud STT are
fallback candidates, not implemented fallbacks.

## 5.6 Mobile framework

Drivers: Android and iOS from one team of two (NFR-6), native access to SMS and call screening
on Android.

| Criterion | **Flutter ✔** | React Native | Native (Kotlin + Swift) |
|---|---|---|---|
| One codebase for Android and iOS | ●●● | ●●● | ● two codebases |
| Access to native APIs (`CallScreeningService`, SMS) | ●● platform channels / plugins (`another_telephony`) | ●● native modules | ●●● direct |
| UI consistency and performance | ●●● own rendering engine | ●● | ●●● |
| Team capacity (two developers) | ●●● | ●●● | ● |

**Decision:** Flutter. Android-specific features are written in Kotlin inside the Flutter
project: `CallGuardService.kt` is an Android `CallScreeningService` that the OS starts on an
incoming call. In this `main` snapshot, the Dart side passes the access token and API base URL
(`apiBaseUrl`) through a platform channel, and the service queries the backend directly.
Locale synchronisation is a pending PR #15 change.

## 5.7 Primary data storage

Drivers: relational data (users → messages → detections, reports, numbers), aggregate metrics for
the dashboard (FR-19), JSON triggers per detection.

| Criterion | **PostgreSQL ✔** | MongoDB | MySQL |
|---|---|---|---|
| Relational integrity (FKs, cascades) | ●●● | ● | ●●● |
| Semi-structured fields (triggers, model metrics) | ●●● `jsonb` | ●●● | ●● JSON |
| Aggregations for the dashboard | ●●● SQL, window functions | ●● aggregation pipeline | ●●● |
| Future semantic search over known scam patterns | ●●● `pgvector` extension | ●● Atlas Vector Search (managed) | ● |
| Go driver | ●●● `pgx` | ●●● | ●● |

**Decision:** PostgreSQL for all persistent data; Redis for short-lived data (rate-limit
counters, later a verdict cache).

## 5.8 Summary of chosen stack

| Layer | Choice |
|---|---|
| Mobile | Flutter, Riverpod, Dio, `web_socket_channel`, `speech_to_text`, `another_telephony`, Kotlin `CallScreeningService` |
| Web | Next.js, TypeScript, Tailwind CSS, Recharts |
| Backend | Go, Gin, pgx, go-redis, grpc-go, JWT, Prometheus client |
| ML | Python, scikit-learn, Hugging Face Transformers (XLM-R), FastAPI, grpcio |
| Data | PostgreSQL, Redis |
| Ops | Docker Compose, Kubernetes / k3s manifests, GitHub Actions CI |
