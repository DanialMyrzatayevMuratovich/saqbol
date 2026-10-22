# 5. Technology Comparison

Each key decision is compared against criteria taken from the requirements
([06-requirements.md](06-requirements.md)). Scores: ●●● strong, ●● adequate, ● weak.
The chosen option is marked **✔**.

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
of the verdict (FR-3); CPU inference < 1 s (NFR-1); very little real labelled data.

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
XLM-RoBERTa is the main research candidate and is fine-tuned in Google Colab
(`training/colab_train_xlmr.ipynb`). A hosted LLM is rejected for the production path because of
privacy (NFR-3), latency and cost. A rule engine (`app/classifier/rules.py`) adds the scam
category, explicit triggers and advice on top of either model.

## 5.5 Speech-to-text for live call analysis

Drivers: Kazakh and Russian speech (FR-10), alert < 3 s (NFR-1), privacy (NFR-3), zero budget.

| Criterion | **On-device OS recogniser (`speech_to_text` plugin) ✔** | Self-hosted Whisper (`faster-whisper`) | Cloud STT (Google Cloud Speech-to-Text / Yandex SpeechKit) |
|---|---|---|---|
| Kazakh / Russian | ●● depends on the OS language packs on the phone; **must be verified per device** | ●● both languages supported; Kazakh accuracy lower than Russian | ●●● both offer Kazakh and Russian models |
| Latency | ●●● streaming partial results on device | ● chunked, needs a GPU for real time | ●● streaming, network round trip |
| Privacy | ●●● audio stays on the phone (on Android it may be processed by the Google speech service) | ●●● audio stays on our server | ● audio sent to a third party |
| Cost | ●●● free | ●● GPU server | ● paid per minute |
| Implementation effort | ●●● Flutter plugin | ● audio streaming + GPU deployment | ●● SDK + billing account |

**Decision:** on-device recognition for the MVP. Only text leaves the phone. STT quality on
Kazakh is a known risk (R4 in [Project management](10-project-management.md)): we will measure
word error rate on our own test recordings, and Whisper or a cloud STT is the fallback if
on-device quality is insufficient.

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
incoming call. The Dart side passes it the access token and locale through a platform channel,
and the service queries the backend directly.

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
