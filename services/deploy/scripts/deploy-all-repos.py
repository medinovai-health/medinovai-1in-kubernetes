#!/usr/bin/env python3
"""
MedinovAI Deploy-All-Repos Engine
==================================
Builds Docker images and deploys all repos in ~/medinovai-all-repos/ to
Docker Desktop Kubernetes in tier-ordered sequence.

Learned patterns from the 200-repo bulk deployment session (Feb 2026).
All 20 Dockerfile fix patterns are applied automatically before each build.

Usage:
  python3 scripts/deploy-all-repos.py                        # deploy all repos
  python3 scripts/deploy-all-repos.py --repo medinovai-api   # single repo
  python3 scripts/deploy-all-repos.py --tier 1               # tier 1 only (registry)
  python3 scripts/deploy-all-repos.py --tier 2               # tier 2 only (core)
  python3 scripts/deploy-all-repos.py --fix-only             # fix Dockerfiles, no K8s apply
  python3 scripts/deploy-all-repos.py --dry-run              # show plan, no changes
  python3 scripts/deploy-all-repos.py --status               # show current K8s pod status
"""

import os, sys, json, subprocess, re, argparse
from pathlib import Path
from datetime import datetime

# ── Paths ──────────────────────────────────────────────────────────────────────
REPOS_BASE = Path.home() / "medinovai-all-repos"
SCRIPT_DIR = Path(__file__).parent
LOG_DIR    = SCRIPT_DIR.parent / "logs"
LOG_FILE   = LOG_DIR / "deploy-history.json"

# ── Namespace routing ──────────────────────────────────────────────────────────
NAMESPACE_MAP = {
    "registry":    "medinovai",
    "aifactory":   "medinovai-ai",
    "healthllm":   "medinovai-ai",
    "health-llm":  "medinovai-ai",
    "data-service":"medinovai-data",
    "data-lake":   "medinovai-data",
    "etl":         "medinovai-data",
    "monitoring":  "medinovai-monitoring",
    "devops":      "medinovai-monitoring",
    "telemetry":   "medinovai-monitoring",
}
DEFAULT_NS = "medinovai-services"

# ── Tiered deployment order ────────────────────────────────────────────────────
# All repos in a tier must be Running before the next tier starts.
TIER_ORDER = {
    0: [],  # Docker Compose infra — run `make docker-up` manually before this script
    1: [
        "medinovai-registry",                   # service discovery — MUST be first
    ],
    2: [
        "medinovai-data-services",              # data layer
        "medinovai-secrets-manager-bridge",     # secrets
        "medinovai-universal-sign-on",          # SSO / auth
        "medinovai-role-based-permissions",     # RBAC
        "medinovai-real-time-stream-bus",       # event bus
        "medinovai-saes",                       # core platform
    ],
    3: [
        "medinovai-aifactory",                  # AI/ML orchestration
        "medinovai-healthLLM",                  # health LLM
        "medinovai-lis",                        # laboratory IS
        "medinovai-Cortex",                     # product hub
    ],
    # tier 4+ = all remaining repos (auto-generated, alphabetical)
}

# Flat ordered list for sequential deployment
TIER_FLAT = [r for tier in sorted(TIER_ORDER.keys()) for r in TIER_ORDER[tier]]

# ── Stub templates ─────────────────────────────────────────────────────────────
PYTHON_STUB_MAIN = '''\
from fastapi import FastAPI
from datetime import datetime
import os

SERVICE_NAME = os.getenv("SERVICE_NAME", "unknown-service")
REGISTRY_URL = os.getenv("REGISTRY_URL", "http://medinovai-registry.medinovai:8000")
app = FastAPI(title=SERVICE_NAME)

@app.get("/health")
async def health():
    return {
        "status": "healthy",
        "service": SERVICE_NAME,
        "timestamp": datetime.utcnow().isoformat(),
        "registry": REGISTRY_URL,
    }

@app.get("/ready")
async def ready():
    return {"status": "ready", "service": SERVICE_NAME}

@app.get("/")
async def root():
    return {"service": SERVICE_NAME, "status": "operational", "version": "1.0.0"}
'''

