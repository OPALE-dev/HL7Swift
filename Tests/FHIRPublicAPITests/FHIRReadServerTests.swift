import XCTest
import FHIR
import ModelsR4
import NIO
import NIOHTTP1
import AsyncHTTPClient

private actor ReadServerTransport: FHIRHTTPTransport {
    let api: FHIRR4ReadServer
    init(_ api: FHIRR4ReadServer) { self.api = api }
    func send(_ request: FHIRHTTPRequest) async throws -> FHIRHTTPResponse {
        await api.respond(to: request, read: { type, id in
            guard type == "Patient", id == "p1" else { return nil }
            let patient = Patient(); patient.id = "p1"; return .patient(patient)
        }, search: { query in
            let patient = Patient(); patient.id = .init(FHIRString(query.pageToken == nil ? "p1" : "p2"))
            return .init(resources: [.patient(patient)], total: 2,
                         nextPageToken: query.pageToken == nil ? "next" : nil)
        })
    }
}

/// Test-only adapter: translates real HTTP to the same public server API.
/// Handler state is accessed only on its channel's event loop.
private final class ReadServerHTTPHandler: ChannelInboundHandler, @unchecked Sendable {
    typealias InboundIn = HTTPServerRequestPart
    private let transport: ReadServerTransport
    private var head: HTTPRequestHead?
    init(_ transport: ReadServerTransport) { self.transport = transport }
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        switch unwrapInboundIn(data) {
        case .head(let head): self.head = head
        case .body: break // The loopback qualification below exercises GET only.
        case .end:
            guard let head, let url = URL(string: "http://loopback.invalid" + head.uri) else { return }
            self.head = nil
            let request = FHIRHTTPRequest(url: url, method: head.method.rawValue,
                headers: Dictionary(head.headers.map { ($0.name, $0.value) }, uniquingKeysWith: { _, last in last }))
            let promise = context.eventLoop.makePromise(of: FHIRHTTPResponse.self)
            let channel = context.channel; let transport = self.transport
            promise.futureResult.whenSuccess { response in
                var headers = HTTPHeaders(response.headers.map { ($0.key, $0.value) })
                headers.add(name: "Content-Length", value: String(response.body.count))
                channel.write(HTTPServerResponsePart.head(.init(version: .http1_1, status: .init(statusCode: response.status), headers: headers)), promise: nil)
                if !response.body.isEmpty { channel.write(HTTPServerResponsePart.body(.byteBuffer(ByteBuffer(bytes: response.body))), promise: nil) }
                channel.writeAndFlush(HTTPServerResponsePart.end(nil), promise: nil)
            }
            _Concurrency.Task {
                do { promise.succeed(try await transport.send(request)) }
                catch { promise.succeed(.init(status: 500)) }
            }
        }
    }
}

final class FHIRReadServerTests: XCTestCase {
    private func server() throws -> FHIRR4ReadServer {
        try .init(baseURL: URL(string: "https://pacs.example/fhir/R4")!, capabilities: [
            .init(resourceType: "Patient", parameters: [.init(name: "identifier", type: .token)]),
            .init(resourceType: "ImagingStudy", parameters: [
                .init(name: "patient", type: .reference), .init(name: "started", type: .date)]),
            .init(resourceType: "Endpoint", search: false)
        ], publicationDate: Date(timeIntervalSince1970: 1_700_000_000))
    }
    private func patient(_ id: String = "p1", meta: Bool = false) throws -> ResourceProxy {
        let metadata = meta ? #", "meta":{"versionId":"7","lastUpdated":"2026-10-13T10:00:00Z"}"# : ""
        return try JSONDecoder().decode(ResourceProxy.self, from: Data("{\"resourceType\":\"Patient\",\"id\":\"\(id)\"\(metadata)}".utf8))
    }
    private func request(_ path: String, method: String = "GET", headers: [String: String] = [:], body: String? = nil) -> FHIRHTTPRequest {
        .init(url: URL(string: "https://internal-proxy.invalid/fhir/R4/" + path)!, method: method,
              headers: headers, body: body.map { Data($0.utf8) })
    }
    private func noRead(_ type: String, _ id: String) async throws -> ResourceProxy? { XCTFail("Read callback called"); return nil }
    private func noSearch(_ query: FHIRR4ServerSearchRequest) async throws -> FHIRR4ServerSearchPage { XCTFail("Search callback called"); return .init(resources: []) }

