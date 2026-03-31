#!/usr/bin/env python3
"""
TEST2 Health Wait — polls until all services are healthy or times out.

Usage:
  python3 infra/docker/health-wait.py                          # Wait for all TEST2 services
  python3 infra/docker/health-wait.py --timeout 300            # Custom timeout in seconds
  python3 infra/docker/health-wait.py --filter infra           # Wait only for infra tier
  python3 infra/docker/health-wait.py --quiet                  # Minimal output (CI mode)

Exit codes: 0 = all healthy, 1 = timeout/error
"""

import subprocess
import sys
import time
import argparse

INFRA_CONTAINERS = {
    "TEST2-postgres-primary", "TEST2-postgres-clinical", "TEST2-redis",
    "TEST2-zookeeper", "TEST2-kafka", "TEST2-mongodb", "TEST2-elasticsearch",
    "TEST2-rabbitmq", "TEST2-vault", "TEST2-keycloak", "TEST2-prometheus",
    "TEST2-grafana", "TEST2-loki", "TEST2-jaeger",
}


def get_status():
    result = subprocess.run(
        ["docker", "ps", "--filter", "name=TEST2", "--format", "{{.Names}}\t{{.Status}}"],
        capture_output=True, text=True
    )
    statuses = {}
    for line in result.stdout.strip().split("\n"):
        if "\t" in line:
            name, status = line.split("\t", 1)
            statuses[name.strip()] = status.strip()
    return statuses


def classify(status):
    if "(healthy)" in status:
        return "healthy"
    elif "unhealthy" in status:
        return "unhealthy"
    elif "starting" in status.lower() or "health: starting" in status:
        return "starting"
    elif "Restarting" in status:
        return "crashing"
    elif status.startswith("Up") and "(healthy)" not in status and "health:" not in status:
        return "up_no_hc"  # Running but no healthcheck (e.g. mailhog)
    return "other"


def main():
    parser = argparse.ArgumentParser(description="Wait for TEST2 services to be healthy")
    parser.add_argument("--timeout", type=int, default=600, help="Timeout in seconds (default: 600)")
    parser.add_argument("--filter", choices=["infra", "all"], default="all", help="Filter services to check")
    parser.add_argument("--quiet", action="store_true", help="Minimal output for CI")
    parser.add_argument("--poll-interval", type=int, default=10, help="Poll interval in seconds (default: 10)")
    args = parser.parse_args()

    print(f"Waiting for TEST2 services (timeout: {args.timeout}s, filter: {args.filter})...")
    start = time.time()
    last_print = 0

    while True:
        elapsed = int(time.time() - start)

        if elapsed >= args.timeout:
            statuses = get_status()
            unhealthy = [f"{n}: {s}" for n, s in statuses.items()
                         if classify(s) in ("unhealthy", "crashing")]
            print(f"\nTIMEOUT after {elapsed}s — {len(unhealthy)} services not healthy:")
            for u in unhealthy:
                print(f"  {u}")
            print("Run: make test2-diagnose   # for details")
            return 1

        statuses = get_status()

        if args.filter == "infra":
            relevant = {n: s for n, s in statuses.items() if n in INFRA_CONTAINERS}
        else:
            relevant = statuses

        counts = {"healthy": 0, "unhealthy": 0, "starting": 0, "crashing": 0, "up_no_hc": 0, "other": 0}
        for s in relevant.values():
            counts[classify(s)] += 1

        done = counts["healthy"] + counts["up_no_hc"]  # no-healthcheck services are fine
        total = len(relevant)
        bad = counts["unhealthy"] + counts["crashing"]

        if elapsed - last_print >= args.poll_interval or elapsed == 0:
            if not args.quiet:
                bars = "[" + "=" * (done * 40 // max(total, 1)) + " " * (40 - done * 40 // max(total, 1)) + "]"
                print(f"  [{elapsed:4d}s] {bars} {done}/{total} ready "
                      f"| starting:{counts['starting']} unhealthy:{counts['unhealthy']} crashing:{counts['crashing']}")
                if bad > 0:
                    bad_svcs = [n for n, s in relevant.items() if classify(s) in ("unhealthy", "crashing")]
                    print(f"           Problematic: {', '.join(bad_svcs[:5])}")
            last_print = elapsed

        if counts["starting"] == 0 and bad == 0 and done == total:
            print(f"\nAll {total} services healthy! (took {elapsed}s)")
            return 0

        time.sleep(2)


if __name__ == "__main__":
    sys.exit(main())
