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

    public init(directory: URL) {
        self.directory = directory.standardizedFileURL
    }

    func url(for relativePath: String) -> URL {
        directory.appendingPathComponent(relativePath, isDirectory: false)
    }
}
