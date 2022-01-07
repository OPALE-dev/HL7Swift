# HL7Swift

HL7Swift is a minimal implementation of the HL7 2.x standard written in Swift. It provides a few tools to parse, send and receive HL7 pipe delimited messages with ease. It is based the official HL7 implementation guides and resources (XML data that defines the specification) to provide comprehensive tool to address the complexity and vast definitions the specification brought.

## Disclaimer

HL7Swift is *not* a production ready library and is not intented to be used as such. It focuses on the computing aspects of the HL7 standard, and provides a powerful set of tools to deal with HL7 messages at the atomic level. The authors of this source code cannot be held responsible for its misuses or malfunctions, as it is defined in the license below.

_Also, this is a WIP, so it is still subject to many breaking API changes that will make your life very very hard._

## Dependencies

* **SwiftNIO**: [https://github.com/apple/swift-nio](https://github.com/apple/swift-nio)
* **Swift Argument Parser** : [https://github.com/apple/swift-argument-parser](https://github.com/apple/swift-argument-parser)

## Features

- Parse HL7 message (v2.x)
- Build standardized HL7 messages
- Send HL7 messages over TCP/IP (HL7 client)
- Receive HL7 messages over TCP/IP (HL7 server)

## TODO

- Documentation
- Message validation
- Handle exceptions
- Convert to XML
- Read message with the correct encoding
- Terser for groups
- Tests groups generation for all tests messages (get all specs too)
- Implement HL7 v3
- Impelment HL7 FHIR

## Getting Started

### Installation

To use the `HL7Swift` library in a Swift Package Manager project, add it to the dependencies for your package and your command-line executable target:

    let package = Package(
        // name, platforms, products, etc.
        dependencies: [
            .package(url: "https://github.com/opale-paris/hl7swift", branch: "master"),
        ],
        targets: [
            .executableTarget(name: "your-program", dependencies: [
                .product(name: "HL7Swift"),
            ]),
        ]
    )

### Manage HL7 versions

Before everything you have to instanciate the `HL7` specification object as follow:

    let hl7 = HL7()
    
The library manages all the 2.x HL7 versions implementation for you. An (kinda) enum defines the multiple versions, for example:

    let version = Version.v251

Versions are backed by pre-loaded static instances of their respective specific implementation (as `Versionable`). 
You can retreive a version specific implementation as follow:

    let spec251 = hl7.spec(ofVersion: version)
    
A `Versionable` implementation provides in-memory data structures that represents the [HL7 model specifications](https://build.fhir.org/ig/FHIR/fluentpath/v2-class-model.png) for its given verson.

### Parse messages

To parse a message, you don't need to know its specific version as the parser will find it for you.

You can load a HL7 message from a file:

    let message = Message(withFileAt: fileURL)
    
Or directly from string:

    let message = Message(hl7String)
    
When initialized, the `Message` object parses HL7 segments and fields to determine the message version (`MSH-12`) and type (`MSH-9`).
Based in these informations, it provides a related `SpecMessage` instance if available which represent the HL7 message specification.

### Message data

`HL7Swift` provides several ways to get/set message data, using `subscript` notation or using the `Terser` object detailled later in this document. This section is dedicated to the subscript-based method.

#### Static helpers

The library provides sets of static symbols that represent item of the specification like segment, message types and field names. These symbols are made to assist the developer while using the API and enforce the implementation by reducing complexity related to typing errors.

**Segment symbols:**

    print(HL7.MSH)
        -> "MSH"
      
**Message type symbols:**

    print(HL7.V251.ACK())
        -> "HL7Swift.HL7.V251.ACK"
    
**Segment fileds symbols:**

    print(HL7.Message_Type)
        -> "Message Type"

These symbols are very handy when used with `subscript` methods.

#### Get data

Get a segment:

    let segment = message[HL7.MSH]
    
Get a field:

    let field = message[HL7.MSH]?[HL7.Message_Type]

#### Set data

Set a segment:

    message[HL7.MSH] = Segment("MSH|||...")
    
_NB: if existing, a previous segment with the same code will be replaced, otherwise, you are responsible for the segment order when inserting new segments._

Set a field:

    message[HL7.MSH]?[HL7.Message_Type] = Field("ACK")

### Spec Message

The `SpecMessage` class provides a set of tools to help categorize parsed messages regarding to the HL7 specification. It supplies a `Group` instance (`specMessage.rootGroup`) that represents the [HL7 model](https://build.fhir.org/ig/FHIR/fluentpath/v2-class-model.png) as define by the specification.

### Terser

_TBD_

## Code generation

For convenience and because the HL7 specification is a huge collection of both pre-defined types and human readable text-based items, some part of the source code provided by `HL7Swift` are generated by a binary named `HL7CodeGen`.

## Documentation

Documentation can be generated using `jazzy`:

    jazzy \
      --module HL7Swift \
      --swift-build-tool spm \
      --build-tool-arguments -Xswiftc,-swift-version,-Xswiftc,5
      
Or with swift doc:

    swift doc generate \
        --module-name HL7Swift Sources/HL7Swift \
        --minimum-access-level private \
        --output docs --format html

## Binaries

### HL7Client

_TBD_

### HL7Server

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
