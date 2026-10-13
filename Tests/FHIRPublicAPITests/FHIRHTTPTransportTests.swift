import XCTest
import FHIR
import ModelsR4
import NIO
import NIOHTTP1
import AsyncHTTPClient

private final class FHIRTestHTTPHandler: ChannelInboundHandler {
    typealias InboundIn = HTTPServerRequestPart
    typealias OutboundOut = HTTPServerResponsePart
    private let body = ByteBuffer(string: #"{"resourceType":"Patient","id":"loopback"}"#)
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        guard case .end = unwrapInboundIn(data) else { return }
        let headers = HTTPHeaders([("Content-Type", "application/fhir+json"), ("Content-Length", String(body.readableBytes))])
        context.write(wrapOutboundOut(.head(.init(version: .http1_1, status: .ok, headers: headers))), promise: nil)
        context.write(wrapOutboundOut(.body(.byteBuffer(body))), promise: nil)
        context.writeAndFlush(wrapOutboundOut(.end(nil)), promise: nil)
    }
}

final class FHIRHTTPTransportTests: XCTestCase {
    func testRealHTTPRoundTripAndBodyLimit() async throws {
        let server = try await ServerBootstrap(group: MultiThreadedEventLoopGroup.singleton)
            .childChannelInitializer { channel in
                channel.pipeline.configureHTTPServerPipeline().flatMap {
                    channel.eventLoop.makeCompletedFuture {
                        try channel.pipeline.syncOperations.addHandler(FHIRTestHTTPHandler())
                    }
                }
            }.bind(host: "127.0.0.1", port: 0).get()
        let http = HTTPClient(eventLoopGroupProvider: .singleton)
        do {
            let port = try XCTUnwrap(server.localAddress?.port)
            let base = try XCTUnwrap(URL(string: "http://127.0.0.1:\(port)/fhir"))
            let api = try FHIRR4RESTClient(baseURL: base, transport: AsyncFHIRHTTPTransport(client: http))
            let response = try await api.read("Patient", id: "loopback")
            XCTAssertEqual(response.resource?.get(if: Patient.self)?.id?.value?.string, "loopback")
            let bounded = try FHIRR4RESTClient(baseURL: base, transport: AsyncFHIRHTTPTransport(client: http, maximumResponseBytes: 8))
            do { _ = try await bounded.read("Patient", id: "loopback"); XCTFail("Oversized body accepted") }
            catch { }
            try await http.shutdown()
            try await server.close().get()
        } catch {
            try? await http.shutdown()
            try? await server.close().get()
            throw error
        }
    }
}
