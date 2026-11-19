import HL7Core
import HL7V2
import ModelsR4

/// Why source information was not represented in the mapped output.
public enum HL7MappingLossReason: String, Codable, Equatable, Sendable {
    case unsupportedMessage
    case unmappedSegment
    case skippedSegment
}

/// A known loss, identified without copying potentially sensitive HL7 values.
public struct HL7MappingLoss: Codable, Equatable, Sendable {
    public let sourcePath: String
    public let reason: HL7MappingLossReason

    public init(sourcePath: String, reason: HL7MappingLossReason) {
        self.sourcePath = sourcePath
        self.reason = reason
    }
}

/// The implementation and versions used for a mapping attempt.
public struct HL7MappingProvenance: Codable, Equatable, Sendable {
    public let converter: String
    public let sourceVersion: String?
    public let targetVersion: String

    public init(converter: String, sourceVersion: String?, targetVersion: String) {
        self.converter = converter
        self.sourceVersion = sourceVersion
        self.targetVersion = targetVersion
    }
}

/// Output plus diagnostics, provenance and known losses for one transformation.
public struct HL7MappingResult<Output> {
    public let output: Output?
    public let report: HL7DiagnosticReport
    public let provenance: HL7MappingProvenance
    public let losses: [HL7MappingLoss]

    public init(
        output: Output?,
        report: HL7DiagnosticReport,
        provenance: HL7MappingProvenance,
        losses: [HL7MappingLoss]
    ) {
        self.output = output
        self.report = report
        self.provenance = provenance
        self.losses = losses
    }
}

public extension HL72FHIRR4Converter {
    /// Maps with an explicit account of known omissions. The legacy `convert`
    /// methods retain their throwing and optional-returning behavior.
    ///
    /// This API does not certify FHIR conformance or field-level completeness.
    func mapWithReport(_ message: Message) -> HL7MappingResult<ModelsR4.Bundle> {
        let stage = "v2-to-fhir-r4"
        let version = message.messageVersion?.rawValue
        let provenance = HL7MappingProvenance(
            converter: "HL72FHIRR4Converter",
            sourceVersion: version,
            targetVersion: "R4"
        )

        guard supportedMessages.contains(message.type.name) else {
            let loss = HL7MappingLoss(sourcePath: "Message", reason: .unsupportedMessage)
            let diagnostic = HL7Diagnostic(
                code: "HL7MAPPING-UNSUPPORTED-MESSAGE",
                severity: .warning,
                message: "This message type is not supported by the HL7 v2 to FHIR R4 converter.",
                standard: .v2,
                stage: stage,
                version: version,
                location: .init(path: "Message"),
                causeCode: "UNSUPPORTED_MESSAGE"
            )
            return HL7MappingResult(
                output: nil,
                report: HL7DiagnosticReport(
                    stages: [.init(identifier: stage, status: .incomplete)],
                    diagnostics: [diagnostic]
                ),
                provenance: provenance,
                losses: [loss]
            )
        }

        var losses: [HL7MappingLoss] = []
        var diagnostics: [HL7Diagnostic] = []
        var occurrences: [String: Int] = [:]
        for segment in message.allSegments {
            let occurrence = occurrences[segment.code, default: 0] + 1
            occurrences[segment.code] = occurrence
            let path = "\(segment.code)[\(occurrence)]"
            let mapped = ["MSH", "PID", "PV1"].contains(segment.code)
            let skipped = mapped && (
                occurrence > 1
                    || (segment.code == "PV1" && (message[HL7.PID] == nil || segment[2] == nil))
            )
            guard !mapped || skipped else { continue }

            let reason: HL7MappingLossReason = skipped ? .skippedSegment : .unmappedSegment
            losses.append(.init(sourcePath: path, reason: reason))
            diagnostics.append(HL7Diagnostic(
                code: skipped ? "HL7MAPPING-SKIPPED-SEGMENT" : "HL7MAPPING-UNMAPPED-SEGMENT",
                severity: .warning,
                message: skipped
                    ? "The segment was not represented in the output."
                    : "The segment has no mapping in this converter.",
                standard: .v2,
                stage: stage,
                version: version,
                location: .init(path: path),
                causeCode: skipped ? "SEGMENT_NOT_EMITTED" : "NO_SEGMENT_MAPPING"
            ))
        }

        let output: ModelsR4.Bundle?
        do {
            output = try convert(message)
        } catch {
            output = nil
            diagnostics.append(HL7Diagnostic(
                code: "HL7MAPPING-CONVERSION-FAILED",
                severity: .error,
                message: "The HL7 v2 to FHIR R4 conversion failed.",
                standard: .v2,
                stage: stage,
                version: version,
                causeCode: "CONVERSION_FAILED"
            ))
        }

        // The converter maps only a subset of fields even in the three handled
        // segments, so an absence of known losses cannot imply completeness.
        return HL7MappingResult(
            output: output,
            report: HL7DiagnosticReport(
                stages: [.init(identifier: stage, status: .incomplete)],
                diagnostics: diagnostics
            ),
            provenance: provenance,
            losses: losses
        )
    }
}
