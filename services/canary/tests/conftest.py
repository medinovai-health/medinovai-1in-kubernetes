# tests/conftest.py

import pytest
import os
from unittest.mock import MagicMock

# Mock FHIR Resources
@pytest.fixture
def fhir_patient():
    """Fixture for a basic FHIR Patient resource."""
    return {
        "resourceType": "Patient",
        "id": "example",
        "name": [
            {
                "use": "official",
                "family": "Chalmers",
                "given": ["Peter", "James"]
            }
        ],
        "gender": "male",
        "birthDate": "1974-12-25"
    }

@pytest.fixture
def fhir_observation():
    """Fixture for a basic FHIR Observation resource."""
    return {
        "resourceType": "Observation",
        "id": "example",
        "status": "final",
        "code": {
            "coding": [
                {
                    "system": "http://loinc.org",
                    "code": "29463-7",
                    "display": "Body Weight"
                }
            ]
        },
        "subject": {
            "reference": "Patient/example"
        },
        "valueQuantity": {
            "value": 185,
            "unit": "lbs",
            "system": "http://unitsofmeasure.org",
            "code": "[lb_av]"
        }
    }

# Mock API Client
@pytest.fixture
def mock_api_client():
    """Fixture for a mock API client."""
    client = MagicMock()
    client.get.return_value.status_code = 200
    client.post.return_value.status_code = 201
    return client

# Mock Database
@pytest.fixture
def mock_db_session():
    """Fixture for a mock database session."""
    session = MagicMock()
    session.query.return_value.all.return_value = []
    return session

# Mock Authentication
@pytest.fixture
def mock_auth_token():
    """Fixture for a mock authentication token."""
    return "mock_token_string"
