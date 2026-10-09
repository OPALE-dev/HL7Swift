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
}
