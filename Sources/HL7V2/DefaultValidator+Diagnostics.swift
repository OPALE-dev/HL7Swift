import HL7Core
import HL7Swift

public extension DefaultValidator {
    /// Runs the existing HL7 v2 checks and presents their findings as a scoped report.
    ///
    /// The legacy segment, field and datatype checks do not yet cover every rule
    /// in the embedded specifications. Those stages remain incomplete even when
    /// the legacy validator finds no problem. Parsing happens before this call
    /// and is not represented as a validation stage here.
    func validateReport(_ message: Message, level: ValidationLevel = .version) -> HL7DiagnosticReport {
        let results = validate(message, level: level)
        let hasMatchingSpecification = message.specMessage != nil
            && message.version == message.messageVersion
            && (message.forcedVersion == nil || message.forcedVersion == message.messageVersion)

        let levels: [ValidationLevel] = [.version, .segments, .fields, .datatypes]
        let requestedLevels = levels.filter { $0.rawValue <= level.rawValue }
        let stages = requestedLevels.map { checkedLevel in
            HL7ValidationStage(
                identifier: checkedLevel.diagnosticStage,
                status: checkedLevel == .version && hasMatchingSpecification ? .complete : .incomplete
            )
        }

        let diagnostics = results.compactMap { result -> HL7Diagnostic? in
            guard result.type != .none else { return nil }
            return HL7Diagnostic(
                code: "HL7V2-LEGACY-\(result.level.diagnosticCode)-\(result.type.diagnosticCode)",
                severity: result.type.diagnosticSeverity,
                message: result.text,
                standard: .v2,
                stage: result.level.diagnosticStage,
                version: message.version?.rawValue
            )
        }

        return HL7DiagnosticReport(stages: stages, diagnostics: diagnostics)
    }
}

private extension ValidationLevel {
    var diagnosticStage: String {
        switch self {
        case .version: return "v2.version"
        case .segments: return "v2.segments"
        case .fields: return "v2.fields"
        case .datatypes: return "v2.datatypes"
        }
    }

    var diagnosticCode: String {
        switch self {
        case .version: return "VERSION"
        case .segments: return "SEGMENTS"
        case .fields: return "FIELDS"
        case .datatypes: return "DATATYPES"
        }
    }
}

private extension ResultType {
    var diagnosticSeverity: HL7DiagnosticSeverity {
        switch self {
        case .none, .notice: return .information
        case .warning: return .warning
        case .error: return .error
        }
    }

    var diagnosticCode: String {
        switch self {
        case .none: return "NONE"
        case .notice: return "NOTICE"
        case .warning: return "WARNING"
        case .error: return "ERROR"
        }
    }
}
