/// Whether one planned validation stage ran with all its required inputs.
public enum HL7ValidationStageStatus: String, Codable, Equatable, Sendable {
    case complete
    case incomplete
    case notRun
}

/// One validation stage and its completion state.
public struct HL7ValidationStage: Codable, Equatable, Sendable {
    public let identifier: String
    public let status: HL7ValidationStageStatus

    public init(identifier: String, status: HL7ValidationStageStatus) {
        self.identifier = identifier
        self.status = status
    }
}

/// The result of validation, distinct from the severity of any one finding.
public enum HL7ValidationOutcome: String, Codable, Equatable, Sendable {
    case valid
    case invalid
    case indeterminate
}

/// A complete or partial validation report with machine-readable findings.
///
/// An error proves the checked input invalid even when other stages are
/// incomplete. Without errors, at least one completed stage and no incomplete
/// or unrun stages are required for `valid`.
public struct HL7DiagnosticReport: Codable, Equatable, Sendable {
    public let stages: [HL7ValidationStage]
    public let diagnostics: [HL7Diagnostic]

    public init(stages: [HL7ValidationStage], diagnostics: [HL7Diagnostic] = []) {
        self.stages = stages
        self.diagnostics = diagnostics
    }

    public var outcome: HL7ValidationOutcome {
        if diagnostics.contains(where: { $0.severity == .error }) {
            return .invalid
        }
        if stages.isEmpty || stages.contains(where: { $0.status != .complete }) {
            return .indeterminate
        }
        return .valid
    }

    /// A concise text representation for logs or command-line tools.
    public func renderText() -> String {
        var lines = ["Validation: \(outcome.rawValue)"]
        lines.append(contentsOf: stages.map { "Stage \($0.identifier): \($0.status.rawValue)" })
        lines.append(contentsOf: diagnostics.map { diagnostic in
            let path = diagnostic.location?.path.map { " \($0)" } ?? ""
            return "[\(diagnostic.severity.rawValue)] \(diagnostic.code)\(path): \(diagnostic.message)"
        })
        return lines.joined(separator: "\n")
    }
}