    func testMetadataAdvertisesOnlyConfiguredCapabilities() async throws {
        let response = await (try server()).respond(to: request("metadata"), read: noRead, search: noSearch)
        XCTAssertEqual(response.status, 200)
        let metadata = try JSONDecoder().decode(CapabilityStatement.self, from: response.body)
        XCTAssertEqual(metadata.fhirVersion.value?.string, "4.0.1")
        let rest = try XCTUnwrap(metadata.rest?.first)
        XCTAssertEqual(rest.mode.value, .server)
        XCTAssertEqual(rest.resource?.count, 3)
        let patient = try XCTUnwrap(rest.resource?.first)
        XCTAssertEqual(patient.interaction?.compactMap { $0.code.value?.rawValue }, ["read", "search-type"])
        XCTAssertEqual(patient.searchParam?.compactMap { $0.name.value?.string }, ["_id", "identifier"])
        XCTAssertNil(rest.interaction)
        XCTAssertEqual(patient.readHistory?.value?.bool, false)
    }

    func testReadAndConditionalHTTPMetadata() async throws {
        let api = try server(); let resource = try patient(meta: true)
        let read: (String, String) async throws -> ResourceProxy? = { type, id in
            XCTAssertEqual(type, "Patient"); XCTAssertEqual(id, "p1"); return resource
        }
        let response = await api.respond(to: request("Patient/p1"), read: read, search: noSearch)
        XCTAssertEqual(response.status, 200)
        XCTAssertEqual(response.header("ETag"), "W/\"7\"")
        XCTAssertEqual(response.header("Last-Modified"), "Tue, 13 Oct 2026 10:00:00 GMT")
        for headers in [["if-none-match": "\"other\", \"7\""], ["If-None-Match": "*"],
                        ["If-Modified-Since": "Tue, 13 Oct 2026 10:00:00 GMT"]] {
            let cached = await api.respond(to: request("Patient/p1", headers: headers), read: read, search: noSearch)
            XCTAssertEqual(cached.status, 304); XCTAssertTrue(cached.body.isEmpty)
            XCTAssertNil(cached.header("Content-Type"))
        }
        let precedence = await api.respond(to: request("Patient/p1", headers: ["If-None-Match": "\"other\"", "If-Modified-Since": "Tue, 13 Oct 2026 10:00:00 GMT"]), read: read, search: noSearch)
        XCTAssertEqual(precedence.status, 200)
        let malformed = await api.respond(to: request("Patient/p1", headers: ["If-None-Match": "W/W/\"7\""]), read: read, search: noSearch)
        XCTAssertEqual(malformed.status, 200)
    }

    func testSearchPreservesRepeatedExpressionsAndSafePagination() async throws {
        let api = try server(); let resource = try patient()
        let response = await api.respond(to: request("Patient?identifier=urn%3Aoid%3A1%7C123&identifier=other&_count=1"), read: noRead) { query in
            XCTAssertEqual(query.count, 1); XCTAssertNil(query.pageToken)
            XCTAssertEqual(query.parameters.map(\.value), ["urn:oid:1|123", "other"])
            return .init(resources: [resource], total: 2, nextPageToken: "opaque+/=token")
        }
        XCTAssertEqual(response.status, 200)
        let bundle = try JSONDecoder().decode(ModelsR4.Bundle.self, from: response.body)
        XCTAssertEqual(bundle.type.value, .searchset)
        XCTAssertEqual(bundle.total?.value?.integer, 2)
        XCTAssertEqual(bundle.entry?.first?.fullUrl?.value?.url.absoluteString, "https://pacs.example/fhir/R4/Patient/p1")
        XCTAssertEqual(bundle.entry?.first?.search?.mode?.value, .match)
        let next = try XCTUnwrap(bundle.link?.first { $0.relation.value?.string == "next" }?.url.value?.url)
        XCTAssertEqual(next.host, "pacs.example")
        let items = try XCTUnwrap(URLComponents(url: next, resolvingAgainstBaseURL: false)?.queryItems)
        XCTAssertEqual(items.filter { $0.name == "identifier" }.count, 2)
        XCTAssertEqual(items.last?.value, "opaque+/=token")
    }

