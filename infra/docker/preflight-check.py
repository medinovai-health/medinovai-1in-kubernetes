#!/usr/bin/env python3
"""
TEST2 Pre-flight Deployment Check
Validates that all required Docker images exist locally and key config is correct.
Run before: docker compose -p test2 ... up -d
"""

import subprocess
import sys
import yaml
import os

COMPOSE_FILE = os.path.join(os.path.dirname(__file__), "docker-compose.TEST2-full.yml")
BASE_DIR = "/Users/mayanktrivedi/Github/medinovai-health"

KNOWN_PORT_OVERRIDES = {
    "medinovai-registry": ("8000", "http://localhost:8000/health"),
    "medinovai-data-services": ("8300", "http://localhost:8300/api/health"),
    "medinovai-healthllm": ("12304", "http://localhost:12304/health"),
    "medinovai-real-time-stream-bus": ("3000", "http://localhost:3000/health"),
}

SERVICES_NEEDING_DOCKERFILE_TEST2 = [
    "medinovai-registry",
    "medinovai-notification-center",
    "medinovai-hipaa-gdpr-guard",
    "medinovai-api-gateway",
    "medinovai-data-services",
    "medinovai-real-time-stream-bus",
    "medinovai-healthllm",
    "medinovai-aifactory",
    "medinovai-secrets-manager-bridge",
    "medinovai-security-service",
    "medinovai-universal-sign-on",
    "medinovai-role-based-permissions",
    "medinovai-encryption-vault",
    "medinovai-consent-preference-api",
    "medinovai-audit-trail-explorer",
    "MedinovAI-Model-Service-Orchestrator",
]

def get_local_images():
    result = subprocess.run(
        ["docker", "images", "--format", "{{.Repository}}:{{.Tag}}"],
        capture_output=True, text=True
    )
    return set(result.stdout.strip().split("\n"))

def check_images(services, local_images, env_vars):
    missing = []
    for name, config in services.items():
        image_template = config.get("image", "")
        # Resolve basic env vars
        image = image_template
        for k, v in env_vars.items():
            image = image.replace(f"${{{k}}}", v).replace(f"${{{k}:-{v}}}", v)
        # Handle ${VAR:-default} pattern
        import re
        image = re.sub(r'\$\{[^}]+:-([^}]+)\}', r'\1', image)
        image = re.sub(r'\$\{[^}]+\}', 'latest', image)

        if image.startswith("ghcr.io") or image.startswith("confluentinc") or "/" in image:
            found = any(img.startswith(image.split(":")[0]) for img in local_images)
            if not found:
                missing.append((name, image))
    return missing

def check_healthcheck_ports(services):
    issues = []
    for svc_name, override in KNOWN_PORT_OVERRIDES.items():
        if svc_name in services:
            hc = services[svc_name].get("healthcheck", {})
            test = str(hc.get("test", ""))
            expected_url = override[1]
            if expected_url not in test:
                actual_url = [t for t in test.split() if "localhost" in t]
                issues.append({
                    "service": svc_name,
                    "expected": expected_url,
                    "actual": actual_url[0] if actual_url else test
                })
    return issues

def check_kafka_volumes():
    result = subprocess.run(
        ["docker", "volume", "ls", "--format", "{{.Name}}"],
        capture_output=True, text=True
    )
    volumes = result.stdout.strip().split("\n")
    kafka_vol = "test2-kafka-data" in volumes
    zk_vol = "test2-zookeeper-data" in volumes
    return kafka_vol, zk_vol

def main():
    print("=" * 60)
    print("TEST2 Pre-flight Deployment Check")
    print("=" * 60)
    errors = 0
    warnings = 0

    # Load compose
    with open(COMPOSE_FILE) as f:
        data = yaml.safe_load(f)
    services = data.get("services", {})

    env_vars = {
        "REGISTRY": "ghcr.io/myonsite-healthcare",
        "TAG": "latest",
    }

    # 1. Check images
    print("\n[1/4] Checking Docker images...")
    local_images = get_local_images()
    missing_images = check_images(services, local_images, env_vars)
    if missing_images:
        print(f"  ❌ {len(missing_images)} missing images:")
        for name, img in missing_images:
            print(f"     - {name}: {img}")
        errors += len(missing_images)
    else:
        print(f"  ✅ All {len(services)} service images found locally")

    # 2. Check healthcheck ports
    print("\n[2/4] Checking healthcheck port configurations...")
    hc_issues = check_healthcheck_ports(services)
    if hc_issues:
        print(f"  ❌ {len(hc_issues)} healthcheck port mismatches:")
        for issue in hc_issues:
            print(f"     - {issue['service']}: expected {issue['expected']}, got {issue['actual']}")
        errors += len(hc_issues)
    else:
        print(f"  ✅ All critical healthcheck ports are correctly configured")

    # 3. Check Kafka volumes
    print("\n[3/4] Checking Kafka/Zookeeper volume state...")
    kafka_exists, zk_exists = check_kafka_volumes()
    if kafka_exists and zk_exists:
        print("  ⚠️  Both Kafka volumes exist. If Kafka fails with InconsistentClusterIdException:")
        print("     Run: docker volume rm test2-kafka-data test2-zookeeper-data")
        warnings += 1
    elif kafka_exists != zk_exists:
        print(f"  ❌ Volume mismatch: kafka={kafka_exists}, zookeeper={zk_exists}")
        print("     This WILL cause InconsistentClusterIdException. Delete both volumes first.")
        errors += 1
    else:
        print("  ✅ No stale Kafka/Zookeeper volumes detected (fresh deployment)")

    # 4. Check medinovai-core pyproject.toml
    print("\n[4/4] Checking medinovai-core dependency...")
    core_path = os.path.join(BASE_DIR, "medinovai-core", "pyproject.toml")
    if os.path.exists(core_path):
        with open(core_path) as f:
            content = f.read()
        if '"grpc>=' in content and '"grpcio>=' not in content:
            print("  ❌ medinovai-core/pyproject.toml uses 'grpc' instead of 'grpcio'")
            print("     Fix: change 'grpc>=1.60.0' to 'grpcio>=1.60.0'")
            errors += 1
        elif '"grpcio>=' in content:
            print("  ✅ medinovai-core grpcio dependency is correct")
        else:
            print("  ⚠️  Could not verify grpc dependency in medinovai-core/pyproject.toml")
            warnings += 1
    else:
        print(f"  ⚠️  medinovai-core/pyproject.toml not found at {core_path}")
        warnings += 1

    # Summary
    print("\n" + "=" * 60)
    if errors == 0:
        print(f"✅ Pre-flight PASSED ({warnings} warning(s))")
        print("   Safe to run: docker compose -p test2 ... up -d")
        return 0
    else:
        print(f"❌ Pre-flight FAILED: {errors} error(s), {warnings} warning(s)")
        print("   Fix all errors before deploying.")
        print("\nSee docs/TEST2-DEPLOYMENT-RUNBOOK.md for fix instructions.")
        return 1

if __name__ == "__main__":
    sys.exit(main())
