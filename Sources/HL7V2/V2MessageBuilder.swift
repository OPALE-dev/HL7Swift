import Foundation

/// Initial native messages for patient, order and reporting adapters. MSH-9
/// carries message code/event; an optional negotiated structure can be added.
public enum V2MessageKind: String, CaseIterable, Sendable {
    case admit = "ADT^A01", transfer = "ADT^A02", discharge = "ADT^A03"
    case register = "ADT^A04", preadmit = "ADT^A05", updatePatient = "ADT^A08"
    case addPatient = "ADT^A28", updatePerson = "ADT^A31", mergeAssertion = "ADT^A40"
    case order = "ORM^O01", imagingOrder = "OMI^O23", result = "ORU^R01", document = "MDM^T02"
}

public struct V2IdentifierInput: Sendable, Equatable {
    public var value: String
    public var namespace: String?
    public var universalID: String?
    public var universalIDType: String?
    public var type: String?
    public init(value: String, namespace: String? = nil, universalID: String? = nil,
                universalIDType: String? = nil, type: String? = nil) {
        self.value = value; self.namespace = namespace; self.universalID = universalID
        self.universalIDType = universalIDType; self.type = type
    }
}

public struct V2PatientInput: Sendable, Equatable {
    public var identifiers: [V2IdentifierInput]
    public var family: String
    public var given: [String]
    public var birthTime: String?
    public var administrativeSex: String?
    public init(identifiers: [V2IdentifierInput], family: String, given: [String] = [],
                birthTime: String? = nil, administrativeSex: String? = nil) {
        self.identifiers = identifiers; self.family = family; self.given = given
        self.birthTime = birthTime; self.administrativeSex = administrativeSex
    }
}

public struct V2ImagingProcedureInput: Sendable, Equatable {
    public var accession: V2IdentifierInput
    public var requestedProcedure: V2IdentifierInput
    public var scheduledProcedureStep: V2IdentifierInput
    public var studyInstanceUID: String?
    public var modality: String
    public var scheduledAETitle: String?
    public init(accession: V2IdentifierInput, requestedProcedure: V2IdentifierInput,
                scheduledProcedureStep: V2IdentifierInput, studyInstanceUID: String? = nil,
                modality: String, scheduledAETitle: String? = nil) {
        self.accession = accession; self.requestedProcedure = requestedProcedure
        self.scheduledProcedureStep = scheduledProcedureStep; self.studyInstanceUID = studyInstanceUID
        self.modality = modality; self.scheduledAETitle = scheduledAETitle
    }
}

/// Builds native ER7 using explicit clinical inputs. Values are escaped before
/// composition; assigning-authority components are never discarded. Unknown
/// partner-specific segments can be appended explicitly as raw ER7.
public struct V2MessageBuilder: Sendable {
    private var lines: [String]
    private let escaper: ER7Message
    public let kind: V2MessageKind
    private var observationIndex = 0

    public init(kind: V2MessageKind, sendingApplication: String, sendingFacility: String,
                receivingApplication: String, receivingFacility: String, controlID: String,
                version: String = "2.5.1", processingID: String = "P",
                messageStructure: String? = nil, timestamp: Date = Date()) throws {
        self.kind = kind
        guard !controlID.isEmpty, !version.isEmpty else { throw ER7Error.incompleteHeader }
        // The escaper uses the same native separators as this builder.
        escaper = try ER7Message("MSH|^~\\&|||||||ACK|seed|P|2.5.1")
        let date = DateFormatter()
        date.locale = Locale(identifier: "en_US_POSIX")
        date.dateFormat = "yyyyMMddHHmmssZ"
        let escape = escaper.escape
        let type = kind.rawValue + (messageStructure.map { "^" + escape($0) } ?? "")
        let header = ["MSH", "^~\\&", escape(sendingApplication), escape(sendingFacility),
            escape(receivingApplication), escape(receivingFacility), date.string(from: timestamp), "",
            type, escape(controlID), escape(processingID), escape(version), "", "", "", "", "", "UNICODE UTF-8"]
        lines = [header.joined(separator: "|")]
    }

