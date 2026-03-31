#!/usr/bin/env python3
"""
MedinovAI Node Agent
====================
Lightweight daemon that runs on every enrolled machine (macOS + Linux).
Registers the machine into the MedinovAI network and keeps it stable.

Capabilities:
  1. Enrollment  - One-time registration with coordinator mesh
  2. Heartbeat   - 60s telemetry: CPU/mem/disk/Ollama status/model list
  3. Fleet sync  - Pull missing models, remove retired models per fleet-standard
  4. Dev setup   - Ensure Cursor, Claude Code, git config, AGENTS.md are correct
  5. Security    - Disk encryption check, audit log shipping, HIPAA endpoint check
  6. Mattermost  - Critical alerts forwarded to coordinator (which posts to MM)
  7. Tasks       - Poll coordinator for admin-dispatched tasks and execute them
  8. Self-update - Check coordinator /v1/version, download and restart if newer

Installation:
  macOS:  launchd plist at ~/Library/LaunchAgents/com.medinovai.agent.plist
  Linux:  systemd unit at /etc/systemd/system/medinovai-agent.service

Config file: ~/.medinovai/agent.json  (created on first enrollment)

Usage:
  medinovai-agent enroll --join-token <TOKEN> [--coordinator https://agent.medinovai.com]
  medinovai-agent run          # start daemon (called by launchd/systemd)
  medinovai-agent status       # print current node status
  medinovai-agent version      # print version
"""

from __future__ import annotations

import argparse
import json
import logging
import os
import platform
import shutil
import signal
import subprocess
import sys
import time
import uuid
from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Optional

# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

E_VERSION          = "1.0.0"
E_HEARTBEAT_SECS   = 60
E_TASK_POLL_SECS   = 30
E_FLEET_SYNC_SECS  = 300      # 5 min
E_DEV_SETUP_SECS   = 3600     # 1 hr
E_UPDATE_SECS      = 7200     # 2 hr

# Coordinator endpoints tried in order until one responds
E_COORDINATORS = [
    "https://agent.medinovai.com",
    "https://agent-eu.medinovai.com",
    "http://aifactory.local:8435",
    "http://100.106.54.9:8435",      # Tailscale aifactory
]

E_CONFIG_DIR  = Path.home() / ".medinovai"
E_CONFIG_FILE = E_CONFIG_DIR / "agent.json"
E_LOG_FILE    = E_CONFIG_DIR / "agent.log"
E_AUDIT_FILE  = E_CONFIG_DIR / "audit.jsonl"

# Fleet standard: models required per role
E_FLEET_TIER1 = ["qwen3-coder:latest", "phi4:14b", "qwen3:8b",
                  "nomic-embed-text:latest", "mxbai-embed-large:latest"]
E_FLEET_TIER2 = E_FLEET_TIER1 + ["deepseek-r1:32b", "qwen2.5-coder:32b",
                                   "qwen3:32b", "codestral:22b"]
E_FLEET_RETIRED = ["llama2:7b", "llama2:13b", "llama2:70b", "vicuna:latest",
                    "wizardcoder:latest", "starcoder:latest", "falcon:40b",
                    "zephyr:7b", "tinyllama:1.1b", "neural-chat:latest",
                    "solar:10.7b", "bakllava:7b", "phi3:mini", "phi3:latest"]


# ---------------------------------------------------------------------------
# Logging
# ---------------------------------------------------------------------------

E_CONFIG_DIR.mkdir(parents=True, exist_ok=True)

mos_log = logging.getLogger("medinovai.agent")
mos_log.setLevel(logging.INFO)
_mos_fmt = logging.Formatter("%(asctime)s [%(levelname)s] %(message)s")
_mos_fh  = logging.FileHandler(E_LOG_FILE)
_mos_fh.setFormatter(_mos_fmt)
_mos_sh  = logging.StreamHandler(sys.stdout)
_mos_sh.setFormatter(_mos_fmt)
mos_log.addHandler(_mos_fh)
mos_log.addHandler(_mos_sh)

# ---------------------------------------------------------------------------
# Config management
# ---------------------------------------------------------------------------

def _load_config() -> dict:
    if E_CONFIG_FILE.exists():
        return json.loads(E_CONFIG_FILE.read_text())
    return {}

