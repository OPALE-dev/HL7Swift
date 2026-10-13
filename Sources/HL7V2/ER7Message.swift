import Foundation

public enum ER7Error: Error, Equatable, Sendable {
    case messageTooLarge, missingHeader, invalidDelimiters, invalidSegment(Int)
    case incompleteHeader, unsupportedVersion(String), invalidLineEnding
    case invalidPosition, invalidFieldValue, invalidEncoding
}

/// Tolerance concerns syntax and declared versions, never clinical meaning.
public struct ER7ParsingPolicy: Sendable, Equatable {
    public var acceptNonstandardLineEndings: Bool
    public var acceptedVersions: Set<String>?
    public var interpretationVersion: String?
    public var maximumBytes: Int

    public init(acceptNonstandardLineEndings: Bool = true,
                acceptedVersions: Set<String>? = nil, interpretationVersion: String? = nil,
                maximumBytes: Int = 8 * 1024 * 1024) {
        self.acceptNonstandardLineEndings = acceptNonstandardLineEndings
        self.acceptedVersions = acceptedVersions
        self.interpretationVersion = interpretationVersion
        self.maximumBytes = maximumBytes
    }

    public static let interoperable = Self()
    public static let strict = Self(acceptNonstandardLineEndings: false,
        acceptedVersions: ["2.1", "2.2", "2.3", "2.3.1", "2.4", "2.5", "2.5.1", "2.6", "2.7", "2.7.1", "2.8", "2.8.1", "2.8.2", "2.9", "2.9.1"])
}

public struct ER7Delimiters: Equatable, Sendable {
    public let field: Character
    public let component: Character
    public let repetition: Character
    public let escape: Character
    public let subcomponent: Character
    public let truncation: Character?
}

/// Distinguishes an absent field, an empty value and the HL7 explicit null.
public enum ER7Value: Equatable, Sendable {
    case absent, empty, null, value(String)

    public init(raw: String?) {
        switch raw {
        case nil: self = .absent
        case "": self = .empty
        case "\"\"": self = .null
        case .some(let value): self = .value(value)
        }
    }
}

public struct ER7Segment: Equatable, Sendable {
    public let code: String
    /// One-based HL7 positions. MSH-1 and MSH-2 are represented explicitly.
    public private(set) var fields: [String]
    public subscript(field: Int) -> String? {
        guard field > 0 && field <= fields.count else { return nil }
        return fields[field - 1]
    }

    fileprivate init(code: String, fields: [String]) { self.code = code; self.fields = fields }
    fileprivate mutating func set(_ value: String, at field: Int) {
        if fields.count < field { fields += Array(repeating: "", count: field - fields.count) }
        fields[field - 1] = value
    }
}

/// Resource-free, value-semantic ER7 message for application adapters.
/// Unknown versions and Z-segments can be preserved without silently switching
/// to a different specification. This is a syntax parser, not a profile validator.
public struct ER7Message: Equatable, Sendable {
    public let delimiters: ER7Delimiters
    public private(set) var segments: [ER7Segment]
    public let declaredVersion: String
    public let interpretationVersion: String
    public let notices: [String]
    public let lineEnding: String
    private let endsWithLineEnding: Bool

    public init(_ text: String, policy: ER7ParsingPolicy = .interoperable) throws {
        guard text.utf8.count <= policy.maximumBytes else { throw ER7Error.messageTooLarge }
        guard text.hasPrefix("MSH"), text.count >= 8 else { throw ER7Error.missingHeader }
        let characters = Array(text.prefix(9))
        let field = characters[3]
        let firstLine = text.components(separatedBy: .newlines).first ?? text
        let header = firstLine.split(separator: field, omittingEmptySubsequences: false).map(String.init)
        guard header.count >= 12 else { throw ER7Error.incompleteHeader }
        let encoding = Array(header[1])
        guard (4...5).contains(encoding.count) else { throw ER7Error.invalidDelimiters }
        let all = [field] + encoding
        guard Set(all).count == all.count,
              all.allSatisfy({ character in
                  character.unicodeScalars.count == 1 && character.unicodeScalars.allSatisfy { (33...126).contains($0.value) }
              }) else { throw ER7Error.invalidDelimiters }
        delimiters = .init(field: field, component: encoding[0], repetition: encoding[1],
                           escape: encoding[2], subcomponent: encoding[3], truncation: encoding.count == 5 ? encoding[4] : nil)

        let hasLF = text.contains("\n")
        guard !hasLF || policy.acceptNonstandardLineEndings else { throw ER7Error.invalidLineEnding }
        lineEnding = text.contains("\r\n") ? "\r\n" : (hasLF && !text.contains("\r") ? "\n" : "\r")
        endsWithLineEnding = text.hasSuffix("\r") || text.hasSuffix("\n")
        let normalized = text.replacingOccurrences(of: "\r\n", with: "\r").replacingOccurrences(of: "\n", with: "\r")
        var lines = normalized.components(separatedBy: "\r")
        if lines.last == "" { lines.removeLast() }
        var parsed: [ER7Segment] = []
        for (offset, line) in lines.enumerated() {
            let parts = line.split(separator: field, omittingEmptySubsequences: false).map(String.init)
            let code = parts[0]
            guard code.utf8.count == 3, (code.hasPrefix("Z") || code.utf8.prefix(2).allSatisfy({ (65...90).contains($0) })), code.utf8.allSatisfy({ (65...90).contains($0) || (48...57).contains($0) }),
                  (offset == 0 || code != "MSH"), !line.contains("\u{0b}"), !line.contains("\u{1c}") else {
                throw ER7Error.invalidSegment(offset + 1)
            }
            let fields = code == "MSH" ? [String(field)] + Array(parts.dropFirst()) : Array(parts.dropFirst())
            parsed.append(.init(code: code, fields: fields))
        }
        segments = parsed
        declaredVersion = header[11].split(separator: delimiters.component, omittingEmptySubsequences: false).first.map(String.init) ?? ""
        guard !declaredVersion.isEmpty else { throw ER7Error.incompleteHeader }
        if let versions = policy.acceptedVersions, !versions.contains(declaredVersion) {
            throw ER7Error.unsupportedVersion(declaredVersion)
        }
        interpretationVersion = policy.interpretationVersion ?? declaredVersion
        var warnings: [String] = []
        if hasLF { warnings.append("ER7-NONSTANDARD-LINE-ENDINGS") }
        if interpretationVersion != declaredVersion { warnings.append("ER7-VERSION-INTERPRETATION-OVERRIDE") }
        notices = warnings
    }

