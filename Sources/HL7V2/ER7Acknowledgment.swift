import Foundation

public enum ER7AcknowledgmentCode: String, Sendable, CaseIterable {
    case applicationAccept = "AA", applicationError = "AE", applicationReject = "AR"
    case commitAccept = "CA", commitError = "CE", commitReject = "CR"
}

public extension ER7Message {
    /// Builds the selected ACK phase without a specification. The application
    /// decides when acceptance/persistence/processing has actually happened.
    /// This function does not automatically choose or emit both enhanced phases.
    func acknowledgment(code: ER7AcknowledgmentCode, sendingApplication: String,
                        sendingFacility: String, controlID: String = UUID().uuidString,
                        timestamp: Date = Date()) throws -> ER7Message {
        guard let originalID = segment("MSH")?[10], !originalID.isEmpty, originalID != "\"\"",
              !controlID.isEmpty, controlID != "\"\"" else { throw MLLPConnectionError.missingControlID }
        let date = DateFormatter()
        date.locale = Locale(identifier: "en_US_POSIX")
        date.dateFormat = "yyyyMMddHHmmssZ"
        let component = String(delimiters.component)
        let event = rawValue(segment: "MSH", field: 9, component: 2)
        let messageType = event.map { "ACK" + component + $0 + component + "ACK" } ?? "ACK"
        var fields = [segment("MSH")?[2] ?? "", escape(sendingApplication), escape(sendingFacility),
            segment("MSH")?[3] ?? "", segment("MSH")?[4] ?? "", date.string(from: timestamp), "",
            messageType, escape(controlID), segment("MSH")?[11] ?? "P", segment("MSH")?[12] ?? declaredVersion]
        if let charset = segment("MSH")?[18] {
            fields += Array(repeating: "", count: 5) + [charset]
        }
        let separator = String(delimiters.field)
        let wire = "MSH" + separator + fields.joined(separator: separator) + "\rMSA" + separator + code.rawValue + separator + originalID + "\r"
        return try ER7Message(wire, policy: .init(interpretationVersion: interpretationVersion))
    }
}