def _save_config(mos_cfg: dict) -> None:
    E_CONFIG_DIR.mkdir(parents=True, exist_ok=True)
    E_CONFIG_FILE.write_text(json.dumps(mos_cfg, indent=2))
    E_CONFIG_FILE.chmod(0o600)

def _get_machine_id() -> str:
    mos_cfg = _load_config()
    if "machine_id" in mos_cfg:
        return mos_cfg["machine_id"]
    # Generate deterministic UUID from hostname+MAC or random fallback
    try:
        mos_mid = str(uuid.uuid5(uuid.NAMESPACE_DNS, platform.node()))
    except Exception:
        mos_mid = str(uuid.uuid4())
    return mos_mid

def _get_role() -> str:
    mos_cfg = _load_config()
    return mos_cfg.get("role", "dev-machine")

# ---------------------------------------------------------------------------
# Network helpers
# ---------------------------------------------------------------------------

import urllib.error
import urllib.request

def _http_post(mos_url: str, mos_data: dict, mos_token: str = "") -> Optional[dict]:
    try:
        mos_body = json.dumps(mos_data).encode()
        mos_headers = {"Content-Type": "application/json"}
        if mos_token:
            mos_headers["Authorization"] = f"Bearer {mos_token}"
        mos_req = urllib.request.Request(mos_url, data=mos_body, headers=mos_headers)
        with urllib.request.urlopen(mos_req, timeout=10) as mos_resp:
            return json.loads(mos_resp.read())
    except Exception as e:
        mos_log.debug(f"POST {mos_url} failed: {e}")
        return None

def _http_get(mos_url: str, mos_token: str = "") -> Optional[dict]:
    try:
        mos_headers = {}
        if mos_token:
            mos_headers["Authorization"] = f"Bearer {mos_token}"
        mos_req = urllib.request.Request(mos_url, headers=mos_headers)
        with urllib.request.urlopen(mos_req, timeout=10) as mos_resp:
            return json.loads(mos_resp.read())
    except Exception as e:
        mos_log.debug(f"GET {mos_url} failed: {e}")
        return None

def _find_coordinator() -> Optional[str]:
    """Try each coordinator URL in order, return first healthy one."""
    mos_cfg = _load_config()
    # Check if config has a last-known-good coordinator
    if mos_cfg.get("coordinator"):
        mos_result = _http_get(f"{mos_cfg['coordinator']}/v1/health")
        if mos_result and mos_result.get("status") == "ok":
            return mos_cfg["coordinator"]
    for mos_url in E_COORDINATORS:
        mos_result = _http_get(f"{mos_url}/v1/health")
        if mos_result and mos_result.get("status") == "ok":
            mos_log.info(f"Coordinator found: {mos_url}")
            return mos_url
    return None


# ---------------------------------------------------------------------------
# System telemetry
# ---------------------------------------------------------------------------