    /// Decode bytes using the connector's explicitly negotiated character set.
    public init(data: Data, encoding: String.Encoding = .utf8, policy: ER7ParsingPolicy = .interoperable) throws {
        guard data.count <= policy.maximumBytes else { throw ER7Error.messageTooLarge }
        guard let text = String(data: data, encoding: encoding) else { throw ER7Error.invalidEncoding }
        try self.init(text, policy: policy)
    }

    public func segment(_ code: String, occurrence: Int = 1) -> ER7Segment? {
        guard occurrence > 0 else { return nil }
        return segments.filter { $0.code == code }.dropFirst(occurrence - 1).first
    }

    /// One-based positions at every level; nil preserves the distinction from an
    /// explicitly empty component. Escapes are decoded only on explicit request.
    public func rawValue(segment code: String, occurrence: Int = 1, field: Int,
                         repetition: Int = 1, component: Int? = nil, subcomponent: Int? = nil) -> String? {
        guard repetition > 0, let raw = segment(code, occurrence: occurrence)?[field] else { return nil }
        if code == "MSH" && field <= 2 { return repetition == 1 && component == nil && subcomponent == nil ? raw : nil }
        let repeats = raw.split(separator: delimiters.repetition, omittingEmptySubsequences: false)
        guard repetition <= repeats.count else { return nil }
        var result = String(repeats[repetition - 1])
        if let component {
            let parts = result.split(separator: delimiters.component, omittingEmptySubsequences: false)
            guard component > 0, component <= parts.count else { return nil }
            result = String(parts[component - 1])
        }
        if let subcomponent {
            let parts = result.split(separator: delimiters.subcomponent, omittingEmptySubsequences: false)
            guard subcomponent > 0, subcomponent <= parts.count else { return nil }
            result = String(parts[subcomponent - 1])
        }
        return result
    }

    public mutating func setRawValue(_ value: String, segment code: String, occurrence: Int = 1, field: Int) throws {
        guard field > 0, occurrence > 0, !(code == "MSH" && [1, 2, 12].contains(field)),
              !value.contains(delimiters.field), !value.contains(where: { "\r\n\u{0b}\u{1c}".contains($0) }) else { throw ER7Error.invalidFieldValue }
        let indices = segments.indices.filter { segments[$0].code == code }
        guard occurrence <= indices.count else { throw ER7Error.invalidPosition }
        segments[indices[occurrence - 1]].set(value, at: field)
    }

    public func serialized(lineEnding override: String? = nil) -> String {
        let separator = String(delimiters.field)
        let lines = segments.map { segment in
            let fields = segment.code == "MSH" ? Array(segment.fields.dropFirst()) : segment.fields
            return segment.code + (fields.isEmpty ? "" : separator + fields.joined(separator: separator))
        }
        let ending = override ?? lineEnding
        return lines.joined(separator: ending) + (endsWithLineEnding ? ending : "")
    }

    /// Returns display text. Unknown/local escape sequences remain intact.
    public func unescape(_ raw: String, encoding: String.Encoding = .utf8) -> String {
        let pieces = raw.split(separator: delimiters.escape, omittingEmptySubsequences: false).map(String.init)
        var output = ""
        for (index, piece) in pieces.enumerated() {
            if index % 2 == 0 { output += piece; continue }
            let known: [String: String] = ["F": String(delimiters.field), "S": String(delimiters.component),
                "R": String(delimiters.repetition), "T": String(delimiters.subcomponent), "E": String(delimiters.escape), ".br": "\n"]
            if index == pieces.count - 1 { output += String(delimiters.escape) + piece }
            else if let value = known[piece] { output += value }
            else if piece.hasPrefix("X"), piece.count % 2 == 1 {
                let hex = Array(piece.dropFirst())
                let bytes = stride(from: 0, to: hex.count, by: 2).compactMap { UInt8(String(hex[$0...($0 + 1)]), radix: 16) }
                if bytes.count == hex.count / 2, let value = String(data: Data(bytes), encoding: encoding) { output += value }
                else { output += String(delimiters.escape) + piece + String(delimiters.escape) }
            } else { output += String(delimiters.escape) + piece + String(delimiters.escape) }
        }
        return output
    }

    public func escape(_ text: String) -> String {
        let codes: [Character: String] = [delimiters.field: "F", delimiters.component: "S",
            delimiters.repetition: "R", delimiters.subcomponent: "T", delimiters.escape: "E", "\r": "X0D", "\n": "X0A"]
        return text.unicodeScalars.map { scalar in
            codes[Character(String(scalar))].map { String(delimiters.escape) + $0 + String(delimiters.escape) } ?? String(scalar)
        }.joined()
    }
}
