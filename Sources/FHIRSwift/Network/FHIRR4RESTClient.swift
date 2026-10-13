import Foundation
import NIOCore
import NIOHTTP1
import AsyncHTTPClient
import ModelsR4

/// Injectable wire transport so adapters can use their own HTTP lifecycle and
/// test without a live FHIR service. No application storage or OAuth flow is imposed.
public protocol FHIRHTTPTransport: Sendable {
    func send(_ request: FHIRHTTPRequest) async throws -> FHIRHTTPResponse
}

public struct FHIRHTTPRequest: Sendable {
    public var url: URL
    public var method: String
    public var headers: [String: String]
    public var body: Data?
    public init(url: URL, method: String, headers: [String: String] = [:], body: Data? = nil) {
        self.url = url; self.method = method; self.headers = headers; self.body = body
    }
}

public struct FHIRHTTPResponse: Sendable {
    public var status: Int
    public var headers: [String: String]
    public var body: Data
    public init(status: Int, headers: [String: String] = [:], body: Data = Data()) {
        self.status = status; self.headers = headers; self.body = body
    }
    public func header(_ name: String) -> String? {
        headers.first { $0.key.caseInsensitiveCompare(name) == .orderedSame }?.value
    }
}

/// Uses a caller-owned AsyncHTTPClient (for example ELENA's shared client).
/// Shutdown remains the owner's responsibility. The body limit applies before
/// decoding, including error responses.
public struct AsyncFHIRHTTPTransport: FHIRHTTPTransport {
    private let client: HTTPClient
    public let timeout: TimeAmount
    public let maximumResponseBytes: Int
    public init(client: HTTPClient, timeout: TimeAmount = .seconds(30), maximumResponseBytes: Int = 16 * 1024 * 1024) {
        precondition(maximumResponseBytes > 0)
        self.client = client; self.timeout = timeout; self.maximumResponseBytes = maximumResponseBytes
    }
    public func send(_ request: FHIRHTTPRequest) async throws -> FHIRHTTPResponse {
        var wire = HTTPClientRequest(url: request.url.absoluteString)
        wire.method = HTTPMethod(rawValue: request.method)
        for (name, value) in request.headers { wire.headers.add(name: name, value: value) }
        if let body = request.body { wire.body = .bytes(ByteBuffer(bytes: body)) }
        let response = try await client.execute(wire, timeout: timeout)
        let bytes = try await response.body.collect(upTo: maximumResponseBytes)
        var headers: [String: String] = [:]
        for (name, value) in response.headers { headers[name.lowercased()] = value }
        return .init(status: Int(response.status.code), headers: headers, body: Data(bytes.readableBytesView))
    }
}

/// HTTP metadata is retained even for minimal (empty-body) create/update replies.
public struct FHIRR4RESTResponse {
    public let status: Int
    public let resource: ResourceProxy?
    public let location: String?
    public let entityTag: String?
    public let lastModified: String?
}

public enum FHIRRESTError: Error {
    case invalidBaseURL, invalidPath, invalidHeader, invalidResponse, unexpectedResourceType
    case unsafePaginationURL
    /// OperationOutcome is retained for the application, never logged here.
    case http(status: Int, outcome: OperationOutcome?)
}

/// R4 client for resource REST interactions, search Bundles and transactions.
/// Instances can share a transport; model objects should not be mutated while
/// encoding. This client performs no profile or terminology validation.
public struct FHIRR4RESTClient: Sendable {
    public let baseURL: URL
    private let transport: any FHIRHTTPTransport
    private let headers: [String: String]

    public init(baseURL: URL, transport: any FHIRHTTPTransport, headers: [String: String] = [:]) throws {
        guard ["https", "http"].contains(baseURL.scheme?.lowercased() ?? ""), baseURL.host != nil,
              baseURL.user == nil, baseURL.password == nil, baseURL.query == nil, baseURL.fragment == nil else {
            throw FHIRRESTError.invalidBaseURL
        }
        guard headers.allSatisfy({ !$0.key.contains(where: { ":\r\n".contains($0) }) && !$0.value.contains(where: { "\r\n".contains($0) }) }) else {
            throw FHIRRESTError.invalidHeader
        }
        self.baseURL = baseURL; self.transport = transport; self.headers = headers
    }

    public func read(_ resourceType: String, id: String) async throws -> FHIRR4RESTResponse {
        try await execute(method: "GET", path: [resourceType, id], expected: resourceType, requireBody: true)
    }

    /// All search entries, links, total and OperationOutcome entries are kept.
    /// Ordered query items permit repeated parameters and comma/pipe tokens.
    public func search(_ resourceType: String, parameters: [URLQueryItem] = []) async throws -> FHIRR4RESTResponse {
        try await execute(method: "GET", path: [resourceType], query: parameters, expected: "Bundle", requireBody: true)
    }

    public func capabilities() async throws -> FHIRR4RESTResponse {
        try await execute(method: "GET", path: ["metadata"], expected: "CapabilityStatement", requireBody: true)
    }

    public func create(_ resource: Resource, ifNoneExist: String? = nil) async throws -> FHIRR4RESTResponse {
        let conditional = ifNoneExist.map { ["If-None-Exist": $0] } ?? [:]
        return try await execute(method: "POST", path: [type(of: resource).resourceType.rawValue],
            body: JSONEncoder().encode(resource), extraHeaders: conditional)
    }

