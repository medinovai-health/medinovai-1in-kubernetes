#!/usr/bin/env python3
"""
TEST2 Pre-flight Deployment Check
Validates images, healthcheck ports, Kafka volumes, env vars, Docker memory, and port availability.

Usage:
  python3 infra/docker/preflight-check.py              # Full check
  python3 infra/docker/preflight-check.py --skip-images  # Skip image check (for CI)
  python3 infra/docker/preflight-check.py --env-file /path/to/test2.env

Docs: docs/TEST2-DEPLOYMENT-RUNBOOK.md
"""

import subprocess
import sys
import os
import re
import yaml
import socket
import argparse

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
COMPOSE_FILE = os.path.join(SCRIPT_DIR, "docker-compose.TEST2-full.yml")
ENV_FILE = os.path.join(SCRIPT_DIR, "test2.env")

# Resolve base dir from env var or find relative to this script
BASE_DIR = os.path.join(
    os.environ.get("REPOS_PATH", os.path.expanduser("~/Github")),
    "medinovai-health"
)

# Non-standard healthcheck ports — must match what's in docker-compose.TEST2-full.yml
KNOWN_PORT_OVERRIDES = {
    "medinovai-registry":            ("8000",  "http://localhost:8000/health"),
    "medinovai-data-services":       ("8300",  "http://localhost:8300/api/health"),
    "medinovai-healthllm":           ("12304", "http://localhost:12304/health"),
    "medinovai-real-time-stream-bus": ("3000",  "http://localhost:3000/health"),
}

# Services requiring Dockerfile.TEST2 (compose service name -> repo dir name)
SERVICES_WITH_DOCKERFILE_TEST2 = {
    "medinovai-registry":               "medinovai-registry",
    "medinovai-data-services":          "medinovai-data-services",
    "medinovai-real-time-stream-bus":   "medinovai-real-time-stream-bus",
    "medinovai-healthllm":              "medinovai-healthLLM",
    "medinovai-aifactory":              "medinovai-aifactory",
    "medinovai-notification-center":    "medinovai-notification-center",
    "medinovai-hipaa-gdpr-guard":       "medinovai-hipaa-gdpr-guard",
    "medinovai-api-gateway":            "medinovai-api-gateway",
    "medinovai-secrets-manager-bridge": "medinovai-secrets-manager-bridge",
    "medinovai-security":               "medinovai-security-service",
    "medinovai-universal-sign-on":      "medinovai-universal-sign-on",
    "medinovai-role-based-permissions": "medinovai-role-based-permissions",
    "medinovai-encryption-vault":       "medinovai-encryption-vault",
    "medinovai-consent-preference-api": "medinovai-consent-preference-api",
    "medinovai-audit-trail-explorer":   "medinovai-audit-trail-explorer",
    "medinovai-model-service-orchestrator": "MedinovAI-Model-Service-Orchestrator",
}

# Key infra ports that must be free before deploying
KEY_PORTS_TO_CHECK = [16610, 16612, 16613, 16614, 16615, 16616, 16619, 16620]

REQUIRED_ENV_VARS = [
    "KAFKA_CLUSTER_ID",
    "POSTGRES_PASSWORD",
    "REDIS_PASSWORD",
]


def run(cmd, capture=True):
    result = subprocess.run(cmd, capture_output=capture, text=True)
    return result.stdout.strip(), result.returncode


def load_env_file(env_file):
    env = {}
    if os.path.exists(env_file):
        with open(env_file) as f:
            for line in f:
                line = line.strip()
                if line and not line.startswith("#") and "=" in line:
                    k, _, v = line.partition("=")
                    env[k.strip()] = v.strip()
    return env


def get_local_images():
    out, _ = run(["docker", "images", "--format", "{{.Repository}}:{{.Tag}}"])
    return set(out.split("\n")) if out else set()


def check_images(services, local_images, env_vars):
    missing = []
    for name, config in services.items():
        image_template = config.get("image", "")
        image = image_template
        for k, v in env_vars.items():
            image = image.replace(f"${{{k}}}", v)
        image = re.sub(r'\$\{[^}]+:-([^}]+)\}', r'\1', image)
        image = re.sub(r'\$\{[^}]+\}', 'latest', image)
        if "/" in image and not image.startswith("local"):
            repo = image.split(":")[0]
            found = any(img.startswith(repo) for img in local_images if img)
            if not found:
                missing.append((name, image))
    return missing