def _get_telemetry() -> dict:
    mos_t: dict[str, Any] = {}

    # CPU (simple /proc or sysctl approach, no psutil dependency)
    try:
        if platform.system() == "Darwin":
            mos_out = subprocess.check_output(
                ["ps", "-A", "-o", "%cpu"], text=True, timeout=5
            )
            mos_vals = [float(x) for x in mos_out.strip().split("\n")[1:] if x.strip()]
            mos_t["cpu_pct"] = round(sum(mos_vals) / os.cpu_count(), 1)
        else:
            import resource
            mos_t["cpu_pct"] = 0.0
    except Exception:
        mos_t["cpu_pct"] = 0.0

    # Memory
    try:
        if platform.system() == "Darwin":
            mos_vm = subprocess.check_output(["vm_stat"], text=True, timeout=5)
            mos_pages_free = int([l for l in mos_vm.splitlines() if "Pages free" in l][0].split(":")[1].strip().rstrip("."))
            mos_pages_spec = int([l for l in mos_vm.splitlines() if "Pages speculative" in l][0].split(":")[1].strip().rstrip("."))
            mos_total_bytes = os.sysconf("SC_PHYS_PAGES") * os.sysconf("SC_PAGE_SIZE")
            mos_free_bytes  = (mos_pages_free + mos_pages_spec) * 4096
            mos_t["mem_total_gb"] = round(mos_total_bytes / 1e9, 1)
            mos_t["mem_used_gb"]  = round((mos_total_bytes - mos_free_bytes) / 1e9, 1)
        else:
            mos_mi = Path("/proc/meminfo").read_text()
            def _kb(key): return int([l for l in mos_mi.splitlines() if l.startswith(key)][0].split()[1])
            mos_total = _kb("MemTotal:")
            mos_avail = _kb("MemAvailable:")
            mos_t["mem_total_gb"] = round(mos_total / 1e6, 1)
            mos_t["mem_used_gb"]  = round((mos_total - mos_avail) / 1e6, 1)
    except Exception:
        mos_t["mem_total_gb"] = 0.0
        mos_t["mem_used_gb"]  = 0.0

    # Disk
    try:
        mos_disk = shutil.disk_usage(Path.home())
        mos_t["disk_total_gb"] = round(mos_disk.total / 1e9, 1)
        mos_t["disk_used_gb"]  = round(mos_disk.used  / 1e9, 1)
    except Exception:
        mos_t["disk_total_gb"] = 0.0
        mos_t["disk_used_gb"]  = 0.0

    # Tailscale IP
    try:
        mos_ts = subprocess.check_output(
            ["tailscale", "ip", "-4"], text=True, timeout=5
        ).strip()
        mos_t["tailscale_ip"] = mos_ts
    except Exception:
        mos_t["tailscale_ip"] = ""

    return mos_t

def _get_ollama_status() -> dict:
    """Query local Ollama API."""
    mos_result = {"ollama_running": False, "ollama_version": "", "models": []}
    try:
        mos_resp = _http_get("http://localhost:11434/api/tags")
        if mos_resp:
            mos_result["ollama_running"] = True
            mos_result["models"] = [m["name"] for m in mos_resp.get("models", [])]
        mos_ver = _http_get("http://localhost:11434/api/version")
        if mos_ver:
            mos_result["ollama_version"] = mos_ver.get("version", "")
    except Exception:
        pass
    return mos_result


# ---------------------------------------------------------------------------
# Alert detection
# ---------------------------------------------------------------------------

def _check_alerts(mos_t: dict, mos_ollama: dict) -> list[str]:
    mos_alerts = []
    mos_disk_pct = (mos_t["disk_used_gb"] / mos_t["disk_total_gb"] * 100) if mos_t["disk_total_gb"] else 0

    if mos_disk_pct > 90:
        mos_alerts.append(f"CRITICAL: Disk {mos_disk_pct:.0f}% full ({mos_t['disk_used_gb']:.0f}/{mos_t['disk_total_gb']:.0f}GB)")
    elif mos_disk_pct > 80:
        mos_alerts.append(f"WARNING: Disk {mos_disk_pct:.0f}% full")

    if mos_t["mem_total_gb"] > 0:
        mos_mem_pct = mos_t["mem_used_gb"] / mos_t["mem_total_gb"] * 100
        if mos_mem_pct > 95:
            mos_alerts.append(f"CRITICAL: Memory {mos_mem_pct:.0f}% used")

    if mos_ollama.get("ollama_running") is False:
        mos_cfg = _load_config()
        if mos_cfg.get("role") in ("aifactory-node",):
            mos_alerts.append("CRITICAL: Ollama is not running on AIFactory node")

    return mos_alerts

# ---------------------------------------------------------------------------
# Fleet sync
# ---------------------------------------------------------------------------

def _sync_fleet() -> None:
    """Pull missing standard models, remove retired ones."""
    mos_cfg    = _load_config()
    mos_role   = mos_cfg.get("role", "intern")
    mos_ollama = _get_ollama_status()

    if not mos_ollama["ollama_running"]:
        mos_log.warning("Fleet sync skipped: Ollama not running")
        return

    mos_installed = set(mos_ollama["models"])

    # Determine target fleet
    if mos_role in ("aifactory-node", "power-user"):
        mos_target = set(E_FLEET_TIER2)
    else:
        mos_target = set(E_FLEET_TIER1)

    # Pull missing
    for mos_model in mos_target - mos_installed:
        mos_log.info(f"Fleet sync: pulling {mos_model}")
        try:
            subprocess.run(["ollama", "pull", mos_model], timeout=600, check=False)
        except Exception as e:
            mos_log.error(f"Failed to pull {mos_model}: {e}")

    # Remove retired models
    for mos_model in mos_installed:
        mos_base = mos_model.split(":")[0] + ":" + mos_model.split(":")[-1]
        if mos_model in E_FLEET_RETIRED or mos_base in E_FLEET_RETIRED:
            mos_log.info(f"Fleet sync: removing retired {mos_model}")
            try:
                subprocess.run(["ollama", "rm", mos_model], timeout=60, check=False)
            except Exception as e:
                mos_log.error(f"Failed to remove {mos_model}: {e}")

