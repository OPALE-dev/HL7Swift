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

    func testLegacyValidatorProducesScopedVersionReport() throws {
        let hl7 = try HL7()
        let message = try Message("MSH|^~\\&|||||||ACK|1|P|2.5.1\rMSA|AA|1", hl7: hl7)
        let validator = DefaultValidator()

        let legacyResults = validator.validate(message, level: .version)
        let report = validator.validateReport(message, level: .version)

        XCTAssertEqual(legacyResults.count, 0)
        XCTAssertEqual(report.outcome, .indeterminate)
        XCTAssertEqual(report.stages, [.init(identifier: "v2.version", status: .incomplete)])
        XCTAssertTrue(report.diagnostics.isEmpty)
    }

    func testDeeperLegacyChecksStayIncomplete() throws {
        let hl7 = try HL7()
        let message = try Message("MSH|^~\\&|||||||ACK|1|P|2.5.1\rMSA|AA|1", hl7: hl7)
        let validator = DefaultValidator()

        let legacyResults = validator.validate(message, level: .datatypes)
        let report = validator.validateReport(message, level: .datatypes)

        XCTAssertEqual(report.outcome, .indeterminate)
        XCTAssertEqual(report.stages.map(\.identifier), ["v2.version", "v2.segments", "v2.fields", "v2.datatypes"])
        XCTAssertEqual(report.stages.map(\.status), [.incomplete, .incomplete, .incomplete, .incomplete])
        XCTAssertEqual(report.diagnostics.count, legacyResults.count)
        for (finding, legacy) in zip(report.diagnostics, legacyResults) {
            XCTAssertEqual(finding.message, legacy.text)
            XCTAssertEqual(finding.standard, .v2)
            XCTAssertEqual(finding.version, "2.5.1")
        }
    }

    func testUnknownMessageTypeIsInvalidWithoutPretendingStructureWasChecked() throws {
        let hl7 = try HL7()
        let message = try Message("MSH|^~\\&|||||||ZZZ|1|P|2.5.1", hl7: hl7)

        let report = DefaultValidator().validateReport(message, level: .segments)

        XCTAssertEqual(report.outcome, .invalid)
        XCTAssertEqual(report.stages.map(\.status), [.incomplete, .incomplete])
        XCTAssertEqual(report.diagnostics.first?.code, "HL7V2-LEGACY-VERSION-ERROR")
        XCTAssertEqual(report.diagnostics.first?.severity, .error)
        XCTAssertEqual(report.diagnostics.first?.stage, "v2.version")
    }
}
