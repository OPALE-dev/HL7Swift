# Calling FHIR Services

Read, search, and write FHIR R4 resources with async/await.

## Overview

``FHIRR4RESTClient`` uses async/await and the `ModelsR4` models. Its
transport is injectable, and the application owns the lifecycle of the HTTP
client and its TLS and authentication policies.

```swift
import FHIR
import ModelsR4
import AsyncHTTPClient

let http = HTTPClient(eventLoopGroupProvider: .singleton)
let api = try FHIRR4RESTClient(
    baseURL: URL(string: "https://hospital.example/fhir")!,
    transport: AsyncFHIRHTTPTransport(client: http),
    headers: ["Authorization": "Bearer <application-token>"]
)
let page = try await api.search("ServiceRequest", parameters: [
    URLQueryItem(name: "subject", value: "Patient/example")
])
if let bundle = page.resource?.get(if: ModelsR4.Bundle.self) {
    // All entries, links, and totals are available, including empty search sets.
    let next = try await api.nextPage(bundle)
}
// The owner of `http` shuts it down when its application stops.
```

### Interactions

The client implements the interactions of
[FHIR R4 RESTful API](https://hl7.org/fhir/R4/http.html): read, create (POST),
update (PUT), delete, search, capabilities, history, versioned read, and batch
and transaction Bundles. `If-Match` and `If-None-Exist` are explicit. Minimal
create, update, and delete responses may have an empty body; Location, ETag,
and Last-Modified stay available.

### Errors and safety

A failed HTTP status throws ``FHIRRESTError`` `.http(status:outcome:)`, with
the OperationOutcome when there is one. The client never logs response bodies
or tokens. Pagination refuses links outside the origin and base path, which
protects the authorization headers. ``AsyncFHIRHTTPTransport`` bounds the
received body to 16 MiB, with a 30-second default timeout.

### Resolving references

``FHIRR4ReferenceResolver`` resolves, without network access, contained
references, URN and `fullUrl` references, and relative references already
present in a Bundle. An identifier that is ambiguous between servers is
refused; pass the `fullUrl` of the resource holding the reference to choose
the base. Versioned references are not resolved yet.

### Limits

The tests cover requests, responses, and synthetic errors; they do not prove
an integration with a given server or conformance to a profile. OAuth and
SMART authorization, custom operations, PATCH, and profile validation are not
implemented. The tests that write to a FHIR service run only when
`HL7_TEST_FHIR_BASE_URL` names a disposable server.
