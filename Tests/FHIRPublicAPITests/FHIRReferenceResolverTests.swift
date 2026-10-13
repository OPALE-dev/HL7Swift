import XCTest
import FHIR
import ModelsR4

final class FHIRReferenceResolverTests: XCTestCase {
    func testRelativeAndURNReferencesAndContainedScope() throws {
        let json = #"{"resourceType":"Bundle","type":"collection","entry":[{"fullUrl":"urn:uuid:patient","resource":{"resourceType":"Patient","id":"p"}},{"fullUrl":"urn:uuid:report","resource":{"resourceType":"Patient","id":"owner","contained":[{"resourceType":"Patient","id":"child"}]}}]}"#
        let bundle = try JSONDecoder().decode(ModelsR4.Bundle.self, from: Data(json.utf8))
        let resolver = FHIRR4ReferenceResolver(bundle: bundle)
        XCTAssertEqual(try resolver.resolve("Patient/p").get().id?.value?.string, "p")
        XCTAssertEqual(try resolver.resolve("urn:uuid:patient").get().id?.value?.string, "p")
        let owner = try XCTUnwrap(bundle.entry?[1].resource?.get(if: Patient.self))
        XCTAssertEqual(try resolver.resolve("#child", containingResource: owner).get().id?.value?.string, "child")
        XCTAssertEqual(try resolver.resolve("#", containingResource: owner).get().id?.value?.string, "owner")
        XCTAssertThrowsError(try resolver.resolve("#child"))
        XCTAssertThrowsError(try resolver.resolve("https://external.invalid/Patient/p"))
    }

    func testAmbiguousIDsRequireTheContainingServiceBase() throws {
        let json = #"{"resourceType":"Bundle","type":"collection","entry":[{"fullUrl":"https://a.invalid/fhir/Patient/p","resource":{"resourceType":"Patient","id":"p"}},{"fullUrl":"https://b.invalid/fhir/Patient/p","resource":{"resourceType":"Patient","id":"p"}}]}"#
        let resolver = FHIRR4ReferenceResolver(bundle: try JSONDecoder().decode(ModelsR4.Bundle.self, from: Data(json.utf8)))
        XCTAssertThrowsError(try resolver.resolve("Patient/p")) { XCTAssertEqual($0 as? FHIRReferenceResolutionError, .ambiguous) }
        XCTAssertNotNil(try resolver.resolve("Patient/p", containingFullURL: URL(string: "https://a.invalid/fhir/ImagingStudy/study")))
        XCTAssertThrowsError(try resolver.resolve("Patient/p/_history/1")) { XCTAssertEqual($0 as? FHIRReferenceResolutionError, .unsupportedVersionedReference) }
    }
}