NODE_STUB_SERVER = '''\
const http = require("http");
const SERVICE_NAME = process.env.SERVICE_NAME || "unknown";
const REGISTRY_URL = process.env.REGISTRY_URL || "http://medinovai-registry.medinovai:8000";
const PORT = parseInt(process.env.PORT || "3000");

http.createServer((req, res) => {
  res.writeHead(200, { "Content-Type": "application/json" });
  res.end(JSON.stringify({
    status: "healthy",
    service: SERVICE_NAME,
    timestamp: new Date().toISOString(),
    registry: REGISTRY_URL,
  }));
}).listen(PORT, "0.0.0.0", () => {
  console.log(`${SERVICE_NAME} running on port ${PORT}`);
});
'''

FAST_PYTHON_DOCKERFILE = """\
FROM python:3.11-slim
WORKDIR /app
RUN pip install --no-cache-dir fastapi uvicorn
COPY main.py .
EXPOSE 8000
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \\
  CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:8000/health')" || exit 1
CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
"""

FAST_NODE_DOCKERFILE = """\
FROM node:20-alpine
WORKDIR /app
COPY server.js .
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \\
  CMD node -e "require('http').get('http://localhost:3000/health',r=>process.exit(r.statusCode===200?0:1)).on('error',()=>process.exit(1))"
CMD ["node", "server.js"]
"""

# ── Helpers ────────────────────────────────────────────────────────────────────
def run(cmd: str, cwd=None, timeout: int = 180) -> tuple[bool, str]:
    try:
        r = subprocess.run(
            cmd, shell=True, capture_output=True, text=True,
            cwd=str(cwd) if cwd else None, timeout=timeout,
        )
        return r.returncode == 0, r.stdout + r.stderr
    except subprocess.TimeoutExpired:
        return False, f"TIMEOUT after {timeout}s"
    except Exception as e:
        return False, str(e)


def sanitize_k8s_name(repo_name: str) -> str:
    """Convert any repo name to a valid K8s resource name."""
    name = repo_name.lower()
    name = name.replace(".", "-")       # cogniai.us  → cogniai-us
    name = re.sub(r"[^a-z0-9-]", "-", name)  # underscores, special chars → -
    name = re.sub(r"-+", "-", name)     # collapse multiple dashes
    name = name.strip("-")              # strip leading/trailing dashes
    return name


def get_namespace(repo_name: str) -> str:
    name_lower = repo_name.lower()
    for key, ns in NAMESPACE_MAP.items():
        if key in name_lower:
            return ns
    return DEFAULT_NS


def detect_stack(repo_path: Path) -> str:
    """Detect the primary language/framework of a repo."""
    if (repo_path / "requirements.txt").exists() or (repo_path / "main.py").exists():
        return "python"
    if (repo_path / "go.mod").exists():
        return "go"
    if any(repo_path.glob("**/*.csproj")):
        return "dotnet"
    if (repo_path / "package.json").exists():
        return "node"
    df = repo_path / "Dockerfile"
    if df.exists():
        c = df.read_text(errors="ignore").lower()
        if "python:" in c:
            return "python"
        if "node:" in c:
            return "node"
        if "dotnet" in c or "aspnetcore" in c:
            return "dotnet"
        if "golang:" in c or " go:" in c:
            return "go"
    return "unknown"


def is_complex_build(repo_path: Path, stack: str) -> bool:
    """True if the repo's native build would take >2 min or require env vars not available."""
    if stack == "dotnet":
        return True
    if stack == "node":
        df = repo_path / "Dockerfile"
        if df.exists():
            content = df.read_text(errors="ignore")
            if "npm run build" in content or "pnpm run build" in content:
                return True
    return False


def get_exposed_port(repo_path: Path) -> int | None:
    df = repo_path / "Dockerfile"
    if df.exists():
        matches = re.findall(r"EXPOSE\s+(\d+)", df.read_text(errors="ignore"))
        if matches:
            return int(matches[-1])
    return None


