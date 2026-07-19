# saqbol-backend

Go backend for SaqBol — REST API, JWT auth, SMS scam check, real-time call gateway.
Stack: Gin, pgx/v5 (PostgreSQL), go-redis, gorilla/websocket, gRPC contract for the ML service.

## Requirements
- Go 1.25+
- Docker (PostgreSQL + Redis via docker-compose)

## Quick start

```bash
cp .env.example .env
docker compose up -d
go mod tidy
go run ./cmd/api
```

The server applies embedded SQL migrations on startup and listens on `HTTP_PORT` (default 8080).
All service addresses (`DATABASE_URL`, `REDIS_URL`, `ML_GRPC_ADDR`) come from environment variables, ready for Kubernetes ConfigMap/Secret injection.

> The local Postgres is published on host port `55432` (5432/5433 were busy on this machine). Adjust `docker-compose.yml` and `DATABASE_URL` if you prefer another port.

## Endpoints

| Method | Path | Auth | Purpose |
|---|---|---|---|
| POST | `/api/v1/auth/register` | no | Register, returns token pair |
| POST | `/api/v1/auth/login` | no | Login |
| POST | `/api/v1/auth/refresh` | no | Rotate refresh token |
| POST | `/api/v1/sms/check` | yes | Classify SMS, persist, update number reputation |
| GET | `/api/v1/numbers/:number/risk` | yes | Number reputation |
| POST | `/api/v1/call/analyze` | yes | Analyze a full transcript |
| POST | `/api/v1/reports` | yes | User feedback (confirmed / false_positive) |
| GET | `/api/v1/history` | yes | Check history |
| GET | `/api/v1/admin/metrics` | yes | Aggregated metrics |
| WS | `/ws/call?token=<access>` | yes | Stream transcript fragments, receive real-time alerts |
| GET | `/health` | no | Liveness + DB ping |

## ML integration

The classifier is hidden behind the `ml.Classifier` interface with two implementations:
- `MockClassifier` (`ML_MOCK=true`) — bilingual KZ/RU keyword heuristic, used now.
- `GRPCClassifier` — talks to the Python FastAPI ML service over gRPC (contract in `proto/ml/v1/ml.proto`), wired in a later stage.

Switching from mock to gRPC changes one line in `main.go`; handlers and persistence stay untouched.
