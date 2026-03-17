#!/usr/bin/env python3
"""
MCP-Deploy Tool Server — Bridges AtlasOS agents to deployment scripts.

HTTP endpoints:
  GET  /health       — Health check
  GET  /tools/list   — List available tools (MCP-style)
  POST /tools/list   — List tools (JSON-RPC body optional)
  POST /tools/call   — Invoke a tool

Runs on port 3120. Uses BaseHTTPRequestHandler pattern matching AtlasOS MCP servers.
"""

import json
import os
import subprocess
import sys
from datetime import datetime
from http.server import BaseHTTPRequestHandler, HTTPServer
from pathlib import Path
from urllib.parse import parse_qs, urlparse

# ─── Paths ───────────────────────────────────────────────────────────────────
SERVER_DIR = Path(__file__).resolve().parent
REPO_ROOT = SERVER_DIR.parent.parent
SCRIPTS_DEPLOY = REPO_ROOT / "scripts" / "deploy"
SCRIPTS_BOOTSTRAP = REPO_ROOT / "scripts" / "bootstrap"
SCRIPTS_VALIDATION = REPO_ROOT / "scripts" / "validation"
SCRIPTS_AGENTS = REPO_ROOT / "scripts" / "agents"

PORT = int(os.environ.get("MCP_DEPLOY_PORT", "3120"))
SANDBOX_MODE = os.environ.get("SANDBOX_MODE", "").lower() in ("1", "true", "yes")

# Tools that require human approval before execution (never auto-run in production)
TOOL_PERMISSIONS = {
    "deploy_service": "execute",
    "deploy_agents": "execute",
    "deploy_brain": "execute",
    "promote_canary": "execute",
    "rollback_service": "execute",
    "health_check": "execute",
    "validate_setup": "execute",
    "validate_dependencies": "execute",
    "bootstrap_all": "approval",
    "init_secrets": "approval",
    "init_vault": "approval",
    "embed_atlasos": "execute",
}

AUDIT_LOG = REPO_ROOT / "outputs" / "mcp-deploy-audit.jsonl"


def log_audit(tool: str, args: dict, outcome: str, stdout: str = "", stderr: str = "", sandbox: bool = False):
    """Append execution to audit log."""
    try:
        AUDIT_LOG.parent.mkdir(parents=True, exist_ok=True)
        entry = {
            "timestamp": datetime.utcnow().isoformat() + "Z",
            "tool": tool,
            "arguments": args,
            "outcome": outcome,
            "sandbox": sandbox,
            "stdout_preview": (stdout or "")[:500],
            "stderr_preview": (stderr or "")[:500],
        }
        with open(AUDIT_LOG, "a") as f:
            f.write(json.dumps(entry) + "\n")
    except Exception as e:
        print(f"[audit] Failed to log: {e}", file=sys.stderr)


def run_script(script_path: Path, args: list[str], cwd: Path | None = None, env: dict | None = None) -> tuple[int, str, str]:
    """Run a bash script and return (returncode, stdout, stderr)."""
    if not script_path.exists():
        return 1, "", f"Script not found: {script_path}"
    effective_env = os.environ.copy()
    if env:
        effective_env.update(env)
    try:
        proc = subprocess.run(
            ["bash", str(script_path)] + args,
            cwd=cwd or REPO_ROOT,
            capture_output=True,
            text=True,
            timeout=600,
            env=effective_env,
        )
        return proc.returncode, proc.stdout or "", proc.stderr or ""
    except subprocess.TimeoutExpired:
        return 1, "", "Script timed out after 600s"
    except Exception as e:
        return 1, "", str(e)


def sandbox_response(tool: str, args: dict, script: str) -> dict:
    """Return simulated response when SANDBOX_MODE is enabled."""
    return {
        "status": "ok",
        "sandbox": True,
        "tool": tool,
        "arguments": args,
        "message": f"[SANDBOX] Would have run: {script}",
        "stdout": f"[SANDBOX] Simulated success for {tool}",
        "stderr": "",
        "returncode": 0,
        "timestamp": datetime.utcnow().isoformat() + "Z",
    }


