# SaqBol on a single VPS (k3s, IP + HTTP)

Runs the whole backend stack on one server via k3s. No domain, no TLS — accessed by the
server's public IP over HTTP. Suitable for a demo; add TLS + a domain before real data.

## What runs on the server
backend (Go), ml (Python), web (Next.js), PostgreSQL (StatefulSet + PVC), Redis, and the
k3s Traefik ingress. The Flutter app is NOT on the server — it runs on phones and points at
`http://<VPS_IP>`.

## Routing (one IP, path-based)
- `http://<VPS_IP>/api/...`  → backend
- `http://<VPS_IP>/ws/...`   → backend (WebSocket)
- `http://<VPS_IP>/health`   → backend
- `http://<VPS_IP>/`         → web (which calls `/api/...` same-origin)

## Server setup (Ubuntu VPS)

```bash
# 1. install docker (to build images) and k3s
curl -fsSL https://get.docker.com | sh
curl -sfL https://get.k3s.io | sh -
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube-config
export KUBECONFIG=~/.kube-config     # or use: sudo k3s kubectl ...

# 2. get the code
git clone <your-repo> saqbol && cd saqbol

# 3. IMPORTANT: change production secrets before deploying
#    edit k8s/config/secret.yaml -> POSTGRES_PASSWORD, JWT_ACCESS_SECRET, JWT_REFRESH_SECRET
#    edit k8s/config/configmap.yaml -> ADMIN_PHONES (your admin phone)

# 4. open the HTTP port
sudo ufw allow 80/tcp

# 5. deploy
./k3s/deploy.sh
```

`deploy.sh` builds the three images with docker, imports them into k3s containerd
(`k3s ctr images import`), applies the manifests and the Traefik ingress, and waits for
rollout. Open `http://<VPS_IP>/` when it finishes.

## Point the mobile app at the server

```bash
flutter build apk --dart-define=API_BASE_URL=http://<VPS_IP>
```

Android cleartext HTTP is already enabled (`usesCleartextTraffic="true"`). On iOS you must add
an ATS exception (`NSAppTransportSecurity` → `NSAllowsArbitraryLoads`) to run over plain HTTP.

## Notes
- Postgres/Redis are internal only (no host ports) — reached via cluster DNS.
- k3s ships the `local-path` storage class, so the Postgres PVC binds automatically.
- `/metrics` is intentionally NOT exposed via the public ingress; scrape it in-cluster.
- Move to HTTPS + a domain later: put Caddy/Traefik TLS in front and switch the app to `https://`.
