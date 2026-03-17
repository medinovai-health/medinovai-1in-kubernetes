#!/usr/bin/env python3
"""
Webhook Receiver — Lightweight HTTP service that receives GitHub webhooks and ArgoCD
notifications, then publishes events to the stream bus.
"""
from __future__ import annotations

import hashlib
import hmac
import json
import logging
import os
from datetime import datetime, timezone
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from typing import Any
from urllib.parse import urlparse

import requests

PORT = int(os.environ.get("PORT", "3121"))
STREAM_BUS_URL = os.environ.get("STREAM_BUS_URL", "http://medinovai-real-time-stream-bus:3000")
GITHUB_WEBHOOK_SECRET = os.environ.get("GITHUB_WEBHOOK_SECRET", "")
SERVICE_NAME = os.environ.get("SERVICE_NAME", "webhook-receiver")

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    datefmt="%Y-%m-%dT%H:%M:%SZ",
)
logger = logging.getLogger(SERVICE_NAME)


def _verify_github_signature(payload: bytes, signature_header: str) -> bool:
    """Verify X-Hub-Signature-256 for GitHub webhooks."""
    if not GITHUB_WEBHOOK_SECRET:
        logger.warning("GITHUB_WEBHOOK_SECRET not set — accepting all GitHub webhooks")
        return True
    if not signature_header:
        return False
    expected = "sha256=" + hmac.new(
        GITHUB_WEBHOOK_SECRET.encode(),
        payload,
        hashlib.sha256,
    ).hexdigest()
    return hmac.compare_digest(expected, signature_header)


def publish_to_stream_bus(event_type: str, payload: dict[str, Any], source: str) -> bool:
    """Publish event to stream bus. Returns True on success."""
    event = {
        "type": event_type,
        "source": source,
        "payload": payload,
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }
    url = f"{STREAM_BUS_URL.rstrip('/')}/events"
    try:
        r = requests.post(url, json=event, timeout=5)
        if r.ok:
            logger.info("Published %s to stream bus", event_type)
            return True
        logger.warning("Stream bus returned %d: %s", r.status_code, r.text[:200])
    except requests.RequestException as e:
        logger.warning("Stream bus publish failed: %s", e)
    return False


def handle_github_push(body: dict) -> tuple[str, dict]:
    """Map GitHub push event to git.push."""
    return (
        "git.push",
        {
            "ref": body.get("ref", ""),
            "repository": body.get("repository", {}),
            "pusher": body.get("pusher", {}),
            "commits": body.get("commits", []),
            "head_commit": body.get("head_commit"),
        },
    )


def handle_github_pull_request(body: dict) -> tuple[str, dict]:
    """Map GitHub pull_request event to git.pr.opened or git.pr.merged."""
    action = body.get("action", "")
    pr = body.get("pull_request", {})
    merged = pr.get("merged", False)
    if action == "closed" and merged:
        event_type = "git.pr.merged"
    elif action == "opened":
        event_type = "git.pr.opened"
    else:
        event_type = f"git.pr.{action}"
    return (
        event_type,
        {
            "number": pr.get("number"),
            "state": pr.get("state"),
            "title": pr.get("title"),
            "merged": merged,
            "repository": body.get("repository", {}),
            "sender": body.get("sender", {}),
        },
    )


def handle_github_check_suite(body: dict) -> tuple[str, dict]:
    """Map GitHub check_suite event. Emit git.check.failed when conclusion is failure."""
    action = body.get("action", "")
    suite = body.get("check_suite", {})
    conclusion = suite.get("conclusion", "")
    if action == "completed" and conclusion in ("failure", "cancelled"):
        event_type = "git.check.failed"
    else:
        event_type = f"git.check.{action}"
    return (
        event_type,
        {
            "conclusion": conclusion,
            "status": suite.get("status"),
            "head_branch": suite.get("head_branch"),
            "head_sha": suite.get("head_sha"),
            "repository": body.get("repository", {}),
        },
    )


GITHUB_HANDLERS = {
    "push": handle_github_push,
    "pull_request": handle_github_pull_request,
    "check_suite": handle_github_check_suite,
}