# ─── Tool definitions (MCP inputSchema style) ─────────────────────────────────
TOOLS = [
    {
        "name": "deploy_service",
        "description": "Deploy a single MedinovAI service using canary, rolling, or blue-green strategy.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "service_name": {"type": "string", "description": "Service name (e.g. api-gateway)"},
                "environment": {"type": "string", "description": "Environment: staging, production", "default": "staging"},
                "strategy": {"type": "string", "description": "Deploy strategy: canary, rolling, blue-green", "default": "rolling"},
                "namespace": {"type": "string", "description": "Kubernetes namespace", "default": "medinovai-services"},
            },
            "required": ["service_name"],
        },
    },
    {
        "name": "deploy_agents",
        "description": "Deploy domain-specific AGENTS.md and HEARTBEAT.md to all repos. Requires GITHUB_DIR.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "agent_type": {"type": "string", "description": "Optional category filter (e.g. clinical, backend-service)"},
            },
            "required": [],
        },
    },
    {
        "name": "deploy_brain",
        "description": "Deploy MedinovAI Atlas brain training files (ATLAS_AUTONOMOUS_ARCHITECTURE, atlas-autonomous-brain.mdc) to all repos.",
        "inputSchema": {"type": "object", "properties": {}, "required": []},
    },
    {
        "name": "promote_canary",
        "description": "Promote a canary deployment to full rollout.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "service_name": {"type": "string", "description": "Service name"},
                "namespace": {"type": "string", "description": "Kubernetes namespace", "default": "medinovai-services"},
            },
            "required": ["service_name"],
        },
    },
    {
        "name": "rollback_service",
        "description": "Rollback a service to its previous version.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "service_name": {"type": "string", "description": "Service name"},
                "namespace": {"type": "string", "description": "Kubernetes namespace", "default": "medinovai-services"},
            },
            "required": ["service_name"],
        },
    },
    {
        "name": "health_check",
        "description": "Run health checks on deployed services. Returns structured JSON summary.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "tier": {"type": "string", "description": "Tier to check: 1, 2, all", "default": "all"},
            },
            "required": [],
        },
    },
    {
        "name": "validate_setup",
        "description": "Validate MedinovAI Atlas repo setup: scripts, configs, workspace structure.",
        "inputSchema": {"type": "object", "properties": {}, "required": []},
    },
    {
        "name": "validate_dependencies",
        "description": "Validate dependency order: no service deploys before its dependencies.",
        "inputSchema": {"type": "object", "properties": {}, "required": []},
    },
    {
        "name": "bootstrap_all",
        "description": "Full MedinovAI local stack bootstrap from zero. REQUIRES APPROVAL.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "primary": {"type": "boolean", "description": "This node is primary DB host", "default": False},
                "skip_infra": {"type": "boolean", "description": "Skip Docker Compose infra", "default": False},
            },
            "required": [],
        },
    },
    {
        "name": "init_secrets",
        "description": "Initialize secret management and seed initial secrets. REQUIRES APPROVAL.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "cloud": {"type": "string", "description": "Cloud: aws, gcp, azure", "default": "aws"},
                "environment": {"type": "string", "description": "Environment", "default": "staging"},
            },
            "required": [],
        },
    },
    {
        "name": "init_vault",
        "description": "Initialize HashiCorp Vault for MedinovAI platform. REQUIRES APPROVAL.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "mode": {"type": "string", "description": "compose or k8s", "default": "compose"},
                "seed_only": {"type": "boolean", "description": "Re-seed secrets only", "default": False},
            },
            "required": [],
        },
    },
    {
        "name": "embed_atlasos",
        "description": "Embed AtlasOS agent capabilities into MedinovAI repositories.",
        "inputSchema": {
            "type": "object",
            "properties": {
                "target": {"type": "string", "description": "all, repo:<name>, category:<cat>"},
                "dry_run": {"type": "boolean", "description": "Preview only", "default": False},
                "commit": {"type": "boolean", "description": "Auto-commit changes", "default": False},
            },
            "required": [],
        },
    },
]


