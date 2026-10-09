import XCTest
import CDA

final class CDAPublicAPITests: XCTestCase {
    func testParsesEnvelopeThroughPublicModule() throws {
        let document = try CDAParser().parse("""
        <ClinicalDocument xmlns="urn:hl7-org:v3">
          <id root="1.2.250.1" extension="42"/>
          <title>Compte rendu</title>
        </ClinicalDocument>
        """)

        XCTAssertEqual(document.identifier?.root, "1.2.250.1")
        XCTAssertEqual(document.title, "Compte rendu")
        XCTAssertEqual(HL7DiagnosticReport(stages: [
            .init(identifier: "schema", status: .notRun),
        ]).outcome, .indeterminate)
    }

    func testParsedEnvelopeDoesNotClaimCDAConformance() {
        let result = CDAParser().parseWithReport("""
        <ClinicalDocument xmlns="urn:hl7-org:v3">
          <id root="1.2.250.1"/>
          <title>Compte rendu</title>
        </ClinicalDocument>
        """)

        XCTAssertEqual(result.document?.identifier?.root, "1.2.250.1")
        XCTAssertEqual(result.report.outcome, .indeterminate)
        XCTAssertEqual(result.report.stages.map(\.status), [
            .complete, .complete, .incomplete, .notRun, .notRun, .notRun,
        ])
        XCTAssertTrue(result.report.diagnostics.isEmpty)
    }

    func testMalformedXMLProducesDiagnosticWithoutRawInput() {
        let result = CDAParser().parseWithReport("<ClinicalDocument><title>Secret patient</title>")

        XCTAssertNil(result.document)
        XCTAssertEqual(result.report.outcome, .invalid)
        XCTAssertEqual(result.report.stages.prefix(2).map(\.status), [.incomplete, .notRun])
        XCTAssertEqual(result.report.diagnostics.first?.code, "CDA-XML-PARSE-FAILED")
        XCTAssertFalse(result.report.renderText().contains("Secret patient"))
    }

    func testWrongRootProducesRootNameDiagnostic() {
        let result = CDAParser().parseWithReport("<OtherDocument/>")

        XCTAssertNil(result.document)
        XCTAssertEqual(result.report.outcome, .invalid)
        XCTAssertEqual(result.report.stages.prefix(2).map(\.status), [.complete, .incomplete])
        XCTAssertEqual(result.report.diagnostics.first?.code, "CDA-ROOT-NAME-MISSING")
        XCTAssertEqual(result.report.diagnostics.first?.standard, .cda)
    }
}
