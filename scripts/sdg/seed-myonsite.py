#!/usr/bin/env python3
"""
myOnsiteHealthcare.com — Synthetic Data Generator (SDG) seed.

Generates deterministic synthetic patients, lab orders, specimens, results,
clinical trials, and audit events for the myonsite-healthcare tenant.
All data is PHI-free (synthetic names/dates/IDs).

Usage:
    python3 deploy/sdg/seed-myonsite.py --tenant-id myonsite-healthcare --patient-count 500
    python3 deploy/sdg/seed-myonsite.py --output-dir /tmp/sdg --seed 42
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import random
import string
import sys
from datetime import datetime, timedelta, timezone
from pathlib import Path
from typing import Any
from uuid import uuid5, NAMESPACE_DNS

E_MODULE_ID = "sdg-seed-myonsite"
E_VERSION = "1.0.0"
E_SEED_DEFAULT = 42

FIRST_NAMES = [
    "James", "Mary", "Robert", "Patricia", "John", "Jennifer", "Michael",
    "Linda", "David", "Elizabeth", "William", "Barbara", "Richard", "Susan",
    "Joseph", "Jessica", "Thomas", "Sarah", "Christopher", "Karen",
    "Charles", "Lisa", "Daniel", "Nancy", "Matthew", "Betty", "Anthony",
    "Margaret", "Mark", "Sandra", "Donald", "Ashley", "Steven", "Dorothy",
    "Paul", "Kimberly", "Andrew", "Emily", "Joshua", "Donna",
]

LAST_NAMES = [
    "Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller",
    "Davis", "Rodriguez", "Martinez", "Hernandez", "Lopez", "Gonzalez",
    "Wilson", "Anderson", "Thomas", "Taylor", "Moore", "Jackson", "Martin",
    "Lee", "Perez", "Thompson", "White", "Harris", "Sanchez", "Clark",
    "Ramirez", "Lewis", "Robinson", "Walker", "Young", "Allen", "King",
    "Wright", "Scott", "Torres", "Nguyen", "Hill", "Flores",
]

LAB_PANELS = [
    {"code": "CBC", "name": "Complete Blood Count", "components": [
        {"code": "WBC", "name": "White Blood Cell Count", "unit": "10^3/uL", "low": 4.5, "high": 11.0},
        {"code": "RBC", "name": "Red Blood Cell Count", "unit": "10^6/uL", "low": 4.0, "high": 5.5},
        {"code": "HGB", "name": "Hemoglobin", "unit": "g/dL", "low": 12.0, "high": 17.5},
        {"code": "PLT", "name": "Platelet Count", "unit": "10^3/uL", "low": 150.0, "high": 400.0},
    ]},
    {"code": "BMP", "name": "Basic Metabolic Panel", "components": [
        {"code": "GLU", "name": "Glucose", "unit": "mg/dL", "low": 70.0, "high": 100.0},
        {"code": "BUN", "name": "Blood Urea Nitrogen", "unit": "mg/dL", "low": 7.0, "high": 20.0},
        {"code": "CRE", "name": "Creatinine", "unit": "mg/dL", "low": 0.6, "high": 1.2},
        {"code": "NA", "name": "Sodium", "unit": "mEq/L", "low": 136.0, "high": 145.0},
        {"code": "K", "name": "Potassium", "unit": "mEq/L", "low": 3.5, "high": 5.0},
    ]},
    {"code": "LFT", "name": "Liver Function Test", "components": [
        {"code": "ALT", "name": "Alanine Aminotransferase", "unit": "U/L", "low": 7.0, "high": 56.0},
        {"code": "AST", "name": "Aspartate Aminotransferase", "unit": "U/L", "low": 10.0, "high": 40.0},
        {"code": "ALP", "name": "Alkaline Phosphatase", "unit": "U/L", "low": 44.0, "high": 147.0},
        {"code": "TBIL", "name": "Total Bilirubin", "unit": "mg/dL", "low": 0.1, "high": 1.2},
    ]},
    {"code": "TSH", "name": "Thyroid Stimulating Hormone", "components": [
        {"code": "TSH", "name": "TSH", "unit": "mIU/L", "low": 0.4, "high": 4.0},
    ]},
    {"code": "HBA1C", "name": "Hemoglobin A1c", "components": [
        {"code": "HBA1C", "name": "HbA1c", "unit": "%", "low": 4.0, "high": 5.6},
    ]},
]

SPECIMEN_TYPES = ["Blood", "Serum", "Plasma", "Urine", "CSF"]
ORDER_STATUSES = ["ordered", "collected", "in_progress", "resulted", "verified"]


def deterministic_id(namespace: str, index: int) -> str:
    return str(uuid5(NAMESPACE_DNS, f"{namespace}.{index}.medinovai.sdg"))


def generate_patients(rng: random.Random, count: int, tenant_id: str) -> list[dict[str, Any]]:
    patients: list[dict[str, Any]] = []
    base_date = datetime(2024, 1, 1, tzinfo=timezone.utc)
    for i in range(count):
        dob = base_date - timedelta(days=rng.randint(365 * 18, 365 * 90))
        patients.append({
            "patient_id": deterministic_id(f"{tenant_id}.patient", i),
            "tenant_id": tenant_id,
            "mrn": f"MRN-{tenant_id[:3].upper()}-{i+1:06d}",
            "first_name": rng.choice(FIRST_NAMES),
            "last_name": rng.choice(LAST_NAMES),
            "date_of_birth": dob.strftime("%Y-%m-%d"),
            "gender": rng.choice(["M", "F"]),
            "email": f"patient{i+1}@synthetic.medinovai.local",
            "phone": f"+1-555-{rng.randint(100,999):03d}-{rng.randint(1000,9999):04d}",
            "address": {
                "line1": f"{rng.randint(100,9999)} {rng.choice(['Main','Oak','Elm','Park','Cedar'])} St",
                "city": rng.choice(["Springfield", "Riverside", "Georgetown", "Fairview", "Madison"]),
                "state": rng.choice(["CA", "TX", "NY", "FL", "IL", "PA", "OH"]),
                "zip": f"{rng.randint(10000,99999)}",
                "country": "US",
            },
            "created_at": (base_date + timedelta(days=rng.randint(0, 365))).isoformat(),
        })
    return patients


def generate_lab_orders(
    rng: random.Random, patients: list[dict], tenant_id: str, orders_per_patient: int = 3,
) -> tuple[list[dict], list[dict]]:
    orders: list[dict] = []
    results: list[dict] = []
    base_date = datetime(2025, 1, 1, tzinfo=timezone.utc)

    for pi, patient in enumerate(patients):
        n_orders = rng.randint(1, orders_per_patient)
        for oi in range(n_orders):
            panel = rng.choice(LAB_PANELS)
            order_date = base_date + timedelta(days=rng.randint(0, 400), hours=rng.randint(6, 18))
            status = rng.choice(ORDER_STATUSES)
            order_id = deterministic_id(f"{tenant_id}.order.{pi}", oi)
            specimen_id = deterministic_id(f"{tenant_id}.specimen.{pi}", oi)

            orders.append({
                "order_id": order_id,
                "tenant_id": tenant_id,
                "patient_id": patient["patient_id"],
                "panel_code": panel["code"],
                "panel_name": panel["name"],
                "specimen_id": specimen_id,
                "specimen_type": rng.choice(SPECIMEN_TYPES),
                "ordering_provider": f"Dr. {rng.choice(LAST_NAMES)}",
                "status": status,
                "ordered_at": order_date.isoformat(),
                "collected_at": (order_date + timedelta(hours=rng.randint(1, 4))).isoformat() if status != "ordered" else None,
                "resulted_at": (order_date + timedelta(hours=rng.randint(4, 48))).isoformat() if status in ("resulted", "verified") else None,
            })

            if status in ("resulted", "verified"):
                for comp in panel["components"]:
                    mean = (comp["low"] + comp["high"]) / 2
                    std = (comp["high"] - comp["low"]) / 4
                    value = round(rng.gauss(mean, std), 1)
                    flag = "N"
                    if value < comp["low"]:
                        flag = "L"
                    elif value > comp["high"]:
                        flag = "H"
                    results.append({
                        "result_id": deterministic_id(f"{tenant_id}.result.{pi}.{oi}", hash(comp["code"]) % 10000),
                        "order_id": order_id,
                        "tenant_id": tenant_id,
                        "patient_id": patient["patient_id"],
                        "component_code": comp["code"],
                        "component_name": comp["name"],
                        "value": value,
                        "unit": comp["unit"],
                        "reference_low": comp["low"],
                        "reference_high": comp["high"],
                        "flag": flag,
                        "status": status,
                    })
    return orders, results


def generate_audit_events(
    rng: random.Random, patients: list[dict], orders: list[dict], tenant_id: str,
) -> list[dict]:
    events: list[dict] = []
    actors = [
        "admin@myonsitehealthcare.com",
        "demo-clinician@myonsitehealthcare.com",
        "demo-labtech@myonsitehealthcare.com",
        "system:medinovai-registry",
        "system:medinovai-lis",
    ]
    event_types = [
        "patient.created", "patient.viewed", "order.created", "order.updated",
        "result.verified", "report.generated", "user.login", "user.logout",
        "consent.granted", "audit.accessed",
    ]
    base_date = datetime(2025, 6, 1, tzinfo=timezone.utc)

    for i in range(min(len(patients) * 2, 1000)):
        ts = base_date + timedelta(seconds=rng.randint(0, 86400 * 180))
        events.append({
            "event_id": deterministic_id(f"{tenant_id}.audit", i),
            "tenant_id": tenant_id,
            "timestamp": ts.isoformat(),
            "event_type": rng.choice(event_types),
            "actor_id": rng.choice(actors),
            "resource_type": rng.choice(["Patient", "LabOrder", "LabResult", "User", "System"]),
            "resource_id": rng.choice(patients)["patient_id"] if patients else "system",
            "action": rng.choice(["create", "read", "update", "verify", "login", "export"]),
            "outcome": "success",
            "phi_safe": True,
            "correlation_id": deterministic_id(f"{tenant_id}.corr", i),
        })
    return events


def generate_clinical_trials(rng: random.Random, tenant_id: str) -> list[dict]:
    protocols = [
        ("MNAI-2025-LIS-001", "LIS Workflow Optimization Trial", "Phase III"),
        ("MNAI-2025-EPG-002", "Edge Privacy Gateway De-ID Accuracy", "Phase II"),
        ("MNAI-2025-AI-003", "AI-Assisted Lab Result Interpretation", "Phase I"),
    ]
    trials: list[dict] = []
    for idx, (proto_id, title, phase) in enumerate(protocols):
        trials.append({
            "trial_id": deterministic_id(f"{tenant_id}.trial", idx),
            "tenant_id": tenant_id,
            "protocol_id": proto_id,
            "title": title,
            "phase": phase,
            "status": rng.choice(["recruiting", "active", "completed"]),
            "sites": [{"site_id": f"SITE-{rng.randint(100,999)}", "name": f"myOnsite Clinic {chr(65+idx)}"}],
            "enrolled": rng.randint(10, 200),
            "target_enrollment": 250,
            "start_date": "2025-03-01",
            "estimated_end_date": "2026-06-30",
        })
    return trials


def write_outputs(output_dir: Path, data: dict[str, Any]) -> None:
    output_dir.mkdir(parents=True, exist_ok=True)
    for key, records in data.items():
        path = output_dir / f"{key}.json"
        path.write_text(json.dumps(records, indent=2, default=str))
        print(f"  {key}: {len(records)} records → {path}")


def main() -> None:
    parser = argparse.ArgumentParser(description="myOnsiteHealthcare SDG Seed")
    parser.add_argument("--tenant-id", default="myonsite-healthcare")
    parser.add_argument("--patient-count", type=int, default=500)
    parser.add_argument("--orders-per-patient", type=int, default=3)
    parser.add_argument("--seed", type=int, default=E_SEED_DEFAULT)
    parser.add_argument("--output-dir", default=None)
    parser.add_argument("--db-url", default=None, help="PostgreSQL URL (if set, inserts directly)")
    args = parser.parse_args()

    rng = random.Random(args.seed)
    tenant_id = args.tenant_id

    print(f"[SDG] Generating synthetic data for tenant '{tenant_id}'")
    print(f"[SDG] Seed={args.seed}, patients={args.patient_count}")

    patients = generate_patients(rng, args.patient_count, tenant_id)
    print(f"  Patients: {len(patients)}")

    orders, results = generate_lab_orders(rng, patients, tenant_id, args.orders_per_patient)
    print(f"  Lab orders: {len(orders)}, results: {len(results)}")

    audit_events = generate_audit_events(rng, patients, orders, tenant_id)
    print(f"  Audit events: {len(audit_events)}")

    trials = generate_clinical_trials(rng, tenant_id)
    print(f"  Clinical trials: {len(trials)}")

    data = {
        "patients": patients,
        "lab_orders": orders,
        "lab_results": results,
        "audit_events": audit_events,
        "clinical_trials": trials,
    }

    output_dir = Path(args.output_dir) if args.output_dir else Path("deploy/sdg/output")
    write_outputs(output_dir, data)

    manifest = {
        "sdg_version": E_VERSION,
        "module_id": E_MODULE_ID,
        "tenant_id": tenant_id,
        "seed": args.seed,
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "counts": {k: len(v) for k, v in data.items()},
        "deterministic": True,
        "phi_free": True,
    }
    manifest_path = output_dir / "manifest.json"
    manifest_path.write_text(json.dumps(manifest, indent=2))
    print(f"\n[SDG] Manifest → {manifest_path}")
    print(f"[SDG] Total records: {sum(len(v) for v in data.values())}")

    if args.db_url:
        print(f"[SDG] Direct DB insert not yet implemented — use JSON files with ETL pipeline")


if __name__ == "__main__":
    main()
