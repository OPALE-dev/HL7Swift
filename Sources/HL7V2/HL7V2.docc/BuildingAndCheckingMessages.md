# Building and Checking Messages

Build patient, order, imaging, and result messages, and check them against an
explicit contract.

## Overview

``V2MessageBuilder`` builds the ADT A01, A02, A03, A04, A05, A08, A28, A31,
and A40 events, ORM O01, OMI O23, ORU R01, and MDM T02. Values are escaped
before they are composed into fields.

```swift
import HL7V2

var builder = try V2MessageBuilder(kind: .imagingOrder,
    sendingApplication: "RIS", sendingFacility: "HOSP",
    receivingApplication: "PACS", receivingFacility: "HOSP", controlID: "order-123")
try builder.addPatient(.init(
    identifiers: [.init(value: "patient-123", namespace: "HOSP", type: "MR")],
    family: "Example", given: ["Alex"], birthTime: "19800501"))
try builder.addOrder(control: "NW", placer: .init(value: "order-123", namespace: "RIS"),
    serviceCode: "CT", serviceText: "Chest", codingSystem: "LOCAL")
try builder.addImagingProcedure(.init(
    accession: .init(value: "acc-123", namespace: "RIS"),
    requestedProcedure: .init(value: "rp-123", namespace: "RIS"),
    scheduledProcedureStep: .init(value: "sps-123", namespace: "RIS"), modality: "CT"))
let message = try builder.build()
let report = V2NativeValidator().validate(message,
    policy: .init(requirePatientAuthority: true))
```

### Content

Patient identifiers (CX) and order identifiers (EI) keep their assigning
authorities.

| Method | Produces |
| --- | --- |
| `addTextObservation` | OBX segments of type TX, with repetitions |
| `addPriorIdentifiers` | An MRG segment that states prior identifiers; it merges nothing |
| `addImagingProcedure` | An IPC segment: accession, requested procedure, scheduled step, optional Study Instance UID, modality, and AE title. No DICOM entry or UID is generated implicitly |
| `addTextDocument` | TXA and OBX TX segments for an MDM T02 report, with explicit document identifier and status |
| `appendRawSegment` | A local segment; header, line, and framing injection is refused |

The builder writes the MSH-9 code and event; `messageStructure` names the
agreed structure explicitly. EVN, TXA, and scheduling details are filled in
according to the partner contract.

### Checks

``V2NativeValidator`` checks an explicit scope: the envelope, the segments
required by the contract, patient and order identifiers, assigning
authorities when the policy requires them, and acknowledgement codes.
`expectedMessageType` compares the whole MSH-9 field. Absent, empty, and
explicitly null values stay distinct. Diagnostics give positions and codes
without revealing patient values.

The `v2.standard-profile` stage stays `notRun` for constraints that are not
implemented, so a clean report is `indeterminate` about full conformance. IHE
profiles, detailed date rules, conditional fields, and terminologies are not
validated implicitly. See `HL7DiagnosticReport` (from `HL7Core`).
