import XCTest
import HL7V2
import NIO
import NIOSSL

private final class TestACKHandler: ChannelInboundHandler {
    typealias InboundIn = ByteBuffer
    let status: String?
    let mismatch: Bool
    init(status: String?, mismatch: Bool) { self.status = status; self.mismatch = mismatch }
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        guard let status else { return }
        let payload = unwrapInboundIn(data)
        guard let message = try? ER7Message(data: Data(payload.readableBytesView)) else { context.close(promise: nil); return }
        let id = mismatch ? "wrong-id" : (message.segment("MSH")?[10] ?? "")
        let ack = "MSH|^~\\&|PACS|HOSP|RIS|HOSP|||ACK|reply|P|\(message.declaredVersion)\rMSA|\(status)|\(id)\r"
        context.writeAndFlush(NIOAny(ByteBuffer(string: ack)), promise: nil)
    }
}

final class MLLPConnectionTests: XCTestCase {
    private func withServer(status: String? = "AA", mismatch: Bool = false,
                            tls: TLSConfiguration? = nil,
                            body: (Int) async throws -> Void) async throws {
        let context = try tls.map { try NIOSSLContext(configuration: $0) }
        let bootstrap = ServerBootstrap(group: MultiThreadedEventLoopGroup.singleton)
            .childChannelInitializer { channel in
                channel.eventLoop.makeCompletedFuture {
                    if let context { try channel.pipeline.syncOperations.addHandler(NIOSSLServerHandler(context: context)) }
                    try channel.pipeline.syncOperations.addHandler(MessageToByteHandler(MLLPFrameEncoder()))
                    try channel.pipeline.syncOperations.addHandler(ByteToMessageHandler(MLLPFrameDecoder()))
                    try channel.pipeline.syncOperations.addHandler(TestACKHandler(status: status, mismatch: mismatch))
                }
            }
        let server = try await bootstrap.bind(host: "127.0.0.1", port: 0).get()
        do {
            try await body(XCTUnwrap(server.localAddress?.port))
            try await server.close().get()
        } catch {
            try? await server.close().get()
            throw error
        }
    }

    private func message(_ id: String = "request") throws -> ER7Message {
        try ER7Message("MSH|^~\\&|RIS|HOSP|PACS|HOSP|||ORM^O01|\(id)|P|99.vendor\rPID|||123\r")
    }

    func testTwoExchangesAndUnknownDeclaredVersion() async throws {
        try await withServer { port in
            let client = MLLPConnection()
            try await client.connect(host: "127.0.0.1", port: port)
            do {
                for id in ["first", "second"] {
                    let ack = try await client.send(message(id))
                    XCTAssertEqual(ack.segment("MSA")?[2], id)
                    XCTAssertEqual(ack.declaredVersion, "99.vendor")
                }
                try await client.close()
            } catch { try? await client.close(); throw error }
        }
    }

    func testApplicationErrorACKIsReturnedToOutboxPolicy() async throws {
        try await withServer(status: "AE") { port in
            let client = MLLPConnection()
            try await client.connect(host: "127.0.0.1", port: port)
            let ack = try await client.send(message())
            XCTAssertEqual(ack.segment("MSA")?[1], "AE")
            try await client.close()
        }
    }

    func testMismatchedACKClosesConnection() async throws {
        try await withServer(mismatch: true) { port in
            let client = MLLPConnection()
            try await client.connect(host: "127.0.0.1", port: port)
            do { _ = try await client.send(message()); XCTFail("Wrong ACK accepted") }
            catch MLLPConnectionError.mismatchedAcknowledgment { }
            do { _ = try await client.send(message()); XCTFail("Closed socket reused") }
            catch MLLPConnectionError.notConnected { }
        }
    }

    func testTimeoutClosesConnection() async throws {
        try await withServer(status: nil) { port in
            let client = MLLPConnection(responseTimeout: .milliseconds(50))
            try await client.connect(host: "127.0.0.1", port: port)
            do { _ = try await client.send(message()); XCTFail("Expected timeout") }
            catch MLLPConnectionError.timeout { }
            do { _ = try await client.send(message()); XCTFail("Timed-out socket reused") }
            catch MLLPConnectionError.notConnected { }
        }
    }

    func testTLSChecksTrustAndHostname() async throws {
        // Public, generated test-only key. Never use this identity in a service.
        let certPath = try XCTUnwrap(Bundle.module.url(forResource: "localhost-cert", withExtension: "pem"))
        let keyPath = try XCTUnwrap(Bundle.module.url(forResource: "localhost-key", withExtension: "pem"))
        let certificates = try NIOSSLCertificate.fromPEMFile(certPath.path)
        let key = try NIOSSLPrivateKey(file: keyPath.path, format: .pem)
        let serverTLS = TLSConfiguration.makeServerConfiguration(certificateChain: certificates.map { .certificate($0) }, privateKey: .privateKey(key))
        try await withServer(tls: serverTLS) { port in
            var trusted = TLSConfiguration.makeClientConfiguration()
            trusted.trustRoots = .certificates(certificates)
            let valid = MLLPConnection()
            try await valid.connect(host: "127.0.0.1", port: port, tls: trusted, serverHostname: "localhost")
            let ack = try await valid.send(message())
            XCTAssertEqual(ack.segment("MSA")?[1], "AA")
            try await valid.close()
            for (config, hostname) in [(trusted, "wrong.invalid"), (TLSConfiguration.makeClientConfiguration(), "localhost")] {
                let rejected = MLLPConnection(responseTimeout: .seconds(3))
                do {
                    try await rejected.connect(host: "127.0.0.1", port: port, tls: config, serverHostname: hostname)
                    _ = try await rejected.send(message())
                    XCTFail("Invalid TLS peer accepted")
                } catch { }
                try? await rejected.close()
            }
        }
    }

    func testCancellationClosesSocketAndReportsCancellation() async throws {
        try await withServer(status: nil) { port in
            let client = MLLPConnection(responseTimeout: .seconds(5))
            try await client.connect(host: "127.0.0.1", port: port)
            let input = try message()
            let operation = _Concurrency.Task { try await client.send(input) }
            // Give the actor a scheduling opportunity; cancellation is tested
            // both before/after entering send by the cancellation check.
            await _Concurrency.Task.yield()
            operation.cancel()
            do { _ = try await operation.value; XCTFail("Cancellation ignored") }
            catch is CancellationError { }
            do { _ = try await client.send(input); XCTFail("Cancelled socket reused") }
            catch MLLPConnectionError.notConnected { }
        }
    }
}
