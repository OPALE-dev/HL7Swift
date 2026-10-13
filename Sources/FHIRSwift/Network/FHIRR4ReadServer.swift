import Foundation
import ModelsR4

/// Describes exactly the searches implemented by the application's data adapter.
/// Modifiers/chains must be explicitly listed in `acceptedNames`; no SQL is generated.
public struct FHIRR4ServerSearchParameter {
    public let name: String
    public let type: SearchParamType
    public let acceptedNames: [String]
    public init(name: String, type: SearchParamType, acceptedNames: [String]? = nil) {
        self.name = name; self.type = type; self.acceptedNames = acceptedNames ?? [name]
    }
}

public struct FHIRR4ServerResourceCapability {
    public let resourceType: String
    public let read: Bool
    public let search: Bool
    public let parameters: [FHIRR4ServerSearchParameter]
    public init(resourceType: String, read: Bool = true, search: Bool = true,
                parameters: [FHIRR4ServerSearchParameter] = []) {
        self.resourceType = resourceType; self.read = read; self.search = search
        self.parameters = parameters
    }
}

/// Ordered raw search expressions: repeated parameters and escaped token syntax
/// are preserved for the application to interpret according to FHIR semantics.
public struct FHIRR4ServerSearchRequest {
    public let resourceType: String
    public let parameters: [URLQueryItem]
    public let count: Int
    public let pageToken: String?
}

/// Matches only, not `_include` results. The application supplies a stable,
/// authorization-scoped cursor; the library never turns it into a database offset.
public struct FHIRR4ServerSearchPage {
    public let resources: [ResourceProxy]
    public let total: Int?
    public let nextPageToken: String?
    public init(resources: [ResourceProxy], total: Int? = nil, nextPageToken: String? = nil) {
        self.resources = resources; self.total = total; self.nextPageToken = nextPageToken
    }
}

/// Safe public errors, deliberately without patient data or underlying error text.
public enum FHIRR4ServerError: Error {
    case invalidConfiguration, invalidSearch, unauthorized, forbidden, unavailable
}

/// Framework-independent, read-only R4 HTTP semantics. No listener, database,
/// authorization policy, profile validator or mutable resource store is supplied.
/// Authenticate/authorize every request before calling this adapter, including
/// metadata, and scope both callbacks to the current principal. Model instances
/// must not be mutated concurrently while their response is encoded.
public struct FHIRR4ReadServer {
    public let baseURL: URL
    public let capabilities: [FHIRR4ServerResourceCapability]
    public let defaultCount: Int
    public let maximumCount: Int
    public let maximumResponseBytes: Int
    private let publicationDate: Date

    public init(baseURL: URL, capabilities: [FHIRR4ServerResourceCapability],
                publicationDate: Date, defaultCount: Int = 20, maximumCount: Int = 200,
                maximumResponseBytes: Int = 16 * 1024 * 1024) throws {
        guard ["http", "https"].contains(baseURL.scheme ?? ""), baseURL.host != nil,
              baseURL.user == nil, baseURL.password == nil, baseURL.query == nil,
              baseURL.fragment == nil, defaultCount > 0, maximumCount >= defaultCount, maximumResponseBytes > 0,
              Set(capabilities.map(\.resourceType)).count == capabilities.count,
              !baseURL.path.split(separator: "/").contains(where: { $0 == "." || $0 == ".." }) else {
            throw FHIRR4ServerError.invalidConfiguration
        }
        for capability in capabilities {
            guard ResourceType(rawValue: capability.resourceType) != nil,
                  capability.read || capability.search,
                  capability.search || capability.parameters.isEmpty,
                  Set(capability.parameters.map(\.name)).count == capability.parameters.count,
                  capability.parameters.allSatisfy({ parameter in
                      !parameter.name.isEmpty && !["_count", "_format", "_pageToken", "_id"].contains(parameter.name)
                      && parameter.acceptedNames.contains(parameter.name)
                      && parameter.acceptedNames.allSatisfy { $0 == parameter.name || $0.hasPrefix(parameter.name + ":") || $0.hasPrefix(parameter.name + ".") }
                  }) else { throw FHIRR4ServerError.invalidConfiguration }
        }
        self.baseURL = baseURL; self.capabilities = capabilities
        self.publicationDate = publicationDate; self.defaultCount = defaultCount; self.maximumCount = maximumCount
        self.maximumResponseBytes = maximumResponseBytes
    }

