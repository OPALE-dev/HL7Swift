# ``HL7V2``

Parse, build, check, and exchange HL7 v2 messages, with no specification files.

## Overview

`HL7V2` works on the ER7 encoding of HL7 v2 messages. It keeps each message
as received: the declared version, local segments, repetitions, trailing empty
fields, and the distinction between absent, empty, and null values. On top of
that representation, it builds the common patient, order, imaging, and result
messages, runs explicit contract checks, projects clinical context for
reading, and exchanges messages over MLLP, with or without TLS.

HL7Swift neither distributes nor loads HL7 v2 specifications or schemas.
Parsing, construction, checks, serialization, MLLP, and acknowledgements need
no specification directory or download: the implementation is written in
Swift, not generated from the XSD files of the standard.

```swift
import HL7V2

var message = try ER7Message(wire)
let patientID = message.rawValue(segment: "PID", field: 3, component: 1)
try message.setRawValue(message.escape("Smith|Jones"), segment: "PID", field: 5)
let output = message.serialized()
```

HL7Swift is not a medical device. A message that passes its checks is not
proven conformant to the standard or to a profile: each report states which
checks ran.

## Topics

### Essentials

- <doc:ReadingAndWritingMessages>
- ``ER7Message``
- ``ER7ParsingPolicy``
- ``ER7Value``

### Building and checking messages

- <doc:BuildingAndCheckingMessages>
- ``V2MessageBuilder``
- ``V2NativeValidator``

### Exchanging messages

- <doc:ExchangingMessagesOverMLLP>
- <doc:ReceivingMessages>
- ``MLLPConnection``
- ``V2InboundProcessor``

### Clinical context

- <doc:ClinicalProjections>
- ``V2ClinicalProjection``
