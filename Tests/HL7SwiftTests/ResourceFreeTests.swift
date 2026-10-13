import XCTest
@testable import HL7Swift

final class ResourceFreeTests: XCTestCase {
    func testUnicodeAndInterleavedRepetitions() throws {
        let text = "MSH|^~\\&|RIS|HOSP|PACS|HOSP|||ORU^R01|abc|P|2.5.1\rPID|||123||Été^Zoé\rOBX|1|TX|||first\rNTE|1||note\rOBX|2|TX|||second"
        let message = try Message(text, hl7: HL7())
        XCTAssertEqual(message.description, text)
        XCTAssertEqual(message["PID"]?[5]?.description, "Été^Zoé")
        XCTAssertEqual(message["OBX", 2]?[5]?.description, "second")
        XCTAssertNil(message["OBX", 3])
        XCTAssertNil(message["OBX", 0])
        XCTAssertNotNil(message.specMessage)
    }

    func testAcknowledgmentUsesNumericFieldsAndOriginalControlID() throws {
        let message = try Message("MSH|^~\\&|RIS|HOSP|PACS|HOSP|||ADT^A08|incoming|P|2.5.1\rPID|||123", hl7: HL7())
        let ack = try message.acknowledgment(status: .AE, application: "PACS", facility: "HOSP", controlID: "reply")
        XCTAssertEqual(ack["MSH"]?[3]?.description, "PACS")
        XCTAssertEqual(ack["MSH"]?[5]?.description, "RIS")
        XCTAssertEqual(ack["MSH"]?[10]?.description, "reply")
        XCTAssertEqual(ack["MSA"]?[1]?.description, "AE")
        XCTAssertEqual(ack["MSA"]?[2]?.description, "incoming")
    }
}
