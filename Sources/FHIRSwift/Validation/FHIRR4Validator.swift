import Foundation
import HL7Core
import ModelsR4

/// Performs bounded structural checks on a FHIR R4 JSON resource.
///
/// This is not a profile, invariant or terminology validator. A successfully
/// decoded model therefore remains indeterminate as to FHIR conformance.
public struct FHIRR4Validator {
    public init() {}

    public func validateJSON(_ data: Data) -> HL7DiagnosticReport {
        let syntaxStage = "fhir.r4.json"
        let modelStage = "fhir.r4.model"
        let remainingStages: [HL7ValidationStage] = [
            .init(identifier: "fhir.r4.profiles", status: .notRun),
            .init(identifier: "fhir.r4.invariants", status: .notRun),
            .init(identifier: "fhir.r4.terminology", status: .notRun),
        ]

        let json: Any
        do {
            json = try JSONSerialization.jsonObject(with: data)
        } catch {
            return report(
                syntax: .incomplete,
                model: .notRun,
                remaining: remainingStages,
                diagnostic: finding(
                    code: "FHIRR4-JSON-MALFORMED",
                    message: "The input is not valid JSON.",
                    stage: syntaxStage,
                    path: "$",
                    causeCode: "JSON_PARSE_FAILED"
                )
            )
        }

        guard let object = json as? [String: Any] else {
            return report(
                syntax: .complete,
                model: .incomplete,
                remaining: remainingStages,
                diagnostic: finding(
                    code: "FHIRR4-RESOURCE-NOT-OBJECT",
                    message: "A FHIR resource must be a JSON object.",
                    stage: modelStage,
                    path: "$",
                    causeCode: "RESOURCE_NOT_OBJECT"
                )
            )
        }

        guard let resourceType = object["resourceType"] as? String, !resourceType.isEmpty else {
            return report(
                syntax: .complete,
                model: .incomplete,
                remaining: remainingStages,
                diagnostic: finding(
                    code: "FHIRR4-RESOURCE-TYPE-MISSING",
                    message: "The resourceType property is missing or is not a non-empty string.",
                    stage: modelStage,
                    path: "$.resourceType",
                    causeCode: "RESOURCE_TYPE_MISSING"
                )
            )
        }

        do {
            let resource = try JSONDecoder().decode(ResourceProxy.self, from: data)
            if case .unrecognized = resource {
                return report(
                    syntax: .complete,
                    model: .incomplete,
                    remaining: remainingStages,
                    diagnostic: HL7Diagnostic(
                        code: "FHIRR4-RESOURCE-TYPE-UNSUPPORTED",
                        severity: .warning,
                        message: "The resourceType is not supported by the bundled R4 models.",
                        standard: .fhir,
                        stage: modelStage,
                        version: "R4",
                        location: .init(path: "$.resourceType"),
                        causeCode: "UNRECOGNIZED_RESOURCE_TYPE"
                    )
                )
            }
            return HL7DiagnosticReport(stages: [
                .init(identifier: syntaxStage, status: .complete),
                .init(identifier: modelStage, status: .complete),
            ] + remainingStages)
        } catch {
            return report(
                syntax: .complete,
                model: .incomplete,
                remaining: remainingStages,
                diagnostic: finding(
                    code: "FHIRR4-MODEL-DECODE-FAILED",
                    message: "The JSON resource could not be decoded by the bundled R4 model.",
                    stage: modelStage,
                    path: "$",
                    causeCode: "MODEL_DECODE_FAILED"
                )
            )
        }
    }

    private func report(
        syntax: HL7ValidationStageStatus,
        model: HL7ValidationStageStatus,
        remaining: [HL7ValidationStage],
        diagnostic: HL7Diagnostic
    ) -> HL7DiagnosticReport {
        HL7DiagnosticReport(stages: [
            .init(identifier: "fhir.r4.json", status: syntax),
            .init(identifier: "fhir.r4.model", status: model),
        ] + remaining, diagnostics: [diagnostic])
    }

    private func finding(
        code: String,
        message: String,
        stage: String,
        path: String,
        causeCode: String
    ) -> HL7Diagnostic {
        HL7Diagnostic(
            code: code,
            severity: .error,
            message: message,
            standard: .fhir,
            stage: stage,
            version: "R4",
            location: .init(path: path),
            causeCode: causeCode
        )
    }
}
