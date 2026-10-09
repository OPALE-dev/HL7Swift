import XCTest
import HL7Mapping

final class HL7MappingPublicAPITests: XCTestCase {
    func testCreatesConverterThroughPublicModule() throws {
        let converter = try HL72FHIRR4Converter()

        XCTAssertEqual(converter.description, "HL7v2.x To FHIR ModelsR4 Converter")
        XCTAssertEqual(HL7DiagnosticReport(stages: [
            .init(identifier: "mapping", status: .complete),
        ]).outcome, .valid)
    }
}