def check_healthcheck_ports(services):
    issues = []
    for svc_name, (port, expected_url) in KNOWN_PORT_OVERRIDES.items():
        if svc_name in services:
            hc = services[svc_name].get("healthcheck", {})
            test = str(hc.get("test", ""))
            if expected_url not in test:
                actual = [t for t in test.split() if "localhost" in t]
                issues.append({
                    "service": svc_name,
                    "expected": expected_url,
                    "actual": actual[0] if actual else "(not found in test)",
                })
    return issues


def check_dockerfile_test2():
    missing = []
    for svc, repo in SERVICES_WITH_DOCKERFILE_TEST2.items():
        df = os.path.join(BASE_DIR, repo, "Dockerfile.TEST2")
        if not os.path.exists(df):
            missing.append((svc, df))
    return missing


def check_kafka_volumes():
    out, _ = run(["docker", "volume", "ls", "--format", "{{.Name}}"])
    volumes = set(out.split("\n"))
    return "test2-kafka-data" in volumes, "test2-zookeeper-data" in volumes


def check_kafka_cluster_id(env_vars):
    kid = env_vars.get("KAFKA_CLUSTER_ID", "")
    return bool(kid), kid


def check_docker_memory():
    out, _ = run(["docker", "info", "--format", "{{.MemTotal}}"])
    try:
        gb = int(out) / 1024 / 1024 / 1024
        return gb >= 12, gb
    except Exception:
        return True, 0


def check_ports_free():
    in_use = []
    for port in KEY_PORTS_TO_CHECK:
        try:
            with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
                s.settimeout(0.5)
                if s.connect_ex(("localhost", port)) == 0:
                    in_use.append(port)
        except Exception:
            pass
    return in_use


def check_required_env_vars(env_vars):
    missing = [k for k in REQUIRED_ENV_VARS if not env_vars.get(k)]
    return missing


def check_medinovai_core():
    pyproject = os.path.join(BASE_DIR, "medinovai-core", "pyproject.toml")
    if not os.path.exists(pyproject):
        return None, f"Not found at {pyproject}"
    with open(pyproject) as f:
        content = f.read()
    if '"grpc>=' in content and '"grpcio>=' not in content:
        return False, "Uses 'grpc' (wrong) — must be 'grpcio'"
    elif '"grpcio>=' in content:
        return True, "grpcio>=1.60.0 ✓"
    return True, "grpcio dependency OK"


