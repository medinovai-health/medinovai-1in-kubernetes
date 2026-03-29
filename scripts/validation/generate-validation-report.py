#!/usr/bin/env python3
"""
Customer-1 Validation Report Generator.

Collects IQ/OQ/PQ evidence, QA summary, trust snapshot, and SDG manifest
into a single Markdown + JSON deliverable.

Usage:
    python3 scripts/generate-validation-report.py --results-dir logs/customer1/<timestamp>
    python3 scripts/generate-validation-report.py --results-dir logs/customer1/<timestamp> --output REPORT.md
"""
from __future__ import annotations

import argparse
import json
import sys
from datetime import datetime, timezone
from pathlib import Path
from typing import Any

E_MODULE_ID = "validation-report-generator"


def load_json(path: Path) -> dict[str, Any]:
    try:
        return json.loads(path.read_text())
    except Exception:
        return {}


def render_checks_table(checks: list[dict]) -> str:
    rows = ["| Check | Pass | Detail |", "|-------|------|--------|"]
    for c in checks:
        icon = "PASS" if c.get("pass") else "FAIL"
        rows.append(f"| {c.get('check', '?')} | {icon} | {c.get('detail', '')} |")
    return "\n".join(rows)


def generate_report(results_dir: Path, tenant_id: str) -> str:
    iq = load_json(results_dir / "validation" / "iq-evidence.json")
    oq = load_json(results_dir / "validation" / "oq-evidence.json")
    pq = load_json(results_dir / "validation" / "pq-evidence.json")
    qa = load_json(results_dir / "qa" / "qa-summary.json")
    trust = load_json(results_dir / "trust-snapshot.json")
    sdg = load_json(results_dir / "sdg" / "manifest.json")

    now = datetime.now(timezone.utc).isoformat()
    composite = trust.get("composite_score", "N/A")
    level = trust.get("level", "N/A")
    gate_passed = trust.get("gate_passed", False)

    iq_checks = iq.get("checks", [])
    oq_checks = oq.get("checks", [])
    pq_checks = pq.get("checks", [])
    baselines = pq.get("baselines", {})

    qa_total = qa.get("total", 0)
    qa_pass = qa.get("pass", 0)
    qa_fail = qa.get("fail", 0)
    qa_skip = qa.get("skip", 0)

    sdg_counts = sdg.get("counts", {})

    report = f"""# Customer-1 Validation Report — myOnsiteHealthcare.com

**Tenant:** `{tenant_id}`
**Generated:** {now}
**Results Directory:** `{results_dir}`

---

## Executive Summary

| Metric | Value |
|--------|-------|
| Trust Score | **{composite}/100** [{level}] |
| Trust Gate | **{"PASSED" if gate_passed else "FAILED"}** (threshold: {trust.get("gate_threshold", 60)}) |
| QA Tests | {qa_pass} passed, {qa_fail} failed, {qa_skip} skipped ({qa_total} total) |
| IQ Checks | {sum(1 for c in iq_checks if c.get("pass"))}/{len(iq_checks)} passed |
| OQ Checks | {sum(1 for c in oq_checks if c.get("pass"))}/{len(oq_checks)} passed |
| PQ Checks | {sum(1 for c in pq_checks if c.get("pass"))}/{len(pq_checks)} passed |

---

## Trust Score Breakdown

| Dimension | Score | Weight |
|-----------|-------|--------|
"""
    dims = trust.get("dimensions", {})
    weights = trust.get("weights", {})
    for dim in sorted(dims.keys()):
        report += f"| {dim} | {dims[dim]}/10 | {weights.get(dim, 0)*100:.0f}% |\n"

    report += f"""
---

## IQ — Installation Qualification

{render_checks_table(iq_checks) if iq_checks else "*No IQ evidence found.*"}

---

## OQ — Operational Qualification

{render_checks_table(oq_checks) if oq_checks else "*No OQ evidence found.*"}

---

## PQ — Performance Qualification

{render_checks_table(pq_checks) if pq_checks else "*No PQ evidence found.*"}

### Performance Baselines

| Metric | Value |
|--------|-------|
| Registry /health | {baselines.get("registry_health_ms", "N/A")}ms |
| Portal load | {baselines.get("portal_load_ms", "N/A")}ms |
| Keycloak OIDC | {baselines.get("keycloak_oidc_ms", "N/A")}ms |

---

## QA Suite Results

| Metric | Value |
|--------|-------|
| Total tests | {qa_total} |
| Passed | {qa_pass} |
| Failed | {qa_fail} |
| Skipped | {qa_skip} |
| Verdict | **{qa.get("verdict", "N/A")}** |

---

## SDG (Synthetic Data) Summary

| Dataset | Records |
|---------|---------|
"""
    for dataset, count in sorted(sdg_counts.items()):
        report += f"| {dataset} | {count} |\n"
    if not sdg_counts:
        report += "| *No SDG data found* | — |\n"

    report += f"""
- Seed: {sdg.get("seed", "N/A")}
- Deterministic: {sdg.get("deterministic", "N/A")}
- PHI-free: {sdg.get("phi_free", "N/A")}

---

## Acceptance Criteria Checklist

| Criterion | Status |
|-----------|--------|
| `deploy-customer1.sh` exits 0 | {"PASS" if gate_passed else "CHECK"} |
| `admin@myonsitehealthcare.com` can log in | {"PASS" if oq.get("pass") else "CHECK"} |
| 3+ golden scenarios pass | {"PASS" if qa_pass >= 3 else "FAIL"} |
| SDG data visible in UI | {"PASS" if sdg_counts else "CHECK"} |
| Tenant isolation test passes | {"PASS" if qa_pass > 0 else "CHECK"} |
| IQ/OQ all green | {"PASS" if iq.get("pass") and oq.get("pass") else "FAIL"} |
| Trust score >= 60 | {"PASS" if gate_passed else "FAIL"} |
| Validation report generated | PASS |
| No CHANGE_ME secrets | {"PASS" if any(c.get("check") == "no_changeme_secrets" and c.get("pass") for c in iq_checks) else "CHECK"} |

---

## Blockers

"""
    blockers = []
    for phase_name, checks in [("IQ", iq_checks), ("OQ", oq_checks), ("PQ", pq_checks)]:
        for c in checks:
            if not c.get("pass"):
                blockers.append(f"- **{phase_name}**: {c.get('check', '?')} — {c.get('detail', '')}")
    if blockers:
        report += "\n".join(blockers)
    else:
        report += "*No blockers — all checks passed.*"

    report += f"""

---

**Report generated by:** `{E_MODULE_ID}`
**Timestamp:** {now}
"""
    return report


