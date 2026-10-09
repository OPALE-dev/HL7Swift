import XCTest
import FHIR

final class FHIRPublicAPITests: XCTestCase {
    func testCreatesStandaloneClientThroughPublicModule() throws {
        let baseURL = try XCTUnwrap(URL(string: "https://example.invalid/fhir"))

        XCTAssertEqual(FHIRClient(baseURL).baseURL, baseURL)
        XCTAssertEqual(HL7DiagnosticReport(stages: [
            .init(identifier: "syntax", status: .incomplete),
        ]).outcome, .indeterminate)
    }

    func testR4ModelDecodeIsNotPresentedAsFullValidation() {
        let report = FHIRR4Validator().validateJSON(Data(#"{"resourceType":"Patient","id":"example"}"#.utf8))

        XCTAssertEqual(report.outcome, .indeterminate)
        XCTAssertEqual(report.stages.map(\.status), [
            .complete, .complete, .notRun, .notRun, .notRun,
        ])
        XCTAssertTrue(report.diagnostics.isEmpty)
    }

    func testMalformedJSONIsInvalidWithoutLeakingInput() {
        let report = FHIRR4Validator().validateJSON(Data(#"{"secret":"patient name""#.utf8))

        XCTAssertEqual(report.outcome, .invalid)
        XCTAssertEqual(report.stages.prefix(2).map(\.status), [.incomplete, .notRun])
        XCTAssertEqual(report.diagnostics.first?.code, "FHIRR4-JSON-MALFORMED")
        XCTAssertFalse(report.renderText().contains("patient name"))
    }

    func testMissingResourceTypeIsInvalid() {
        let report = FHIRR4Validator().validateJSON(Data(#"{"id":"example"}"#.utf8))

        XCTAssertEqual(report.outcome, .invalid)
        XCTAssertEqual(report.diagnostics.first?.code, "FHIRR4-RESOURCE-TYPE-MISSING")
        XCTAssertEqual(report.diagnostics.first?.location?.path, "$.resourceType")
    }

    func testJSONArrayCannotBeAResource() {
        let report = FHIRR4Validator().validateJSON(Data("[]".utf8))

        XCTAssertEqual(report.outcome, .invalid)
        XCTAssertEqual(report.stages.prefix(2).map(\.status), [.complete, .incomplete])
        XCTAssertEqual(report.diagnostics.first?.code, "FHIRR4-RESOURCE-NOT-OBJECT")
    }

    func testUnknownResourceTypeStaysIndeterminate() {
        let report = FHIRR4Validator().validateJSON(Data(#"{"resourceType":"FutureResource"}"#.utf8))

        XCTAssertEqual(report.outcome, .indeterminate)
        XCTAssertEqual(report.stages[1].status, .incomplete)
        XCTAssertEqual(report.diagnostics.first?.code, "FHIRR4-RESOURCE-TYPE-UNSUPPORTED")
    }

    func testKnownResourceWithWrongFieldTypeIsInvalidForModel() {
        let report = FHIRR4Validator().validateJSON(Data(#"{"resourceType":"Patient","name":"secret"}"#.utf8))

        XCTAssertEqual(report.outcome, .invalid)
        XCTAssertEqual(report.diagnostics.first?.code, "FHIRR4-MODEL-DECODE-FAILED")
        XCTAssertFalse(report.renderText().contains("secret"))
    }
}