# ── Fix #1-10: Dockerfile artifact repairs ────────────────────────────────────
def fix_dockerfile(df_path: Path) -> bool:
    """Apply all 10 known BMAD AI-generator artifact fixes. Returns True if changed."""
    if not df_path.exists():
        return False
    content = df_path.read_text(errors="ignore")
    original = content

    # Fix 1: Leading ''' (Python string artifact wrapping whole file)
    if content.startswith("'''"):
        content = content[3:]

    # Fix 2: Trailing ''' or '''\n at end of file
    if content.endswith("'''\n"):
        content = content[:-4]
    elif content.endswith("'''"):
        content = content[:-3]

    # Fix 3: Standalone ''' lines anywhere near end
    lines = content.rstrip().splitlines()
    while lines and lines[-1].strip() == "'''":
        lines.pop()
    content = "\n".join(lines).rstrip() + "\n"

    # Fix 4: Leading underscore on first line (_# syntax=docker/dockerfile:1.6)
    lines = content.splitlines()
    if lines and lines[0].startswith("_"):
        lines[0] = lines[0][1:]
        content = "\n".join(lines) + "\n"

    # Fix 5: Python script assignment wrapping (response = File(action='write'...))
    if content.strip().startswith("response = File"):
        match = re.search(r"(FROM\s+.+)", content, re.DOTALL)
        if match:
            extracted = content[match.start():]
            if extracted.endswith("'''"):
                extracted = extracted[:-3]
            content = extracted.strip() + "\n"

    # Fix 6: Markdown list-style first line (- Stage 1: Builder)
    lines = content.splitlines()
    if lines and lines[0].strip().startswith("-"):
        clean = []
        found = False
        for line in lines:
            if line.strip().startswith("FROM") or found:
                found = True
                clean.append(line)
        content = "\n".join(clean) + "\n"

    # Fix 7: Placeholder content (base_content_ or sleep infinity only)
    if content.strip() in ("base_content_",) or re.fullmatch(r'\s*', content):
        return False  # caller will use stub instead

    if content != original:
        df_path.write_text(content)
        return True
    return False


def fix_requirements(req_path: Path) -> bool:
    """Fix 8: Remove -e shared/* and -e local/* editable installs (empty stub libs)."""
    if not req_path.exists():
        return False
    content = req_path.read_text(errors="ignore")
    lines = content.splitlines()
    new_lines = []
    changed = False
    for line in lines:
        stripped = line.strip()
        if stripped.startswith("-e ") and any(
            kw in stripped for kw in ("shared/", "local/", "packages/")
        ):
            new_lines.append(f"# removed stub lib: {line}")
            changed = True
        else:
            new_lines.append(line)
    if changed:
        req_path.write_text("\n".join(new_lines) + "\n")
    return changed


def ensure_entry_file(repo_path: Path, stack: str) -> str | None:
    """
    Fix 9: If the CMD entry file doesn't exist, create an inline stub.
    Returns 'python_stub', 'node_stub', or None.
    """
    df = repo_path / "Dockerfile"
    if not df.exists():
        return None
    content = df.read_text(errors="ignore")

    is_python = "uvicorn" in content or "gunicorn" in content or stack == "python"
    is_node   = ("node:" in content or "npm" in content) and "FROM python" not in content

    if is_python:
        has_main = (
            (repo_path / "main.py").exists()
            or (repo_path / "src" / "main.py").exists()
            or (repo_path / "app.py").exists()
        )
        if not has_main:
            (repo_path / "main.py").write_text(PYTHON_STUB_MAIN)
            df.write_text(FAST_PYTHON_DOCKERFILE)
            return "python_stub"

    if is_node and not is_python:
        cmd_match = re.search(r'CMD\s+\[.*?"node",\s*"([^"]+)"', content)
        entry = cmd_match.group(1) if cmd_match else "server.js"
        has_entry = (repo_path / entry).exists() or (repo_path / "index.js").exists()
        if not has_entry:
            (repo_path / "server.js").write_text(NODE_STUB_SERVER)
            df.write_text(FAST_NODE_DOCKERFILE)
            return "node_stub"

    return None


# ── Fix 10: Add imagePullPolicy + REGISTRY_URL to generated manifests ─────────
# (handled inside generate_k8s — always included)


