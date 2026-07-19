# SaqBol — runbook for Claude

Instructions for an assistant to clone this project and run the whole stack from scratch.
SaqBol detects fraudulent SMS and calls in Kazakh/Russian. It is ONE monorepo with four
apps: `saqbol-backend` (Go), `saqbol-ml` (Python), `saqbol-web` (Next.js), `saqbol-mobile`
(Flutter). Clients only talk to the backend; the backend calls the ML service over gRPC.

## 1. Get the code

```bash
git clone https://github.com/DanialMyrzatayevMuratovich/saqbol.git
cd saqbol
```

There is only one repository — everything is inside it. No submodules.

## 2. Prerequisites

- **Docker Desktop must be running** (the one-command path uses it). Start it and wait until
  `docker info` succeeds.
- For local (non-Docker) development only: Go 1.25+, Python 3.10+, Node 20+, Flutter 3.41+.

## 3. Run everything (recommended: docker compose)

```bash
docker compose up -d --build
```

This builds and starts all five containers: postgres, redis, ml, backend, web.
Postgres/Redis are internal (no host ports). Published ports:

- Web dashboard: http://localhost:3000
- Backend API:   http://localhost:8080  (health: http://localhost:8080/health)
- ML REST:       http://localhost:8000/health   (gRPC is internal on 9090)

Wait for readiness, then smoke-test:

```bash
# wait for backend
until curl -sf http://localhost:8080/health >/dev/null; do sleep 2; done

# register a user + check a scam SMS end-to-end (client -> backend -> ml -> postgres)
B=http://localhost:8080/api/v1
TOKEN=$(curl -s -X POST $B/auth/register -H 'Content-Type: application/json' \
  -d '{"phone":"+77000000001","password":"secret123","name":"Demo"}' \
  | python3 -c 'import sys,json;print(json.load(sys.stdin)["access_token"])')
curl -s -X POST $B/sms/check -H "Authorization: Bearer $TOKEN" -H 'Content-Type: application/json' \
  -d '{"text":"Служба безопасности банка, назовите код из смс","source_number":"+77770001100"}'
```

A `verdict":"scam"` with `model_version":"baseline-tfidf-logreg-v1"` means the whole chain works.

Stop / reset:

```bash
docker compose down          # stop
docker compose down -v       # stop and wipe the database volume
```

### Admin panel access (web)
The admin pages (`/messages`, `/models`, metrics) require an admin user. In
`docker-compose.yml` set `ADMIN_PHONES` to the phone you registered, then:

```bash
docker compose up -d backend      # restart backend so it promotes that phone to admin
```

Log in on the web dashboard with that phone → admin pages work.

## 4. Alternative deploy paths

- **Local Kubernetes (minikube):** see `k8s/README.md` → `./k8s/deploy.sh`.
- **Single VPS with k3s (IP, HTTP):** see `k3s/README.md` → `./k3s/deploy.sh`.

## 5. Run services individually (dev, optional)

```bash
# backend (needs postgres+redis; start them via `docker compose up -d postgres redis`)
cd saqbol-backend && cp .env.example .env && go run ./cmd/api

# ml
cd saqbol-ml && python3 -m venv .venv && source .venv/bin/activate \
  && pip install -r requirements.txt && bash scripts/gen_proto.sh \
  && python training/train_baseline.py && python -m app.server

# web
cd saqbol-web && npm install && echo 'NEXT_PUBLIC_API_BASE_URL=http://localhost:8080' > .env.local && npm run dev
```

Note: `saqbol-ml/app/generated/` (Python gRPC stubs) is git-ignored — regenerate with
`bash scripts/gen_proto.sh` (the Docker build does this automatically). The Go stubs
(`saqbol-backend/proto/ml/v1/*.pb.go`) ARE committed, so `go build` works out of the box.

## 6. Tests

```bash
cd saqbol-backend && go test ./...
cd saqbol-ml && source .venv/bin/activate && pip install -r requirements-dev.txt && python -m pytest -q
cd saqbol-mobile && flutter test
cd saqbol-web && npm test
```

## 7. Android app build — DO THIS ONLY WHEN THE USER EXPLICITLY ASKS

Do NOT build or open the Android app automatically. Only when the user explicitly commands it:

```bash
cd saqbol-mobile
flutter pub get

# for the Android emulator, the host machine is 10.0.2.2:
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080

# or build an APK against a running server:
flutter build apk --dart-define=API_BASE_URL=http://<SERVER_IP>:8080
```

Cleartext HTTP is already enabled in the Android manifest, so a plain `http://` backend works.
To open in Android Studio: open the `saqbol-mobile/` folder, let Gradle sync, pick a device,
and set the same `--dart-define=API_BASE_URL` in the run configuration.
