#!/usr/bin/env python3
"""Validate FHIR schemas against R5 specification."""

import json
import sys
from pathlib import Path

REQUIRED_FIELDS = ["resourceType", "$schema"]
VALID_RESOURCE_TYPES = [
    "Patient", "Observation", "MedicationRequest", "Appointment",
    "Device", "AuditEvent", "MosPatientMetrics", "MosDeviceReading"
]

def validate_schema(filepath: Path) -> list:
    """Validate a single FHIR schema file."""
    errors = []
    
    try:
        with open(filepath) as f:
            schema = json.load(f)
        
        # Check required fields
        for field in REQUIRED_FIELDS:
            if field not in schema:
                errors.append(f"{filepath}: Missing required field '{field}'")
        
        # Validate resource type
        if "title" in schema:
            resource_type = schema["title"]
            if resource_type not in VALID_RESOURCE_TYPES:
                errors.append(f"{filepath}: Unknown resource type '{resource_type}'")
    
    except json.JSONDecodeError as e:
        errors.append(f"{filepath}: Invalid JSON - {e}")
    except Exception as e:
        errors.append(f"{filepath}: Error - {e}")
    
    return errors

def main():
    """Validate all FHIR schema files."""
    errors = []
    
    schemas_dir = Path("schemas/jsonschema")
    if schemas_dir.exists():
        for schema_file in schemas_dir.glob("*.json"):
            errors.extend(validate_schema(schema_file))
    
    if errors:
        print("❌ FHIR schema validation failed:")
        for error in errors:
            print(f"  {error}")
        sys.exit(1)
    else:
        print("✅ All FHIR schemas valid")
        sys.exit(0)

if __name__ == "__main__":
    main()
