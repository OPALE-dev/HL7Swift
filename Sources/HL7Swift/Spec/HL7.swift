import Foundation

/// Autonomous historical API. Native working models support the clinical
/// families documented in NativeV2Models; no schema files are read at runtime.
public struct HL7 {
    var validator = DefaultValidator()
    private let versions: [Version: Versioned]

    public init() throws {
        versions = [
            .v21: try V21(.v21), .v23: try V23(.v23), .v231: try V231(.v231),
            .v24: try V24(.v24), .v25: try V25(.v25), .v251: try V251(.v251),
            .v26: try V26(.v26), .v27: try V27(.v27), .v271: try V271(.v271),
            .v28: try V28(.v28), .v281: try V281(.v281), .v282: try V282(.v282)
        ]
    }

    public func spec(ofVersion version: Version) -> Versioned? { versions[version] }
    struct MessageType: Typable { var name: String }
    struct UnknowMessageType: Typable { var name: String }
    class UnknowVersion: Versioned {}

    public func parse(_ string: String, validator: HL7Validator? = nil) throws -> Message? {
        let message = try Message(string, hl7: self)
        if let validator, validator.validate(message, level: .version).contains(where: { $0.type == .error }) { return nil }
        return message
    }
    public func build(_ type: Typable, version: Version, preloadSegments: [String] = []) throws -> Message? {
        guard let model = spec(ofVersion: version) else { return nil }
        return try Message(type, spec: model, preloadSegments: preloadSegments)
    }
    public func validate(_ message: Message) -> [ValidationResult] { validator.validate(message, level: .version) }
}

public protocol Typable { var name: String { get } }
public protocol Versionable {
    var version: Version { get }
    func type(forName name: String) -> Typable?
}

/// Native, deliberately partial working model used by the compatibility API.
/// Model availability never establishes release-specific normative conformance.
public class Versioned: NSObject, Versionable {
    public func type(forName name: String) -> Typable? { nil }
    public var version: Version
    public var messages: [String: SpecMessage] = [:]
    public var dataTypes: [String: DataType] = [:]
    public var fields: [String: [Field]] = [:]
    public var segments: [String: Segment] = [:]
    public var groups: [String: [String: Segment]] = [:]

    init(_ version: Version) throws {
        self.version = version
        super.init()
        reloadNativeModels()
    }

    public func reloadNativeModels() {
        messages.removeAll(); fields.removeAll(); segments.removeAll(); groups.removeAll(); dataTypes.removeAll()
        NativeV2Models.install(on: self)
    }

    @available(*, deprecated, message: "No XML is loaded. Use reloadNativeModels().")
    public func loadXML() throws { reloadNativeModels() }
}
