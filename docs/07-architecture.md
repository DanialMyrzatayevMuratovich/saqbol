# 7. Architecture

The diagrams are written in PlantUML. Editable sources are in [`diagrams/src/`](../diagrams/src),
and SVG and PNG exports are in [`diagrams/export/`](../diagrams/export).
To regenerate the exports, see [`diagrams/README.md`](../diagrams/README.md).

## 7.1 System context

![System context](../diagrams/export/system-context.svg)

SaqBol sits between the user and the channels fraudsters use (SMS and voice calls).
It never touches the cellular network itself. On Android it reads the SMS inbox and screens
incoming calls through official OS APIs, with the user's permission. For live calls it relies on
the phone's speech recogniser and receives only text. Model training happens outside the running
system (Google Colab for XLM-RoBERTa, local scikit-learn for the baseline), and only the
trained artifacts are deployed.

## 7.2 Use cases

![Use cases](../diagrams/export/use-case.svg)

Grey use cases are planned (FR-7, FR-17 remote push). The main scenarios are UC-2 (manual SMS
check) and UC-7 (live call analysis). Both include UC-3 (explanation), which is the core value of
the product: the user sees *why* a message is dangerous.

## 7.3 Components

![Components](../diagrams/export/component.svg)

| Component | Responsibility | Code |
|---|---|---|
| **Mobile app** | UI for SMS check, guard, live call analysis, history; Android integration (SMS inbox, `CallScreeningService`); on-device speech-to-text | `saqbol-mobile/lib/src/features/*`, `android/.../CallGuardService.kt` |
| **Web dashboard** | Admin pages: metrics, flagged messages, model versions | `saqbol-web/src/app/*` |
| **Backend router and middleware** | JWT auth, admin role check, Redis rate limit, Prometheus metrics, routing | `saqbol-backend/internal/httpserver` |
| **auth** | Register, login, refresh tokens; bcrypt password hashes | `internal/auth` |
| **sms** | Single and batch SMS check; stores message and detection; raises number risk on scam | `internal/sms` |
| **calls** | WebSocket stream, sliding window (last 600 chars), alert flag, call session; offline transcript analysis | `internal/calls` |
| **numbers / reports / history / admin** | Reputation lookup, user feedback, history, admin metrics and model versions | `internal/*` |
| **ml client** | gRPC client to the ML service; a mock classifier for tests | `internal/ml` |
| **store** | PostgreSQL access (pgx) and embedded migrations | `internal/store` |
| **ML gRPC server** | `ScamClassifier.Classify` / `ClassifyStream` | `saqbol-ml/app/grpc_server.py`, `proto/ml/v1/ml.proto` |
| **Classification pipeline** | Combines model probability and rule score, applies thresholds, builds verdict, category, triggers, advice | `saqbol-ml/app/classifier/pipeline.py` |
| **Baseline model** | TF-IDF + Logistic Regression; top-weighted n-grams as explanation | `app/classifier/baseline.py` |
| **Rule engine** | Category patterns, explicit triggers in Kazakh and Russian (e.g. "код из смс", "қауіпсіздік қызметі", look-alike domains such as `kaspii.kz`), advice texts | `app/classifier/rules.py` |

### Interfaces

