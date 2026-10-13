import XCTest
@testable import HL7Swift

/// These tiny, handwritten XML fixtures are implementation tests, not copies
/// of the HL7 specification. Optional loading remains testable in clean CI.
final class ExternalSpecificationTests: XCTestCase {
    private func withDirectory(_ body: (URL) throws -> Void) throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("hl7swift-spec-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        try body(directory)
    }

    func testLoadsExplicitFlatDirectoryAndKeepsOtherVersionsEmpty() throws {
        try withDirectory { directory in
            let files = [
                "messages.xsd": "<xsd:schema xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\"><xsd:element ref=\"ACK\"/></xsd:schema>",
                "ACK.xsd": "<xsd:schema xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\"><xsd:complexType name=\"ACK.CONTENT\"><xsd:sequence><xsd:element ref=\"MSH\" minOccurs=\"1\" maxOccurs=\"1\"/><xsd:element ref=\"MSA\" minOccurs=\"1\" maxOccurs=\"1\"/></xsd:sequence></xsd:complexType></xsd:schema>",
                "fields.xsd": "<xsd:schema xmlns:xsd=\"http://www.w3.org/2001/XMLSchema\"><xsd:attributeGroup name=\"MSH.10.ATTRIBUTES\"><xsd:attribute name=\"LongName\" fixed=\"Message Control ID\"/></xsd:attributeGroup></xsd:schema>"
            ]
            for (name, text) in files { try Data(text.utf8).write(to: directory.appendingPathComponent(name)) }
            let source = HL7V2SpecificationSource(directory: directory, versionDirectories: ["2.5.1": directory])
            let hl7 = try HL7(specificationSource: source)
            XCTAssertEqual(hl7.spec(ofVersion: .v251)?.messages.count, 1)
            XCTAssertTrue(try XCTUnwrap(hl7.spec(ofVersion: .v28)).messages.isEmpty)
            let message = try Message("MSH|^~\\&|||||||ACK|id|P|2.5.1\rMSA|AA|id", hl7: hl7)
            XCTAssertNotNil(message.specMessage)
            XCTAssertEqual(message["MSH"]?["Message Control ID"], "id")
        }
    }

    func testDTDAndMalformedXMLThrowInsteadOfCrashing() throws {
        try withDirectory { directory in
            let source = HL7V2SpecificationSource(directory: directory, versionDirectories: ["2.5.1": directory])
            for xml in ["<!DOCTYPE schema [<!ENTITY x 'value'>]><schema/>", "<schema>"] {
                try Data(xml.utf8).write(to: directory.appendingPathComponent("datatypes.xsd"))
                XCTAssertThrowsError(try HL7(specificationSource: source))
            }
        }
    }
}
