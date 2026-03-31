# AtlasOS Healthcare Connector Deployment Matrix

## Connector Inventory

| # | Connector | Port | Protocol | Data Class | PHI | Consent | Production Ready |
|---|-----------|------|----------|------------|-----|---------|-----------------|
| 1 | fhir-r4 | 8301 | FHIR R4 REST | PHI | Required | Tools implemented |
| 2 | hl7-v2 | 8302 | HL7 v2 / MLLP | PHI | Required | Tools implemented |
| 3 | epic-fhir | 8303 | FHIR R4 + SMART | PHI | Required | Needs Epic sandbox |
| 4 | cerner-fhir | 8304 | FHIR R4 + SMART | PHI | Required | Needs Cerner sandbox |
| 5 | dicom | 8305 | DICOMweb | PHI | Required | Tools implemented |
| 6 | redcap | 8306 | REDCap REST | PHI | Required | Needs REDCap instance |
| 7 | cdisc | 8307 | CDISC Library REST | Internal | No | Tools implemented |
| 8 | terminology | 8308 | FHIR Terminology | Public | No | Tools implemented |
| 9 | openehr | 8309 | OpenEHR REST / AQL | PHI | Required | Needs EHRBase |
| 10 | veeva | 8310 | Veeva Vault REST | Confidential | No | Needs Veeva sandbox |
| 11 | salesforce-health | 8311 | SOQL / Health Cloud | PHI | Required | Needs SF instance |
| 12 | aws-healthlake | 8312 | AWS FHIR R4 | PHI | Required | Needs AWS account |
| 13 | azure-health | 8313 | Azure FHIR R4 | PHI | Required | Needs Azure account |

## Tools per Connector

### fhir-r4 (Port 8301)

| Tool | Method | Description |
|------|--------|-------------|
| `fhir_read` | GET | Read any FHIR resource by type and ID |
| `fhir_search` | GET | Search with FHIR query params |
| `fhir_capability` | GET | Server capability statement |
| `fhir_patient_everything` | GET | $everything operation |
| `fhir_batch` | POST | Batch/transaction bundle |

### hl7-v2 (Port 8302)

| Tool | Method | Description |
|------|--------|-------------|
| `hl7_parse` | POST | Parse raw HL7 v2 message |
| `hl7_adt_query` | GET | ADT patient query |
| `hl7_oru_lookup` | GET | Lab result lookup |
| `hl7_mllp_send` | POST | Send via MLLP |

### epic-fhir (Port 8303)

| Tool | Method | Description |
|------|--------|-------------|
| `epic_patient_search` | GET | Patient search |
| `epic_read_resource` | GET | Read any resource |
| `epic_appointments` | GET | Appointment search |
| `epic_clinical_notes` | GET | DocumentReference |
| `epic_smart_token` | POST | SMART backend auth |

### cerner-fhir (Port 8304)

| Tool | Method | Description |
|------|--------|-------------|
| `cerner_patient_search` | GET | Patient search |
| `cerner_read_resource` | GET | Read any resource |
| `cerner_encounters` | GET | Encounter search |
| `cerner_observations` | GET | Observation search |

### dicom (Port 8305)

| Tool | Method | Description |
|------|--------|-------------|
| `dicom_qido_search` | GET | QIDO-RS study/series search |
| `dicom_wado_retrieve` | GET | WADO-RS instance retrieval |
| `dicom_stow_store` | POST | STOW-RS instance storage |
| `dicom_worklist` | GET | Modality worklist query |

### redcap (Port 8306)

| Tool | Method | Description |
|------|--------|-------------|
| `redcap_export_records` | POST | Export records |
| `redcap_export_metadata` | POST | Export field metadata |
| `redcap_export_reports` | POST | Export report |
| `redcap_project_info` | POST | Project information |

### cdisc (Port 8307)