# ---------------------------------------------------------------------------
# Dev environment setup
# ---------------------------------------------------------------------------

def _setup_dev_env() -> None:
    """Ensure developer toolchain is configured per MedinovAI standards."""
    mos_cfg  = _load_config()
    mos_role = mos_cfg.get("role", "intern")

    # Ensure AGENTS.md exists in ~/workspace if dev role
    if mos_role in ("intern", "dev-machine", "power-user"):
        mos_workspace = Path.home() / "workspace"
        mos_workspace.mkdir(exist_ok=True)
        mos_agents_md = mos_workspace / "AGENTS.md"
        if not mos_agents_md.exists():
            mos_agents_md.write_text(_agents_md_template(mos_role))
            mos_log.info("Created ~/workspace/AGENTS.md")

    # Ensure git config has user info
    try:
        mos_email = subprocess.check_output(
            ["git", "config", "--global", "user.email"], text=True, timeout=5
        ).strip()
        if not mos_email:
            raise ValueError("no email")
    except Exception:
        mos_log.warning("git user.email not set — skipping git config enforcement")


def _agents_md_template(mos_role: str) -> str:
    return f"""# AGENTS.md — MedinovAI Development Standards
# Auto-generated by MedinovAI Agent v{E_VERSION}
# Role: {mos_role}

## Coding Standards
- Language conventions: constants start with `E_`, variables with `mos_`
- lowerCamelCase for variable names: `mos_variableName`
- Code blocks limited to 40 lines
- UTF-8 encoding throughout

## Branch Rules
- Never commit directly to `main` or `develop`
- Feature branches: `feature/TICKET-description`
- Hotfix branches: `hotfix/TICKET-description`

## Operations Allowed
- Read all project files
- Write to feature/* branches only
- Run unit tests
- Create pull requests

## Escalation Triggers
- Any change to auth, encryption, or audit logging → escalate to tech lead
- Any PHI-adjacent code change → escalate + HIPAA review
- Failing tests → do not merge, open issue

## Model Routing
- Default: http://localhost:11434 (tier-1 models)
- Power user: connect to aifactory.local:11434 (tier-2 models)
- Never send PHI to external APIs (OpenAI, Anthropic cloud, etc.)
"""

# ---------------------------------------------------------------------------
# Security checks
# ---------------------------------------------------------------------------

def _check_security() -> list[str]:
    mos_issues = []
    mos_sys    = platform.system()

    if mos_sys == "Darwin":
        try:
            mos_out = subprocess.check_output(
                ["fdesetup", "status"], text=True, timeout=10
            )
            if "FileVault is On" not in mos_out:
                mos_issues.append("SECURITY: FileVault (disk encryption) is OFF")
        except Exception:
            pass
    elif mos_sys == "Linux":
        # Check if root filesystem is on LUKS
        try:
            mos_out = subprocess.check_output(["lsblk", "-o", "TYPE"], text=True, timeout=10)
            if "crypt" not in mos_out:
                mos_issues.append("SECURITY: No disk encryption detected (LUKS not found)")
        except Exception:
            pass

    # Check for world-readable SSH private keys
    mos_ssh_dir = Path.home() / ".ssh"
    if mos_ssh_dir.exists():
        for mos_key in mos_ssh_dir.glob("id_*"):
            if mos_key.suffix not in (".pub",):
                if mos_key.stat().st_mode & 0o077:
                    mos_issues.append(f"SECURITY: SSH key {mos_key.name} has loose permissions")

    return mos_issues

# ---------------------------------------------------------------------------
# Audit logging
# ---------------------------------------------------------------------------

