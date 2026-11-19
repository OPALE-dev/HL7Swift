# Exchanging Imaging Resources Across Releases

Convert and transport imaging resources between FHIR R4, R4B, and R5.

## Overview

``FHIRRelease`` (`r4`, `r4b`, `r5`), ``FHIRPACSCodec``, and
``FHIRPACSHTTPTransport`` form a bounded exchange layer for Patient,
ImagingStudy, Endpoint, ServiceRequest, DiagnosticReport, Appointment, Task,
and Procedure, with their Bundle, CapabilityStatement, and OperationOutcome
envelopes. It adds no general FHIR server, storage, clinical workflow, or
arbitrary conversion between releases. The R4 APIs stay available; the layer
uses the ModelsR4, ModelsR4B, and ModelsR5 targets of FHIRModels.

```swift
import Foundation
import FHIR

let r5JSON = try FHIRPACSCodec.convert(r4JSON, from: .r4, to: .r5)
let canonicalJSON = try FHIRPACSCodec.convert(r5JSON, from: .r5, to: .r4)

// A caller-owned transport, and an explicit partner base.
let wire = FHIRPACSHTTPTransport(release: .r5, transport: existingHTTPTransport)
let client = try FHIRR4RESTClient(
    baseURL: URL(string: "https://ris.example/fhir/R5")!, transport: wire)
// The client works with R4 models; resources on the wire are R5.
let response = try await client.read("ImagingStudy", id: studyID)
```

The transport keeps the status, ETag, Location, and other wire metadata,
converts JSON bodies, removes a stale Content-Length, and sends an explicit
`fhirVersion`. Its capabilities call refuses a partner that advertises
another release. A non-FHIR HTTP error is passed to the caller; successful
FHIR responses must decode in the configured release. It runs no OAuth flow
and detects no version automatically.

### Representation and limits

R4 is the interchange representation of these adapters, not a storage
requirement. Applications that must keep the original bytes keep them
separately.

The R5 adaptations cover ServiceRequest.code (inline CodeableReference),
ImagingStudy modalities (CodeableConcept), DiagnosticReport.study, the
Endpoint connection and payload structure, Procedure occurrence fields, and
the supported concept, reference, and Appointment note and cancellation
changes. What R4 cannot represent is refused with
``FHIRPACSConversionError``, with a path and a reason: referenced-only
concepts, ImagingSelection, several Endpoint connection types or payload
groups, and unmapped fields. Unknown keys are checked against a re-encoding of
the model, so that decoding cannot erase them silently, and a field known
only to the source release is refused. Extensions must be representable in
the target model.

This is structural checking, not profile, invariant, cardinality,
terminology, or clinical validation. Decoding a resource does not qualify an
implementation guide or an IHE profile.

### Verification

`FHIRPACSVersionTests` uses synthetic JSON of each release: the eight
resources round-trip through R4, R4B, and R5, and nested search Bundles,
CapabilityStatement versions, refused losses, and HTTP metadata are checked:

```sh
swift test --filter FHIRPACSVersionTests
```

References: [R4B changes](https://hl7.org/fhir/R4B/r4b-explanation.html),
[R5 ImagingStudy](https://hl7.org/fhir/R5/imagingstudy.html),
[R5 ServiceRequest](https://hl7.org/fhir/R5/servicerequest.html), and
[R5 DiagnosticReport](https://hl7.org/fhir/R5/diagnosticreport.html).
