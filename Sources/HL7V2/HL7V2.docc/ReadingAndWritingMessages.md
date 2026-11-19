# Reading and Writing Messages

Read and edit an HL7 v2 message by its positions, and write it back unchanged
where it was not edited.

## Overview

``ER7Message`` is a `Sendable` value type that needs no specification
resource. It keeps the declared version, trailing empty fields, repetitions,
and local segments, and is edited by HL7 positions:

```swift
import HL7V2

let policy = ER7ParsingPolicy(
    acceptedVersions: ["2.3", "2.5.1", "2.9.1"],
    interpretationVersion: "2.5.1"
)
var message = try ER7Message(wire, policy: policy)
let identifier = message.rawValue(segment: "PID", field: 3, component: 1)
let authority = message.rawValue(segment: "PID", field: 3, component: 4)
try message.setRawValue(message.escape("Double|Barrelled"), segment: "PID", field: 5)
let output = message.serialized()
```

### Parsing policy

The default ``ER7ParsingPolicy`` accepts CR, LF, and CRLF segment terminators
and any non-empty version. The `.strict` policy requires CR and a known
version. A forced interpretation version is kept apart from
`declaredVersion` and produces a notice; the parser never falls back to
another message structure on its own.

A forced interpretation does not validate the shape of the message. A
connector must agree on the expected events, fields, assigning authorities,
and rules with its partner. The library never infers a patient identity from
an identifier without an assigning authority.

### Positions and values

Positions and occurrences start at 1. ``ER7Value`` distinguishes `.absent`,
`.empty`, `.null` (`""`), and `.value`. Repetitions, components, and
subcomponents are split with the delimiters of MSH-1 and MSH-2. Unescaping is
explicit, and keeps local or unknown escape sequences.

Decode bytes with the character set agreed with the partner, through
`init(data:encoding:policy:)`. MSH-18 never triggers an implicit transcoding.

### Scope

``ER7Message`` keeps the ER7 text. It is not an engine for segment groups,
batches, data type constraints, or IHE profiles.

## Historical API

The `HL7Swift` product keeps the historical `Message` type, with named access
to segments and fields and a flat `Terser`, for existing integrations:

```swift
import HL7Swift

let hl7 = try HL7()
let message = try Message(wire, hl7: hl7)
let messageType = message[HL7.MSH]?[HL7.Message_Type]
message[HL7.PID]?[HL7.Patient_Name] = "Doe^Jane"
```

New code should use ``ER7Message``.
