# Versioned PACS exchanges: R4, R4B and R5

The `FHIR` product provides `FHIRRelease` (`r4`, `r4b`, `r5`), `FHIRPACSCodec` and `FHIRPACSHTTPTransport`. Existing R4 APIs remain available. The Apple FHIRModels dependency remains pinned to 0.8.0; the adapter uses its ModelsR4, ModelsR4B and ModelsR5 targets.

This is a bounded PACS exchange layer: Patient, ImagingStudy, Endpoint, ServiceRequest, DiagnosticReport, Appointment, Task and Procedure, with Bundle, CapabilityStatement and OperationOutcome envelopes. It does not add a general FHIR server, storage, clinical workflow or arbitrary cross-version conversion.

```swift
import Foundation
import FHIR

let r5JSON = try FHIRPACSCodec.convert(r4JSON, from: .r4, to: .r5)
let canonicalJSON = try FHIRPACSCodec.convert(r5JSON, from: .r5, to: .r4)

// A caller-owned transport, lifetime and explicit partner base.
let wire = FHIRPACSHTTPTransport(release: .r5, transport: existingHTTPTransport)
let client = try FHIRR4RESTClient(
    baseURL: URL(string: "https://ris.example/fhir/R5")!, transport: wire)
// Client-facing resources are R4 interchange models; wire resources are R5.
let response = try await client.read("ImagingStudy", id: studyID)
```

The transport retains status, ETag, Location and other wire metadata, transforms JSON bodies, removes stale Content-Length after conversion, and sends an explicit `fhirVersion`. Its capabilities call refuses a partner advertising a different release. A non-FHIR HTTP error is retained for the caller; successful FHIR responses must decode in the configured release. It performs no OAuth flow or automatic version detection. Credentials and safe pagination remain the caller/client's responsibilities.

## Representation and explicit limits

R4 is an interchange representation shared by these adapters, not a storage requirement. Applications must retain immutable original wire bytes separately where their audit rules require it.

R5 adaptations include ServiceRequest.code (inline CodeableReference), ImagingStudy modalities (CodeableConcept), DiagnosticReport.study, Endpoint connection/payload structure, Procedure occurrence fields, and the supported concept/reference and Appointment note/cancellation changes. Referenced-only concepts that cannot be represented by the R4 PACS interaction, ImagingSelection, multiple Endpoint connection types/payload groups, or unmapped fields are refused with `FHIRPACSConversionError`, including a path and reason. Unknown keys are checked against model re-encoding so that decoding cannot silently erase them. A field recognized only in the source release but absent from the target is refused. Extensions must also be representable by the target model.

This is structural/model checking, **not** profile, invariant, cardinality-completeness, terminology or clinical conformance validation. Successfully decoding a resource does not qualify an implementation guide or IHE profile. Additional R5 capabilities must be implemented explicitly, with tests, before extending this scope.

## Verification

`FHIRPACSVersionTests` uses versioned synthetic JSON: all eight resources round-trip through R4/R4B/R5; nested search bundles, exact CapabilityStatement versions, loss refusals and HTTP metadata/header handling are checked. Run with `swift test --filter FHIRPACSVersionTests`. Qualification and platform results are recorded separately; the application must test actual clinical effects and its declared CapabilityStatement interactions.

Normative references: [R4B changes](https://hl7.org/fhir/R4B/r4b-explanation.html), [R5 ImagingStudy](https://hl7.org/fhir/R5/imagingstudy.html), [R5 ServiceRequest](https://hl7.org/fhir/R5/servicerequest.html), [R5 DiagnosticReport](https://hl7.org/fhir/R5/diagnosticreport.html).

Local qualification on 2026-10-23: the complete macOS suite passed (103 tests, two skipped); all seven new version tests passed on Linux/aarch64 with Swift 6.2.4 (`swift:6.2-jammy`, parallel XCTest, two workers). The complete Linux suite did not finish: its remaining `FHIRReadServerTests/testUnsupportedSearchIsRejectedBeforeApplication` process was waiting in `XCTestCase.performTearDownSequence` / `awaitUsingExpectation`, confirmed with LLDB. This does not establish a full Linux or CI pass. The qualification container and cache volume were removed. Elena separately exercised all three releases against an isolated synthetic archive, including real report PDF/SR effects, exact wire payloads, headers and connector retries. No external partner or production deployment was qualified.