def handle_github_event(event_type: str, body: dict) -> tuple[str, dict] | None:
    """Dispatch GitHub webhook to handler. Returns (event_type, payload) or None to skip."""
    handler = GITHUB_HANDLERS.get(event_type)
    if handler:
        return handler(body)
    return None


def handle_argocd_notification(body: dict) -> tuple[str, dict] | None:
    """Map ArgoCD notification to argocd.sync.succeeded or argocd.sync.failed."""
    # ArgoCD sends Notifications: https://argo-cd.readthedocs.io/en/stable/operator-manual/notifications/
    # Common format: {"message": "...", "application": {...}, "syncResult": {...}}
    # Simplified: look for sync status in the payload
    msg = body.get("message", "").lower()
    app = body.get("application", body)
    app_name = app.get("metadata", {}).get("name", app.get("name", "unknown"))

    if "sync" in msg and ("success" in msg or "succeeded" in msg):
        return ("argocd.sync.succeeded", {"application": app_name, "body": body})
    if "sync" in msg and ("fail" in msg or "error" in msg):
        return ("argocd.sync.failed", {"application": app_name, "body": body})

    # Fallback: check common ArgoCD notification keys
    sync_result = body.get("syncResult", body.get("sync", {}))
    if isinstance(sync_result, dict):
        status = sync_result.get("status", sync_result.get("phase", ""))
        if status in ("Synced", "Succeeded", "success"):
            return ("argocd.sync.succeeded", {"application": app_name, "body": body})
        if status in ("Failed", "Error", "Failed", "failure"):
            return ("argocd.sync.failed", {"application": app_name, "body": body})

    return ("argocd.notification", {"application": app_name, "body": body})


class WebhookHandler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def log_message(self, format: str, *args: Any) -> None:
        logger.info("%s - %s", self.address_string(), format % args)

    def send_response_simple(self, status: int, body: dict) -> None:
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(json.dumps(body).encode())

    def do_GET(self) -> None:
        parsed = urlparse(self.path)
        if parsed.path in ("/health", "/health/"):
            self.send_response_simple(
                200,
                {"status": "healthy", "service": SERVICE_NAME, "timestamp": datetime.now(timezone.utc).isoformat()},
            )
            return
        self.send_response(404)
        self.end_headers()

    def do_POST(self) -> None:
        parsed = urlparse(self.path)
        path = parsed.path.rstrip("/")

        if path == "/webhooks/github":
            self._handle_github()
            return
        if path == "/webhooks/argocd":
            self._handle_argocd()
            return

        self.send_response(404)
        self.end_headers()

    def _read_json_body(self) -> dict | None:
        content_length = int(self.headers.get("Content-Length", 0))
        if content_length == 0:
            return None
        raw = self.rfile.read(content_length)
        try:
            return json.loads(raw.decode("utf-8"))
        except json.JSONDecodeError:
            return None

    def _handle_github(self) -> None:
        raw = self.rfile.read(int(self.headers.get("Content-Length", 0)))
        signature = self.headers.get("X-Hub-Signature-256", "")

        if not _verify_github_signature(raw, signature):
            logger.warning("GitHub webhook signature verification failed")
            self.send_response_simple(401, {"error": "invalid signature"})
            return

        try:
            body = json.loads(raw.decode("utf-8"))
        except json.JSONDecodeError:
            self.send_response_simple(400, {"error": "invalid JSON"})
            return

        event_type = self.headers.get("X-GitHub-Event", "")
        result = handle_github_event(event_type, body)
        if result:
            evt, payload = result
            publish_to_stream_bus(evt, payload, "github")
        else:
            logger.info("GitHub event %s not mapped (ignored)", event_type)

        self.send_response_simple(200, {"status": "ok", "event": event_type})

    def _handle_argocd(self) -> None:
        body = self._read_json_body()
        if not body:
            self.send_response_simple(400, {"error": "invalid or empty body"})
            return

        result = handle_argocd_notification(body)
        if result:
            evt, payload = result
            publish_to_stream_bus(evt, payload, "argocd")

        self.send_response_simple(200, {"status": "ok"})


def main() -> None:
    server = ThreadingHTTPServer(("0.0.0.0", PORT), WebhookHandler)
    logger.info("%s running on port %d", SERVICE_NAME, PORT)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.shutdown()


if __name__ == "__main__":
    main()
