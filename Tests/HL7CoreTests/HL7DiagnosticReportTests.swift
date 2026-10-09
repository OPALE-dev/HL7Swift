import XCTest
import HL7Core

final class HL7DiagnosticReportTests: XCTestCase {
    func testOutcomeRequiresCompleteStages() {
        XCTAssertEqual(HL7DiagnosticReport(stages: []).outcome, .indeterminate)
        XCTAssertEqual(HL7DiagnosticReport(stages: [
            .init(identifier: "syntax", status: .complete),
            .init(identifier: "profiles", status: .incomplete),
        ]).outcome, .indeterminate)
        XCTAssertEqual(HL7DiagnosticReport(stages: [
            .init(identifier: "syntax", status: .complete),
        ], diagnostics: [finding(severity: .warning)]).outcome, .valid)
    }

    func testErrorMakesPartialReportInvalid() {
        let report = HL7DiagnosticReport(stages: [
            .init(identifier: "syntax", status: .complete),
            .init(identifier: "profiles", status: .notRun),
        ], diagnostics: [finding(severity: .error)])

        XCTAssertEqual(report.outcome, .invalid)
    }

    func testStructuredDiagnosticRoundTripsThroughJSON() throws {
        let report = HL7DiagnosticReport(stages: [
            .init(identifier: "structure", status: .complete),
        ], diagnostics: [HL7Diagnostic(
            code: "HL7V2-FIELD-001",
            severity: .warning,
            message: "Field has too many repetitions",
            standard: .v2,
            stage: "structure",
            version: "2.5.1",
            profile: "example-profile",
            location: .init(path: "PID-3", line: 2, column: 1),
            provenance: .init(rule: "PID-3", artifact: "v2.5.1", artifactVersion: "2.5.1"),
            causeCode: "REPETITION_LIMIT"
        )])

        let decoded = try JSONDecoder().decode(HL7DiagnosticReport.self, from: JSONEncoder().encode(report))
        XCTAssertEqual(decoded, report)
        XCTAssertEqual(decoded.diagnostics.first?.location?.path, "PID-3")
        XCTAssertTrue(decoded.renderText().contains("[warning] HL7V2-FIELD-001 PID-3"))
    }

    private func finding(severity: HL7DiagnosticSeverity) -> HL7Diagnostic {
        HL7Diagnostic(code: "EXAMPLE-001", severity: severity, message: "Example", standard: .fhir, stage: "syntax")
    }
}
