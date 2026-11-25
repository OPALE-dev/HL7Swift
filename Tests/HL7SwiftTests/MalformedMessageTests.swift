import XCTest
@testable import HL7Swift

/// Truncated or degenerate messages, and paths to nodes a message does not
/// hold, raise an error or return nil instead of stopping the process.
final class MalformedMessageTests: XCTestCase {
    private let header = "MSH|^~\\&|RIS|HOSP|PACS|HOSP|||"

    func testDegenerateHeadersThrowInsteadOfStopping() throws {
        let hl7 = try HL7()
        // A header without field separator is refused by the pattern check or by
        // the field count, depending on how the platform's regular expressions
        // treat the carriage return: both are refusals of the same kind.
        let refused: [(String, [HL7Error])] = [
            ("PID|1|2", [.unsupportedMessage(message: "MSH segment not found")]),
            ("MSH\rPID|1", [.unsupportedMessage(message: "Not HL7 message"),
                            .unsupportedMessage(message: "Not enought field in segment MSH")]),
            ("MSH|\rPID|1", [.unsupportedMessage(message: "Not enought field in segment MSH")]),
            ("MSH|^~\\&|||||||ADT^A08|id|P|~", [.unsupportedMessage(message: "Version field empty")]),
            ("MSH|^~\\&|||||||ADT^A08|id|P|", [.unsupportedMessage(message: "Version field empty")]),
            ("MSH|^~\\&|||||||ADT^A08|id|P|^2.5.1", [.unsupportedVersion(message: "Unknow/unsupported version")]),
        ]
        for (text, errors) in refused {
            XCTAssertThrowsError(try Message(text, hl7: hl7), text) {
                guard let error = $0 as? HL7Error else { return XCTFail("\(text): \($0)") }
                XCTAssertTrue(errors.contains(error), "\(text): \(error)")
            }
        }
    }

    func testDegenerateMessageTypesAreRead() throws {
        let hl7 = try HL7()
        // A trigger event left empty, subcomponents and empty repetitions in
        // MSH-9 are read as they are.
        let empty = try Message(header + "ADT^|id|P|2.5.1", hl7: hl7)
        XCTAssertEqual(empty.triggerEvent, "")
        let nested = try Message(header + "ADT&X^A08^ADT_A01|id|P|2.5.1", hl7: hl7)
        XCTAssertEqual(nested.triggerEvent, "A08")
        XCTAssertEqual(nested.messageStructure, "ADT_A01")
        let repeated = try Message(header + "~|id|P|2.5.1", hl7: hl7)
        XCTAssertNil(repeated.triggerEvent)
        XCTAssertEqual(try Message(header + "ACK|id|P|2.5.1\rMSA|AA|id", hl7: hl7).type.name, "ACK")
    }

    func testTerserReturnsNilForNodesTheMessageDoesNotHold() throws {
        let message = try Message(
            header + "ADT^A08|id|P|2.5.1\rPID|||123^^^HOSP^MR~456||Été^Zoé", hl7: HL7())
        let terser = Terser(message)
        // Present nodes are unchanged.
        XCTAssertEqual(try terser.get("/PID-3"), "123^^^HOSP^MR~456")
        XCTAssertEqual(try terser.get("/PID-3(2)"), "456")
        XCTAssertEqual(try terser.get("/PID-3-1"), "123")
        XCTAssertEqual(try terser.get("/PID-5-2"), "Zoé")

        for path in [
            "/PID-3(3)", "/PID-3(0)", "/PID-3(2)-1", "/PID-3-9", "/PID-3-1-1", "/PID-3-1-1-1",
            "/PID-99", "/PI", "/PIDX-1", "/PID-5-0",
            "/PATIENT(99999999999999999999999)/PID",
        ] {
            XCTAssertNil(try terser.get(path), path)
        }
        XCTAssertFalse(try terser.val("/PID-3(3)-1", value: "x"))
    }

    func testDetachedNodesHaveNoPosition() throws {
        let message = try Message(header + "ADT^A08|id|P|2.5.1\rPID|||123", hl7: HL7())
        let field = Field("a^b~c")
        XCTAssertNil(message.getPositionInMessage(field.cells[0]))
        XCTAssertNil(message.getPositionInMessage(field.cells[0].components[1]))
        XCTAssertEqual(field.fieldCode, "-0")
        XCTAssertEqual(message.rootGroup?.autocomplete("PID").isEmpty, true)
    }

    func testSegmentsWithoutFieldsAndUnnumberedTypes() {
        XCTAssertEqual(Segment("MSH").description, "MSH")
        XCTAssertEqual(shortname(""), "")
        let unnumbered = ComponentType(name: "CX")
        XCTAssertEqual(unnumbered.name, "CX")
        XCTAssertEqual(unnumbered.index, -1)
        XCTAssertEqual(ComponentType(name: "CX.x").index, -1)
        let numbered = ComponentType(name: "CX.4")
        XCTAssertEqual(numbered.name, "CX.4")
        XCTAssertEqual(numbered.index, 4)
    }
}
