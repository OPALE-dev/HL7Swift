# ``FHIR``

Call FHIR REST services, serve read-only FHIR APIs, and exchange imaging
resources across FHIR R4, R4B, and R5.

## Overview

`FHIR` builds on Apple's [FHIRModels](https://github.com/apple/FHIRModels).
It provides an asynchronous R4 REST client, read-only server primitives that
an application mounts on its own HTTP stack, projections of imaging studies,
a bounded R4, R4B, and R5 exchange layer for imaging resources, and a first
structural validator.

The library owns no HTTP server, storage, account, or credential: the
application keeps the lifecycle of its HTTP client, its TLS and
authentication policies, and its authorization rules.

## Topics

### Calling FHIR services

- <doc:CallingFHIRServices>
- ``FHIRR4RESTClient``
- ``AsyncFHIRHTTPTransport``
- ``FHIRRESTError``
- ``FHIRR4ReferenceResolver``

### Serving FHIR

- <doc:ServingAReadOnlyFHIRAPI>
- ``FHIRR4ReadServer``
- ``FHIRHTTPRequest``
- ``FHIRHTTPResponse``
- ``FHIRR4ServerSearchPage``
- ``FHIRR4ImagingProjection``

### FHIR releases

- <doc:ExchangingImagingResourcesAcrossReleases>
- ``FHIRRelease``
- ``FHIRPACSCodec``
- ``FHIRPACSHTTPTransport``
- ``FHIRPACSConversionError``

### Validation

- ``FHIRR4Validator``