def execute_tool(name: str, arguments: dict) -> dict:
    """Execute a tool and return structured JSON response."""
    args = arguments or {}

    if SANDBOX_MODE:
        if name in ("bootstrap_all", "init_secrets", "init_vault"):
            return {
                "status": "needs_approval",
                "sandbox": True,
                "tool": name,
                "arguments": args,
                "message": f"Tool '{name}' requires human approval. Run manually: see README.",
                "timestamp": datetime.utcnow().isoformat() + "Z",
            }
        return sandbox_response(name, args, f"scripts/.../{name}")

    # ─── deploy_service ─────────────────────────────────────────────────────
    if name == "deploy_service":
        service = args.get("service_name", "")
        if not service:
            return {"status": "error", "error": "service_name is required"}
        environment = args.get("environment", "staging")
        strategy = args.get("strategy", "rolling")
        namespace = args.get("namespace", "medinovai-services")
        script = SCRIPTS_DEPLOY / "deploy_service.sh"
        argv = ["--service", service, "--environment", environment, "--strategy", strategy]
        run_env = {"NAMESPACE": namespace} if namespace else None
        rc, out, err = run_script(script, argv, env=run_env)
        log_audit(name, args, "success" if rc == 0 else "failure", out, err, SANDBOX_MODE)
        return {
            "status": "ok" if rc == 0 else "error",
            "tool": name,
            "returncode": rc,
            "stdout": out,
            "stderr": err,
            "timestamp": datetime.utcnow().isoformat() + "Z",
        }

    # ─── deploy_agents ──────────────────────────────────────────────────────
    if name == "deploy_agents":
        script = SCRIPTS_DEPLOY / "deploy_agents.sh"
        if not os.environ.get("GITHUB_DIR"):
            return {"status": "error", "error": "GITHUB_DIR environment variable is required"}
        argv = []
        rc, out, err = run_script(script, argv)
        log_audit(name, args, "success" if rc == 0 else "failure", out, err, SANDBOX_MODE)
        return {
            "status": "ok" if rc == 0 else "error",
            "tool": name,
            "returncode": rc,
            "stdout": out,
            "stderr": err,
            "timestamp": datetime.utcnow().isoformat() + "Z",
        }

    # ─── deploy_brain ───────────────────────────────────────────────────────
    if name == "deploy_brain":
        script = SCRIPTS_DEPLOY / "deploy_brain.sh"
        if not os.environ.get("GITHUB_DIR"):
            return {"status": "error", "error": "GITHUB_DIR environment variable is required"}
        rc, out, err = run_script(script, [])
        log_audit(name, args, "success" if rc == 0 else "failure", out, err, SANDBOX_MODE)
        return {
            "status": "ok" if rc == 0 else "error",
            "tool": name,
            "returncode": rc,
            "stdout": out,
            "stderr": err,
            "timestamp": datetime.utcnow().isoformat() + "Z",
        }

    # ─── promote_canary ──────────────────────────────────────────────────────
    if name == "promote_canary":
        service = args.get("service_name", "")
        if not service:
            return {"status": "error", "error": "service_name is required"}
        namespace = args.get("namespace", "medinovai-services")
        script = SCRIPTS_DEPLOY / "promote_canary.sh"
        argv = ["--service", service, "--environment", "production"]
        env = os.environ.copy()
        env["NAMESPACE"] = namespace
        rc, out, err = run_script(script, argv, env=env)
        log_audit(name, args, "success" if rc == 0 else "failure", out, err, SANDBOX_MODE)
        return {
            "status": "ok" if rc == 0 else "error",
            "tool": name,
            "returncode": rc,
            "stdout": out,
            "stderr": err,
            "timestamp": datetime.utcnow().isoformat() + "Z",
        }

    # ─── rollback_service ───────────────────────────────────────────────────
    if name == "rollback_service":
        service = args.get("service_name", "")
        if not service:
            return {"status": "error", "error": "service_name is required"}
        namespace = args.get("namespace", "medinovai-services")
        script = SCRIPTS_DEPLOY / "rollback_service.sh"
        argv = ["--service", service, "--environment", "staging"]
        env = os.environ.copy()
        env["NAMESPACE"] = namespace
        rc, out, err = run_script(script, argv, env=env)
        log_audit(name, args, "success" if rc == 0 else "failure", out, err, SANDBOX_MODE)
        return {
            "status": "ok" if rc == 0 else "error",
            "tool": name,
            "returncode": rc,
            "stdout": out,
            "stderr": err,
            "timestamp": datetime.utcnow().isoformat() + "Z",
        }

    # ─── health_check ────────────────────────────────────────────────────────
    if name == "health_check":
        tier = args.get("tier", "all")
        dep_graph = REPO_ROOT / "config" / "dependency-graph.json"
        result = {"status": "ok", "tool": name, "tier": tier, "checks": [], "summary": {}}

        if dep_graph.exists():
            script = SCRIPTS_VALIDATION / "health_check_tier.sh"
            rc, out, err = run_script(script, ["--tier", tier])
            result["stdout"] = out
            result["stderr"] = err
            result["returncode"] = rc
            result["summary"]["tier_script"] = "passed" if rc == 0 else "failed"
        else:
            result["summary"]["tier_script"] = "skipped (no dependency-graph.json)"
            result["stdout"] = ""
            result["stderr"] = ""

        try:
            proc = subprocess.run(
                ["kubectl", "get", "pods", "--all-namespaces", "-o", "json"],
                capture_output=True,
                text=True,
                timeout=15,
                cwd=REPO_ROOT,
            )
            if proc.returncode == 0:
                data = json.loads(proc.stdout)
                items = data.get("items", [])
                running = sum(1 for p in items if p.get("status", {}).get("phase") == "Running")
                pending = sum(1 for p in items if p.get("status", {}).get("phase") == "Pending")
                failed = sum(1 for p in items if p.get("status", {}).get("phase") in ("Failed", "Unknown"))
                result["summary"]["pods"] = {"total": len(items), "running": running, "pending": pending, "failed": failed}
            else:
                result["summary"]["pods"] = {"error": "kubectl failed or not available"}
        except Exception as e:
            result["summary"]["pods"] = {"error": str(e)}

        result["timestamp"] = datetime.utcnow().isoformat() + "Z"
        log_audit(name, args, "success", json.dumps(result["summary"]), "", SANDBOX_MODE)
        return result

    # ─── validate_setup ───────────────────────────────────────────────────────
    if name == "validate_setup":
        script = SCRIPTS_VALIDATION / "validate_setup.sh"
        rc, out, err = run_script(script, [])
        log_audit(name, args, "success" if rc == 0 else "failure", out, err, SANDBOX_MODE)
        return {
            "status": "ok" if rc == 0 else "error",
            "tool": name,
            "returncode": rc,
            "stdout": out,
            "stderr": err,
            "timestamp": datetime.utcnow().isoformat() + "Z",
        }

    # ─── validate_dependencies ───────────────────────────────────────────────
    if name == "validate_dependencies":
        script = SCRIPTS_VALIDATION / "validate_dependency_order.sh"
        rc, out, err = run_script(script, [])
        log_audit(name, args, "success" if rc == 0 else "failure", out, err, SANDBOX_MODE)
        return {
            "status": "ok" if rc == 0 else "error",
            "tool": name,
            "returncode": rc,
            "stdout": out,
            "stderr": err,
            "timestamp": datetime.utcnow().isoformat() + "Z",
        }

    # ─── bootstrap_all ───────────────────────────────────────────────────────
    if name == "bootstrap_all":
        # Always requires approval — never auto-execute
        cmd = "bash scripts/bootstrap/bootstrap-all.sh"
        if args.get("primary"):
            cmd += " --primary"
        if args.get("skip_infra"):
            cmd += " --skip-infra"
        return {
            "status": "needs_approval",
            "tool": name,
            "arguments": args,
            "message": "bootstrap_all requires human approval.",
            "command": cmd,
            "timestamp": datetime.utcnow().isoformat() + "Z",
        }

    # ─── init_secrets ─────────────────────────────────────────────────────────
    if name == "init_secrets":
        if TOOL_PERMISSIONS.get(name) == "approval":
            return {
                "status": "needs_approval",
                "tool": name,
                "arguments": args,
                "message": "init_secrets requires human approval. Run manually: bash scripts/bootstrap/init-secrets.sh",
                "timestamp": datetime.utcnow().isoformat() + "Z",
            }
        script = SCRIPTS_BOOTSTRAP / "init-secrets.sh"
        cloud = args.get("cloud", "aws")
        environment = args.get("environment", "staging")
        argv = ["--cloud", cloud, "--environment", environment]
        rc, out, err = run_script(script, argv)
        log_audit(name, args, "success" if rc == 0 else "failure", out, err, SANDBOX_MODE)
        return {
            "status": "ok" if rc == 0 else "error",
            "tool": name,
            "returncode": rc,
            "stdout": out,
            "stderr": err,
            "timestamp": datetime.utcnow().isoformat() + "Z",
        }

    # ─── init_vault ──────────────────────────────────────────────────────────
    if name == "init_vault":
        if TOOL_PERMISSIONS.get(name) == "approval":
            return {
                "status": "needs_approval",
                "tool": name,
                "arguments": args,
                "message": "init_vault requires human approval. Run manually: bash scripts/bootstrap/init-vault.sh",
                "timestamp": datetime.utcnow().isoformat() + "Z",
            }
        script = SCRIPTS_BOOTSTRAP / "init-vault.sh"
        argv = ["--mode", args.get("mode", "compose")]
        if args.get("seed_only"):
            argv.append("--seed-only")
        rc, out, err = run_script(script, argv)
        log_audit(name, args, "success" if rc == 0 else "failure", out, err, SANDBOX_MODE)
        return {
            "status": "ok" if rc == 0 else "error",
            "tool": name,
            "returncode": rc,
            "stdout": out,
            "stderr": err,
            "timestamp": datetime.utcnow().isoformat() + "Z",
        }

    # ─── embed_atlasos ───────────────────────────────────────────────────────
    if name == "embed_atlasos":
        script = SCRIPTS_AGENTS / "embed_atlasos.sh"
        argv = []
        target = args.get("target", "all")
        if target == "all":
            argv.append("--all")
        elif target.startswith("repo:"):
            argv.extend(["--repo", target[5:]])
        elif target.startswith("category:"):
            argv.extend(["--category", target[9:]])
        else:
            argv.append("--all")
        if args.get("dry_run"):
            argv.append("--dry-run")
        if args.get("commit"):
            argv.append("--commit")
        rc, out, err = run_script(script, argv)
        log_audit(name, args, "success" if rc == 0 else "failure", out, err, SANDBOX_MODE)
        return {
            "status": "ok" if rc == 0 else "error",
            "tool": name,
            "returncode": rc,
            "stdout": out,
            "stderr": err,
            "timestamp": datetime.utcnow().isoformat() + "Z",
        }

    return {"status": "error", "error": f"Unknown tool: {name}", "timestamp": datetime.utcnow().isoformat() + "Z"}