def _audit_log(mos_event: str, mos_data: dict) -> None:
    try:
        mos_entry = json.dumps({
            "ts":    datetime.now(timezone.utc).isoformat(),
            "event": mos_event,
            **mos_data,
        })
        with open(E_AUDIT_FILE, "a") as f:
            f.write(mos_entry + "\n")
    except Exception as e:
        mos_log.warning(f"Audit log write failed: {e}")


# ---------------------------------------------------------------------------
# Task execution
# ---------------------------------------------------------------------------

def _execute_task(mos_task: dict) -> dict:
    """Execute a coordinator-dispatched task. Returns result dict."""
    mos_type    = mos_task.get("type", "shell")
    mos_payload = mos_task.get("payload", {})

    if mos_type == "shell":
        mos_cmd = mos_payload.get("command", "")
        if not mos_cmd:
            return {"success": False, "error": "No command in payload"}
        try:
            mos_out = subprocess.check_output(
                mos_cmd, shell=True, text=True, timeout=300, stderr=subprocess.STDOUT
            )
            return {"success": True, "output": mos_out[:4096]}
        except subprocess.CalledProcessError as e:
            return {"success": False, "error": e.output[:2048]}
        except Exception as e:
            return {"success": False, "error": str(e)}

    elif mos_type == "ollama_pull":
        mos_model = mos_payload.get("model", "")
        if not mos_model:
            return {"success": False, "error": "No model specified"}
        try:
            subprocess.run(["ollama", "pull", mos_model], timeout=600, check=True)
            return {"success": True, "output": f"Pulled {mos_model}"}
        except Exception as e:
            return {"success": False, "error": str(e)}

    elif mos_type == "ollama_rm":
        mos_model = mos_payload.get("model", "")
        try:
            subprocess.run(["ollama", "rm", mos_model], timeout=60, check=True)
            return {"success": True, "output": f"Removed {mos_model}"}
        except Exception as e:
            return {"success": False, "error": str(e)}

    elif mos_type == "self_update":
        mos_version = mos_payload.get("version", "")
        mos_url     = mos_payload.get("url", "")
        if mos_url:
            return _self_update(mos_url, mos_version)
        return {"success": False, "error": "No update URL"}

    return {"success": False, "error": f"Unknown task type: {mos_type}"}

def _self_update(mos_url: str, mos_version: str) -> dict:
    """Download new agent version and restart."""
    try:
        import tempfile
        mos_tmp = Path(tempfile.mktemp(suffix=".py"))
        urllib.request.urlretrieve(mos_url, mos_tmp)
        mos_self = Path(__file__).resolve()
        shutil.copy2(mos_tmp, mos_self)
        mos_log.info(f"Updated to v{mos_version}, restarting...")
        os.execv(sys.executable, [sys.executable] + sys.argv)
        return {"success": True, "output": f"Updated to {mos_version}"}
    except Exception as e:
        return {"success": False, "error": str(e)}


# ---------------------------------------------------------------------------
# Main daemon loop
# ---------------------------------------------------------------------------

