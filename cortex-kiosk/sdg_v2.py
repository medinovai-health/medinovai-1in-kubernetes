# SDG v2 — Synthetic Data Generator for medinovai-1in-kubernetes
# Build: 20260413.2200.001 | © 2026 DescartesBio / MedinovAI Health.

E_WORKFLOW_FAMILIES = ["Onboarding", "Maintenance", "Analytics", "Support", "Compliance"]
E_PARTY_TYPES = ["Patient", "Provider", "Admin", "Auditor", "System"]

def generate(family: str = "Onboarding", party: str = "Patient", count: int = 10) -> list:
    """Generate synthetic data for the given workflow family and party type."""
    return [
        {
            "id": i,
            "module": "medinovai-1in-kubernetes",
            "family": family,
            "party": party,
            "data": f"synthetic_record_{i}",
            "hipaa_compliant": True,
        }
        for i in range(count)
    ]
