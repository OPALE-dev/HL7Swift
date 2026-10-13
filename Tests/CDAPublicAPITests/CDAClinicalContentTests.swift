import XCTest
import CDA

final class CDAClinicalContentTests: XCTestCase {
    func testPatientAndNestedSectionsRemainScoped() throws {
        let xml = """
        <ClinicalDocument xmlns="urn:hl7-org:v3" xmlns:x="urn:foreign">
          <title>Compte rendu</title>
          <recordTarget><patientRole>
            <id root="1.2.3" extension="patient-123"/>
            <x:id root="forged"/>
            <patient><name><given>Zoé</given><family>Été</family></name>
              <birthTime value="19800501"/><administrativeGenderCode code="F"/>
            </patient>
          </patientRole></recordTarget>
          <component><structuredBody><component><section>
            <code code="18748-4" codeSystem="2.16.840.1.113883.6.1"/>
            <title>Imagerie</title>
            <text><paragraph>Première ligne</paragraph><paragraph>Deuxième <content>ligne</content></paragraph><x:script>forged text</x:script></text>
            <entry><observation/></entry>
            <component><section><title>Conclusion</title><text>Normal</text></section></component>
          </section></component></structuredBody></component>
        </ClinicalDocument>
        """
        let result = CDAParser().parseWithReport(xml)
        let document = try XCTUnwrap(result.document)
        XCTAssertEqual(document.title, "Compte rendu")
        XCTAssertEqual(document.recordTargets.first?.identifiers.count, 1)
        XCTAssertEqual(document.recordTargets.first?.names.first?.given, ["Zoé"])
        XCTAssertEqual(document.recordTargets.first?.birthTime, "19800501")
        XCTAssertEqual(document.sections.count, 2)
        XCTAssertNil(document.sections[0].parentIndex)
        XCTAssertEqual(document.sections[1].parentIndex, 0)
        XCTAssertEqual(document.sections[0].entryCount, 1)
        XCTAssertEqual(document.sections[0].narrativeText, "Première ligne\nDeuxième ligne")
        XCTAssertEqual(document.sections[1].narrativeText, "Normal")
        XCTAssertEqual(result.report.outcome, .indeterminate)
    }

    func testForeignAncestorsCannotForgePatientsOrSections() throws {
        let xml = """
        <ClinicalDocument xmlns="urn:hl7-org:v3" xmlns:x="urn:foreign">
          <x:recordTarget><patientRole><id root="forged"/></patientRole></x:recordTarget>
          <x:component><structuredBody><component><section><text>forged</text></section></component></structuredBody></x:component>
        </ClinicalDocument>
        """
        let document = try CDAParser().parse(xml)
        XCTAssertTrue(document.recordTargets.isEmpty)
        XCTAssertTrue(document.sections.isEmpty)
    }

    func testDepthAndSizeLimitsAndCDATA() throws {
        let xml = "<ClinicalDocument xmlns=\"urn:hl7-org:v3\"><title><![CDATA[Été <literal>]]></title></ClinicalDocument>"
        XCTAssertEqual(try CDAParser().parse(xml).title, "Été <literal>")
        XCTAssertThrowsError(try CDAParser(maximumBytes: 10).parse(xml)) { XCTAssertEqual($0 as? CDAError, .resourceLimit) }
        XCTAssertThrowsError(try CDAParser(maximumDepth: 1).parse(xml)) { XCTAssertEqual($0 as? CDAError, .resourceLimit) }
    }
}
