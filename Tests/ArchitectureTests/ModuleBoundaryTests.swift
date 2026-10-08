import XCTest
import CDA
import FHIR
import HL7Mapping
import HL7V2

final class ModuleBoundaryTests: XCTestCase {
    func testHL7V2ModuleReexportsExistingAPI() throws {
        let hl7 = try HL7()
        let message = try Message(
            "MSH|^~\\&|||||||ACK|1|P|2.5.1||||||\rMSA|AA|1|",
            hl7: hl7
        )

        XCTAssertEqual(message.type.name, "ACK")
    }

    func testFHIRModuleOwnsStandaloneClient() throws {
        let url = try XCTUnwrap(URL(string: "https://example.invalid/fhir"))
        let client = FHIRClient(url)

        XCTAssertEqual(client.baseURL, url)
    }

    func testCDAParsesDocumentEnvelope() throws {
        let xml = """
        <ClinicalDocument xmlns="urn:hl7-org:v3">
          <templateId root="2.16.840.1.113883.10.20.22.1.1"/>
          <id root="1.2.250.1" extension="document-42"/>
          <code code="34133-9" codeSystem="2.16.840.1.113883.6.1"/>
          <title>Compte rendu clinique</title>
          <effectiveTime value="20261008153000+0200"/>
          <confidentialityCode code="N"/>
          <languageCode code="fr-FR"/>
        </ClinicalDocument>
        """

        let document = try CDAParser().parse(xml)

        XCTAssertEqual(document.identifier?.root, "1.2.250.1")
        XCTAssertEqual(document.identifier?.extensionValue, "document-42")
        XCTAssertEqual(document.templateIdentifiers.count, 1)
        XCTAssertEqual(document.typeCode, "34133-9")
        XCTAssertEqual(document.title, "Compte rendu clinique")
        XCTAssertEqual(document.languageCode, "fr-FR")
    }
}