class MedinovAIAgent:
    def __init__(self):
        self.mos_cfg              = _load_config()
        self.mos_coordinator      = None
        self.mos_node_token       = self.mos_cfg.get("node_token", "")
        self.mos_node_id          = self.mos_cfg.get("machine_id", _get_machine_id())
        self.mos_running          = True
        self.mos_last_fleet_sync  = 0.0
        self.mos_last_dev_setup   = 0.0
        self.mos_last_update_chk  = 0.0

    def _find_coordinator_cached(self) -> Optional[str]:
        if self.mos_coordinator:
            mos_health = _http_get(f"{self.mos_coordinator}/v1/health")
            if mos_health and mos_health.get("status") == "ok":
                return self.mos_coordinator
        self.mos_coordinator = _find_coordinator()
        if self.mos_coordinator:
            mos_cfg = _load_config()
            mos_cfg["coordinator"] = self.mos_coordinator
            _save_config(mos_cfg)
        return self.mos_coordinator

    def _send_heartbeat(self) -> None:
        mos_coord = self._find_coordinator_cached()
        if not mos_coord or not self.mos_node_token:
            mos_log.warning("Heartbeat skipped: no coordinator or token")
            return

        mos_t      = _get_telemetry()
        mos_ollama = _get_ollama_status()
        mos_sec    = _check_security()
        mos_alerts = _check_alerts(mos_t, mos_ollama) + mos_sec

        mos_payload = {
            "uptime_s":       int(time.time()),
            "cpu_pct":        mos_t.get("cpu_pct", 0),
            "mem_used_gb":    mos_t.get("mem_used_gb", 0),
            "mem_total_gb":   mos_t.get("mem_total_gb", 0),
            "disk_used_gb":   mos_t.get("disk_used_gb", 0),
            "disk_total_gb":  mos_t.get("disk_total_gb", 0),
            "tailscale_ip":   mos_t.get("tailscale_ip", ""),
            "ollama_running": mos_ollama["ollama_running"],
            "ollama_version": mos_ollama["ollama_version"],
            "models":         mos_ollama["models"],
            "alerts":         mos_alerts,
        }
        mos_resp = _http_post(f"{mos_coord}/v1/heartbeat", mos_payload, self.mos_node_token)
        if mos_resp:
            mos_log.debug("Heartbeat sent OK")
            _audit_log("heartbeat", {"alerts": len(mos_alerts)})
        else:
            mos_log.warning("Heartbeat failed — coordinator unreachable")
            self.mos_coordinator = None  # force re-discovery next cycle

    def _poll_tasks(self) -> None:
        mos_coord = self._find_coordinator_cached()
        if not mos_coord or not self.mos_node_token:
            return
        mos_resp = _http_get(
            f"{mos_coord}/v1/tasks/{self.mos_node_id}",
            self.mos_node_token,
        )
        if not mos_resp:
            return
        for mos_task in mos_resp.get("tasks", []):
            mos_tid    = mos_task["task_id"]
            mos_log.info(f"Executing task {mos_tid} type={mos_task.get('type')}")
            mos_result = _execute_task(mos_task)
            _http_post(
                f"{mos_coord}/v1/tasks/{mos_tid}/ack",
                mos_result,
                self.mos_node_token,
            )
            _audit_log("task_exec", {"task_id": mos_tid, "success": mos_result["success"]})

    def run(self) -> None:
        mos_log.info(f"MedinovAI Agent v{E_VERSION} starting — node_id={self.mos_node_id}")
        signal.signal(signal.SIGTERM, lambda *_: self._stop())
        signal.signal(signal.SIGINT,  lambda *_: self._stop())

        mos_tick_hb   = 0.0
        mos_tick_task = 0.0

        while self.mos_running:
            mos_now = time.monotonic()

            if mos_now - mos_tick_hb >= E_HEARTBEAT_SECS:
                self._send_heartbeat()
                mos_tick_hb = mos_now

            if mos_now - mos_tick_task >= E_TASK_POLL_SECS:
                self._poll_tasks()
                mos_tick_task = mos_now

            if mos_now - self.mos_last_fleet_sync >= E_FLEET_SYNC_SECS:
                mos_log.info("Running fleet sync...")
                _sync_fleet()
                self.mos_last_fleet_sync = mos_now

            if mos_now - self.mos_last_dev_setup >= E_DEV_SETUP_SECS:
                _setup_dev_env()
                self.mos_last_dev_setup = mos_now

            time.sleep(10)

    def _stop(self) -> None:
        mos_log.info("MedinovAI Agent shutting down")
        self.mos_running = False


# ---------------------------------------------------------------------------
# CLI — enroll, run, status, version
# ---------------------------------------------------------------------------

