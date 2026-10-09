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

    func testReportsKnownUnmappedSegmentsWithoutIncludingTheirValues() throws {
        let hl7 = try HL7()
        let message = try Message(
            "MSH|^~\\&|||||||ORU^R01^ORU_R01|1|P|2.5.1\r" +
            "PID|||123||Doe^Jane\r" +
            "OBR|1||||Sensitive order text\r" +
            "OBX|1|TX|||Sensitive observation text",
            hl7: hl7
        )
        let converter = try HL72FHIRR4Converter()

        let result = converter.mapWithReport(message)

        XCTAssertNotNil(result.output)
        XCTAssertEqual(result.report.outcome, .indeterminate)
        XCTAssertEqual(result.report.stages, [.init(identifier: "v2-to-fhir-r4", status: .incomplete)])
        XCTAssertEqual(result.provenance.sourceVersion, "2.5.1")
        XCTAssertEqual(result.provenance.targetVersion, "R4")
        XCTAssertEqual(result.losses.map(\.sourcePath), ["OBR[1]", "OBX[1]"])
        XCTAssertEqual(result.losses.map(\.reason), [.unmappedSegment, .unmappedSegment])
        XCTAssertEqual(result.report.diagnostics.map(\.code), [
            "HL7MAPPING-UNMAPPED-SEGMENT", "HL7MAPPING-UNMAPPED-SEGMENT",
        ])
        XCTAssertFalse(result.report.renderText().contains("Sensitive"))
    }

    func testUnsupportedMessageReturnsNoOutputAndExplicitLoss() throws {
        let hl7 = try HL7()
        let message = try Message("MSH|^~\\&|||||||ACK|1|P|2.5.1\rMSA|AA|1", hl7: hl7)

        let result = try HL72FHIRR4Converter().mapWithReport(message)

        XCTAssertNil(result.output)
        XCTAssertEqual(result.report.outcome, .indeterminate)
        XCTAssertEqual(result.losses, [.init(sourcePath: "Message", reason: .unsupportedMessage)])
        XCTAssertEqual(result.report.diagnostics.first?.code, "HL7MAPPING-UNSUPPORTED-MESSAGE")
    }

    func testRepeatedMappedSegmentIsRecordedAsSkipped() throws {
        let hl7 = try HL7()
        let message = try Message(
            "MSH|^~\\&|||||||ORU^R01^ORU_R01|1|P|2.5.1\r" +
            "PID|||123||Doe^Jane\r" +
            "PID|||456||Roe^John",
            hl7: hl7
        )

        let result = try HL72FHIRR4Converter().mapWithReport(message)

        XCTAssertEqual(result.losses, [.init(sourcePath: "PID[2]", reason: .skippedSegment)])
    }
}
