/// The format whose content or rules produced a diagnostic.
public enum HL7Standard: String, Codable, Equatable, Sendable {
    case v2
    case fhir
    case cda
}

/// The impact of one finding. A warning does not make a complete report invalid.
public enum HL7DiagnosticSeverity: String, Codable, Equatable, Sendable {
    case information
    case warning
    case error
}

/// A location in the input. `path` uses the notation of the relevant format.
public struct HL7DiagnosticLocation: Codable, Equatable, Sendable {
    public let path: String?
    public let line: Int?
    public let column: Int?

    public init(path: String? = nil, line: Int? = nil, column: Int? = nil) {
        self.path = path
        self.line = line
        self.column = column
    }
}

/// Identifies the rule or versioned artifact behind a finding, when known.
public struct HL7DiagnosticProvenance: Codable, Equatable, Sendable {
    public let rule: String?
    public let artifact: String?
    public let artifactVersion: String?

    public init(rule: String? = nil, artifact: String? = nil, artifactVersion: String? = nil) {
        self.rule = rule
        self.artifact = artifact
        self.artifactVersion = artifactVersion
    }
}

/// A structured finding shared by HL7 v2, FHIR, CDA and mappings.
///
/// `code` is a stable machine-readable identifier. `message` is for display and
/// may change or be localized. `causeCode` identifies a lower-level failure
/// without embedding raw input, credentials or an arbitrary error description.
public struct HL7Diagnostic: Codable, Equatable, Sendable {
    public let code: String
    public let severity: HL7DiagnosticSeverity
    public let message: String
    public let standard: HL7Standard
    public let version: String?
    public let profile: String?
    public let stage: String
    public let location: HL7DiagnosticLocation?
    public let provenance: HL7DiagnosticProvenance?
    public let causeCode: String?

    public init(
        code: String,
        severity: HL7DiagnosticSeverity,
        message: String,
        standard: HL7Standard,
        stage: String,
        version: String? = nil,
        profile: String? = nil,
        location: HL7DiagnosticLocation? = nil,
        provenance: HL7DiagnosticProvenance? = nil,
        causeCode: String? = nil
    ) {
        self.code = code
        self.severity = severity
        self.message = message
        self.standard = standard
        self.version = version
        self.profile = profile
        self.stage = stage
        self.location = location
        self.provenance = provenance
        self.causeCode = causeCode
    }
}
