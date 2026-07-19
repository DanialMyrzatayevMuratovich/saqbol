#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
WEB_API_URL="${WEB_API_URL:-http://api.saqbol.local}"

if ! minikube status >/dev/null 2>&1; then
  minikube start --driver=docker --cpus=4 --memory=4096
fi

minikube addons enable ingress

eval "$(minikube docker-env)"

docker build -t saqbol-backend:latest "$ROOT/saqbol-backend"
docker build -t saqbol-ml:latest "$ROOT/saqbol-ml"
docker build -t saqbol-web:latest --build-arg API_BASE_URL="$WEB_API_URL" "$ROOT/saqbol-web"

kubectl apply -f "$ROOT/k8s/namespace.yaml"
kubectl apply -R -f "$ROOT/k8s"

kubectl -n saqbol rollout status statefulset/postgres --timeout=180s
kubectl -n saqbol rollout status deployment/redis --timeout=120s
kubectl -n saqbol rollout status deployment/ml --timeout=180s
kubectl -n saqbol rollout status deployment/backend --timeout=180s
kubectl -n saqbol rollout status deployment/web --timeout=180s

echo
echo "Pods:"
kubectl -n saqbol get pods
echo
echo "Add to /etc/hosts:  127.0.0.1 saqbol.local api.saqbol.local"
echo "Run in a separate terminal:  minikube tunnel"
echo "Web:     http://saqbol.local"
echo "Backend: http://api.saqbol.local/health"