class MCPDeployHandler(BaseHTTPRequestHandler):
    """HTTP request handler for /health, /tools/list, /tools/call."""

    def log_message(self, format, *args):
        pass  # Suppress default logging; audit log covers operations

    def _send_json(self, status: int, data: dict):
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(json.dumps(data).encode())

    def _send_error(self, status: int, message: str):
        self._send_json(status, {"error": message})

    def do_GET(self):
        parsed = urlparse(self.path)
        path = parsed.path.rstrip("/") or "/"

        if path == "/health":
            self._send_json(200, {
                "status": "ok",
                "component": "mcp-deploy",
                "port": PORT,
                "sandbox_mode": SANDBOX_MODE,
                "tools_count": len(TOOLS),
                "timestamp": datetime.utcnow().isoformat() + "Z",
            })
        elif path == "/tools/list":
            tools_payload = [{
                "name": t["name"],
                "description": t["description"],
                "inputSchema": t["inputSchema"],
            } for t in TOOLS]
            self._send_json(200, {"tools": tools_payload, "tool_permissions": TOOL_PERMISSIONS})
        else:
            self._send_error(404, "Not found")

    def do_POST(self):
        parsed = urlparse(self.path)
        path = parsed.path.rstrip("/") or "/"

        if path == "/tools/list":
            tools_payload = [{
                "name": t["name"],
                "description": t["description"],
                "inputSchema": t["inputSchema"],
            } for t in TOOLS]
            self._send_json(200, {"tools": tools_payload, "tool_permissions": TOOL_PERMISSIONS})
        elif path == "/tools/call":
            content_length = int(self.headers.get("Content-Length", 0))
            body = self.rfile.read(content_length)
            try:
                req = json.loads(body) if body else {}
            except json.JSONDecodeError:
                self._send_error(400, "Invalid JSON body")
                return

            name = req.get("name") or req.get("params", {}).get("name")
            arguments = req.get("arguments") or req.get("params", {}).get("arguments") or {}

            if not name:
                self._send_error(400, "Missing 'name' in request")
                return

            result = execute_tool(name, arguments)

            content = [{"type": "text", "text": json.dumps(result, indent=2)}]
            self._send_json(200, {"content": content, "isError": result.get("status") == "error"})
        else:
            self._send_error(404, "Not found")


def main():
    print(f"MCP-Deploy Tool Server starting on port {PORT}")
    print(f"  Repo root: {REPO_ROOT}")
    print(f"  SANDBOX_MODE: {SANDBOX_MODE}")
    print(f"  Endpoints: GET /health, GET|POST /tools/list, POST /tools/call")

    server = HTTPServer(("0.0.0.0", PORT), MCPDeployHandler)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        print("\nShutting down...")
        server.shutdown()


if __name__ == "__main__":
    main()
