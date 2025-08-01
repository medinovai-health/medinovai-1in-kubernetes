# Unified Port-Routing Strategy

> **Applies to every MedinovAI / MyOnSite-Healthcare repository**  —  Whether the
> project runs as a standalone Docker container or inside Kubernetes (Colima,
> EKS, etc.).  
> **Goal:** eliminate host-port collisions forever and make every service
> addressable through clean hostnames.

---

## 1  Global routing layer (runs once per laptop / server)

| Stack                | Component                         | Host Ports that it owns |
|----------------------|------------------------------------|-------------------------|
| **Docker**           | Traefik                            | `80` / `443`            |
| **Kubernetes**       | `ingress-nginx` controller         | `8080` / `8443`¹        |

¹ You can map the controller to `80/443` if those ports are free; `8080/8443`
  were chosen here to avoid clashing with Traefik.

These two long-running services are the **only** containers allowed to bind
host ports. Everything else stays on an internal network where ports can be
re-used safely.

```bash
# One-time setup
# -------------------------------------------------------------
# Docker routing network
docker network create proxy 2>/dev/null || true

# Traefik reverse-proxy (auto-restart)
docker run -d --name traefik \
  --network proxy \
  --restart unless-stopped \
  -p 80:80  -p 443:443 \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v $HOME/traefik/traefik.yml:/traefik.yml \
  traefik:v3.0

# Kubernetes ingress mapped to the host (optional)
# If you didn’t publish ingress in Colima already:
# kubectl -n ingress-nginx port-forward svc/ingress-nginx-controller 8080:80 8443:443 &
```

Add wildcard DNS once (macOS):

```bash
brew install dnsmasq
# Docker (*.localhost ➜ 127.0.0.1)
echo "address=/.localhost/127.0.0.1" | sudo tee /opt/homebrew/etc/dnsmasq.d/localhost.conf
# Kubernetes (*.k8s.local ➜ 127.0.0.1)
echo "address=/.k8s.local/127.0.0.1"    | sudo tee /opt/homebrew/etc/dnsmasq.d/k8s.conf
sudo brew services start dnsmasq
sudo networksetup -setdnsservers Wi-Fi 127.0.0.1
```

---

## 2  How **Docker projects** must run

1. **Never** use `-p HOST:CONTAINER` or `ports:` in `docker-compose.yml`.
2. Join the `proxy` network and add Traefik labels.

```yaml
services:
  my-api:
    image: ghcr.io/your-org/my-api:latest
    networks: [proxy]
    environment:
      - PORT=8000               # internal only
    labels:
      traefik.enable: "true"
      traefik.http.routers.my-api.rule: Host(`my-api.localhost`)
      traefik.http.services.my-api.loadbalancer.server.port: "8000"
    restart: unless-stopped
```

Access locally: `https://my-api.localhost/`

Multiple containers can **all** listen on `8000` internally—Traefik isolates
and routes by hostname.

---

## 3  How **Kubernetes projects** must run

Commit (or template) the following two manifests:

```yaml
# k8s/service.yaml
apiVersion: v1
kind: Service
metadata:
  name: my-api
spec:
  selector:
    app: my-api
  ports:
    - port: 8000
      targetPort: 8000
---
# k8s/ingress.yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: my-api
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  ingressClassName: nginx
  rules:
    - host: my-api.k8s.local
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: my-api
                port:
                  number: 8000
```

No NodePort or LoadBalancer required. Access locally via
`https://my-api.k8s.local/`.

---

## 4  README template fragment (copy-paste)

```markdown
### Local run
1. Make sure the global proxy is up (`docker ps | grep traefik`) and the
   Kubernetes ingress is forwarded (`kubectl get svc -n ingress-nginx`).
2. Start the service:
   *Docker*
   ```bash
   docker compose up -d --build
   open https://my-api.localhost
   ```
   *Kubernetes*
   ```bash
   kubectl apply -k k8s/
   open https://my-api.k8s.local
   ```
3. _Reminder_: publishing host ports is forbidden; routing is handled by
   Traefik/Ingress.
```

---

## 5  Automated guard-rail (optional)

Add a CI step (`scripts/lint-no-port-publish.sh`) that fails the build if
someone adds `-p …:` or `ports:` to compose files or `nodePort:` to manifests.

---

## 6  Why this works

* Traefik and ingress-nginx are the **sole owners** of host ports.
* Internal container/pod ports live in their own network namespaces—unlimited
  reuse, zero conflicts.
* Both proxies auto-reload when new labels/Ingress objects appear, so routing is
  _self-service_.
