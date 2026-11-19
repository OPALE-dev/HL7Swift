# Serving a Read-Only FHIR API

Answer FHIR R4 read and search requests from the application's own data and
HTTP stack.

## Overview

``FHIRR4ReadServer`` is a read-only HTTP layer: it starts no server, depends
on no web framework, and keeps no parallel FHIR storage.

```swift
import FHIR
import ModelsR4

let api = try FHIRR4ReadServer(
    baseURL: URL(string: "https://archive.example/fhir/R4")!,
    capabilities: [
        .init(resourceType: "Patient", parameters: [
            .init(name: "identifier", type: .token)
        ]),
        .init(resourceType: "ImagingStudy", parameters: [
            .init(name: "patient", type: .reference),
            .init(name: "started", type: .date)
        ]),
        .init(resourceType: "Endpoint", search: false)
    ],
    publicationDate: deploymentDate
)
```

Declare only the searches the backend implements. `_id` is announced for
every searchable resource, and the backend must match it exactly. An
`identifier` search keeps its system and value; a `patient` reference must be
resolved with the FHIR identities of the domain. The parser keeps the search
expressions; it does not evaluate them.

### Integration contract

After authentication and authorization, call `respond(to:read:search:)` with
a ``FHIRHTTPRequest`` and two callbacks scoped to the current principal:

```swift
let response = await api.respond(to: wireRequest,
    read: { type, id in
        // Read the authorized domain. nil answers 404.
        try await authorizedRepository.readFHIR(type: type, id: id)
    },
    search: { query in
        // Apply the FHIR criteria and the cursor to the authorized query.
        try await authorizedRepository.searchFHIR(query)
    }
)
```

`authorizedRepository` belongs to the application. A read returns a
`ResourceProxy`; a search returns
``FHIRR4ServerSearchPage`` `(resources:total:nextPageToken:)`. ModelsR4 objects
are classes: do not change them while they are serialized.

An adapter for a web framework translates the method, URL, headers, and body
into ``FHIRHTTPRequest``, then the status, headers, and bytes of
``FHIRHTTPResponse`` into its response, with routes under the same base path.
It passes the full path, and does not re-encode the JSON body.
Authentication, OAuth challenges, authorization, TLS, HTTP body limits,
auditing, and the masking of search logs stay in the application.

### Implemented subset

| Request | Behavior |
| --- | --- |
| `GET [base]/metadata` | CapabilityStatement (R4 4.0.1, JSON) with the resources, read and search-type interactions, and configured searches; no write capability |
| `GET [base]/[type]/[id]` | Read, 404, weak ETag from `meta.versionId`, Last-Modified from `meta.lastUpdated`, If-None-Match and If-Modified-Since with 304 |
| `GET [base]/[type]`, `POST [base]/[type]/_search` | Repeated expressions kept, explicit supported parameters, `_count` bounded (20 by default, at most 200), `_count=0`, and an opaque `_pageToken` cursor |

Search set Bundles carry the matches, an optional total, and self and next
links. Outgoing URLs come from the configured canonical base, never from the
received Host header or from the backend. JSON is negotiated through Accept
or `_format`; errors answer 406, 415, or 405 with Allow, and an
OperationOutcome that never echoes patient data or storage errors.

The backend returns resources of the requested type with stable, unique FHIR
ids, honors `_count`, and binds its cursors to the principal, the criteria,
and a stable order. `total` counts the authorized matches, not the resources
of the page.

Unknown searches, undeclared modifiers or chains, and parameters such as
`_include` are refused with 400, even with `Prefer: handling=lenient`. Empty
values of supported parameters are ignored. Declare a modifier or chain that
the backend implements with `acceptedNames`. Expressions are limited to 100
parameters, 16 KiB of query or form, and 4 KiB per value. Responses are
bounded to 16 MiB after encoding (`maximumResponseBytes`).

### Imaging projections

``FHIRR4ImagingProjection`` builds an exchange representation from a snapshot
that the application provides: FHIR id, Study Instance UID, patient FHIR id,
explicit status, Endpoint references, series, and instances.

```swift
let study = try FHIRR4ImagingProjection.imagingStudy(
    id: studyFHIRID, studyUID: studyInstanceUID, patientID: patientFHIRID,
    status: .available, endpointIDs: ["wado"],
    series: [.init(uid: seriesInstanceUID, modality: "CT", instances: [
        .init(uid: sopInstanceUID, sopClassUID: sopClassUID)
    ])]
)
let endpoint = try FHIRR4ImagingProjection.wadoRSEndpoint(
    id: "wado", address: dicomwebBaseURL, status: .active
)
```

The Study Instance UID uses the `urn:dicom:uid` identifier system; series and
instance UIDs stay raw, and the SOP Class uses `urn:ietf:rfc:3986`. The
helper chooses neither the patient, the availability, nor the rights. Counts
describe the subset given; `series: nil` or `instances: nil` means unknown,
not zero. UIDs are checked for form and duplicates, not for registration.

### Limits

There is no write, vread, history, server batch or transaction, XML, system
search, compartments, `_include`, FHIRPath, exhaustive profile validation, or
IHE actor. The CapabilityStatement is not a conformance certificate.

References: [FHIR R4 REST](https://hl7.org/fhir/R4/http.html),
[search](https://hl7.org/fhir/R4/search.html),
[ImagingStudy](https://hl7.org/fhir/R4/imagingstudy.html), and
[a WADO-RS Endpoint](https://hl7.org/fhir/R4/endpoint-example-wadors.json.html).
