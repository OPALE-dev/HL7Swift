import Foundation

public struct CDAName: Equatable, Sendable {
    public var given: [String] = []
    public var family: [String] = []
    public var prefix: [String] = []
    public var suffix: [String] = []
    public init() {}
}

/// Header assertions only. Identifier authorities and conflicts are resolved
/// by the receiving application; no patient merge is inferred.
public struct CDARecordTarget: Equatable, Sendable {
    public var identifiers: [CDADocument.Identifier] = []
    public var names: [CDAName] = []
    public var birthTime: String?
    public var administrativeGenderCode: String?
    public init() {}
}

/// Readable section projection, in document order. `parentIndex` preserves
/// nesting in `CDADocument.sections`. Narrative is plain text, never executable
/// XHTML, and is not a replacement for the source XML or signed document.
public struct CDASection: Equatable, Sendable {
    public var parentIndex: Int?
    public var identifier: CDADocument.Identifier?
    public var templateIdentifiers: [CDADocument.Identifier] = []
    public var code: String?
    public var codeSystem: String?
    public var title: String?
    public var narrativeText: String = ""
    public var entryCount: Int = 0
    public init(parentIndex: Int? = nil) { self.parentIndex = parentIndex }
}
