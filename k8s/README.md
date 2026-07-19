# SaqBol — Kubernetes (local)

Local Kubernetes deployment of the whole SaqBol stack (replaces docker-compose).
All services and databases run in the cluster; only the Flutter app stays outside and calls
the backend through the Ingress.

Cluster: **minikube** (docker driver) + **nginx ingress** addon.

## Layout

```
k8s/
├── namespace.yaml          # namespace: saqbol
├── config/
│   ├── configmap.yaml      # non-secret env (ports, ML_MOCK, thresholds, service DNS names)
│   └── secret.yaml         # POSTGRES_PASSWORD, DATABASE_URL, JWT secrets (placeholders)
├── postgres/               # StatefulSet + headless Service + PVC (volumeClaimTemplate)
├── redis/                  # Deployment + Service
├── ml/                     # Deployment + Service (gRPC 9090, REST 8000)
├── backend/                # Deployment (initContainer waits for pg/redis) + Service (8080)
├── web/                    # Deployment + Service (3000)
├── ingress.yaml            # saqbol.local -> web, api.saqbol.local -> backend
└── deploy.sh               # build images into cluster -> apply -> wait for rollout
```

## Key decisions

- **minikube over kind**: nginx ingress is a one-command addon; smoother for a local demo.
- **Postgres = StatefulSet + volumeClaimTemplate**: stable identity (`postgres-0`) and a PVC bound
  to that identity, so data survives pod restarts. A Deployment would be an anti-pattern for a DB.
- **Service DNS**: services reach each other by name inside the namespace — `ml:9090` (gRPC),
  `postgres:5432`, `redis:6379`. No hardcoded IPs.
- **Secret vs ConfigMap**: passwords / JWT keys in a Secret; ports, thresholds, service names in a
  ConfigMap. (Secrets are base64, not encrypted — for prod use SealedSecrets/Vault/SOPS.)
- **gRPC + ClusterIP**: fine for a single ml replica. Scaling ml to N replicas needs a headless
  Service + client-side load balancing (gRPC keeps one long-lived HTTP/2 connection).
- **web API URL**: the browser calls the backend through the Ingress, so the web image is built with
  `API_BASE_URL=http://api.saqbol.local` (a build arg, not the in-cluster `backend` name).

## Deploy

```bash
./k8s/deploy.sh
```

Then, to reach it from the host (docker driver):

```bash
# /etc/hosts
127.0.0.1 saqbol.local api.saqbol.local

# separate terminal (keeps running)
minikube tunnel
```

- Web:     http://saqbol.local
- Backend: http://api.saqbol.local/health

Without the tunnel you can always reach the backend via port-forward:

```bash
kubectl -n saqbol port-forward svc/backend 8080:8080
```

## Common commands

```bash
kubectl -n saqbol get pods
kubectl -n saqbol logs deploy/backend
kubectl -n saqbol get pvc          # data-postgres-0 should be Bound
minikube stop                      # pause cluster
minikube delete                    # remove cluster
```
