#!/usr/bin/env python3
"""
TEST2 Smoke Test — validates all services respond to health checks via host ports.

Usage:
  python3 infra/docker/test2-smoke-test.py              # Test all services
  python3 infra/docker/test2-smoke-test.py --timeout 5  # Custom per-request timeout
  python3 infra/docker/test2-smoke-test.py --fail-fast  # Stop on first failure
  python3 infra/docker/test2-smoke-test.py --quiet      # Summary only (CI mode)

Exit codes: 0 = all pass, 1 = some failures
"""

import subprocess
import sys
import os
import re
import yaml
import urllib.request
import urllib.error
import argparse
import time

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
COMPOSE_FILE = os.path.join(SCRIPT_DIR, "docker-compose.TEST2-full.yml")

# Services that don't expose /health (intentionally skipped)
SKIP_HEALTH_CHECK = {
    "mailhog",           # Mail catcher, no /health endpoint
    "prometheus",        # Uses /-/healthy (different path)
    "grafana",           # Uses /api/health (different path)
    "loki",              # Uses /ready
    "jaeger",            # Static UI
    "zookeeper",         # TCP only
    "kafka",             # TCP only
    "vault",             # Uses /v1/sys/health
    "keycloak",          # Uses /health/ready
    "rabbitmq",          # Uses /api/health
    "elasticsearch",     # Uses /_cluster/health
}

# Special health check URLs for non-standard services
SPECIAL_HEALTH_URLS = {
    "prometheus":   "/-/healthy",
    "grafana":      "/api/health",
    "loki":         "/ready",
    "vault":        "/v1/sys/health",
    "keycloak":     "/health/ready",
    "rabbitmq":     "/api/health",
    "elasticsearch": "/_cluster/health",
}


def http_get(url, timeout=5):
    try:
        req = urllib.request.urlopen(url, timeout=timeout)
        return req.getcode(), None
    except urllib.error.HTTPError as e:
        return e.code, None
    except Exception as e:
        return None, str(e)[:60]


def main():
    parser = argparse.ArgumentParser(description="TEST2 Smoke Test")
    parser.add_argument("--timeout", type=int, default=5, help="Per-request timeout (default: 5)")
    parser.add_argument("--fail-fast", action="store_true", help="Stop on first failure")
    parser.add_argument("--quiet", action="store_true", help="Summary only")
    args = parser.parse_args()

    with open(COMPOSE_FILE) as f:
        data = yaml.safe_load(f)
    services = data.get("services", {})

    results = {"pass": [], "fail": [], "skip": [], "no_port": []}
    start = time.time()

    if not args.quiet:
        print(f"TEST2 Smoke Test — {len(services)} services")
        print("=" * 60)

    for svc_name, config in sorted(services.items()):
        ports = config.get("ports", [])
        if not ports:
            results["no_port"].append(svc_name)
            continue

        # Get first port mapping
        port_str = str(ports[0])
        host_port = int(port_str.split(":")[0])

        # Determine health URL
        display_name = svc_name.replace("medinovai-", "").replace("-", "_")
        short_name = config.get("container_name", svc_name).replace("TEST2-", "")

        if short_name in SKIP_HEALTH_CHECK:
            # Use special URL or skip
            if short_name in SPECIAL_HEALTH_URLS:
                path = SPECIAL_HEALTH_URLS[short_name]
                url = f"http://localhost:{host_port}{path}"
                status_code, err = http_get(url, args.timeout)
                if status_code and status_code < 500:
                    results["pass"].append((svc_name, host_port, status_code))
                    if not args.quiet:
                        print(f"  PASS {svc_name:<45} port:{host_port} HTTP {status_code}")
                else:
                    results["fail"].append((svc_name, host_port, err or status_code))
                    if not args.quiet:
                        print(f"  FAIL {svc_name:<45} port:{host_port} {err or f'HTTP {status_code}'}")
                    if args.fail_fast:
                        break
            else:
                results["skip"].append(svc_name)
                if not args.quiet:
                    print(f"  SKIP {svc_name:<45} port:{host_port} (no /health endpoint)")
            continue

        url = f"http://localhost:{host_port}/health"
        status_code, err = http_get(url, args.timeout)

        if status_code == 200:
            results["pass"].append((svc_name, host_port, status_code))
            if not args.quiet:
                print(f"  PASS {svc_name:<45} port:{host_port} HTTP 200")
        else:
            results["fail"].append((svc_name, host_port, err or f"HTTP {status_code}"))
            if not args.quiet:
                print(f"  FAIL {svc_name:<45} port:{host_port} {err or f'HTTP {status_code}'}")
            if args.fail_fast:
                break

    elapsed = time.time() - start
    total = len(results["pass"]) + len(results["fail"])

    print("\n" + "=" * 60)
    print(f"SMOKE TEST RESULTS ({elapsed:.1f}s)")
    print(f"  PASS: {len(results['pass'])}")
    print(f"  FAIL: {len(results['fail'])}")
    print(f"  SKIP: {len(results['skip'])} (no /health endpoint)")
    print(f"  NO PORT: {len(results['no_port'])}")

    if results["fail"]:
        print(f"\nFailed services:")
        for svc, port, err in results["fail"]:
            print(f"  {svc} (port {port}): {err}")
        print(f"\nRun: make test2-diagnose   # for detailed logs")
        return 1
    else:
        print(f"\nAll {len(results['pass'])} tested services are responding!")
        return 0


if __name__ == "__main__":
    sys.exit(main())
