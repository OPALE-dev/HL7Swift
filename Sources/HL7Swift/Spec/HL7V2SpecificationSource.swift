import Foundation

/// An explicitly supplied, local set of HL7 v2 XML artefacts.
///
/// HL7Swift never ships HL7 v2 specifications. Applications that are entitled
/// to use a particular release may opt into specification-backed construction
/// and validation by passing a directory in this layout:
///
/// ```text
/// <directory>/v2.5.1/datatypes.xsd
/// <directory>/v2.5.1/fields.xsd
/// <directory>/v2.5.1/messages.xsd
/// <directory>/v2.5.1/segments.xsd
/// <directory>/v2.5.1/messages/ADT_A01.xsd
/// ```
///
/// The caller is responsible for obtaining, checking and licensing the
/// artefacts. This type deliberately performs no download or network access.
public struct HL7V2SpecificationSource: Sendable, Equatable {
    public let directory: URL
    /// Optional version-to-directory map for locally supplied flat HL7 archives.
    public let versionDirectories: [String: URL]

    public init(directory: URL, versionDirectories: [String: URL] = [:]) {
        self.directory = directory.standardizedFileURL
        self.versionDirectories = versionDirectories.mapValues(\.standardizedFileURL)
    }

    func url(for relativePath: String) -> URL {
        let parts = relativePath.split(separator: "/").map(String.init)
        if let first = parts.first, let versionDirectory = versionDirectories[String(first.dropFirst())] {
            let nested = versionDirectory.appendingPathComponent(parts.dropFirst().joined(separator: "/"))
            if FileManager.default.isReadableFile(atPath: nested.path) { return nested }
            return versionDirectory.appendingPathComponent(parts.last ?? "")
        }
        return directory.appendingPathComponent(relativePath, isDirectory: false)
    }
}