    func testPOSTSearchAndEmptyCountOnlySearch() async throws {
        let api = try server()
        let response = await api.respond(to: request("Patient/_search", method: "POST", headers: ["Content-Type": "application/x-www-form-urlencoded; charset=utf-8"], body: "identifier=a%2Bb+c&_count=0"), read: noRead) { query in
            XCTAssertEqual(query.parameters.first?.value, "a+b c"); XCTAssertEqual(query.count, 0)
            return .init(resources: [], total: 12)
        }
        XCTAssertEqual(response.status, 200)
        let bundle = try JSONDecoder().decode(ModelsR4.Bundle.self, from: response.body)
        XCTAssertEqual(bundle.total?.value?.integer, 12); XCTAssertNil(bundle.entry)
        XCTAssertEqual(bundle.link?.count, 1)
    }

    func testUnsupportedSearchIsRejectedBeforeApplication() async throws {
        let api = try server()
        for path in ["Patient?name=private", "Patient?identifier:missing=true", "Patient?_count=-1", "Patient?_count=201",
                     "Patient?_count=1&_count=2", "Patient?_include=Patient:organization", "Patient?" + String(repeating: "a", count: 17000)] {
            let response = await api.respond(to: request(path), read: noRead, search: noSearch)
            XCTAssertEqual(response.status, 400, path)
            let outcome = try JSONDecoder().decode(OperationOutcome.self, from: response.body)
            XCTAssertEqual(outcome.issue.first?.code.value, .invalid)
            XCTAssertFalse(String(decoding: response.body, as: UTF8.self).contains("private"))
        }
        for form in ["identifier=%", "identifier=%ZZ", "identifier=a#fragment"] {
            let response = await api.respond(to: request("Patient/_search", method: "POST", headers: ["Content-Type": "application/x-www-form-urlencoded"], body: form), read: noRead, search: noSearch)
            XCTAssertEqual(response.status, 400)
        }
    }

    func testNegotiationRoutesAndWritesNeverCallBackend() async throws {
        let api = try server()
        for accept in ["application/fhir+xml", "application/fhir+json;q=0, */*;q=1", "application/fhir+json;q=invalid"] {
            let response = await api.respond(to: request("metadata", headers: ["Accept": accept]), read: noRead, search: noSearch)
            XCTAssertEqual(response.status, 406)
        }
        let override = await api.respond(to: request("metadata?_format=json", headers: ["Accept": "application/xml"]), read: noRead, search: noSearch)
        XCTAssertEqual(override.status, 200)
        for path in ["Patient/p1/_history", "Patient/a%2Fb", "Patient/", "Observation", "Endpoint"] {
            let response = await api.respond(to: request(path), read: noRead, search: noSearch)
            XCTAssertEqual(response.status, 404)
        }
        let write = await api.respond(to: request("Patient/p1", method: "PUT"), read: noRead, search: noSearch)
        XCTAssertEqual(write.status, 405); XCTAssertEqual(write.header("Allow"), "GET")
        let media = await api.respond(to: request("Patient/_search", method: "POST", headers: ["Content-Type": "application/json"], body: "{}"), read: noRead, search: noSearch)
        XCTAssertEqual(media.status, 415)
    }

    func testMissingResourcesAndSafeErrors() async throws {
        let api = try server()
        let missing = await api.respond(to: request("Patient/p1"), read: { _, _ in nil }, search: noSearch)
        XCTAssertEqual(missing.status, 404)
        struct StorageError: Error { let secret = "patient-secret-password" }
        let failed = await api.respond(to: request("Patient/p1"), read: { _, _ in throw StorageError() }, search: noSearch)
        XCTAssertEqual(failed.status, 500)
        XCTAssertFalse(String(decoding: failed.body, as: UTF8.self).contains("patient-secret"))
        let forbidden = await api.respond(to: request("Patient/p1"), read: { _, _ in throw FHIRR4ServerError.forbidden }, search: noSearch)
        XCTAssertEqual(forbidden.status, 403)
    }

