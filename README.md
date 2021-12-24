# HL7Swift

HL7Swift is a minimal implementation of the HL7 2.x standard written in Swift. It provides a few tools to parse, send and receive HL7 pipe delimited messages with ease. 

## Disclaimer

HL7Swift is *not* a production ready library and is not intented to be used as such. It focuses on the computing aspects of the HL7 standard, and provides a powerful set of tools to deal with HL7 messages at the atomic level. The authors of this source code cannot be held responsible for its misuses or malfunctions, as it is defined in the license below.

## Dependencies

* **SwiftNIO**: [https://github.com/apple/swift-nio](https://github.com/apple/swift-nio)
* **Swift Argument Parser** : [https://github.com/apple/swift-argument-parser](https://github.com/apple/swift-argument-parser)

## Features

- Parse HL7 message (v2.x)
- Send HL7 messages over TCP/IP (HL7 client)
- Receive HL7 messages over TCP/IP (HL7 server)

## TODO

- Documentation
- Message validation
- Handle exceptions
- Pretty print message with groups
- Convert to XML
- Read message with the correct encoding
- Enum for message type ? (YES!)

## Getting Started

_TBD_

## Contributors

* Rafaël Warnault <rw@opale.pro>
* Paul Repain <pr@opale.pro>

## License

MIT License

Copyright (c) 2021 - OPALE <contact@opale.pro>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