| Interface | Protocol | Contract |
|---|---|---|
| Mobile / web → backend | HTTPS REST, JSON, `/api/v1/*` | See [prototype API examples](08-prototype.md#82-api-examples) |
| Mobile → backend, live call | WebSocket `/ws/call?token=…`, JSON frames `{"text": …}` → `{verdict, probability, category, triggers, advice, alert}` | `internal/calls/handler.go` |
| Backend → ML | gRPC, Protocol Buffers | `saqbol-backend/proto/ml/v1/ml.proto` |
| Backend → PostgreSQL / Redis | SQL (pgx) / Redis protocol | migrations in `internal/store/migrations` |

## 7.4 Key scenarios

**SMS check (UC-2, UC-3, UC-9)**

![SMS check sequence](../diagrams/export/sequence-sms-check.svg)

**Live call analysis (UC-7)**

![Live call sequence](../diagrams/export/sequence-live-call.svg)

## 7.5 Data model

![Data model](../diagrams/export/data-model.svg)

- `messages` stores every check (SMS and call transcripts). `detections` stores the model output
  for a message: probability, category, triggers, latency.
- `numbers` is the crowd-sourced reputation. It is linked to `messages.source_number` logically,
  not with a foreign key, because a number can be scored before anyone checks a message from it.
- `model_versions` and `detections.latency_ms` support the experiments chapter of the thesis.

## 7.6 Deployment

| Environment | How | Notes |
|---|---|---|
| Local / demo | `docker compose up -d --build` — postgres, redis, ml, backend, web | Postgres and Redis are not exposed on the host; ports 3000 / 8080 / 8000 |
| Kubernetes (minikube) | `k8s/deploy.sh` | Separate deployments and services per component |
| Single VPS (k3s) | `k3s/deploy.sh` | HTTP over IP; TLS is a pending task (NFR-3) |

CI (`.github/workflows/ci.yml`) builds and checks all four apps on every push.

## 7.7 Architectural decisions

| # | Decision | Rationale |
|---|---|---|
| AD-1 | Clients talk only to the backend; the ML service is internal | One place for auth, rate limiting and persistence; the ML service can be replaced or scaled independently |
| AD-2 | gRPC between backend and ML | Typed cross-language contract and low overhead ([5.2](05-technology-comparison.md#52-backend--ml-service-communication)) |
| AD-3 | One classifier for SMS and call transcripts | Both are short-text classification; the `channel` field lets us specialise later |
| AD-4 | Speech recognition on the device; only text goes to the server | Privacy (NFR-3), no GPU server needed ([5.5](05-technology-comparison.md#55-speech-to-text-for-live-call-analysis)) |
| AD-5 | Model probability combined with a rule engine (`max` of both) | Rules keep recall on known local patterns while real data is scarce; the model generalises beyond the rules |
| AD-6 | Evaluate on real messages only; synthetic and translated data go to training only | Synthetic data inflates metrics (see [verification plan](09-verification-plan.md)) |

## 7.8 Alignment check

| Use case | Requirements | Components | Data |
|---|---|---|---|
| UC-1 Register / log in | FR-15, NFR-4 | auth, store | users |
| UC-2 Check SMS | FR-1, FR-5 | mobile SMS screen → sms → ml client → ML pipeline | messages, detections |
| UC-3 Explanation | FR-2, FR-3 | ML pipeline (baseline explain + rules), mobile highlighted text | detections.triggers, scam_categories |
| UC-4 / UC-6 Number reputation, call warning | FR-4, FR-20 | CallGuardService → numbers | numbers |
| UC-5 Inbox / incoming SMS scan | FR-6, FR-17 | mobile guard → sms (batch) | messages, detections |
| UC-7 Live call | FR-9 … FR-12, FR-14, NFR-1 | mobile voice + STT → calls (WS) → ML | call_sessions |
| UC-8 Offline transcript | FR-13 | calls (REST) → ML | call_sessions |
| UC-9 Feedback | FR-8, FR-4 | mobile history → reports | reports, numbers |
| UC-10 History | FR-16 | history | messages, detections |
| UC-11 Language | FR-18 | mobile locale storage | device storage; `users.locale` set at registration |
| UC-12 … 14 Admin | FR-19 | web → admin | messages, detections, model_versions |

### Known gaps found during this review

- ~~`detections.model_version_id` is never filled~~ — fixed in SAQ-26: every detection points at
  the `model_versions` row named in the ML response; a version nobody registered yet is added
  on first use with empty metrics.
- `FR-13` accepts a transcript only; audio upload is not implemented.
- The original draft (`SaqBol_TZ.md`) mentions NestJS, pgvector and object storage. The
  implementation uses Go, and has neither pgvector nor object storage yet. This document
  describes the actual system.