    public func update(_ resource: Resource, id: String, ifMatch: String? = nil) async throws -> FHIRR4RESTResponse {
        if let modelID = resource.id?.value?.string, modelID != id { throw FHIRRESTError.invalidPath }
        return try await execute(method: "PUT", path: [type(of: resource).resourceType.rawValue, id],
            body: JSONEncoder().encode(resource), extraHeaders: ifMatch.map { ["If-Match": $0] } ?? [:])
    }

    public func delete(_ resourceType: String, id: String, ifMatch: String? = nil) async throws -> FHIRR4RESTResponse {
        try await execute(method: "DELETE", path: [resourceType, id], extraHeaders: ifMatch.map { ["If-Match": $0] } ?? [:])
    }

    public func history(_ resourceType: String, id: String? = nil, parameters: [URLQueryItem] = []) async throws -> FHIRR4RESTResponse {
        let path = [resourceType] + (id.map { [$0] } ?? []) + ["_history"]
        return try await execute(method: "GET", path: path, query: parameters, expected: "Bundle", requireBody: true)
    }

    public func versionRead(_ resourceType: String, id: String, version: String) async throws -> FHIRR4RESTResponse {
        try await execute(method: "GET", path: [resourceType, id, "_history", version], expected: resourceType, requireBody: true)
    }

    public func submit(_ bundle: ModelsR4.Bundle) async throws -> FHIRR4RESTResponse {
        guard [.batch, .transaction].contains(bundle.type.value) else { throw FHIRRESTError.unexpectedResourceType }
        return try await execute(method: "POST", path: [], body: JSONEncoder().encode(bundle), expected: "Bundle", requireBody: true)
    }

    /// Follow a Bundle link only within this FHIR base. Authorization headers
    /// are never forwarded to a different origin or outside the base path.
    public func nextPage(_ bundle: ModelsR4.Bundle) async throws -> FHIRR4RESTResponse? {
        guard let link = bundle.link?.first(where: { $0.relation.value?.string == "next" }),
              let string = link.url.value?.url.absoluteString else { return nil }
        let basePath = baseURL.standardized.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let url = URL(string: string, relativeTo: baseURL.appendingPathComponent(""))?.absoluteURL,
              url.scheme == baseURL.scheme, url.host == baseURL.host, url.port == baseURL.port,
              url.user == nil, url.password == nil, url.fragment == nil,
              basePath.isEmpty || url.standardized.path == "/" + basePath || url.standardized.path.hasPrefix("/" + basePath + "/") else {
            throw FHIRRESTError.unsafePaginationURL
        }
        return try await perform(.init(url: url, method: "GET"), expected: "Bundle", requireBody: true)
    }

    private func execute(method: String, path: [String], query: [URLQueryItem] = [], body: Data? = nil,
                         extraHeaders: [String: String] = [:], expected: String? = nil, requireBody: Bool = false) async throws -> FHIRR4RESTResponse {
        guard path.allSatisfy({ !$0.isEmpty && $0 != "." && $0 != ".." && $0.utf8.allSatisfy { (65...90).contains($0) || (97...122).contains($0) || (48...57).contains($0) || $0 == 45 || $0 == 46 || $0 == 95 } }) else { throw FHIRRESTError.invalidPath }
        var url = baseURL
        for part in path { url.appendPathComponent(part) }
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        if !query.isEmpty { components.queryItems = query }
        guard let finalURL = components.url else { throw FHIRRESTError.invalidPath }
        return try await perform(.init(url: finalURL, method: method, headers: extraHeaders, body: body), expected: expected, requireBody: requireBody)
    }

    private func perform(_ input: FHIRHTTPRequest, expected: String?, requireBody: Bool) async throws -> FHIRR4RESTResponse {
        var request = input
        request.headers = headers.merging(input.headers) { _, new in new }
        request.headers["Accept"] = "application/fhir+json"
        if request.body != nil { request.headers["Content-Type"] = "application/fhir+json" }
        guard request.headers.values.allSatisfy({ !$0.contains(where: { "\r\n".contains($0) }) }) else { throw FHIRRESTError.invalidHeader }
        try _Concurrency.Task.checkCancellation()
        let response = try await transport.send(request)
        guard (200..<300).contains(response.status) else {
            let outcome = try? JSONDecoder().decode(OperationOutcome.self, from: response.body)
            throw FHIRRESTError.http(status: response.status, outcome: outcome)
        }
        let resource: ResourceProxy?
        if response.body.isEmpty {
            guard !requireBody else { throw FHIRRESTError.invalidResponse }
            resource = nil
        } else {
            guard let decoded = try? JSONDecoder().decode(ResourceProxy.self, from: response.body) else { throw FHIRRESTError.invalidResponse }
            if let expected, decoded.resourceType != expected { throw FHIRRESTError.unexpectedResourceType }
            resource = decoded
        }
        return .init(status: response.status, resource: resource, location: response.header("Location"),
                     entityTag: response.header("ETag"), lastModified: response.header("Last-Modified"))
    }
}