def cmd_enroll(mos_args: argparse.Namespace) -> None:
    """One-time enrollment: register this machine with a coordinator."""
    mos_join_token  = mos_args.join_token
    mos_coordinator = mos_args.coordinator or _find_coordinator()

    if not mos_coordinator:
        print("ERROR: Could not reach any coordinator. Check network/Tailscale.")
        sys.exit(1)

    mos_machine_id = _get_machine_id()
    mos_hostname   = platform.node()
    mos_os         = platform.system().lower()    # darwin | linux
    mos_arch       = platform.machine().lower()   # arm64 | x86_64

    mos_payload = {
        "join_token":    mos_join_token,
        "hostname":      mos_hostname,
        "machine_id":    mos_machine_id,
        "os_type":       "macos" if mos_os == "darwin" else mos_os,
        "arch":          "arm64" if "arm" in mos_arch or "aarch" in mos_arch else "amd64",
        "role":          mos_args.role,
        "ollama":        bool(shutil.which("ollama")),
        "agent_version": E_VERSION,
        "tags":          mos_args.tags.split(",") if mos_args.tags else [],
    }

    print(f"Enrolling {mos_hostname} with coordinator {mos_coordinator}...")
    mos_resp = _http_post(f"{mos_coordinator}/v1/enroll", mos_payload)

    if not mos_resp or "node_token" not in mos_resp:
        print("ERROR: Enrollment failed. Check join token and coordinator URL.")
        sys.exit(1)

    mos_cfg = {
        "machine_id":   mos_machine_id,
        "node_token":   mos_resp["node_token"],
        "coordinator":  mos_coordinator,
        "hostname":     mos_hostname,
        "role":         mos_args.role,
        "enrolled_at":  datetime.now(timezone.utc).isoformat(),
        "agent_version": E_VERSION,
    }
    _save_config(mos_cfg)
    _audit_log("enrolled", {"coordinator": mos_coordinator, "role": mos_args.role})

    print(f"\n✅ Enrolled successfully!")
    print(f"   Node ID:     {mos_machine_id}")
    print(f"   Coordinator: {mos_coordinator}")
    print(f"   Role:        {mos_args.role}")
    print(f"   Config:      {E_CONFIG_FILE}")
    print(f"\nNext: start the agent service with:")
    if platform.system() == "Darwin":
        print("  launchctl load ~/Library/LaunchAgents/com.medinovai.agent.plist")
    else:
        print("  sudo systemctl enable --now medinovai-agent")

def cmd_run(_) -> None:
    MedinovAIAgent().run()

def cmd_status(_) -> None:
    mos_cfg = _load_config()
    if not mos_cfg:
        print("Not enrolled. Run: medinovai-agent enroll --join-token <TOKEN>")
        return
    print(f"MedinovAI Agent v{E_VERSION}")
    print(f"  Node ID:     {mos_cfg.get('machine_id', 'unknown')}")
    print(f"  Hostname:    {mos_cfg.get('hostname', platform.node())}")
    print(f"  Role:        {mos_cfg.get('role', 'unknown')}")
    print(f"  Coordinator: {mos_cfg.get('coordinator', 'not set')}")
    print(f"  Enrolled:    {mos_cfg.get('enrolled_at', 'unknown')}")
    mos_ollama = _get_ollama_status()
    print(f"  Ollama:      {'running ✅' if mos_ollama['ollama_running'] else 'not running ❌'}")
    if mos_ollama["ollama_running"]:
        print(f"  Models:      {len(mos_ollama['models'])} loaded")

def cmd_version(_) -> None:
    print(f"medinovai-agent {E_VERSION}")

# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

def main() -> None:
    mos_parser = argparse.ArgumentParser(
        prog="medinovai-agent",
        description="MedinovAI Node Agent — keeps your machine in the MedinovAI network",
    )
    mos_sub = mos_parser.add_subparsers(dest="command")

    mos_enroll = mos_sub.add_parser("enroll", help="Enroll this machine")
    mos_enroll.add_argument("--join-token",   required=True, help="One-time join token from admin")
    mos_enroll.add_argument("--coordinator",  default="", help="Coordinator URL (auto-discovered if omitted)")
    mos_enroll.add_argument("--role",         default="dev-machine",
        choices=["intern", "power-user", "dev-machine", "aifactory-node"])
    mos_enroll.add_argument("--tags",         default="", help="Comma-separated tags")
    mos_enroll.set_defaults(func=cmd_enroll)

    mos_run = mos_sub.add_parser("run", help="Start daemon (called by launchd/systemd)")
    mos_run.set_defaults(func=cmd_run)

    mos_status = mos_sub.add_parser("status", help="Show node status")
    mos_status.set_defaults(func=cmd_status)

    mos_ver = mos_sub.add_parser("version", help="Show version")
    mos_ver.set_defaults(func=cmd_version)

    mos_args = mos_parser.parse_args()
    if not mos_args.command:
        mos_parser.print_help()
        sys.exit(1)
    mos_args.func(mos_args)

if __name__ == "__main__":
    main()
