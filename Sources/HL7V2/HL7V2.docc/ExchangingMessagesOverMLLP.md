# Exchanging Messages over MLLP

Send a message and receive its correlated acknowledgement, over TCP or TLS.

## Overview

``MLLPConnection`` runs asynchronous, correlated MLLP exchanges:

```swift
import HL7V2
import NIOSSL

let connection = MLLPConnection(responseTimeout: .seconds(15))
try await connection.connect(host: "ris.example", port: 2575,
    tls: TLSConfiguration.makeClientConfiguration())
let reply = try await connection.send(try ER7Message(wire))
// Inspect MSA-1: AA/AE/AR or CA/CE/CR. Receiving an acknowledgement does not
// mean that the partner processed the message successfully.
try await connection.close()
```

The application may pass its own `EventLoopGroup` and TLS configuration
(trust roots, client identity, partner policy). A group passed in stays owned
by the application; the default singleton group is shared. With a standard
client TLS configuration, the connection verifies the certificate chain and
the server name. `tls: nil` means plain TCP.

### Correlation and failures

One exchange runs at a time, and MSA-2 must match MSH-10. An application
error acknowledgement is still a received answer, for the caller's retry
policy to handle. After a timeout, a cancellation, or an invalid
acknowledgement, the socket is closed, so that a late acknowledgement cannot
confirm the next message. There are no automatic retries. The owner closes
the connection explicitly, in particular when its service stops.

### Framing

The public `MLLPFrameDecoder` and `MLLPFrameEncoder` handlers of the `HL7Swift`
product expose raw frames to SwiftNIO listeners. Character set and declared
version are interpreted after framing, by ``ER7Message``. Size limits,
fragmented FS/CR, concatenated frames, and truncated streams are handled by
the same framer.

### Testing

The tests cover framing, two exchanges in a row, an unknown version kept as
is, application errors, timeouts, correlation, and accepted or refused TLS
(trust and host name). The PEM keys under `Tests` are throwaway fixtures
generated for `localhost`, for these tests only.