| Tool | Method | Description |
|------|--------|-------------|
| `cdisc_list_standards` | GET | List CDISC standards |
| `cdisc_get_domains` | GET | SDTM/ADaM domains |
| `cdisc_validate_dataset` | POST | Validate against standard |
| `cdisc_define_xml` | GET | Generate Define-XML |

### terminology (Port 8308)

| Tool | Method | Description |
|------|--------|-------------|
| `term_lookup` | GET | Code system lookup |
| `term_translate` | GET | Concept map translation |
| `term_expand` | GET | Value set expansion |
| `term_validate` | GET | Code validation |
| `term_subsumes` | GET | Subsumption check |

### openehr (Port 8309)

| Tool | Method | Description |
|------|--------|-------------|
| `openehr_get_ehr` | GET | Get EHR by ID or subject |
| `openehr_query_aql` | POST | Execute AQL query |
| `openehr_get_composition` | GET | Get composition |
| `openehr_list_templates` | GET | List templates |

### veeva (Port 8310)

| Tool | Method | Description |
|------|--------|-------------|
| `veeva_get_document` | GET | Get document by ID |
| `veeva_search_documents` | GET | Search documents |
| `veeva_get_trial` | GET | Get clinical trial |
| `veeva_list_study_sites` | GET | List study sites |

### salesforce-health (Port 8311)

| Tool | Method | Description |
|------|--------|-------------|
| `sf_soql_query` | GET | Execute SOQL query |
| `sf_get_account` | GET | Get Health Cloud account |
| `sf_get_care_plan` | GET | Get care plan |
| `sf_health_timeline` | GET | Patient health timeline |

### aws-healthlake (Port 8312)

| Tool | Method | Description |
|------|--------|-------------|
| `healthlake_read` | GET | Read FHIR resource |
| `healthlake_search` | GET | Search FHIR resources |
| `healthlake_list_datastores` | GET | List FHIR datastores |

### azure-health (Port 8313)

| Tool | Method | Description |
|------|--------|-------------|
| `azure_fhir_read` | GET | Read FHIR resource |
| `azure_fhir_search` | GET | Search FHIR resources |
| `azure_patient_everything` | GET | $everything operation |

## Shared Connector Features

All connectors inherit from `BaseConnector` and provide:

| Feature | Description |
|---------|-------------|
| **Vault credentials** | Secrets fetched from Vault at runtime |
| **Circuit breaker** | 3 failures → circuit opens → auto-recovery |
| **Audit trail** | Every read/write audited via audit-chain |
| **Consent check** | PHI access requires consent verification |
| **PHI boundary** | PHI data routed through STOS PHI boundary |
| **Event publishing** | Connector events published to event-bus |
| **Data classification** | Each request tagged: public/internal/confidential/phi |
| **Tenant scoping** | All operations scoped by tenant_id |
| **Locale support** | Default locale configurable per connector |

## Credential Storage (Vault)

Each connector reads credentials from:

```
medinovai-secrets/data/atlasos/connectors/{connector_id}
```

### Required Credentials per Connector

| Connector | Required Vault Fields |
|-----------|---------------------|
| fhir-r4 | `base_url`, `auth_token` (optional) |
| hl7-v2 | `mllp_host`, `mllp_port` |
| epic-fhir | `client_id`, `private_key`, `base_url` |
| cerner-fhir | `client_id`, `client_secret`, `token_url`, `base_url` |
| dicom | `wado_url`, `qido_url`, `stow_url` |
| redcap | `api_url`, `api_token` |
| cdisc | `api_key` (optional — public API available) |
| terminology | `tx_server_url` (defaults to public FHIR TX) |
| openehr | `base_url`, `username`, `password` |
| veeva | `vault_url`, `username`, `password` |
| salesforce-health | `instance_url`, `access_token` |
| aws-healthlake | `aws_access_key`, `aws_secret_key`, `region`, `datastore_id` |
| azure-health | `fhir_url`, `tenant_id`, `client_id`, `client_secret` |
