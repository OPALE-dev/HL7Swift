import XCTest
import FHIR
import ModelsR4

private actor StubFHIRTransport: FHIRHTTPTransport {
    private(set) var requests: [FHIRHTTPRequest] = []
    var response: FHIRHTTPResponse
    init(_ response: FHIRHTTPResponse) { self.response = response }
    func send(_ request: FHIRHTTPRequest) async throws -> FHIRHTTPResponse {
        requests.append(request)
        return response
    }
}

final class FHIRRESTTests: XCTestCase {
    private func client(_ transport: StubFHIRTransport) throws -> FHIRR4RESTClient {
        try .init(baseURL: URL(string: "https://example.invalid/fhir")!, transport: transport,
                  headers: ["Authorization": "Bearer test-token"])
    }

    func testReadImagingStudyAndVersionMetadata() async throws {
        let transport = StubFHIRTransport(.init(status: 200, headers: ["ETag": "W/\"7\""], body: Data(#"{"resourceType":"ImagingStudy","id":"study","status":"available","subject":{"reference":"Patient/p"}}"#.utf8)))
        let response = try await client(transport).read("ImagingStudy", id: "study")
        XCTAssertNotNil(response.resource?.get(if: ImagingStudy.self))
        XCTAssertEqual(response.entityTag, "W/\"7\"")
        let requests = await transport.requests
        XCTAssertEqual(requests.first?.url.path, "/fhir/ImagingStudy/study")
        XCTAssertEqual(requests.first?.headers["Accept"], "application/fhir+json")
    }

    func testSearchKeepsFullBundleAndRepeatedQueries() async throws {
        let json = #"{"resourceType":"Bundle","type":"searchset","total":0,"entry":[],"link":[{"relation":"next","url":"https://example.invalid/fhir/ServiceRequest?page=2"}]}"#
        let transport = StubFHIRTransport(.init(status: 200, body: Data(json.utf8)))
        let api = try client(transport)
        let response = try await api.search("ServiceRequest", parameters: [.init(name: "identifier", value: "urn:oid:1|123"), .init(name: "date", value: "ge2026-01-01"), .init(name: "date", value: "le2026-12-31")])
        let bundle = try XCTUnwrap(response.resource?.get(if: ModelsR4.Bundle.self))
        XCTAssertEqual(bundle.total?.value?.integer, 0)
        _ = try await api.nextPage(bundle)
        let requests = await transport.requests
        XCTAssertEqual(requests.count, 2)
        let query = URLComponents(url: requests[0].url, resolvingAgainstBaseURL: false)?.queryItems
        XCTAssertEqual(query?.filter { $0.name == "date" }.count, 2)
        XCTAssertEqual(query?.first?.value, "urn:oid:1|123")
        XCTAssertEqual(requests[1].url.query, "page=2")
    }

    func testUpdateUsesPUTAndMinimalResponseCompletes() async throws {
        let transport = StubFHIRTransport(.init(status: 204, headers: ["location": "Patient/p/_history/2"]))
        let patient = try JSONDecoder().decode(Patient.self, from: Data(#"{"resourceType":"Patient","id":"p"}"#.utf8))
        let response = try await client(transport).update(patient, id: "p", ifMatch: "W/\"1\"")
        XCTAssertNil(response.resource)
        XCTAssertEqual(response.location, "Patient/p/_history/2")
        let requests = await transport.requests
        let request = try XCTUnwrap(requests.first)
        XCTAssertEqual(request.method, "PUT")
        XCTAssertEqual(request.headers["If-Match"], "W/\"1\"")
        XCTAssertEqual(request.url.path, "/fhir/Patient/p")
    }

    func testOperationOutcomeRetainedOnError() async throws {
        let json = #"{"resourceType":"OperationOutcome","issue":[{"severity":"error","code":"conflict","diagnostics":"version mismatch"}]}"#
        let transport = StubFHIRTransport(.init(status: 412, body: Data(json.utf8)))
        do {
            _ = try await client(transport).delete("Patient", id: "p")
            XCTFail("Expected HTTP failure")
        } catch FHIRRESTError.http(let status, let outcome) {
            XCTAssertEqual(status, 412)
            XCTAssertEqual(outcome?.issue.count, 1)
        }
    }

    func testUnsafePaginationAndTraversalNeverSendCredentials() async throws {
        let transport = StubFHIRTransport(.init(status: 200))
        let api = try client(transport)
        for url in ["https://evil.invalid/fhir/Patient", "https://example.invalid/admin", "https://example.invalid/fhir/../admin"] {
            let json = "{\"resourceType\":\"Bundle\",\"type\":\"searchset\",\"link\":[{\"relation\":\"next\",\"url\":\"\(url)\"}]}"
            let bundle = try JSONDecoder().decode(ModelsR4.Bundle.self, from: Data(json.utf8))
            do { _ = try await api.nextPage(bundle); XCTFail("Unsafe link accepted") }
            catch FHIRRESTError.unsafePaginationURL { }
        }
        do { _ = try await api.read("Patient", id: "../admin"); XCTFail("Traversal accepted") }
        catch FHIRRESTError.invalidPath { }
        let requests = await transport.requests
        XCTAssertTrue(requests.isEmpty)
    }

    func testConditionalCreateAndTransaction() async throws {
        let minimal = StubFHIRTransport(.init(status: 201, headers: ["Location": "Patient/p/_history/1"]))
        let patient = Patient()
        let created = try await client(minimal).create(patient, ifNoneExist: "identifier=urn:oid:1|123")
        XCTAssertEqual(created.status, 201)
        let requests = await minimal.requests
        XCTAssertEqual(requests.first?.method, "POST")
        XCTAssertEqual(requests.first?.headers["If-None-Exist"], "identifier=urn:oid:1|123")
        let transport = StubFHIRTransport(.init(status: 200, body: Data(#"{"resourceType":"Bundle","type":"transaction-response","entry":[]}"#.utf8)))
        let bundle = try JSONDecoder().decode(ModelsR4.Bundle.self, from: Data(#"{"resourceType":"Bundle","type":"transaction","entry":[]}"#.utf8))
        let response = try await client(transport).submit(bundle)
        XCTAssertNotNil(response.resource?.get(if: ModelsR4.Bundle.self))
        let transactionRequests = await transport.requests
        XCTAssertEqual(transactionRequests.first?.url.path, "/fhir")
        XCTAssertEqual(transactionRequests.first?.method, "POST")
    }

    func testWrongResourceAndEmptyReadAreRejected() async throws {
        for body in [Data(), Data(#"{"resourceType":"Patient"}"#.utf8)] {
            let transport = StubFHIRTransport(.init(status: 200, body: body))
            do { _ = try await client(transport).read("Endpoint", id: "e"); XCTFail("Invalid read accepted") }
            catch FHIRRESTError.invalidResponse { }
            catch FHIRRESTError.unexpectedResourceType { }
        }
    }
}
