# HL7Swift

[![CI](https://github.com/OPALE-dev/HL7Swift/actions/workflows/ci.yml/badge.svg)](https://github.com/OPALE-dev/HL7Swift/actions/workflows/ci.yml)
[![CodeQL](https://github.com/OPALE-dev/HL7Swift/actions/workflows/codeql.yml/badge.svg)](https://github.com/OPALE-dev/HL7Swift/actions/workflows/codeql.yml)
[![Documentation](https://github.com/OPALE-dev/HL7Swift/actions/workflows/documentation.yml/badge.svg)](https://opale-dev.github.io/HL7Swift/documentation/)
[![Release](https://img.shields.io/github/v/release/OPALE-dev/HL7Swift)](https://github.com/OPALE-dev/HL7Swift/releases/latest)
[![Swift 6.2+](https://img.shields.io/badge/Swift-6.2%2B-F05138?logo=swift&logoColor=white)](https://swift.org)
[![Platforms](https://img.shields.io/badge/platforms-macOS%20%7C%20iOS%20%7C%20Linux-lightgrey)](#requirements)
[![License: MIT](https://img.shields.io/badge/license-MIT-green)](LICENSE)

HL7Swift is a Swift package for healthcare interoperability: HL7 v2 messages
and MLLP, FHIR R4 (with R4B and R5 exchanges), CDA R2 documents, and mappings
between them. Its products impose no application architecture: an
application imports only what it uses, and keeps its own storage, identity
rules, authorization, and retry policies.

HL7Swift neither distributes nor loads HL7 specifications or schemas. The
HL7 v2 support is written in Swift: parsing, construction, checks,
serialization, MLLP, and acknowledgements need no specification files.

> **Disclaimer.** HL7Swift is not a medical device and must not be used for
> diagnosis. Its validators and mappings report the checks they ran: a clean
> report is not a proof of conformance to the standard or to a profile. The
> authors cannot be held responsible for its misuse or malfunction, as stated
> in the [license](LICENSE).

## Products

| Product | Purpose | Guide |
| --- | --- | --- |
| `HL7V2` | Parse, build, check, and exchange HL7 v2 messages over MLLP | [HL7V2](https://opale-dev.github.io/HL7Swift/documentation/hl7v2) |
| `FHIR` | FHIR R4 REST client, read-only server primitives, imaging projections, R4B and R5 exchanges | [FHIR](https://opale-dev.github.io/HL7Swift/documentation/fhir) |
| `CDA` | Read the header, patients, and sections of CDA R2 documents, securely | [CDA](https://opale-dev.github.io/HL7Swift/documentation/cda) |
| `HL7Mapping` | Map HL7 v2 messages to FHIR R4, with a report of what was lost | [HL7Mapping](https://opale-dev.github.io/HL7Swift/documentation/hl7mapping) |
| `HL7Core` | Diagnostics and validation outcomes shared by the other products | [HL7Core](https://opale-dev.github.io/HL7Swift/documentation/hl7core) |
| `HL7Swift`, `FHIRSwift` | Historical APIs (`Message`, `Terser`, `FHIRClient`), kept for existing integrations | — |

## Requirements

- Swift 6.2 or later;
- macOS 13, iOS 16, or Linux (tested with the official `swift` images).

## Installation

Add the package to your `Package.swift`, and depend on the products you use:

```swift
dependencies: [
    .package(url: "https://github.com/OPALE-dev/HL7Swift.git", from: "1.1.0"),
],
targets: [
    .target(name: "MyConnector", dependencies: [
        .product(name: "HL7V2", package: "HL7Swift"),
        .product(name: "FHIR", package: "HL7Swift"),
    ]),
]
```

## Getting started

Read and edit a message by its positions, then write it back:

```swift
import HL7V2

var message = try ER7Message(wire)
let patientID = message.rawValue(segment: "PID", field: 3, component: 1)
try message.setRawValue(message.escape("Smith|Jones"), segment: "PID", field: 5)
let output = message.serialized()
```

Send it over MLLP with TLS, and read the acknowledgement:

```swift
let connection = MLLPConnection(responseTimeout: .seconds(15))
try await connection.connect(host: "ris.example", port: 2575,
    tls: TLSConfiguration.makeClientConfiguration())
let reply = try await connection.send(message)
try await connection.close()
```

Search a FHIR server:

```swift
import FHIR
import AsyncHTTPClient

let http = HTTPClient(eventLoopGroupProvider: .singleton)
let api = try FHIRR4RESTClient(
    baseURL: URL(string: "https://hospital.example/fhir")!,
    transport: AsyncFHIRHTTPTransport(client: http))
let page = try await api.search("ImagingStudy", parameters: [
    URLQueryItem(name: "patient", value: "Patient/example")
])
```

The [documentation](https://opale-dev.github.io/HL7Swift/documentation/)
covers construction and checks, inbound processing, clinical projections, the
read-only FHIR server, release conversions, and CDA, with their limits.

## Command-line tools

| Tool | Purpose |
| --- | --- |
| `HL7Client` | Send HL7 v2 files over MLLP, with optional TLS |
| `HL7Server` | Receive HL7 v2 messages over MLLP and write them to a directory |
| `HL7Router` | Route HL7 v2 messages between endpoints from a YAML configuration |
| `HL7CodeGen` | Export the symbols of the native HL7 v2 working models |

```sh
swift run HL7Server --port 2575
swift run HL7Client --hostname 127.0.0.1 --port 2575 message.hl7
```

These tools are demonstrators, not hardened interfaces: run them on trusted
networks only. Use a host name, not an IP address, when TLS is enabled.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). The test suite runs on macOS, iOS, and
Linux, with synthetic or anonymized public fixtures only. Report
vulnerabilities as described in [SECURITY.md](SECURITY.md). Changes are listed
in the [changelog](CHANGELOG.md).

## Dependencies

[SwiftNIO](https://github.com/apple/swift-nio),
[SwiftNIO SSL](https://github.com/apple/swift-nio-ssl),
[AsyncHTTPClient](https://github.com/swift-server/async-http-client),
[FHIRModels](https://github.com/apple/FHIRModels),
[Swift Argument Parser](https://github.com/apple/swift-argument-parser), and
[Yams](https://github.com/jpsim/Yams).

## Authors

* Rafaël Warnault <rw@opale.pro>
* Paul Repain <pr@opale.pro>

## License

HL7Swift is released under the [MIT License](LICENSE). Copyright (c)
2021-2026 OPALE, https://www.opale.fr.
