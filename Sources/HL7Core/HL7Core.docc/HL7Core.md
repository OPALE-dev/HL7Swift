# ``HL7Core``

Report what a validator or a mapping checked, and what it found.

## Overview

`HL7Core` defines the diagnostics shared by the HL7 v2, FHIR, CDA, and
mapping products, without depending on any of them. These products re-export
its types.

Each ``HL7Diagnostic`` has a stable code, a severity, and a readable message.
It may name the standard, its version, a profile, a location in the input,
and the rule or artefact behind the finding. `causeCode` identifies a
technical cause without embedding the raw content of a document or an error
that could hold sensitive data.

### Outcomes

A ``HL7DiagnosticReport`` declares the stages its producer meant to run. Each
``HL7ValidationStage`` is `complete`, `incomplete`, or `notRun`, and the
outcome follows these rules:

| Outcome | When |
| --- | --- |
| `invalid` | At least one diagnostic has the `error` severity |
| `indeterminate` | No error, but a stage is missing or none was declared |
| `valid` | Every declared stage is complete, and no error was found |

A `valid` report covers only the stages it declares: know the scope of a
validator before reading its report as evidence of conformance to a profile.

```swift
import HL7Core

let report = HL7DiagnosticReport(
    stages: [HL7ValidationStage(identifier: "syntax", status: .complete)],
    diagnostics: []
)
print(report.outcome)     // valid
print(report.renderText())
```

Reports and their elements are `Codable`, `Equatable`, and `Sendable`.

The historical HL7 v2 validator, `DefaultValidator.validateReport(_:level:)`,
turns its findings into `HL7V2-LEGACY-*` diagnostics. Its messages may hold a
value of the original message: treat its reports as potentially sensitive
before you log or export them.

## Topics

### Diagnostics

- ``HL7Diagnostic``
- ``HL7DiagnosticReport``
- ``HL7ValidationStage``