def main():
    parser = argparse.ArgumentParser(description="TEST2 Pre-flight Check")
    parser.add_argument("--skip-images", action="store_true", help="Skip Docker image check (useful in CI)")
    parser.add_argument("--env-file", default=ENV_FILE, help="Path to test2.env")
    args = parser.parse_args()

    print("=" * 60)
    print("TEST2 Pre-flight Deployment Check")
    print(f"Compose:  {COMPOSE_FILE}")
    print(f"Env file: {args.env_file}")
    print(f"Repos:    {BASE_DIR}")
    print("=" * 60)

    errors = 0
    warnings = 0

    with open(COMPOSE_FILE) as f:
        data = yaml.safe_load(f)
    services = data.get("services", {})
    env_vars = load_env_file(args.env_file)
    env_vars.update({"REGISTRY": "ghcr.io/myonsite-healthcare", "TAG": "latest"})

    # Check 1: Required env vars
    print("\n[1/8] Checking required environment variables...")
    missing_vars = check_required_env_vars(env_vars)
    if missing_vars:
        print(f"  FAIL {len(missing_vars)} required vars missing in {args.env_file}:")
        for v in missing_vars:
            print(f"       {v} — not set")
        errors += len(missing_vars)
    else:
        print(f"  OK   All required env vars set (KAFKA_CLUSTER_ID={env_vars.get('KAFKA_CLUSTER_ID','?')[:12]}...)")

    # Check 2: Docker images
    if not args.skip_images:
        print("\n[2/8] Checking Docker images...")
        local_images = get_local_images()
        missing_imgs = check_images(services, local_images, env_vars)
        if missing_imgs:
            print(f"  FAIL {len(missing_imgs)} images missing locally:")
            for name, img in missing_imgs[:10]:
                print(f"       {name}: {img[:70]}")
            if len(missing_imgs) > 10:
                print(f"       ... and {len(missing_imgs)-10} more")
            print(f"  FIX: make test2-rebuild   (rebuilds all Dockerfile.TEST2 services)")
            errors += len(missing_imgs)
        else:
            print(f"  OK   All {len(services)} service images found locally")
    else:
        print("\n[2/8] Skipping Docker image check (--skip-images)")

    # Check 3: Healthcheck port configurations
    print("\n[3/8] Checking healthcheck port configurations...")
    hc_issues = check_healthcheck_ports(services)
    if hc_issues:
        print(f"  FAIL {len(hc_issues)} healthcheck port mismatches:")
        for issue in hc_issues:
            print(f"       {issue['service']}: expected {issue['expected']}, got {issue['actual']}")
        errors += len(hc_issues)
    else:
        print(f"  OK   All critical healthcheck ports correctly configured")
        for svc, (port, url) in KNOWN_PORT_OVERRIDES.items():
            print(f"       {svc}: {url}")

    # Check 4: Kafka/Zookeeper volumes
    print("\n[4/8] Checking Kafka/Zookeeper volume state...")
    kafka_vol, zk_vol = check_kafka_volumes()
    if kafka_vol != zk_vol:
        print(f"  FAIL Volume mismatch: kafka={kafka_vol}, zookeeper={zk_vol}")
        print(f"  FIX: make test2-kafka-reset   (deletes BOTH volumes and restarts clean)")
        errors += 1
    elif kafka_vol and zk_vol:
        print(f"  WARN Both Kafka volumes exist from previous deploy.")
        print(f"       If Kafka fails with InconsistentClusterIdException: make test2-kafka-reset")
        warnings += 1
    else:
        print(f"  OK   No stale Kafka/Zookeeper volumes — fresh deployment ready")

    # Check 5: medinovai-core grpcio dependency
    print("\n[5/8] Checking medinovai-core dependency...")
    core_ok, core_msg = check_medinovai_core()
    if core_ok is False:
        print(f"  FAIL medinovai-core/pyproject.toml: {core_msg}")
        print(f"  FIX: Change 'grpc>=1.60.0' to 'grpcio>=1.60.0' in {BASE_DIR}/medinovai-core/pyproject.toml")
        errors += 1
    elif core_ok is True:
        print(f"  OK   medinovai-core: {core_msg}")
    else:
        print(f"  WARN {core_msg}")
        warnings += 1

    # Check 6: Dockerfile.TEST2 files exist
    print("\n[6/8] Checking Dockerfile.TEST2 files in service repos...")
    missing_dfs = check_dockerfile_test2()
    if missing_dfs:
        print(f"  WARN {len(missing_dfs)} Dockerfile.TEST2 missing:")
        for svc, path in missing_dfs:
            print(f"       {svc}: {path}")
        warnings += len(missing_dfs)
    else:
        print(f"  OK   All {len(SERVICES_WITH_DOCKERFILE_TEST2)} Dockerfile.TEST2 files found")

    # Check 7: Docker available memory
    print("\n[7/8] Checking Docker available memory...")
    mem_ok, mem_gb = check_docker_memory()
    if not mem_ok:
        print(f"  WARN Docker has {mem_gb:.1f}GB RAM — 53 services need ~12GB+")
        print(f"       Increase Docker Desktop memory in Preferences > Resources > Memory")
        warnings += 1
    elif mem_gb > 0:
        print(f"  OK   Docker has {mem_gb:.1f}GB RAM available")
    else:
        print(f"  WARN Could not determine Docker memory")
        warnings += 1

    # Check 8: Key ports free
    print("\n[8/8] Checking if key ports are available...")
    in_use = check_ports_free()
    running_test2 = any("TEST2" in p for p in run(["docker", "ps", "--format", "{{.Names}}"], capture=True)[0].split("\n"))
    if in_use and not running_test2:
        print(f"  FAIL {len(in_use)} key ports already in use: {in_use}")
        print(f"       Conflicting processes are using TEST2 port range")
        errors += len(in_use)
    elif in_use and running_test2:
        print(f"  OK   Ports in use by existing TEST2 stack (expected): {in_use}")
    else:
        print(f"  OK   All key ports in range 16610-16620 are free")

    # Summary
    print("\n" + "=" * 60)
    if errors == 0 and warnings == 0:
        print("PASS Pre-flight PASSED — safe to deploy")
        print("     Run: make test2-up")
    elif errors == 0:
        print(f"PASS Pre-flight PASSED with {warnings} warning(s)")
        print("     Run: make test2-up")
    else:
        print(f"FAIL Pre-flight FAILED: {errors} error(s), {warnings} warning(s)")
        print("     Fix all errors before deploying.")
        print("     See docs/TEST2-DEPLOYMENT-RUNBOOK.md for fix instructions.")
    print("=" * 60)
    return 0 if errors == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
