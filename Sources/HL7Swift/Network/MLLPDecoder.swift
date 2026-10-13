import Foundation
import NIO

public enum MLLPError: Error, Equatable, Sendable {
    case invalidStart, invalidTerminator, frameTooLarge, truncatedFrame, invalidUTF8
}

/// Strict VT + payload + FS + CR framing, independent of TCP/UTF-8 boundaries.
public struct MLLPDecoder: ByteToMessageDecoder {
    public typealias InboundOut = Message
    private enum State { case start, payload, terminator }
    private var state: State = .start
    private var bytes: [UInt8] = []
    private let hl7: HL7
    public let maximumFrameBytes: Int

    public init(hl7: HL7, maximumFrameBytes: Int = 8 * 1024 * 1024) {
        precondition(maximumFrameBytes > 0)
        self.hl7 = hl7
        self.maximumFrameBytes = maximumFrameBytes
    }

    init(withHL7 hl7: HL7, responder: HL7Responder) { self.init(hl7: hl7) }

    public mutating func decode(context: ChannelHandlerContext, buffer: inout ByteBuffer) throws -> DecodingState {
        while let byte: UInt8 = buffer.readInteger() {
            switch state {
            case .start:
                guard byte == 0x0b else { throw MLLPError.invalidStart }
                state = .payload
            case .payload:
                if byte == 0x1c { state = .terminator }
                else {
                    guard byte != 0x0b else { throw MLLPError.invalidStart }
                    guard bytes.count < maximumFrameBytes else { throw MLLPError.frameTooLarge }
                    bytes.append(byte)
                }
            case .terminator:
                guard byte == 0x0d else { throw MLLPError.invalidTerminator }
                guard let string = String(bytes: bytes, encoding: .utf8) else { throw MLLPError.invalidUTF8 }
                let message = try Message(string, hl7: hl7)
                bytes.removeAll(keepingCapacity: true)
                state = .start
                context.fireChannelRead(wrapInboundOut(message))
                return .continue
            }
        }
        return .needMoreData
    }

    public mutating func decodeLast(context: ChannelHandlerContext, buffer: inout ByteBuffer, seenEOF: Bool) throws -> DecodingState {
        let result = try decode(context: context, buffer: &buffer)
        if seenEOF && result == .needMoreData && state != .start { throw MLLPError.truncatedFrame }
        return result
    }
}
