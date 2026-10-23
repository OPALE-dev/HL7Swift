import XCTest
import Foundation
import FHIR

final class FHIRPACSVersionTests: XCTestCase {
    private let fixtures = [
        #"{"resourceType":"Patient","id":"p","name":[{"family":"TEST","given":["Éloïse"]}]}"#,
        #"{"resourceType":"ImagingStudy","id":"s","status":"available","subject":{"reference":"Patient/p"},"modality":[{"system":"urn:dicom","code":"US"}],"series":[{"uid":"1.2.3","modality":{"code":"US"},"bodySite":{"code":"T"},"laterality":{"code":"L"}}],"procedureReference":{"reference":"Procedure/x"}}"#,
        #"{"resourceType":"Endpoint","id":"e","status":"active","connectionType":{"system":"http://terminology.hl7.org/CodeSystem/endpoint-connection-type","code":"dicom-wado-rs"},"payloadType":[{"text":"DICOM"}],"payloadMimeType":["application/dicom"],"address":"https://example.test/dicomweb"}"#,
        #"{"resourceType":"ServiceRequest","id":"o","status":"active","intent":"order","subject":{"reference":"Patient/p"},"code":{"text":"Ultrasound"},"reasonCode":[{"text":"Clinical reason"}],"supportingInfo":[{"reference":"Appointment/a"}]}"#,
        #"{"resourceType":"DiagnosticReport","id":"r","status":"final","code":{"text":"Ultrasound report"},"subject":{"reference":"Patient/p"},"imagingStudy":[{"reference":"ImagingStudy/s"}],"conclusion":"Normal"}"#,
        #"{"resourceType":"Appointment","id":"a","status":"booked","participant":[{"actor":{"reference":"Patient/p"},"status":"accepted"}],"serviceType":[{"text":"Ultrasound"}],"comment":"Synthetic note"}"#,
        #"{"resourceType":"Task","id":"t","status":"in-progress","intent":"order","focus":{"reference":"ServiceRequest/o"},"performerType":[{"text":"Radiographer"}],"reasonCode":{"text":"Exam"}}"#,
        #"{"resourceType":"Procedure","id":"x","status":"completed","subject":{"reference":"Patient/p"},"performedDateTime":"2026-10-23T10:00:00Z","reasonReference":[{"reference":"Condition/c"}]}"#
    ]
    private func data(_ json: String) -> Data { Data(json.utf8) }
    private func sorted(_ value: Data) throws -> Data { try JSONSerialization.data(withJSONObject: JSONSerialization.jsonObject(with: value), options: [.sortedKeys]) }
    func testPACSResourcesRoundTripAcrossAllReleases() throws {
        for fixture in fixtures {
            for release in FHIRRelease.allCases {
                let wire = try FHIRPACSCodec.convert(data(fixture), from: .r4, to: release)
                let back = try FHIRPACSCodec.convert(wire, from: release, to: .r4)
                XCTAssertEqual(try sorted(back), try sorted(data(fixture)), release.rawValue + " " + fixture)
            }
        }
    }
    func testR5ChangesAreStructuralAndBundlesConvertTheirEntries() throws {
        let bundle = data(#"{"resourceType":"Bundle","type":"searchset","entry":[{"resource":\#(fixtures[3])}]}"#)
        let wire = try FHIRPACSCodec.convert(bundle, from: .r4, to: .r5)
        let object = try JSONSerialization.jsonObject(with: wire) as! [String: Any]
        let resource = (object["entry"] as! [[String: Any]])[0]["resource"] as! [String: Any]
        XCTAssertNotNil((resource["code"] as? [String: Any])?["concept"])
        XCTAssertEqual(try sorted(FHIRPACSCodec.convert(wire, from: .r5, to: .r4)), try sorted(bundle))
    }
    func testCapabilityStatementAdvertisesTheSelectedRelease() throws {
        let r4 = data(#"{"resourceType":"CapabilityStatement","status":"active","date":"2026-10-23","kind":"instance","fhirVersion":"4.0.1","format":["json"]}"#)
        for release in FHIRRelease.allCases {
            let wire = try FHIRPACSCodec.convert(r4, from: .r4, to: release)
            let object = try JSONSerialization.jsonObject(with: wire) as! [String: Any]
            XCTAssertEqual(object["fhirVersion"] as? String, release.rawValue)
        }
    }
    func testUnsupportedFieldsAndReferenceOnlyConceptsAreNotDropped() throws {
        let referenceOnly = data(#"{"resourceType":"ServiceRequest","status":"active","intent":"order","subject":{"reference":"Patient/p"},"code":{"reference":{"reference":"ActivityDefinition/a"}}}"#)
        XCTAssertThrowsError(try FHIRPACSCodec.convert(referenceOnly, from: .r5, to: .r4))
        let unknown = data(#"{"resourceType":"Patient","newClinicalField":"must not disappear"}"#)
        XCTAssertThrowsError(try FHIRPACSCodec.convert(unknown, from: .r5, to: .r4))
        let unsupported = data(#"{"resourceType":"Observation","status":"final","code":{"text":"Outside scope"}}"#)
        XCTAssertThrowsError(try FHIRPACSCodec.convert(unsupported, from: .r4, to: .r5))
        let multipleConnections = data(#"{"resourceType":"Endpoint","status":"active","connectionType":[{"coding":[{"code":"a"}]},{"coding":[{"code":"b"}]}],"payload":[{"type":[{"text":"DICOM"}]}],"address":"https://example.test"}"#)
        XCTAssertThrowsError(try FHIRPACSCodec.convert(multipleConnections, from: .r5, to: .r4))
    }
    func testVersionedTransportPreservesHTTPMetadata() async throws {
        let wire = try FHIRPACSCodec.convert(data(fixtures[3]), from: .r4, to: .r5)
        let transport = RecordingFHIRTransport(response: .init(status: 201, headers: ["ETag":"W/\"2\"", "Location":"https://example.test/R5/ServiceRequest/o"], body: wire))
        let adapter = FHIRPACSHTTPTransport(release: .r5, transport: transport)
        let response = try await adapter.send(.init(url: URL(string:"https://example.test/R5/ServiceRequest")!, method:"POST", headers:["If-Match":"W/\"1\""], body:data(fixtures[3])))
        XCTAssertEqual(response.status, 201); XCTAssertEqual(response.header("ETag"), "W/\"2\"")
        XCTAssertEqual(try sorted(response.body), try sorted(data(fixtures[3])))
        let sent = await transport.last
        XCTAssertEqual(sent?.headers["Content-Type"], "application/fhir+json; fhirVersion=5.0.0")
        XCTAssertEqual(sent?.headers["If-Match"], "W/\"1\"")
        XCTAssertEqual(sent?.body, wire)
    }
    func testTransportRefusesContradictoryCapabilityRelease() async throws {
        let body = data(#"{"resourceType":"CapabilityStatement","status":"active","date":"2026-10-23","kind":"instance","fhirVersion":"4.0.1","format":["json"]}"#)
        let adapter = FHIRPACSHTTPTransport(release: .r5, transport: RecordingFHIRTransport(response: .init(status: 200, headers: [:], body: body)))
        do {
            _ = try await adapter.send(.init(url: URL(string:"https://example.test/R5/metadata")!, method:"GET"))
            XCTFail("A configured R5 partner must advertise R5")
        } catch let error as FHIRPACSConversionError { XCTAssertEqual(error.path,"$.fhirVersion") }
    }
    func testTransportRetainsNonFHIRFailureAndEmptySuccess() async throws {
        for (status, body) in [(503, data("<html>Temporary proxy failure</html>")), (204, Data())] {
            let adapter = FHIRPACSHTTPTransport(release: .r5, transport: RecordingFHIRTransport(response: .init(status: status, headers: [:], body: body)))
            let response = try await adapter.send(.init(url: URL(string:"https://example.test/R5/Patient/p")!, method:"GET"))
            XCTAssertEqual(response.status,status); XCTAssertEqual(response.body,body)
        }
    }

}
private actor RecordingFHIRTransport: FHIRHTTPTransport {
    let response: FHIRHTTPResponse
    var last: FHIRHTTPRequest?
    init(response: FHIRHTTPResponse) { self.response = response }
    func send(_ request: FHIRHTTPRequest) async throws -> FHIRHTTPResponse { last = request; return response }
}
