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
            .complete, .complete, .complete, .complete,
            .incomplete, .notRun, .notRun, .notRun,
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

    func testPrefixedCDANamespaceParses() throws {
        let document = try CDAParser().parse("""
        <cda:ClinicalDocument xmlns:cda="urn:hl7-org:v3">
          <cda:id root="1.2.250.1"/>
          <cda:title>Compte rendu</cda:title>
        </cda:ClinicalDocument>
        """)

        XCTAssertEqual(document.identifier?.root, "1.2.250.1")
        XCTAssertEqual(document.title, "Compte rendu")
    }

    func testWrongNamespaceIsRejected() {
        let parser = CDAParser()
        let xml = "<ClinicalDocument xmlns=\"urn:example:other\"><title>Secret</title></ClinicalDocument>"

        XCTAssertThrowsError(try parser.parse(xml)) { error in
            XCTAssertEqual(error as? CDAError, .invalidNamespace)
        }

        let result = parser.parseWithReport(xml)
        XCTAssertNil(result.document)
        XCTAssertEqual(result.report.outcome, .invalid)
        XCTAssertEqual(result.report.stages.prefix(4).map(\.status), [
            .complete, .complete, .incomplete, .complete,
        ])
        XCTAssertEqual(result.report.diagnostics.first?.code, "CDA-NAMESPACE-MISMATCH")
        XCTAssertFalse(result.report.renderText().contains("Secret"))
    }

    func testForeignNamespaceMetadataIsNotExtracted() throws {
        let document = try CDAParser().parse("""
        <ClinicalDocument xmlns="urn:hl7-org:v3" xmlns:other="urn:example:other">
          <other:id root="forged"/>
          <other:title>Forged title</other:title>
          <id root="1.2.250.1"/>
          <title>Real title</title>
        </ClinicalDocument>
        """)

        XCTAssertEqual(document.identifier?.root, "1.2.250.1")
        XCTAssertEqual(document.title, "Real title")
    }

    func testInternalEntityDeclarationIsRejected() {
        let xml = """
        <!DOCTYPE ClinicalDocument [<!ENTITY name "expanded text">]>
        <ClinicalDocument xmlns="urn:hl7-org:v3"><title>&name;</title></ClinicalDocument>
        """

        let result = CDAParser().parseWithReport(xml)

        XCTAssertNil(result.document)
        XCTAssertEqual(result.report.outcome, .invalid)
        XCTAssertEqual(result.report.diagnostics.first?.code, "CDA-XML-DECLARATION-FORBIDDEN")
        XCTAssertFalse(result.report.renderText().contains("expanded text"))
    }

    func testExternalFileEntityIsRejectedWithoutReadingFile() throws {
        let secretURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("hl7swift-cda-\(UUID().uuidString)")
        try Data("private patient value".utf8).write(to: secretURL)
        defer { try? FileManager.default.removeItem(at: secretURL) }

        let xml = """
        <!DOCTYPE ClinicalDocument [<!ENTITY disclosure SYSTEM "\(secretURL.absoluteString)">]>
        <ClinicalDocument xmlns="urn:hl7-org:v3"><title>&disclosure;</title></ClinicalDocument>
        """
        let result = CDAParser().parseWithReport(xml)

        XCTAssertNil(result.document)
        XCTAssertEqual(result.report.diagnostics.first?.code, "CDA-XML-DECLARATION-FORBIDDEN")
        XCTAssertFalse(result.report.renderText().contains("private patient value"))
        XCTAssertFalse(result.report.renderText().contains(secretURL.path))
    }

    func testDoctypeIsRejectedInUTF16AndUTF32() throws {
        let xml = """
        <!DOCTYPE ClinicalDocument>
        <ClinicalDocument xmlns="urn:hl7-org:v3"/>
        """

        for encoding in [String.Encoding.utf16, .utf32] {
            let data = try XCTUnwrap(xml.data(using: encoding))
            let result = CDAParser().parseWithReport(data)

            XCTAssertNil(result.document)
            XCTAssertEqual(result.report.diagnostics.first?.code, "CDA-XML-DECLARATION-FORBIDDEN")
        }
    }
}
