import XCTest
import NIOEmbedded
import NIOCore
@testable import HL7Swift

final class MLLPFramingTests: XCTestCase {
    private let payload = "MSH|^~\\&|||||||ACK|abc|P|2.5.1\rMSA|AA|Été"

    func testEveryByteBoundaryIncludingUTF8AndTerminator() throws {
        let wire = Array(("\u{0b}" + payload + "\u{1c}\r").utf8)
        for split in 1..<wire.count {
            let channel = EmbeddedChannel(handler: ByteToMessageHandler(MLLPDecoder(hl7: try HL7())))
            try channel.writeInbound(ByteBuffer(bytes: wire[..<split]))
            XCTAssertNil(try channel.readInbound(as: Message.self))
            try channel.writeInbound(ByteBuffer(bytes: wire[split...]))
            XCTAssertEqual(try channel.readInbound(as: Message.self)?.description, payload)
            XCTAssertNoThrow(try channel.finish())
        }
    }

    func testCoalescedFrames() throws {
        let channel = EmbeddedChannel(handler: ByteToMessageHandler(MLLPDecoder(hl7: try HL7())))
        let frame = "\u{0b}" + payload + "\u{1c}\r"
        try channel.writeInbound(ByteBuffer(string: frame + frame))
        XCTAssertEqual(try channel.readInbound(as: Message.self)?.description, payload)
        XCTAssertEqual(try channel.readInbound(as: Message.self)?.description, payload)
        XCTAssertNoThrow(try channel.finish())
    }

    func testSizeLimitAndBadTerminator() throws {
        let small = EmbeddedChannel(handler: ByteToMessageHandler(MLLPDecoder(hl7: try HL7(), maximumFrameBytes: 3)))
        XCTAssertThrowsError(try small.writeInbound(ByteBuffer(string: "\u{0b}1234")))
        _ = try? small.finish()
        let bad = EmbeddedChannel(handler: ByteToMessageHandler(MLLPDecoder(hl7: try HL7())))
        XCTAssertThrowsError(try bad.writeInbound(ByteBuffer(string: "\u{0b}" + payload + "\u{1c}x")))
        _ = try? bad.finish()
    }

    func testTruncatedFrameAtEOF() throws {
        let channel = EmbeddedChannel(handler: ByteToMessageHandler(MLLPDecoder(hl7: try HL7())))
        try channel.writeInbound(ByteBuffer(string: "\u{0b}" + payload + "\u{1c}"))
        XCTAssertThrowsError(try channel.finish())
    }
}
