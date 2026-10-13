import Foundation

public extension Message {
    /// Builds an original-mode ACK without requiring external specifications.
    /// Call only after the application has decided which processing result the
    /// acknowledgement represents (for example after durable inbox storage).
    func acknowledgment(status: AcknowledgeStatus, application: String, facility: String,
                        controlID: String = UUID().uuidString) throws -> Message {
        let header = self["MSH"]
        let values = [application, facility, header?[3]?.description ?? "",
                      header?[4]?.description ?? "", controlID]
        guard [application, facility, controlID].allSatisfy({ !$0.contains(where: { "|^~\\&\r\n".contains($0) }) }) else {
            throw HL7Error.encondingFailed(message: "ACK envelope contains delimiters")
        }
        let senderControlID = header?[10]?.description ?? ""
        let processing = header?[11]?.description ?? "P"
        let version = header?[12]?.description ?? "2.5.1"
        let timestamp = DateFormatter()
        timestamp.locale = Locale(identifier: "en_US_POSIX")
        timestamp.dateFormat = "yyyyMMddHHmmssZ"
        let ack = "MSH|^~\\&|\(application)|\(facility)|\(values[2])|\(values[3])|\(timestamp.string(from: Date()))||ACK|\(controlID)|\(processing)|\(version)\rMSA|\(status.rawValue)|\(senderControlID)\r"
        return try Message(ack, hl7: spec ?? HL7())
    }
}
