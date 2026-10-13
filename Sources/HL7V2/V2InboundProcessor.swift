import Foundation
import HL7Core

public struct V2InboundContext: Sendable {
    /// Exact payload received after MLLP framing, before charset interpretation.
    public let sourceBytes: Data
    public let message: ER7Message
    public let report: HL7DiagnosticReport
}

/// Native receive/validate/acknowledge pipeline. The application supplies the
/// durable inbox and processing policy through a required async callback.
/// An ACK is constructed only after that callback returns its chosen code.
public struct V2InboundProcessor: Sendable {
    private let application: String
    private let facility: String
    private let parsingPolicy: ER7ParsingPolicy
    private let validationPolicy: V2NativeValidationPolicy
    private let rejectionCode: ER7AcknowledgmentCode
    private let handle: @Sendable (V2InboundContext) async throws -> ER7AcknowledgmentCode

    public init(application: String, facility: String,
                parsingPolicy: ER7ParsingPolicy = .interoperable,
                validationPolicy: V2NativeValidationPolicy = .init(),
                rejectionCode: ER7AcknowledgmentCode = .applicationReject,
                handle: @escaping @Sendable (V2InboundContext) async throws -> ER7AcknowledgmentCode) {
        precondition([.applicationReject, .commitReject].contains(rejectionCode))
        self.application = application; self.facility = facility
        self.parsingPolicy = parsingPolicy; self.validationPolicy = validationPolicy
        self.rejectionCode = rejectionCode; self.handle = handle
    }

    public func process(_ sourceBytes: Data, encoding: String.Encoding = .utf8) async throws -> ER7Message {
        let message = try ER7Message(data: sourceBytes, encoding: encoding, policy: parsingPolicy)
        let report = V2NativeValidator().validate(message, policy: validationPolicy)
        let code: ER7AcknowledgmentCode
        if report.outcome == .invalid { code = rejectionCode }
        else { code = try await handle(.init(sourceBytes: sourceBytes, message: message, report: report)) }
        return try message.acknowledgment(code: code, sendingApplication: application, sendingFacility: facility)
    }
}
