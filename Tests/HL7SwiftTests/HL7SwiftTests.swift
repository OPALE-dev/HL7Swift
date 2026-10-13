import XCTest
@testable import HL7Swift

/// Compatibility behavior is tested without external schemas. Older exploratory
/// assertions against imported XSD groups have been replaced by native contracts.
final class HL7SwiftTests: XCTestCase {
    func testCorpusRoundTripsWithoutArtefacts() throws {
        let hl7 = try HL7()
        let paths = Bundle.module.paths(forResourcesOfType: "txt", inDirectory: nil)
        XCTAssertFalse(paths.isEmpty)
        for path in paths {
            let content = try String(contentsOfFile: path, encoding: .utf8)
            let message = try Message(content, hl7: hl7)
            // Historical malformed fixture contains a literal newline inside PID.
            if URL(fileURLWithPath: path).lastPathComponent != "ADT-A01 Admit Patient (example from V2.8.2 base standard).txt" {
                XCTAssertEqual(message.description.trimmingCharacters(in: .newlines), content.trimmingCharacters(in: .newlines), URL(fileURLWithPath: path).lastPathComponent)
            }
        }
    }

    func testNativeNamedAccessAndTerser() throws {
        let message = try Message("MSH|^~\\&|RIS|HOSP|PACS|HOSP|||ADT^A08|id|P|2.5.1\rPID|||123^^^HOSP^MR||Été^Zoé", hl7: HL7())
        XCTAssertEqual(message["PID"]?[HL7.Patient_Name], "Été^Zoé")
        XCTAssertEqual(message["MSH"]?[HL7.Message_Control_ID], "id")
        XCTAssertEqual(try Terser(message).get("/PID-3-1"), "123")
        message["PID"]?[HL7.Patient_Name] = "Doe^Jane"
        XCTAssertEqual(message["PID"]?[5]?.description, "Doe^Jane")
    }

    func testNativeConstructionDoesNotMutateWorkingModels() throws {
        let hl7 = try HL7()
        let first = try XCTUnwrap(hl7.build(HL7.V251.ACK(), version: .v251, preloadSegments: ["MSH", "MSA"]))
        first["MSA"]?[HL7.Acknowledgment_Code] = "AA"
        let second = try XCTUnwrap(hl7.build(HL7.V251.ACK(), version: .v251, preloadSegments: ["MSH", "MSA"]))
        XCTAssertEqual(first["MSA"]?[1]?.description, "AA")
        XCTAssertEqual(second["MSA"]?[1]?.description, "")
        XCTAssertEqual(second["MSH"]?[12]?.description, "2.5.1")
    }

    func testInvalidInputAndIncompleteHeadersThrow() throws {
        let hl7 = try HL7()
        for input in ["", "not HL7", "<html/>", "MSH|^~\\&||||"] {
            XCTAssertThrowsError(try Message(input, hl7: hl7))
        }
    }

    func testParentsDoNotRetainParsedTrees() throws {
        weak var segment: Segment?
        weak var field: Field?
        do {
            let message = try Message("MSH|^~\\&|||||||ACK|id|P|2.5.1\rMSA|AA|id", hl7: HL7())
            segment = message["MSA"]
            field = message["MSA"]?[1]
        }
        XCTAssertNil(segment)
        XCTAssertNil(field)
    }

    func testForcedInterpretationPreservesDeclaredVersion() throws {
        let message = try Message("MSH|^~\\&|||||||ADT^A08|id|P|2.5.1\rPID|||123", hl7: HL7(), force: .v24)
        XCTAssertEqual(message.version, .v24)
        XCTAssertEqual(message.messageVersion, .v251)
        XCTAssertEqual(message["MSH"]?[12]?.description, "2.5.1")
        XCTAssertNotNil(message.specMessage)
    }
}
