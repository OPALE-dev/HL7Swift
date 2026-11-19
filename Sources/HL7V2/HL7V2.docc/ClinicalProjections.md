# Clinical Projections

Read the patients, orders, and results of a message, with their boundaries.

## Overview

``V2ClinicalProjection`` reads a message by position:

```swift
let message = try ER7Message(wire, policy: connectorPolicy)
let clinical = V2ClinicalProjection(message)
```

It exposes PID, PV1-19, MRG-1, ORC, OBR, and OBX. IPC is exposed separately:
accession, requested procedure, scheduled step, Study Instance UID, modality,
and AE title, with their patient and order indices. CX and EI identifiers keep
their value, namespace, universal identifier and its type, and identifier
type. Names and composite values stay raw; the application keeps the source
message. Segment indices are zero-based in the `segments` array, while ER7
field positions stay one-based.

### Boundaries

Several patients and orders keep their boundaries: `patientIndex` and
`orderIndex` link each result to its context. A new PID resets the order
context; ORC segments without OBR, such as cancellation requests, are kept.
Segments that are not projected (NTE, Z segments, and so on) are listed by
index, so that nothing is lost silently. Notices carry stable codes, never
clinical values.

### What the projection does not decide

MRG gives prior identifiers and a mandatory policy notice; it merges nothing.
OBR-18 stays an opaque placer field: reading it as an accession number belongs
to the partner contract. ORC, OBR, and OBX statuses, dates, codes, and
authorities are not normalized implicitly. This partial model is neither a
worklist or MPPS command nor a complete mapping to FHIR; fields that are not
projected stay in the ER7 message.
