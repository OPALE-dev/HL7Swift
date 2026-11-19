# ``HL7Mapping``

Map HL7 v2 messages to FHIR R4, with a report of what was mapped and lost.

## Overview

`HL72FHIRR4Converter.mapWithReport(_:)` returns an `HL7MappingResult` with the
Bundle, when there is one, an `HL7DiagnosticReport`, the provenance of the
converter, and the known losses:

```swift
import HL7Mapping

let result = try HL72FHIRR4Converter().mapWithReport(message)
print(result.provenance.targetVersion) // R4
print(result.losses.map(\.sourcePath))
```

The mapping accepts `ORU_R01`, and produces only the resources that come from
MSH, PID, and PV1. Other segments, and repetitions that the converter does not
handle, are reported as losses without copying their values into the
diagnostics.

The `v2-to-fhir-r4` stage stays `incomplete` even when no segment is lost:
field coverage and clinical invariants are not qualified yet. An unsupported
message type returns no output, an explicit loss, and an `indeterminate`
outcome. A converter exception produces an error diagnostic that does not copy
the exception. The report describes the transformation, not the validity of
the source message or of the Bundle.
