#!/usr/bin/env python3
"""
Verify the integrity of tamper-proof audit chains.

Checks that each entry in audit.jsonl has a valid hash chain:
  hash = sha256(seq + prev_hash + timestamp + agent + action + target + outcome)

Usage:
  python3 scripts/verify_audit_chain.py [--workspace <agent>] [--all]

Exit codes:
  0 = all chains valid
  1 = chain integrity violation found
  2 = usage error
"""

import hashlib
import json
import os
import sys

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
WORKSPACES_DIR = os.path.join(REPO_ROOT, "workspaces")

AGENTS = ["ops", "sales", "support", "finance", "eng", "supervisor", "guardian"]


def compute_hash(entry):
    """Compute the expected hash for an audit entry."""
    payload = "".join([
        str(entry.get("seq", "")),
        str(entry.get("prev_hash", "")),
        str(entry.get("timestamp", "")),
        str(entry.get("agent", "")),
        str(entry.get("action", "")),
        str(entry.get("target", "")),
        str(entry.get("outcome", "")),
    ])
    return hashlib.sha256(payload.encode("utf-8")).hexdigest()


def verify_chain(audit_path):
    """Verify a single audit.jsonl file. Returns (valid, errors)."""
    errors = []
    if not os.path.exists(audit_path):
        return True, []  # No audit file yet = no violations

    prev_hash = ""
    with open(audit_path, "r") as f:
        for line_num, line in enumerate(f, 1):
            line = line.strip()
            if not line:
                continue
            try:
                entry = json.loads(line)
            except json.JSONDecodeError:
                errors.append(f"  Line {line_num}: Invalid JSON")
                continue

            # Check sequence continuity
            expected_seq = line_num
            actual_seq = entry.get("seq")
            if actual_seq != expected_seq:
                errors.append(
                    f"  Line {line_num}: Sequence mismatch "
                    f"(expected {expected_seq}, got {actual_seq})"
                )

            # Check prev_hash linkage
            if entry.get("prev_hash", "") != prev_hash:
                errors.append(
                    f"  Line {line_num}: prev_hash mismatch "
                    f"(expected {prev_hash[:16]}..., "
                    f"got {str(entry.get('prev_hash', ''))[:16]}...)"
                )

            # Compute and verify hash
            expected_hash = compute_hash(entry)
            actual_hash = entry.get("hash", "")
            if actual_hash != expected_hash:
                errors.append(
                    f"  Line {line_num}: Hash mismatch "
                    f"(expected {expected_hash[:16]}..., "
                    f"got {actual_hash[:16]}...)"
                )

            prev_hash = actual_hash

    return len(errors) == 0, errors


def main():
    agents_to_check = []

    if "--all" in sys.argv or len(sys.argv) == 1:
        agents_to_check = AGENTS
    elif "--workspace" in sys.argv:
        idx = sys.argv.index("--workspace")
        if idx + 1 < len(sys.argv):
            agents_to_check = [sys.argv[idx + 1]]
        else:
            print("Error: --workspace requires an agent name", file=sys.stderr)
            sys.exit(2)
    else:
        agents_to_check = AGENTS

    total_valid = 0
    total_invalid = 0
    total_skipped = 0

    print("Audit Chain Verification")
    print("=" * 50)

    for agent in agents_to_check:
        audit_path = os.path.join(WORKSPACES_DIR, agent, "audit", "audit.jsonl")
        if not os.path.exists(audit_path):
            print(f"  [{agent}] No audit file — skipped")
            total_skipped += 1
            continue

        valid, errors = verify_chain(audit_path)
        if valid:
            line_count = sum(
                1 for line in open(audit_path) if line.strip()
            )
            print(f"  [{agent}] VALID — {line_count} entries")
            total_valid += 1
        else:
            print(f"  [{agent}] INVALID — {len(errors)} error(s):")
            for err in errors:
                print(f"    {err}")
            total_invalid += 1

    print()
    print("=" * 50)
    print(
        f"Results: {total_valid} valid, "
        f"{total_invalid} invalid, "
        f"{total_skipped} skipped"
    )

    if total_invalid > 0:
        print("Status: FAILED — audit chain integrity violation detected.")
        sys.exit(1)
    else:
        print("Status: PASSED — all audit chains are valid.")
        sys.exit(0)


if __name__ == "__main__":
    main()