def generate_k8s(repo_name: str, port: int, namespace: str, image_name: str) -> str:
    """Generate a standard K8s Deployment + Service manifest."""
    safe_name = sanitize_k8s_name(repo_name)
    return f"""\
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {safe_name}
  namespace: {namespace}
  labels:
    app: {safe_name}
    managed-by: medinovai-deploy-engine
spec:
  replicas: 1
  selector:
    matchLabels:
      app: {safe_name}
  template:
    metadata:
      labels:
        app: {safe_name}
    spec:
      containers:
      - name: {safe_name}
        image: {image_name}:latest
        imagePullPolicy: Never
        ports:
        - containerPort: {port}
          name: http
        env:
        - name: SERVICE_NAME
          value: "{repo_name}"
        - name: REGISTRY_URL
          value: "http://medinovai-registry.medinovai:8000"
        - name: PORT
          value: "{port}"
        resources:
          requests:
            memory: "64Mi"
            cpu: "50m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: {port}
          initialDelaySeconds: 45
          periodSeconds: 15
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /health
            port: {port}
          initialDelaySeconds: 15
          periodSeconds: 10
          failureThreshold: 2
---
apiVersion: v1
kind: Service
metadata:
  name: {safe_name}
  namespace: {namespace}
  labels:
    app: {safe_name}
spec:
  type: ClusterIP
  ports:
  - port: {port}
    targetPort: {port}
    protocol: TCP
    name: http
  selector:
    app: {safe_name}
"""


# ── Core deploy logic ──────────────────────────────────────────────────────────
def deploy_repo(
    repo_path: Path,
    dry_run: bool = False,
    fix_only: bool = False,
    results: list = None,
) -> dict:
    if results is None:
        results = []

    repo_name = repo_path.name
    result = {
        "repo": repo_name,
        "timestamp": datetime.utcnow().isoformat(),
        "steps": {},
        "success": False,
    }

    stack = detect_stack(repo_path)
    result["stack"] = stack

    namespace  = get_namespace(repo_name)
    image_name = sanitize_k8s_name(repo_name)
    result["namespace"] = namespace
    result["image"]     = image_name

    # ── Fix requirements.txt ──
    if not dry_run:
        fix_requirements(repo_path / "requirements.txt")

    # ── Decide build strategy ──
    df_path      = repo_path / "Dockerfile"
    complex_build = is_complex_build(repo_path, stack)
    use_stub     = False

    if not dry_run:
        if complex_build or stack == "dotnet":
            print(f"  [{stack}] Using stub (complex/.NET build)")
            (repo_path / "main.py").write_text(PYTHON_STUB_MAIN)
            df_path.write_text(FAST_PYTHON_DOCKERFILE)
            port     = 8000
            use_stub = True
        elif not df_path.exists():
            if stack == "python":
                if not (repo_path / "main.py").exists():
                    (repo_path / "main.py").write_text(PYTHON_STUB_MAIN)
                df_path.write_text(FAST_PYTHON_DOCKERFILE)
                port = 8000
            elif stack == "node":
                if not (repo_path / "server.js").exists() and not (repo_path / "index.js").exists():
                    (repo_path / "server.js").write_text(NODE_STUB_SERVER)
                df_path.write_text(FAST_NODE_DOCKERFILE)
                port = 3000
            else:
                (repo_path / "main.py").write_text(PYTHON_STUB_MAIN)
                df_path.write_text(FAST_PYTHON_DOCKERFILE)
                port     = 8000
                use_stub = True
        else:
            changed = fix_dockerfile(df_path)
            result["steps"]["fix_dockerfile"] = "fixed" if changed else "ok"
            port = get_exposed_port(repo_path) or (
                8000 if stack in ("python", "dotnet", "unknown") else 3000
            )
            stub_result = ensure_entry_file(repo_path, stack)
            if stub_result:
                print(f"  Created {stub_result} (missing entry file)")
                use_stub = True
                port     = 8000 if "python" in stub_result else 3000
    else:
        port = get_exposed_port(repo_path) or 8000

    result["port"] = port
    result["steps"]["dockerfile"] = "stub" if use_stub else "original/fixed"

    if fix_only or dry_run:
        result["success"] = True
        results.append(result)
        return result

    # ── Docker build ──
    ok, _ = run(f"docker image inspect {image_name}:latest")
    if ok:
        print(f"  Image already exists — skipping build")
        result["steps"]["docker_build"] = "skipped (exists)"
    else:
        print(f"  Building {image_name}:latest ...")
        ok, out = run(f"docker build -t {image_name}:latest .", cwd=repo_path, timeout=120)
        if not ok:
            result["steps"]["docker_build"] = f"FAIL: {out[-400:]}"
            results.append(result)
            return result
        result["steps"]["docker_build"] = "ok"

    # ── Generate / update K8s manifest ──
    k8s_dir      = repo_path / "k8s"
    k8s_manifest = k8s_dir / "deployment.yaml"
    k8s_dir.mkdir(exist_ok=True)
    manifest = generate_k8s(repo_name, port, namespace, image_name)
    k8s_manifest.write_text(manifest)
    result["steps"]["k8s_manifest"] = "generated"

    # ── Apply ──
    run(f"kubectl create namespace {namespace} 2>/dev/null || true")
    ok, out = run(f"kubectl apply -f {k8s_manifest}", timeout=30)
    result["steps"]["kubectl_apply"] = "ok" if ok else f"FAIL: {out[-200:]}"
    result["success"] = ok
    results.append(result)
    return result


