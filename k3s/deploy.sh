#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

import_image() {
  local name="$1"
  docker save "$name:latest" -o "/tmp/$name.tar"
  sudo k3s ctr images import "/tmp/$name.tar"
  rm -f "/tmp/$name.tar"
}

echo "== building images =="
docker build -t saqbol-backend:latest "$ROOT/saqbol-backend"
docker build -t saqbol-ml:latest "$ROOT/saqbol-ml"
docker build -t saqbol-web:latest --build-arg API_BASE_URL= "$ROOT/saqbol-web"

echo "== importing images into k3s containerd =="
import_image saqbol-backend
import_image saqbol-ml
import_image saqbol-web

echo "== applying manifests =="
kubectl apply -f "$ROOT/k8s/namespace.yaml"
kubectl apply -f "$ROOT/k8s/config"
kubectl apply -R -f "$ROOT/k8s/postgres"
kubectl apply -R -f "$ROOT/k8s/redis"
kubectl apply -R -f "$ROOT/k8s/ml"
kubectl apply -R -f "$ROOT/k8s/backend"
kubectl apply -R -f "$ROOT/k8s/web"
kubectl apply -f "$ROOT/k3s/ingress.yaml"

echo "== waiting for rollout =="
kubectl -n saqbol rollout status statefulset/postgres --timeout=180s
kubectl -n saqbol rollout status deployment/redis --timeout=120s
kubectl -n saqbol rollout status deployment/ml --timeout=180s
kubectl -n saqbol rollout status deployment/backend --timeout=180s
kubectl -n saqbol rollout status deployment/web --timeout=180s

kubectl -n saqbol get pods
NODE_IP="$(hostname -I 2>/dev/null | awk '{print $1}')"
echo
echo "Deployed. Open:  http://${NODE_IP:-<VPS_IP>}/"
echo "Backend health:  http://${NODE_IP:-<VPS_IP>}/health"
