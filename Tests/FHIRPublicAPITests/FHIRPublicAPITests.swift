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
}