    func testBackendContractAndInvalidConfigurationAreRejected() async throws {
        let api = try server(); let wrong = try patient("wrong")
        let mismatch = await api.respond(to: request("Patient/p1"), read: { _, _ in wrong }, search: noSearch)
        XCTAssertEqual(mismatch.status, 500)
        let oversized = await api.respond(to: request("Patient?_count=0"), read: noRead) { _ in .init(resources: [wrong]) }
        XCTAssertEqual(oversized.status, 500)
        let badTotal = await api.respond(to: request("Patient"), read: noRead) { _ in .init(resources: [], total: Int.max) }
        XCTAssertEqual(badTotal.status, 500)
        let missingTotal = await api.respond(to: request("Patient?_count=0"), read: noRead) { _ in .init(resources: []) }
        XCTAssertEqual(missingTotal.status, 500)
        XCTAssertThrowsError(try FHIRR4ReadServer(baseURL: URL(string: "https://pacs.example/fhir?token=secret")!, capabilities: [], publicationDate: Date()))
        XCTAssertThrowsError(try FHIRR4ReadServer(baseURL: api.baseURL, capabilities: [.init(resourceType: "NotAResource")], publicationDate: Date()))
        XCTAssertThrowsError(try FHIRR4ReadServer(baseURL: api.baseURL, capabilities: [.init(resourceType: "Patient"), .init(resourceType: "Patient")], publicationDate: Date()))
    }

    func testPublicClientConsumesServerReadCapabilitiesAndNextPage() async throws {
        let api = try server()
        let client = try FHIRR4RESTClient(baseURL: api.baseURL, transport: ReadServerTransport(api))
        let metadata = try await client.capabilities()
        XCTAssertNotNil(metadata.resource?.get(if: CapabilityStatement.self))
        let read = try await client.read("Patient", id: "p1")
        XCTAssertEqual(read.resource?.get(if: Patient.self)?.id?.value?.string, "p1")
        let first = try await client.search("Patient", parameters: [.init(name: "_count", value: "1")])
        let firstBundle = try XCTUnwrap(first.resource?.get(if: ModelsR4.Bundle.self))
        let next = try await client.nextPage(firstBundle)
        let secondBundle = try XCTUnwrap(next?.resource?.get(if: ModelsR4.Bundle.self))
        XCTAssertEqual(secondBundle.entry?.first?.resource?.get(if: Patient.self)?.id?.value?.string, "p2")
        XCTAssertNil(secondBundle.link?.first { $0.relation.value?.string == "next" })
    }

    func testResponseLimitDoesNotReturnOversizedResource() async throws {
        let api = try FHIRR4ReadServer(baseURL: URL(string: "https://pacs.example/fhir/R4")!,
            capabilities: [.init(resourceType: "Patient")], publicationDate: Date(), maximumResponseBytes: 30)
        let patient = try patient()
        let response = await api.respond(to: request("Patient/p1"), read: { _, _ in patient }, search: noSearch)
        XCTAssertEqual(response.status, 500)
        XCTAssertNotNil(try JSONDecoder().decode(OperationOutcome.self, from: response.body))
    }

    func testServerOverRealLoopbackHTTP() async throws {
        let transport = ReadServerTransport(try server())
        let listener = try await ServerBootstrap(group: MultiThreadedEventLoopGroup.singleton)
            .childChannelInitializer { channel in
                channel.pipeline.configureHTTPServerPipeline().flatMap {
                    channel.eventLoop.makeCompletedFuture {
                        try channel.pipeline.syncOperations.addHandler(ReadServerHTTPHandler(transport))
                    }
                }
            }.bind(host: "127.0.0.1", port: 0).get()
        let http = HTTPClient(eventLoopGroupProvider: .singleton)
        do {
            let port = try XCTUnwrap(listener.localAddress?.port)
            let client = try FHIRR4RESTClient(baseURL: URL(string: "http://127.0.0.1:\(port)/fhir/R4")!,
                                               transport: AsyncFHIRHTTPTransport(client: http))
            let metadata = try await client.capabilities()
            XCTAssertNotNil(metadata.resource?.get(if: CapabilityStatement.self))
            let result = try await client.read("Patient", id: "p1")
            XCTAssertEqual(result.resource?.get(if: Patient.self)?.id?.value?.string, "p1")
            let search = try await client.search("Patient", parameters: [.init(name: "_count", value: "1")])
            XCTAssertEqual(search.resource?.get(if: ModelsR4.Bundle.self)?.total?.value?.integer, 2)
            do { _ = try await client.read("Patient", id: "missing"); XCTFail("Missing resource succeeded") }
            catch FHIRRESTError.http(let status, let outcome) { XCTAssertEqual(status, 404); XCTAssertNotNil(outcome) }
            try await http.shutdown(); try await listener.close().get()
        } catch {
            try? await http.shutdown(); try? await listener.close().get(); throw error
        }
    }
}