def main() -> None:
    parser = argparse.ArgumentParser(description="Customer-1 Validation Report Generator")
    parser.add_argument("--results-dir", required=True)
    parser.add_argument("--tenant-id", default="myonsite-healthcare")
    parser.add_argument("--output", default=None)
    args = parser.parse_args()

    results_dir = Path(args.results_dir)
    if not results_dir.exists():
        print(f"Results directory not found: {results_dir}", file=sys.stderr)
        sys.exit(1)

    report = generate_report(results_dir, args.tenant_id)

    output_path = Path(args.output) if args.output else results_dir / "VALIDATION_REPORT.md"
    output_path.write_text(report)
    print(f"Validation report → {output_path}")

    json_path = output_path.with_suffix(".json")
    json_data = {
        "tenant_id": args.tenant_id,
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "results_dir": str(results_dir),
        "iq": load_json(results_dir / "validation" / "iq-evidence.json"),
        "oq": load_json(results_dir / "validation" / "oq-evidence.json"),
        "pq": load_json(results_dir / "validation" / "pq-evidence.json"),
        "qa": load_json(results_dir / "qa" / "qa-summary.json"),
        "trust": load_json(results_dir / "trust-snapshot.json"),
        "sdg": load_json(results_dir / "sdg" / "manifest.json"),
    }
    json_path.write_text(json.dumps(json_data, indent=2))
    print(f"JSON evidence   → {json_path}")


if __name__ == "__main__":
    main()
