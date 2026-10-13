import XCTest
import HL7V2

final class ER7MessageTests: XCTestCase {
    func testCustomDelimitersAndLosslessEdits() throws {
        var message = try ER7Message("MSH*$%!?*RIS*HOSP*PACS*HOSP***ORM$O01*id*P*2.9.1\rPID***123$$$AUTH%456$$$OTHER**Été$Zoé\rZ99*\"\"**tail*\r")
        XCTAssertEqual(message.declaredVersion, "2.9.1")
        XCTAssertEqual(message.rawValue(segment: "PID", field: 3, repetition: 2, component: 4), "OTHER")
        XCTAssertEqual(ER7Value(raw: message.segment("Z99")?[1]), .null)
        XCTAssertEqual(ER7Value(raw: message.segment("Z99")?[2]), .empty)
        XCTAssertEqual(ER7Value(raw: message.segment("Z99")?[6]), .absent)
        let original = message.serialized()
        XCTAssertTrue(original.hasSuffix("Z99*\"\"**tail*\r"))
        try message.setRawValue(message.escape("A*B"), segment: "Z99", field: 2)
        XCTAssertEqual(message.rawValue(segment: "Z99", field: 2), "A!F!B")
        XCTAssertEqual(message.unescape("A!F!B"), "A*B")
    }

    func testVersionTolerancePreservesDeclaration() throws {
        let wire = "MSH|^~\\&|||||||ORM^O01|id|P|99.vendor\nPID|||123\n"
        let message = try ER7Message(wire, policy: .init(interpretationVersion: "2.5.1"))
        XCTAssertEqual(message.declaredVersion, "99.vendor")
        XCTAssertEqual(message.interpretationVersion, "2.5.1")
        XCTAssertEqual(message.serialized(), wire)
        XCTAssertEqual(message.notices, ["ER7-NONSTANDARD-LINE-ENDINGS", "ER7-VERSION-INTERPRETATION-OVERRIDE"])
        XCTAssertThrowsError(try ER7Message(wire, policy: .strict))
        XCTAssertThrowsError(try ER7Message(wire.replacingOccurrences(of: "\n", with: "\r"), policy: .strict))
    }

    func testEscapesAndRepeatedComponentsBeyondLegacyLimits() throws {
        let values = Array(repeating: "a^b", count: 80).joined(separator: "~")
        let wire = "MSH|^~\\&|||||||ORU^R01|id|P|2.5.1\rOBX|1|TX|||\(values)\r"
        let message = try ER7Message(wire)
        XCTAssertEqual(message.rawValue(segment: "OBX", field: 5, repetition: 80, component: 2), "b")
        XCTAssertEqual(message.serialized(), wire)
        XCTAssertEqual(message.unescape("a\\F\\b\\Xc3a9\\\\Zlocal\\"), "a|bé\\Zlocal\\")
        XCTAssertEqual(message.unescape("bad\\Xzz\\"), "bad\\Xzz\\")
        XCTAssertEqual(message.unescape("truncated\\F"), "truncated\\F")
        XCTAssertEqual(message.unescape(message.escape("a|^~\\&\n")), "a|^~\\&\n")
    }

    func testMalformedInputsAndLimits() throws {
        for wire in ["", "PID|1", "MSH|^^^^|||||||ACK|id|P|2.5.1", "MSH|^~\\&|||||||ACK|id|P|2.5.1\r\rPID|1"] {
            XCTAssertThrowsError(try ER7Message(wire))
        }
        XCTAssertThrowsError(try ER7Message("MSH|^~\\&|||||||ACK|id|P|2.5.1", policy: .init(maximumBytes: 4)))
    }

    func testAcknowledgmentPreservesCustomDelimitersAndUnknownVersion() throws {
        let message = try ER7Message("MSH*$%!?*RIS*HOSP*PACS*HOSP***ADT$A08*incoming*P*99.vendor\rPID***123\r")
        for code in ER7AcknowledgmentCode.allCases {
            let ack = try message.acknowledgment(code: code, sendingApplication: "PACS", sendingFacility: "HOSP", controlID: "reply")
            XCTAssertEqual(ack.delimiters, message.delimiters)
            XCTAssertEqual(ack.segment("MSA")?[1], code.rawValue)
            XCTAssertEqual(ack.segment("MSA")?[2], "incoming")
            XCTAssertEqual(ack.segment("MSH")?[5], "RIS")
            XCTAssertEqual(ack.segment("MSH")?[10], "reply")
            XCTAssertEqual(ack.rawValue(segment: "MSH", field: 9, component: 2), "A08")
            XCTAssertEqual(ack.declaredVersion, "99.vendor")
        }
    }
}