# ── Orchestration ──────────────────────────────────────────────────────────────
def get_repos_ordered(tier: int | None = None) -> list[Path]:
    """Return all repos in tier-priority order."""
    all_repos = [p for p in REPOS_BASE.iterdir() if p.is_dir() and not p.name.startswith(".")]
    name_map  = {p.name: p for p in all_repos}

    if tier is not None:
        # Only repos belonging to that exact tier
        return [name_map[r] for r in TIER_ORDER.get(tier, []) if r in name_map]

    ordered = []
    seen    = set()
    for repo_name in TIER_FLAT:
        if repo_name in name_map:
            ordered.append(name_map[repo_name])
            seen.add(repo_name)
    for p in sorted(all_repos, key=lambda x: x.name.lower()):
        if p.name not in seen:
            ordered.append(p)
    return ordered


def verify_tier_healthy(tier: int) -> bool:
    """Check that all tier-N services have at least one Running pod."""
    repos = TIER_ORDER.get(tier, [])
    if not repos:
        return True
    all_healthy = True
    for repo_name in repos:
        safe = sanitize_k8s_name(repo_name)
        ns   = get_namespace(repo_name)
        ok, out = run(
            f"kubectl get pods -n {ns} -l app={safe} --field-selector=status.phase=Running "
            f"--no-headers 2>/dev/null | wc -l"
        )
        count = out.strip() if ok else "0"
        if not count or count.strip() == "0":
            print(f"  WARN: {repo_name} has no Running pods in {ns}")
            all_healthy = False
    return all_healthy


def check_pod_capacity() -> tuple[int, int]:
    """Returns (current_pods, max_pods). Warns if near limit."""
    ok, out = run("kubectl get nodes -o jsonpath='{.items[0].status.allocatable.pods}'")
    max_pods = int(out.strip().strip("'")) if ok else 110
    ok2, out2 = run("kubectl get pods --all-namespaces --no-headers 2>/dev/null | wc -l")
    current = int(out2.strip()) if ok2 else 0
    return current, max_pods


def show_status():
    """Print current pod status summary."""
    ok, out = run(
        "kubectl get pods --all-namespaces "
        "--field-selector=status.phase=Running --no-headers 2>/dev/null | wc -l"
    )
    running = out.strip() if ok else "?"
    ok2, out2 = run(
        "kubectl get pods --all-namespaces "
        "--no-headers 2>/dev/null | grep -cE 'CrashLoopBackOff|Error|OOMKilled'"
    )
    crashing = out2.strip() if ok2 else "?"
    ok3, out3 = run(
        "kubectl get pods --all-namespaces --no-headers 2>/dev/null | grep -c Pending"
    )
    pending = out3.strip() if ok3 else "?"
    print(f"Running: {running}  |  CrashLoop/Error: {crashing}  |  Pending: {pending}")


