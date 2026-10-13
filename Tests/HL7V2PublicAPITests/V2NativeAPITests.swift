import XCTest
import HL7V2

final class V2NativeAPITests: XCTestCase {
    func testNativePatientOrderResultRoundTripAndAuthority() throws {
        var builder = try V2MessageBuilder(kind: .result, sendingApplication: "RIS", sendingFacility: "HOSP",
            receivingApplication: "PACS", receivingFacility: "HOSP", controlID: "order-result")
        try builder.addPatient(.init(identifiers: [.init(value: "123", namespace: "HOSP", universalID: "1.2.3", universalIDType: "ISO", type: "MR")], family: "Été|Nom", given: ["Zoé"]))
        try builder.addOrder(control: "NW", placer: .init(value: "order", namespace: "RIS"), serviceCode: "CT", serviceText: "Thorax")
        builder.addTextObservation(code: "report", text: ["Text|with separators", "Second line"], status: "F")
        let message = try builder.build()
        XCTAssertEqual(message.unescape(message.rawValue(segment: "PID", field: 5, component: 1) ?? ""), "Été|Nom")
        let clinical = V2ClinicalProjection(message)
        XCTAssertEqual(clinical.patients.first?.identifiers.first?.universalID, "1.2.3")
        XCTAssertEqual(clinical.orders.first?.placerIdentifier?.value, "order")
        XCTAssertEqual(clinical.observations.first?.rawValues.count, 2)
        let report = V2NativeValidator().validate(message, policy: .init(requirePatientAuthority: true))
        XCTAssertEqual(report.outcome, .indeterminate)
        XCTAssertTrue(report.diagnostics.isEmpty)
    }

    func testNativeRulesRejectMissingIdentityAndAuthorityWithoutLeakingValues() throws {
        let message = try ER7Message("MSH|^~\\&|||||||ORM^O01|id|P|2.5.1\rPID|||private-id\rORC|NW\r")
        let report = V2NativeValidator().validate(message, policy: .init(requirePatientAuthority: true))
        XCTAssertEqual(report.outcome, .invalid)
        XCTAssertTrue(report.diagnostics.contains { $0.code == "V2-NATIVE-PATIENT-AUTHORITY-REQUIRED" })
        XCTAssertTrue(report.diagnostics.contains { $0.code == "V2-NATIVE-ORDER-IDENTIFIER-REQUIRED" })
        XCTAssertFalse(report.renderText().contains("private-id"))
    }

    func testRawAppendCannotInjectHeaderOrSegments() throws {
        var builder = try V2MessageBuilder(kind: .updatePatient, sendingApplication: "RIS", sendingFacility: "HOSP", receivingApplication: "PACS", receivingFacility: "HOSP", controlID: "id")
        XCTAssertThrowsError(try builder.appendRawSegment(code: "MSH", fields: []))
        XCTAssertThrowsError(try builder.appendRawSegment(code: "Z99", fields: ["value\rPID|injected"]))
        try builder.appendRawSegment(code: "Z99", fields: ["local^value"])
        XCTAssertNotNil(try builder.build().segment("Z99"))
    }
}
