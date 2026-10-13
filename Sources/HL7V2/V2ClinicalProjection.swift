import Foundation

/// CX/EI identifiers retain their authority components. They are never treated
/// as globally unique solely because the identifier value matches.
public struct V2Identifier: Equatable, Sendable {
    public let value: String
    public let namespace: String?
    public let universalID: String?
    public let universalIDType: String?
    public let identifierType: String?
    public let raw: String
}

public struct V2PatientProjection: Equatable, Sendable {
    public let segmentIndex: Int
    public let identifiers: [V2Identifier]
    public let rawNames: [String]
    public let birthTime: String?
    public let administrativeSex: String?
    public var priorIdentifiers: [V2Identifier] = []
    public var visitIdentifier: V2Identifier?
}

public struct V2OrderProjection: Equatable, Sendable {
    public let patientIndex: Int?
    public let segmentIndex: Int
    public let orderControl: String?
    public let placerIdentifier: V2Identifier?
    public let fillerIdentifier: V2Identifier?
    public let rawService: String?
    /// OBR-18 is an opaque placer field: it is not universally an accession.
    public let placerField1: String?
    public let resultStatus: String?
}

public struct V2ObservationProjection: Equatable, Sendable {
    public let patientIndex: Int?
    public let orderIndex: Int?
    public let segmentIndex: Int
    public let valueType: String?
    public let rawIdentifier: String?
    public let rawValues: [String]
    public let rawUnits: String?
    public let resultStatus: String?
}

/// Positional reading model for ADT/ORM/OMI/ORU adapters. It preserves
/// patient/order boundaries and flags unprojected data. It is not a worklist
/// command, a merge instruction or an automatic v2-to-FHIR transformation.
public struct V2ClinicalProjection: Equatable, Sendable {
    public let messageType: String?
    public let triggerEvent: String?
    public let controlID: String?
    public let declaredVersion: String
    public let interpretationVersion: String
    public let patients: [V2PatientProjection]
    public let orders: [V2OrderProjection]
    public let observations: [V2ObservationProjection]
    public let unprojectedSegmentIndices: [Int]
    public let notices: [String]

    public init(_ message: ER7Message) {
        let delimiters = message.delimiters
        func repeats(_ raw: String?) -> [String] {
            guard let raw, !raw.isEmpty, raw != "\"\"" else { return [] }
            return raw.split(separator: delimiters.repetition, omittingEmptySubsequences: false).map(String.init)
        }
        func value(_ raw: String?) -> String? {
            guard let raw, !raw.isEmpty, raw != "\"\"" else { return nil }
            return raw
        }
        func identifier(_ raw: String?, cx: Bool) -> V2Identifier? {
            guard let raw = value(raw) else { return nil }
            let parts = raw.split(separator: delimiters.component, omittingEmptySubsequences: false).map(String.init)
            guard let first = parts.first, !first.isEmpty else { return nil }
            func part(_ index: Int) -> String? { index < parts.count ? value(parts[index]) : nil }
            let authority = cx ? (part(3) ?? "").split(separator: delimiters.subcomponent, omittingEmptySubsequences: false).map(String.init) : []
            func hd(_ index: Int) -> String? { index < authority.count ? value(authority[index]) : nil }
            return .init(value: message.unescape(first), namespace: cx ? hd(0) : part(1),
                         universalID: cx ? hd(1) : part(2), universalIDType: cx ? hd(2) : part(3),
                         identifierType: cx ? part(4) : nil, raw: raw)
        }

        messageType = message.rawValue(segment: "MSH", field: 9, component: 1)
        triggerEvent = message.rawValue(segment: "MSH", field: 9, component: 2)
        controlID = message.segment("MSH")?[10]
        declaredVersion = message.declaredVersion
        interpretationVersion = message.interpretationVersion
        var patients: [V2PatientProjection] = []
        var orders: [V2OrderProjection] = []
        var observations: [V2ObservationProjection] = []
        var unprojected: [Int] = []
        var warnings = message.notices
        var patientIndex: Int?
        var currentORC: ER7Segment?
        var currentORCIndex: Int?
        var orderIndex: Int?
        for (index, segment) in message.segments.enumerated() {
            switch segment.code {
            case "MSH": break
            case "PID":
                let identifiers = repeats(segment[3]).compactMap { identifier($0, cx: true) }
                patients.append(.init(segmentIndex: index, identifiers: identifiers, rawNames: repeats(segment[5]),
                                      birthTime: value(segment[7]), administrativeSex: value(segment[8])))
                patientIndex = patients.count - 1
                currentORC = nil; currentORCIndex = nil; orderIndex = nil
                if identifiers.isEmpty { warnings.append("V2-PATIENT-IDENTIFIER-MISSING") }
                if identifiers.contains(where: { $0.namespace == nil && $0.universalID == nil }) {
                    warnings.append("V2-PATIENT-AUTHORITY-MISSING")
                }
            case "PV1":
                if let patientIndex { patients[patientIndex].visitIdentifier = identifier(segment[19], cx: true) }
                else { warnings.append("V2-VISIT-WITHOUT-PATIENT") }
            case "MRG":
                if let patientIndex { patients[patientIndex].priorIdentifiers += repeats(segment[1]).compactMap { identifier($0, cx: true) } }
                else { warnings.append("V2-MERGE-WITHOUT-PATIENT") }
                warnings.append("V2-MERGE-REQUIRES-APPLICATION-POLICY")
            case "ORC":
                currentORC = segment; currentORCIndex = index; orderIndex = nil
                // ORC-only events such as cancellation remain visible.
                orders.append(.init(patientIndex: patientIndex, segmentIndex: index, orderControl: value(segment[1]),
                    placerIdentifier: identifier(segment[2], cx: false), fillerIdentifier: identifier(segment[3], cx: false),
                    rawService: nil, placerField1: nil, resultStatus: nil))
                orderIndex = orders.count - 1
            case "OBR":
                let order = V2OrderProjection(patientIndex: patientIndex, segmentIndex: index,
                    orderControl: value(currentORC?[1]), placerIdentifier: identifier(segment[2], cx: false) ?? identifier(currentORC?[2], cx: false),
                    fillerIdentifier: identifier(segment[3], cx: false) ?? identifier(currentORC?[3], cx: false),
                    rawService: value(segment[4]), placerField1: value(segment[18]), resultStatus: value(segment[25]))
                if let previous = orderIndex, orders[previous].segmentIndex == currentORCIndex { orders[previous] = order }
                else { orders.append(order); orderIndex = orders.count - 1 }
                if patientIndex == nil { warnings.append("V2-ORDER-WITHOUT-PATIENT") }
            case "OBX":
                observations.append(.init(patientIndex: patientIndex, orderIndex: orderIndex, segmentIndex: index,
                    valueType: value(segment[2]), rawIdentifier: value(segment[3]), rawValues: repeats(segment[5]),
                    rawUnits: value(segment[6]), resultStatus: value(segment[11])))
                if orderIndex == nil { warnings.append("V2-OBSERVATION-WITHOUT-ORDER") }
            default: unprojected.append(index)
            }
        }
        self.patients = patients; self.orders = orders; self.observations = observations
        unprojectedSegmentIndices = unprojected
        // Stable codes contain no PHI. The source message is the complete record.
        notices = warnings
    }
}
