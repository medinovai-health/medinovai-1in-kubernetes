# Webhook Receiver

Lightweight HTTP service that receives GitHub webhooks and ArgoCD notifications, verifies signatures where applicable, and publishes events to the stream bus.

## Endpoints

| Path | Method | Description |
|------|--------|-------------|
| `/health` | GET | Health check. Returns `{"status":"healthy","service":"webhook-receiver"}` |
| `/webhooks/github` | POST | GitHub webhook receiver. Requires `X-Hub-Signature-256` when `GITHUB_WEBHOOK_SECRET` is set. |
| `/webhooks/argocd` | POST | ArgoCD notification receiver. Accepts JSON payloads. |

## Event Mapping

### GitHub Webhooks

| GitHub Event | Stream Bus Event | When |
|--------------|------------------|------|
| `push` | `git.push` | Repository push |
| `pull_request` (opened) | `git.pr.opened` | PR opened |
| `pull_request` (closed, merged) | `git.pr.merged` | PR merged |
| `check_suite` (completed, failure) | `git.check.failed` | Check suite failed |

### ArgoCD Notifications

| Condition | Stream Bus Event |
|-----------|------------------|
| Sync succeeded | `argocd.sync.succeeded` |
| Sync failed | `argocd.sync.failed` |
| Other | `argocd.notification` |

## Configuration

| Env Var | Default | Description |
|---------|---------|-------------|
| `PORT` | `3121` | HTTP listen port |
| `STREAM_BUS_URL` | `http://medinovai-real-time-stream-bus:3000` | Stream bus base URL for publishing events |
| `GITHUB_WEBHOOK_SECRET` | *(empty)* | GitHub webhook secret for signature verification. If unset, all GitHub webhooks are accepted. |
| `SERVICE_NAME` | `webhook-receiver` | Service name in health and logs |

## Signature Verification

For GitHub webhooks, set `GITHUB_WEBHOOK_SECRET` to the secret configured in the GitHub repo webhook settings. The service verifies `X-Hub-Signature-256` (HMAC-SHA256). Invalid signatures return 401.

## Running

```bash
pip install -r requirements.txt
python webhook_receiver.py
```

Or with Docker:

```bash
docker build -t webhook-receiver:latest .
docker run -p 3121:3121 -e GITHUB_WEBHOOK_SECRET=your_secret webhook-receiver:latest
```
