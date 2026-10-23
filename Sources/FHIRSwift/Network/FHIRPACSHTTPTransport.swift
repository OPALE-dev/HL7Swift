import Foundation

/// Adapts PACS JSON on a caller-owned HTTP transport. Callers use R4 interchange
/// resources and an explicit wire release/base URL; HTTP metadata remains intact.
/// Can be shared with FHIRR4RESTClient, including its safe pagination handling.
public struct FHIRPACSHTTPTransport: FHIRHTTPTransport {
    public let release: FHIRRelease
    private let transport: any FHIRHTTPTransport
    public init(release: FHIRRelease, transport: any FHIRHTTPTransport) {
        self.release = release; self.transport = transport
    }
    public func send(_ request: FHIRHTTPRequest) async throws -> FHIRHTTPResponse {
        var wire = request
        if let body = request.body, !body.isEmpty {
            wire.body = try FHIRPACSCodec.convert(body, from: .r4, to: release)
        }
        wire.headers = request.headers.filter { !["accept", "content-type", "content-length"].contains($0.key.lowercased()) }
        wire.headers["Accept"] = "application/fhir+json; fhirVersion=" + release.rawValue
        if wire.body != nil { wire.headers["Content-Type"] = "application/fhir+json; fhirVersion=" + release.rawValue }
        var response = try await transport.send(wire)
        if !response.body.isEmpty {
            if response.status >= 400, (try? JSONSerialization.jsonObject(with: response.body) as? [String: Any])?["resourceType"] as? String != "OperationOutcome" { return response }
            if let object = try? JSONSerialization.jsonObject(with: response.body) as? [String: Any],
               object["resourceType"] as? String == "CapabilityStatement", object["fhirVersion"] as? String != release.rawValue {
                throw FHIRPACSConversionError(path: "$.fhirVersion", reason: "Partner does not advertise the configured FHIR release")
            }
            response.body = try FHIRPACSCodec.convert(response.body, from: release, to: .r4)
            response.headers = response.headers.filter { $0.key.lowercased() != "content-length" }
        }
        return response
    }
}
