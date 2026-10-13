import XCTest
import FHIR
import ModelsR4

final class FHIRImagingProjectionTests: XCTestCase {
    func testExplicitStudySeriesInstancesAndDICOMwebEndpoint() throws {
        let study = try FHIRR4ImagingProjection.imagingStudy(id: "study-1", studyUID: "1.2.3", patientID: "patient-1",
            status: .available, endpointIDs: ["wado"], series: [
                .init(uid: "1.2.3.1", modality: "CT", instances: [.init(uid: "1.2.3.1.1", sopClassUID: "1.2.840.10008.5.1.4.1.1.2")]),
                .init(uid: "1.2.3.2", modality: "CT", instances: [])
            ])
        XCTAssertEqual(study.identifier?.first?.system?.value?.url.absoluteString, "urn:dicom:uid")
        XCTAssertEqual(study.identifier?.first?.value?.value?.string, "urn:oid:1.2.3")
        XCTAssertEqual(study.subject.reference?.value?.string, "Patient/patient-1")
        XCTAssertEqual(study.endpoint?.first?.reference?.value?.string, "Endpoint/wado")
        XCTAssertEqual(study.numberOfSeries?.value?.integer, 2)
        XCTAssertEqual(study.numberOfInstances?.value?.integer, 1)
        XCTAssertEqual(study.modality?.count, 1)
        XCTAssertEqual(study.series?.first?.instance?.first?.sopClass.code?.value?.string, "urn:oid:1.2.840.10008.5.1.4.1.1.2")
        let encoded = try JSONEncoder().encode(study)
        XCTAssertNotNil(try JSONDecoder().decode(ResourceProxy.self, from: encoded).get(if: ImagingStudy.self))
        let endpoint = try FHIRR4ImagingProjection.wadoRSEndpoint(id: "wado", address: URL(string: "https://pacs.example/dicomweb")!, status: .active)
        XCTAssertEqual(endpoint.connectionType.code?.value?.string, "dicom-wado-rs")
        XCTAssertNil(endpoint.header)
        XCTAssertEqual(endpoint.payloadMimeType?.first?.value?.string, "application/dicom")
    }

    func testUnknownCollectionsDoNotBecomeZeroCounts() throws {
        let summary = try FHIRR4ImagingProjection.imagingStudy(id: "study", studyUID: "1.2.3", patientID: "p", status: .unknown)
        XCTAssertNil(summary.series); XCTAssertNil(summary.numberOfSeries); XCTAssertNil(summary.numberOfInstances)
        let study = try FHIRR4ImagingProjection.imagingStudy(id: "study", studyUID: "1.2.3", patientID: "p", status: .registered,
            series: [.init(uid: "1.2.3.1", modality: "MR")])
        XCTAssertEqual(study.numberOfSeries?.value?.integer, 1)
        XCTAssertNil(study.numberOfInstances); XCTAssertNil(study.series?.first?.numberOfInstances)
        let empty = try FHIRR4ImagingProjection.imagingStudy(id: "study", studyUID: "1.2.3", patientID: "p", status: .registered, series: [])
        XCTAssertNil(empty.series)
        XCTAssertEqual(empty.numberOfSeries?.value?.integer, 0)
        XCTAssertEqual(empty.numberOfInstances?.value?.integer, 0)
    }

    func testInvalidUIDsDuplicatesIdentityAndCredentialsAreRejected() throws {
        for uid in ["", "1..2", "1.02.3", "urn:oid:1.2.3", "1.2.a", String(repeating: "1", count: 65)] {
            XCTAssertThrowsError(try FHIRR4ImagingProjection.imagingStudy(id: "study", studyUID: uid, patientID: "p", status: .available))
        }
        XCTAssertThrowsError(try FHIRR4ImagingProjection.imagingStudy(id: "study", studyUID: "1.2.3", patientID: "Patient/p", status: .available))
        XCTAssertThrowsError(try FHIRR4ImagingProjection.imagingStudy(id: "study", studyUID: "1.2.3", patientID: "p", status: .available,
            series: [.init(uid: "1.2.3.1", modality: "CT"), .init(uid: "1.2.3.1", modality: "CT")]))
        for url in ["http://pacs.example/dicomweb", "https://user:password@pacs.example/dicomweb", "https://pacs.example/dicomweb?token=secret"] {
            XCTAssertThrowsError(try FHIRR4ImagingProjection.wadoRSEndpoint(id: "wado", address: URL(string: url)!, status: .active))
        }
    }
}