    /// Advertises only read/search, JSON and no history/versioned reads or writes.
    public func capabilityStatement() throws -> CapabilityStatement {
        let resources: [[String: Any]] = capabilities.map { capability in
            var interactions: [[String: String]] = []
            if capability.read { interactions.append(["code": "read"]) }
            if capability.search { interactions.append(["code": "search-type"]) }
            var resource: [String: Any] = ["type": capability.resourceType, "interaction": interactions,
                "versioning": "versioned", "readHistory": false, "updateCreate": false,
                "conditionalCreate": false, "conditionalRead": "not-supported"]
            // Version metadata/ETags may exist, but no vread/history is promised.
            if capability.read { resource["conditionalRead"] = "full-support" }
            if capability.search {
                resource["searchParam"] = [["name": "_id", "type": "token"]]
                    + capability.parameters.map { ["name": $0.name, "type": $0.type.rawValue] }
            }
            return resource
        }
        return try model(["resourceType": "CapabilityStatement", "status": "active",
            "date": ISO8601DateFormatter().string(from: publicationDate), "kind": "instance",
            "fhirVersion": "4.0.1", "format": ["json"],
            "implementation": ["description": "Application-backed read-only FHIR R4 API", "url": baseURL.absoluteString],
            "rest": [["mode": "server", "resource": resources]]], as: CapabilityStatement.self)
    }

    /// Callbacks are per-request so authentication context is never stored in a
    /// shared server. Return nil for a missing read; throw a safe error otherwise.
    public func respond(to request: FHIRHTTPRequest,
                        read: (String, String) async throws -> ResourceProxy?,
                        search: (FHIRR4ServerSearchRequest) async throws -> FHIRR4ServerSearchPage) async -> FHIRHTTPResponse {
        do {
            return try await execute(request, read: read, search: search)
        } catch FHIRR4ServerError.invalidSearch {
            return outcome(400, code: "invalid", message: "Invalid or unsupported search parameters.")
        } catch FHIRR4ServerError.unauthorized {
            return outcome(401, code: "login", message: "Authentication required.")
        } catch FHIRR4ServerError.forbidden {
            return outcome(403, code: "forbidden", message: "Access denied.")
        } catch FHIRR4ServerError.unavailable {
            return outcome(503, code: "transient", message: "Service temporarily unavailable.")
        } catch {
            return outcome(500, code: "exception", message: "Unable to produce the FHIR response.")
        }
    }

