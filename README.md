# Salesforce Health Cloud – HL7 FHIR R4 Integration

A Salesforce DX project showing how to bring **HL7 FHIR R4** clinical data (Epic, Cerner or any FHIR server) into Salesforce for care teams, with a **Lightning Web Component clinical timeline** and a **rule-based care-gap engine**.

> Portfolio / reference project. It deploys to any Developer Edition or scratch org and runs against the public HAPI FHIR test server by default.

## Architecture

```
 ┌───────────────┐   MuleSoft System API   ┌──────────────────────────┐
 │ Epic / Cerner │ ─── (DataWeave 2.0) ──▶ │  Salesforce Health Cloud │
 │  FHIR R4 API  │                         │                          │
 └──────┬────────┘                         │  Named Credential        │
        │  direct REST (OAuth 2.0)         │   └─ FhirClient.cls      │
        └─────────────────────────────────▶│  FhirBundleParser.cls    │
                                           │  CareGapService.cls      │
                                           │  PatientTimelineCtrl.cls │
                                           │   ├─ LWC patientTimeline │
                                           │   └─ LWC careGapPanel    │
                                           └──────────────────────────┘
```

## What's inside

| Path | Purpose |
|---|---|
| `classes/FhirClient.cls` | FHIR REST client. All callouts use the `FHIR_Server` Named Credential, so no endpoints or secrets live in code. |
| `classes/FhirBundleParser.cls` | Helpers for Bundles, CodeableConcepts and FHIR date formats. |
| `classes/CareGapService.cls` | HEDIS-style care-gap rules (HbA1c, BP, LDL, BMI) checked against LOINC-coded Observations. |
| `classes/PatientTimelineController.cls` | `@AuraEnabled(cacheable=true)` API that merges Encounters, Observations and Conditions, newest first. |
| `classes/FhirCalloutMock.cls`, `FhirIntegrationTest.cls` | `HttpCalloutMock` tests covering success, sorting, overdue gaps and HTTP errors. |
| `lwc/patientTimeline` | Filterable clinical timeline for record pages. |
| `lwc/careGapPanel` | Datatable of open and closed care gaps with recommendations. |
| `mulesoft/dataweave` | DataWeave 2.0 mapping from FHIR Patient to a Health Cloud Person Account. |
| `.github/workflows/ci.yml` | Code Analyzer (PMD), then scratch-org deploy and Apex tests. |

## Quick start

```bash
sf org login web --set-default-dev-hub --alias devhub
sf org create scratch -f config/project-scratch-def.json -a fhir -d
sf project deploy start -d force-app
sf apex run test -l RunLocalTests -w 10 -c
sf org open
```

Add **Patient Clinical Timeline (FHIR)** to a Contact page in Lightning App Builder. Set the *FHIR Patient Id* property to any id from `https://hapi.fhir.org/baseR4/Patient`.

## Production notes (HIPAA / PHI)

- Swap the demo Named Credential for one backed by an **External Credential** (OAuth 2.0 client credentials or JWT bearer) pointing to your EHR's FHIR endpoint.
- Protect PHI fields with **Shield Platform Encryption**, field-level security and **Event Monitoring**.
- For high volumes, route through a **MuleSoft System API** (see `mulesoft/`) instead of direct callouts, and cache results in Health Cloud clinical objects.
- Care-gap rules are plain data, so they can be moved to Custom Metadata to let business users maintain them.

## Tech

Apex · LWC · Named Credentials · HL7 FHIR R4 · LOINC · MuleSoft DataWeave 2.0 · SFDX · GitHub Actions
