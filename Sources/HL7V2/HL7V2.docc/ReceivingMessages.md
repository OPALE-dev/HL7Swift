# Receiving Messages

Acknowledge a received message only once the application has handled it.

## Overview

``V2InboundProcessor`` receives the exact bytes of a message, parses it, and
runs the native checks. Its asynchronous `handle` callback is required: the
application stores the message there, then chooses AA, AE, or AR (or CA, CE,
or CR). The acknowledgement is built after the callback returns; a storage
error propagates, and no positive acknowledgement is sent. An invalid
contract produces the configured rejection code without any business effect.
A syntax error or a missing MSH-10 prevents a correlated acknowledgement.

The callback receives `sourceBytes`, `message`, and `report`. The application
remains responsible for idempotency keys, the MSH-15 and MSH-16 policy, and
the acknowledgement phase agreed with its partner. The processor is not a
durable inbox.

### Building acknowledgements

A listener can build an answer with
`message.acknowledgment(code:sendingApplication:sendingFacility:)`. The six
codes AA, AE, AR, CA, CE, and CR are available. The answer keeps the
delimiters, version, and event of the message, and uses its own MSH-10. The
application chooses the phase from its MSH-15 and MSH-16 contract and its
persistence; the library never sends both phases on its own.

### Historical server

The `HL7Server` of the `HL7Swift` product remains available, but its
synchronous delegate is not a durable inbox: a listener must confirm the
persistence it needs before it acknowledges positively.