    private func execute(_ request: FHIRHTTPRequest,
                         read: (String, String) async throws -> ResourceProxy?,
                         search: (FHIRR4ServerSearchRequest) async throws -> FHIRR4ServerSearchPage) async throws -> FHIRHTTPResponse {
        let prefix = baseURL.path.hasSuffix("/") ? String(baseURL.path.dropLast()) : baseURL.path
        let encodedPath = URLComponents(url: request.url, resolvingAgainstBaseURL: false)?.percentEncodedPath ?? ""
        let requestPath = encodedPath.removingPercentEncoding ?? ""
        guard !encodedPath.lowercased().contains("%2f"), !encodedPath.lowercased().contains("%5c"),
              requestPath.hasPrefix(prefix + "/"), request.url.fragment == nil else {
            return outcome(404, code: "not-found", message: "Unknown FHIR route.")
        }
        let parts = requestPath.dropFirst(prefix.count + 1).split(separator: "/", omittingEmptySubsequences: false).map(String.init)
        guard parts.allSatisfy({ !$0.isEmpty && $0 != "." && $0 != ".." && !$0.contains("\\") }) else {
            return outcome(404, code: "not-found", message: "Unknown FHIR route.")
        }
        guard (request.url.query?.utf8.count ?? 0) <= 16 * 1024,
              request.url.query.map({ $0.removingPercentEncoding != nil }) ?? true else { throw FHIRR4ServerError.invalidSearch }
        var items = URLComponents(url: request.url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        let isPostSearch = parts.count == 2 && parts[1] == "_search" && request.method == "POST"
        if request.method != "GET" && !isPostSearch {
            var response = outcome(405, code: "not-supported", message: "Interaction not supported.")
            response.headers["Allow"] = parts.last == "_search" ? "POST" : "GET"
            return response
        }
        if isPostSearch {
            guard header(request, "Content-Type")?.split(separator: ";").first?.trimmingCharacters(in: .whitespaces).lowercased() == "application/x-www-form-urlencoded" else {
                return outcome(415, code: "not-supported", message: "Search requires form-encoded content.")
            }
            guard let body = request.body, body.count <= 16 * 1024, let form = String(data: body, encoding: .utf8),
                  validPercentEncoding(form), form.removingPercentEncoding != nil else {
                throw FHIRR4ServerError.invalidSearch
            }
            // In form encoding '+' means space; a literal plus must be %2B.
            // `URLComponents` traps on illegal percentEncodedQuery input. Use its
            // failable URL parser instead, after checking percent escapes.
            guard let components = URLComponents(string: "https://form.invalid/?" + form.replacingOccurrences(of: "+", with: "%20")),
                  components.fragment == nil else { throw FHIRR4ServerError.invalidSearch }
            items += components.queryItems ?? []
        }
        guard items.count <= 100, items.allSatisfy({ $0.name.utf8.count <= 256 && ($0.value?.utf8.count ?? 0) <= 4096 }) else {
            throw FHIRR4ServerError.invalidSearch
        }
        guard acceptsJSON(request, items: items) else {
            return outcome(406, code: "not-supported", message: "Only FHIR JSON is supported.")
        }
        if parts == ["metadata"] {
            guard items.allSatisfy({ $0.name == "_format" }) else { throw FHIRR4ServerError.invalidSearch }
            return try encoded(capabilityStatement())
        }
        guard let capability = capabilities.first(where: { $0.resourceType == parts[0] }) else {
            return outcome(404, code: "not-found", message: "Resource type not exposed.")
        }
        if parts.count == 2 && !isPostSearch {
            guard capability.read, validID(parts[1]) else {
                return outcome(404, code: "not-found", message: "Resource not available.")
            }
            guard items.allSatisfy({ $0.name == "_format" }) else { throw FHIRR4ServerError.invalidSearch }
            guard let resource = try await read(capability.resourceType, parts[1]) else {
                return outcome(404, code: "not-found", message: "Resource not found.")
            }
            guard resource.resourceType == capability.resourceType, resource.get().id?.value?.string == parts[1] else {
                throw FHIRR4ServerError.invalidConfiguration
            }
            return try readResponse(resource, request: request)
        }
        guard (parts.count == 1 || isPostSearch), capability.search else {
            return outcome(404, code: "not-found", message: "Interaction not exposed.")
        }
        let parsed = try parseSearch(items, capability: capability)
        let page = try await search(parsed)
        return try encoded(searchBundle(page, request: parsed, items: items))
    }

    private func parseSearch(_ items: [URLQueryItem], capability: FHIRR4ServerResourceCapability) throws -> FHIRR4ServerSearchRequest {
        let accepted = Set(capability.parameters.flatMap(\.acceptedNames) + ["_id", "_count", "_format", "_pageToken"])
        guard items.allSatisfy({ accepted.contains($0.name) }),
              ["_count", "_format", "_pageToken"].allSatisfy({ name in items.filter { $0.name == name }.count <= 1 }) else {
            throw FHIRR4ServerError.invalidSearch
        }
        let countItem = items.first { $0.name == "_count" }?.value
        let count: Int
        if let countItem, !countItem.isEmpty {
            guard countItem.allSatisfy({ $0.isASCII && $0.isNumber }), let value = Int(countItem), value <= maximumCount else {
                throw FHIRR4ServerError.invalidSearch
            }
            count = value
        } else { count = defaultCount }
        return .init(resourceType: capability.resourceType,
            parameters: items.filter { !["_count", "_format", "_pageToken"].contains($0.name) && !($0.value ?? "").isEmpty },
            count: count, pageToken: items.first { $0.name == "_pageToken" }?.value)
    }

    public func searchBundle(_ page: FHIRR4ServerSearchPage, request: FHIRR4ServerSearchRequest,
                             items: [URLQueryItem]) throws -> ModelsR4.Bundle {
        guard validID(request.resourceType), request.count >= 0, request.count <= maximumCount,
              page.resources.count <= request.count, page.total.map({ $0 >= page.resources.count && $0 <= Int(Int32.max) }) ?? true,
              page.nextPageToken.map({ !$0.isEmpty && $0.utf8.count <= 4096 }) ?? true,
              request.count != 0 || page.nextPageToken == nil else { throw FHIRR4ServerError.invalidConfiguration }
        let bundle = ModelsR4.Bundle(type: .init(.searchset))
        var ids = Set<String>()
        bundle.entry = try page.resources.map { resource in
            guard resource.resourceType == request.resourceType, let id = resource.get().id?.value?.string,
                  validID(id), ids.insert(id).inserted else { throw FHIRR4ServerError.invalidConfiguration }
            let entry = BundleEntry(); entry.resource = resource
            entry.fullUrl = FHIRPrimitive(FHIRURI(stringLiteral: resourceURL(request.resourceType, id).absoluteString))
            entry.search = BundleEntrySearch(); entry.search?.mode = .init(.match)
            return entry
        }
        if let total = page.total { bundle.total = .init(FHIRUnsignedInteger(Int32(total))) }
        bundle.link = [BundleLink(relation: "self", url: .init(FHIRURI(stringLiteral: searchURL(request.resourceType, items).absoluteString)))]
        if let next = page.nextPageToken {
            let nextItems = items.filter { $0.name != "_pageToken" } + [.init(name: "_pageToken", value: next)]
            bundle.link?.append(BundleLink(relation: "next", url: .init(FHIRURI(stringLiteral: searchURL(request.resourceType, nextItems).absoluteString))))
        }
        return bundle
    }

    private func readResponse(_ resource: ResourceProxy, request: FHIRHTTPRequest) throws -> FHIRHTTPResponse {
        var headers: [String: String] = [:]
        if let version = resource.get().meta?.versionId?.value?.string {
            guard validID(version) else { throw FHIRR4ServerError.invalidConfiguration }
            headers["ETag"] = "W/\"\(version)\""
        }
        let modified = resource.get().meta?.lastUpdated?.value.map { $0.description }.flatMap(Self.instantDate)
        if let modified { headers["Last-Modified"] = Self.httpDate.string(from: modified) }
        var unchanged = false
        if let condition = header(request, "If-None-Match") {
            unchanged = condition.split(separator: ",").contains { item in
                let tag = item.trimmingCharacters(in: .whitespaces)
                return tag == "*" || (headers["ETag"] != nil && tag.replacingOccurrences(of: "W/", with: "") == headers["ETag"]!.replacingOccurrences(of: "W/", with: ""))
            }
        } else if let condition = header(request, "If-Modified-Since"), let since = Self.httpDate.date(from: condition), let modified {
            unchanged = floor(modified.timeIntervalSince1970) <= since.timeIntervalSince1970
        }
        if unchanged { headers["Vary"] = "Accept"; headers["Cache-Control"] = "private, no-cache"; return .init(status: 304, headers: headers) }
        var response = try encoded(resource); response.headers.merge(headers) { _, new in new }; return response
    }

    private func acceptsJSON(_ request: FHIRHTTPRequest, items: [URLQueryItem]) -> Bool {
        let formats = items.filter { $0.name == "_format" }
        if !formats.isEmpty { return formats.count == 1 && ["json", "application/json", "application/fhir+json"].contains(formats[0].value ?? "") }
        guard let accept = header(request, "Accept") else { return true }
        var best: (specificity: Int, quality: Double)?
        for range in accept.split(separator: ",") {
            let parts = range.split(separator: ";").map { $0.trimmingCharacters(in: .whitespaces).lowercased() }
            guard let media = parts.first else { continue }
            let specificity: Int
            switch media { case "application/fhir+json", "application/json": specificity = 2
            case "application/*": specificity = 1; case "*/*": specificity = 0; default: continue }
            let quality: Double
            if let q = parts.first(where: { $0.hasPrefix("q=") }) {
                guard let parsed = Double(q.dropFirst(2)) else { return false }; quality = parsed
            } else { quality = 1 }
            guard (0...1).contains(quality) else { return false }
            if best == nil || specificity > best!.specificity || (specificity == best!.specificity && quality > best!.quality) { best = (specificity, quality) }
        }
        return (best?.quality ?? 0) > 0
    }

    private func encoded<T: Encodable>(_ value: T) throws -> FHIRHTTPResponse {
        let body = try JSONEncoder().encode(value)
        guard body.count <= maximumResponseBytes else { throw FHIRR4ServerError.invalidConfiguration }
        return .init(status: 200, headers: ["Content-Type": "application/fhir+json", "Vary": "Accept", "Cache-Control": "private, no-cache"], body: body)
    }
    private func outcome(_ status: Int, code: String, message: String) -> FHIRHTTPResponse {
        // Fixed, internal codes/messages only; no reflection of URL, PHI or errors.
        let value = OperationOutcome(issue: [OperationOutcomeIssue(code: .init(IssueType(rawValue: code)!), severity: .init(.error))])
        value.issue[0].diagnostics = .init(FHIRString(message))
        return .init(status: status, headers: ["Content-Type": "application/fhir+json", "Cache-Control": "no-store", "Vary": "Accept"], body: (try? JSONEncoder().encode(value)) ?? Data())
    }
    private func model<T: Decodable>(_ object: [String: Any], as: T.Type) throws -> T {
        try JSONDecoder().decode(T.self, from: JSONSerialization.data(withJSONObject: object))
    }
    private func resourceURL(_ type: String, _ id: String) -> URL { baseURL.appendingPathComponent(type).appendingPathComponent(id) }
    private func searchURL(_ type: String, _ items: [URLQueryItem]) -> URL {
        var components = URLComponents(url: baseURL.appendingPathComponent(type), resolvingAgainstBaseURL: false)!
        components.queryItems = items.isEmpty ? nil : items; return components.url!
    }
    private func header(_ request: FHIRHTTPRequest, _ name: String) -> String? {
        request.headers.first { $0.key.caseInsensitiveCompare(name) == .orderedSame }?.value
    }
    private func validID(_ value: String) -> Bool {
        !value.isEmpty && value.utf8.count <= 64 && value.allSatisfy { $0.isASCII && ($0.isLetter || $0.isNumber || $0 == "-" || $0 == ".") }
    }
    private func validPercentEncoding(_ value: String) -> Bool {
        let bytes = Array(value.utf8); var index = 0
        while index < bytes.count {
            if bytes[index] == 37 {
                guard index + 2 < bytes.count,
                      bytes[index + 1...index + 2].allSatisfy({ (48...57).contains($0) || (65...70).contains($0) || (97...102).contains($0) }) else { return false }
                index += 3
            } else { index += 1 }
        }
        return true
    }
    private static var httpDate: DateFormatter {
        let formatter = DateFormatter(); formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0); formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss 'GMT'"; return formatter
    }
    private static func instantDate(_ value: String) -> Date? {
        let formatter = ISO8601DateFormatter(); formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: value) ?? ISO8601DateFormatter().date(from: value)
    }
}