    public mutating func addPatient(_ patient: V2PatientInput) throws {
        guard !patient.identifiers.isEmpty else { throw ER7Error.invalidFieldValue }
        let identifiers = try patient.identifiers.map { try encode($0, patient: true) }.joined(separator: "~")
        let name = [patient.family, patient.given.first ?? "", patient.given.dropFirst().joined(separator: " ")].map(escaper.escape).joined(separator: "^")
        let fields = ["1", "", identifiers, "", name, "", escaper.escape(patient.birthTime ?? ""), escaper.escape(patient.administrativeSex ?? "")]
        lines.append("PID|" + fields.joined(separator: "|"))
    }

    public mutating func addOrder(control: String, placer: V2IdentifierInput,
                                  filler: V2IdentifierInput? = nil, serviceCode: String,
                                  serviceText: String? = nil, codingSystem: String? = nil) throws {
        let placerValue = try encode(placer, patient: false)
        let fillerValue = try filler.map { try encode($0, patient: false) } ?? ""
        lines.append("ORC|" + [escaper.escape(control), placerValue, fillerValue].joined(separator: "|"))
        let service = [serviceCode, serviceText ?? "", codingSystem ?? ""].map(escaper.escape).joined(separator: "^")
        lines.append("OBR|" + ["1", placerValue, fillerValue, service].joined(separator: "|"))
    }

    public mutating func addTextObservation(code: String, text: [String], status: String = "F") {
        observationIndex += 1
        lines.append("OBX|" + [String(observationIndex), "TX", escaper.escape(code), "",
            text.map(escaper.escape).joined(separator: "~"), "", "", "", "", "", escaper.escape(status)].joined(separator: "|"))
    }

    /// Imaging order details for a downstream worklist adapter. Does not create
    /// a DICOM worklist entry, generate UIDs or choose modality scheduling.
    public mutating func addImagingProcedure(_ procedure: V2ImagingProcedureInput) throws {
        let accession = try encode(procedure.accession, patient: false)
        let requested = try encode(procedure.requestedProcedure, patient: false)
        let step = try encode(procedure.scheduledProcedureStep, patient: false)
        let uid = escaper.escape(procedure.studyInstanceUID ?? "")
        lines.append("IPC|" + [accession, requested, uid, step, escaper.escape(procedure.modality), "", "", "", escaper.escape(procedure.scheduledAETitle ?? "")].joined(separator: "|"))
    }

    public mutating func addTextDocument(type: String, identifier: V2IdentifierInput,
                                         completionStatus: String, text: [String]) throws {
        let id = try encode(identifier, patient: false)
        var fields = Array(repeating: "", count: 17)
        fields[0] = "1"; fields[1] = escaper.escape(type); fields[2] = "TX"
        fields[11] = id; fields[16] = escaper.escape(completionStatus)
        lines.append("TXA|" + fields.joined(separator: "|"))
        addTextObservation(code: type, text: text)
    }

    public mutating func addPriorIdentifiers(_ identifiers: [V2IdentifierInput]) throws {
        guard !identifiers.isEmpty else { throw ER7Error.invalidFieldValue }
        lines.append("MRG|" + (try identifiers.map { try encode($0, patient: true) }).joined(separator: "~"))
    }

    /// Raw fields are already encoded by the caller. Validates one segment at
    /// a time and rejects injected headers, framing bytes and line breaks.
    public mutating func appendRawSegment(code: String, fields: [String]) throws {
        guard code != "MSH", code.count == 3, !fields.contains(where: { $0.contains(where: { "|\r\n\u{0b}\u{1c}".contains($0) }) }) else { throw ER7Error.invalidFieldValue }
        let line = code + "|" + fields.joined(separator: "|")
        _ = try ER7Message(lines[0] + "\r" + line)
        lines.append(line)
    }

    public func build() throws -> ER7Message { try ER7Message(lines.joined(separator: "\r") + "\r") }

    private func encode(_ id: V2IdentifierInput, patient: Bool) throws -> String {
        guard !id.value.isEmpty, id.value != "\"\"", (id.universalID == nil) == (id.universalIDType == nil) else { throw ER7Error.invalidFieldValue }
        let e = escaper.escape
        if patient {
            let authority = [id.namespace ?? "", id.universalID ?? "", id.universalIDType ?? ""].map(e).joined(separator: "&")
            return [e(id.value), "", "", authority, e(id.type ?? "")].joined(separator: "^")
        }
        return [id.value, id.namespace ?? "", id.universalID ?? "", id.universalIDType ?? ""].map(e).joined(separator: "^")
    }
}
