import Foundation
import HL7Core

/// Explicit connector contract, independent of any schema or specification file.
public struct V2NativeValidationPolicy: Sendable {
    public var requirePatientAuthority: Bool
    public var expectedMessageType: String?
    public init(requirePatientAuthority: Bool = false, expectedMessageType: String? = nil) {
        self.requirePatientAuthority = requirePatientAuthority; self.expectedMessageType = expectedMessageType
    }
}

/// Native checks for the initially supported clinical families. Healthy reports
/// remain indeterminate for full standard/profile conformance, since the current
/// checks are intentionally scoped. No XSD or external ruleset is required.
public struct V2NativeValidator: Sendable {
    public init() {}
    public func validate(_ message: ER7Message, policy: V2NativeValidationPolicy = .init()) -> HL7DiagnosticReport {
        var findings: [HL7Diagnostic] = []
        let stage = "v2.native.contract"
        func finding(_ code: String, _ text: String, path: String, severity: HL7DiagnosticSeverity = .error) {
            findings.append(.init(code: code, severity: severity, message: text, standard: .v2, stage: stage,
                version: message.interpretationVersion, location: .init(path: path),
                provenance: .init(rule: code, artifact: "HL7Swift native checks", artifactVersion: "1")))
        }
        func required(_ code: String, _ field: Int, occurrence: Int = 1) {
            let value = ER7Value(raw: message.segment(code, occurrence: occurrence)?[field])
            if value == .absent || value == .empty || value == .null {
                finding("V2-NATIVE-FIELD-REQUIRED", "A required connector field is absent, empty or null.", path: "\(code)[\(occurrence)]-\(field)")
            }
        }
        for field in [9, 10, 11, 12] { required("MSH", field) }
        let family = message.rawValue(segment: "MSH", field: 9, component: 1) ?? ""
        let type = message.segment("MSH")?[9] ?? ""
        if family.isEmpty { finding("V2-NATIVE-MESSAGE-CODE-REQUIRED", "The message code component is empty.", path: "MSH-9.1") }
        if let expected = policy.expectedMessageType, expected != type {
            finding("V2-NATIVE-MESSAGE-TYPE-MISMATCH", "The message type does not match this connector contract.", path: "MSH-9")
        }
        let requiredSegments: [String]
        switch family {
        case "ACK": requiredSegments = ["MSA"]
        case "ADT": requiredSegments = ["PID"]
        case "ORM", "OMI": requiredSegments = ["PID", "ORC"]
        case "ORU": requiredSegments = ["PID", "OBR", "OBX"]
        case "MDM": requiredSegments = ["PID", "TXA", "OBX"]
        default:
            requiredSegments = []
            finding("V2-NATIVE-FAMILY-UNSUPPORTED", "No clinical contract checks are implemented for this message family.", path: "MSH-9", severity: .warning)
        }
        for code in requiredSegments where message.segment(code) == nil {
            finding("V2-NATIVE-SEGMENT-REQUIRED", "A segment required by the connector contract is absent.", path: code)
        }
        if family == "ACK", message.segment("MSA") != nil {
            required("MSA", 1); required("MSA", 2)
            if !ER7AcknowledgmentCode.allCases.map(\.rawValue).contains(message.segment("MSA")?[1] ?? "") {
                finding("V2-NATIVE-ACK-CODE", "The acknowledgement code is unsupported.", path: "MSA-1")
            }
        }
        let clinical = V2ClinicalProjection(message)
        for (index, patient) in clinical.patients.enumerated() {
            required("PID", 3, occurrence: index + 1)
            if patient.identifiers.isEmpty {
                finding("V2-NATIVE-PATIENT-IDENTIFIER-REQUIRED", "No usable patient identifier is present.", path: "PID[\(index + 1)]-3")
            }
            if policy.requirePatientAuthority, patient.identifiers.contains(where: { $0.namespace == nil && $0.universalID == nil }) {
                finding("V2-NATIVE-PATIENT-AUTHORITY-REQUIRED", "The connector requires an assigning authority for patient identifiers.", path: "PID[\(index + 1)]-3")
            }
        }
        for (index, order) in clinical.orders.enumerated() {
            if order.placerIdentifier == nil && order.fillerIdentifier == nil {
                finding("V2-NATIVE-ORDER-IDENTIFIER-REQUIRED", "An order requires a placer or filler identifier in this connector contract.", path: "Order[\(index + 1)]")
            }
        }
        for code in message.notices {
            finding(code, "An explicit interoperability tolerance was applied.", path: "MSH", severity: .warning)
        }
        return .init(stages: [.init(identifier: "v2.er7", status: .complete),
            .init(identifier: stage, status: .complete), .init(identifier: "v2.standard-profile", status: .notRun)], diagnostics: findings)
    }
}