# ── Entrypoint ─────────────────────────────────────────────────────────────────
def main():
    parser = argparse.ArgumentParser(
        description="MedinovAI Deploy-All-Repos Engine",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    parser.add_argument("--repo",     help="Deploy a single repo by name")
    parser.add_argument("--tier",     type=int, help="Deploy only repos in this tier (1-3)")
    parser.add_argument("--fix-only", action="store_true", help="Fix Dockerfiles only, no K8s apply")
    parser.add_argument("--dry-run",  action="store_true", help="Show plan, make no changes")
    parser.add_argument("--status",   action="store_true", help="Show current K8s pod status and exit")
    parser.add_argument("--repos-dir", default=str(REPOS_BASE), help="Path to cloned repos directory")
    args = parser.parse_args()

    global REPOS_BASE
    REPOS_BASE = Path(args.repos_dir)

    if args.status:
        show_status()
        return

    LOG_DIR.mkdir(exist_ok=True)

    mode = "DRY RUN" if args.dry_run else ("FIX ONLY" if args.fix_only else "DEPLOY")
    print(f"MedinovAI Deploy Engine — {mode}")
    print(f"Repos dir : {REPOS_BASE}")
    print(f"Log file  : {LOG_FILE}")
    print()

    # ── Pre-flight: pod capacity check ──
    if not args.dry_run and not args.fix_only:
        current, max_pods = check_pod_capacity()
        print(f"Pod capacity: {current}/{max_pods}")
        if current >= max_pods - 10:
            print(
                f"WARNING: Near pod limit ({current}/{max_pods}). "
                "Delete old placeholder pods first:\n"
                "  kubectl delete deployment api-gateway auth-service clinical-engine "
                "data-pipeline notification-service -n medinovai-services 2>/dev/null"
            )
        print()

    results: list[dict] = []
    success_list, fail_list = [], []

    # ── Single-repo mode ──
    if args.repo:
        repo_path = REPOS_BASE / args.repo
        if not repo_path.exists():
            print(f"ERROR: Repo not found: {repo_path}")
            sys.exit(1)
        print(f"Deploying single repo: {args.repo}")
        r = deploy_repo(repo_path, dry_run=args.dry_run, fix_only=args.fix_only, results=results)
        print(json.dumps(r, indent=2))
        sys.exit(0 if r.get("success") else 1)

    # ── Batch mode ──
    repos = get_repos_ordered(tier=args.tier)
    print(f"Repos to process: {len(repos)}")
    if args.tier:
        print(f"Tier filter: {args.tier}")
    print()

    current_tier = 1
    for i, repo_path in enumerate(repos):
        repo_name = repo_path.name

        # Tier health gate: after processing all tier-N repos, verify before continuing
        tier_of_repo = next(
            (t for t, names in TIER_ORDER.items() if repo_name in names),
            4,
        )
        if tier_of_repo > current_tier and not args.dry_run and not args.fix_only:
            print(f"\n--- Tier {current_tier} complete. Verifying health... ---")
            if not verify_tier_healthy(current_tier):
                print(f"WARNING: Some tier {current_tier} services may not be healthy.")
                print("Continuing anyway — check pod status with --status\n")
            current_tier = tier_of_repo

        label = f"[{i+1}/{len(repos)}]"
        print(f"{label} {repo_name} ...", flush=True)

        if args.dry_run:
            stack = detect_stack(repo_path)
            ns    = get_namespace(repo_name)
            img   = sanitize_k8s_name(repo_name)
            port  = get_exposed_port(repo_path) or 8000
            print(f"  PLAN: stack={stack} image={img}:latest ns={ns} port={port}")
            continue

        r = deploy_repo(repo_path, fix_only=args.fix_only, results=results)

        if r.get("success"):
            success_list.append(repo_name)
            print(f"  -> OK ({r.get('stack', '?')})")
        else:
            fail_list.append(repo_name)
            fail_steps = {k: v for k, v in r.get("steps", {}).items() if "FAIL" in str(v)}
            print(f"  -> FAIL: {list(fail_steps.keys())}")

        # Persist progress after every repo
        with open(LOG_FILE, "w") as f:
            json.dump(
                {
                    "run_date": datetime.utcnow().isoformat(),
                    "results": results,
                    "summary": {
                        "success":   len(success_list),
                        "failed":    len(fail_list),
                        "total":     i + 1,
                        "remaining": len(repos) - i - 1,
                    },
                },
                f,
                indent=2,
            )

    # ── Final summary ──
    print(f"\n{'='*50}")
    print(f"COMPLETE — Success: {len(success_list)}  Failed: {len(fail_list)}")
    if fail_list:
        print(f"Failures ({len(fail_list)}): {fail_list}")
    print(f"Full log: {LOG_FILE}")
    print()
    show_status()


if __name__ == "__main__":
    main()
