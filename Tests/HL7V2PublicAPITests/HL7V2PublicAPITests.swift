import XCTest
import HL7V2

final class HL7V2PublicAPITests: XCTestCase {
    func testParsesAcknowledgmentThroughPublicModule() throws {
        let hl7 = try HL7()
        let message = try Message("MSH|^~\\&|||||||ACK|1|P|2.5.1\rMSA|AA|1", hl7: hl7)

        XCTAssertEqual(message.type.name, "ACK")
        XCTAssertNotNil(message["MSA"])
        XCTAssertEqual(HL7DiagnosticReport(stages: [
            .init(identifier: "syntax", status: .complete),
        ]).outcome, .valid)
    }
}
