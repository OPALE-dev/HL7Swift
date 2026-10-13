import Foundation
import NIO

public enum MLLPError: Error, Equatable, Sendable {
    case invalidStart, invalidTerminator, frameTooLarge, truncatedFrame, invalidUTF8
}

private struct MLLPFramer {
    private enum State { case start, payload, terminator }
    private var state: State = .start
    private var bytes: [UInt8] = []
    let maximumFrameBytes: Int
    init(maximumFrameBytes: Int) { self.maximumFrameBytes = maximumFrameBytes }
    var isIncomplete: Bool { state != .start }

    mutating func read(_ buffer: inout ByteBuffer) throws -> ByteBuffer? {
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
                let payload = ByteBuffer(bytes: bytes)
                bytes.removeAll(keepingCapacity: true)
                state = .start
                return payload
            }
        }
        return nil
    }
}

/// Receives raw payload bytes. Applications choose their character set and
/// parser after framing, so MSH-12 does not constrain transport acceptance.
public struct MLLPFrameDecoder: ByteToMessageDecoder {
    public typealias InboundOut = ByteBuffer
    private var framer: MLLPFramer
    public init(maximumFrameBytes: Int = 8 * 1024 * 1024) {
        precondition(maximumFrameBytes > 0)
        framer = .init(maximumFrameBytes: maximumFrameBytes)
    }
    public mutating func decode(context: ChannelHandlerContext, buffer: inout ByteBuffer) throws -> DecodingState {
        guard let payload = try framer.read(&buffer) else { return .needMoreData }
        context.fireChannelRead(wrapInboundOut(payload))
        return .continue
    }
    public mutating func decodeLast(context: ChannelHandlerContext, buffer: inout ByteBuffer, seenEOF: Bool) throws -> DecodingState {
        let result = try decode(context: context, buffer: &buffer)
        if seenEOF && result == .needMoreData && framer.isIncomplete { throw MLLPError.truncatedFrame }
        return result
    }
}

public struct MLLPFrameEncoder: MessageToByteEncoder {
    public typealias OutboundIn = ByteBuffer
    public init() {}
    public func encode(data: ByteBuffer, out: inout ByteBuffer) throws {
        guard !data.readableBytesView.contains(0x0b), !data.readableBytesView.contains(0x1c) else {
            throw HL7Error.encondingFailed(message: "MLLP payload contains framing control bytes")
        }
        out.writeInteger(UInt8(0x0b))
        out.writeBytes(data.readableBytesView)
        out.writeInteger(UInt8(0x1c))
        out.writeInteger(UInt8(0x0d))
    }
}

/// Historical Message adapter over the same strict, bounded MLLP framer.
public struct MLLPDecoder: ByteToMessageDecoder {
    public typealias InboundOut = Message
    private var framer: MLLPFramer
    private let hl7: HL7
    public let maximumFrameBytes: Int
    public init(hl7: HL7, maximumFrameBytes: Int = 8 * 1024 * 1024) {
        precondition(maximumFrameBytes > 0)
        self.hl7 = hl7; self.maximumFrameBytes = maximumFrameBytes
        framer = .init(maximumFrameBytes: maximumFrameBytes)
    }
    init(withHL7 hl7: HL7, responder: HL7Responder) { self.init(hl7: hl7) }
    public mutating func decode(context: ChannelHandlerContext, buffer: inout ByteBuffer) throws -> DecodingState {
        guard let payload = try framer.read(&buffer) else { return .needMoreData }
        guard let string = String(bytes: payload.readableBytesView, encoding: .utf8) else { throw MLLPError.invalidUTF8 }
        context.fireChannelRead(wrapInboundOut(try Message(string, hl7: hl7)))
        return .continue
    }
    public mutating func decodeLast(context: ChannelHandlerContext, buffer: inout ByteBuffer, seenEOF: Bool) throws -> DecodingState {
        let result = try decode(context: context, buffer: &buffer)
        if seenEOF && result == .needMoreData && framer.isIncomplete { throw MLLPError.truncatedFrame }
        return result
    }
}
