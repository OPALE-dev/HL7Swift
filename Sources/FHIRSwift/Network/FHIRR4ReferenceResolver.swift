import Foundation
import ModelsR4

public enum FHIRReferenceResolutionError: Error, Equatable, Sendable {
    case invalidReference, missing, ambiguous, unsupportedVersionedReference
}

/// Resolves references already present in a Bundle or explicitly provided
/// containing resource. It never contacts a server or follows external links.
/// Resource models remain caller-owned mutable objects; do not mutate their
/// identifiers while using this reading index.
public struct FHIRR4ReferenceResolver {
    private let fullURLs: [String: [ResourceProxy]]
    private let relativeIDs: [String: [ResourceProxy]]

    public init(bundle: ModelsR4.Bundle) {
        var full: [String: [ResourceProxy]] = [:]
        var relative: [String: [ResourceProxy]] = [:]
        for entry in bundle.entry ?? [] {
            guard let resource = entry.resource else { continue }
            if let url = entry.fullUrl?.value?.url.absoluteString { full[url, default: []].append(resource) }
            if let id = resource.get().id?.value?.string {
                relative[resource.resourceType + "/" + id, default: []].append(resource)
            }
        }
        fullURLs = full; relativeIDs = relative
    }

    public func resolve(_ reference: Reference, containingResource: DomainResource? = nil,
                        containingFullURL: URL? = nil) throws -> ResourceProxy {
        guard let value = reference.reference?.value?.string else { throw FHIRReferenceResolutionError.invalidReference }
        return try resolve(value, containingResource: containingResource, containingFullURL: containingFullURL)
    }

    public func resolve(_ reference: String, containingResource: DomainResource? = nil,
                        containingFullURL: URL? = nil) throws -> ResourceProxy {
        guard !reference.isEmpty else { throw FHIRReferenceResolutionError.invalidReference }
        if reference.contains("/_history/") { throw FHIRReferenceResolutionError.unsupportedVersionedReference }
        if reference.hasPrefix("#") {
            let id = String(reference.dropFirst())
            if id.isEmpty {
                guard let containingResource else { throw FHIRReferenceResolutionError.missing }
                return ResourceProxy(with: containingResource)
            }
            let matches = (containingResource?.contained ?? []).filter { $0.get().id?.value?.string == id }
            return try unique(matches)
        }
        if let exact = fullURLs[reference] { return try unique(exact) }
        guard let url = URL(string: reference) else { throw FHIRReferenceResolutionError.invalidReference }
        // Absolute references and URNs must match a Bundle fullUrl exactly.
        if url.scheme != nil { throw FHIRReferenceResolutionError.missing }
        let parts = reference.split(separator: "/", omittingEmptySubsequences: false)
        guard parts.count == 2, !parts[0].isEmpty, !parts[1].isEmpty,
              url.query == nil, url.fragment == nil, !parts.contains("..") else {
            throw FHIRReferenceResolutionError.invalidReference
        }
        if let fullURL = containingFullURL, ["http", "https"].contains(fullURL.scheme ?? "") {
            // fullUrl is base/type/id. Resolve under that service base, not
            // under the containing resource's type directory.
            let base = fullURL.deletingLastPathComponent().deletingLastPathComponent()
            let absolute = base.appendingPathComponent(String(parts[0])).appendingPathComponent(String(parts[1])).absoluteString
            return try unique(fullURLs[absolute] ?? [])
        }
        return try unique(relativeIDs[reference] ?? [])
    }

    private func unique(_ matches: [ResourceProxy]) throws -> ResourceProxy {
        guard !matches.isEmpty else { throw FHIRReferenceResolutionError.missing }
        guard matches.count == 1 else { throw FHIRReferenceResolutionError.ambiguous }
        return matches[0]
    }
}
