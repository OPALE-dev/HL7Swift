import Foundation
import NIO
import NIOSSL

public enum MLLPConnectionError: Error, Equatable, Sendable {
    case notConnected, alreadyConnected, requestInProgress, closed, timeout
    case missingControlID, mismatchedAcknowledgment, invalidAcknowledgment
}

/// One request in flight per connection. A timeout, cancellation or invalid ACK
/// closes the socket to prevent a late reply being consumed by a later request.
/// Automatic retries are deliberately delegated to the application's outbox.
public actor MLLPConnection {
    private var channel: Channel?
    private var requestInProgress = false
    private let group: any EventLoopGroup
    private let responseTimeout: TimeAmount
    private let maximumFrameBytes: Int
    private let policy: ER7ParsingPolicy

    public init(group: any EventLoopGroup = MultiThreadedEventLoopGroup.singleton,
                responseTimeout: TimeAmount = .seconds(30), maximumFrameBytes: Int = 8 * 1024 * 1024,
                parsingPolicy: ER7ParsingPolicy = .interoperable) {
        precondition(maximumFrameBytes > 0)
        self.group = group; self.responseTimeout = responseTimeout
        self.maximumFrameBytes = maximumFrameBytes; self.policy = parsingPolicy
    }

    public func connect(host: String, port: Int, tls: TLSConfiguration? = nil,
                        serverHostname: String? = nil, connectTimeout: TimeAmount = .seconds(10)) async throws {
        guard channel == nil, !requestInProgress else { throw MLLPConnectionError.alreadyConnected }
        requestInProgress = true
        defer { requestInProgress = false }
        let context = try tls.map { try NIOSSLContext(configuration: $0) }
        let maximum = maximumFrameBytes
        let bootstrap = ClientBootstrap(group: group)
            .connectTimeout(connectTimeout)
            .channelInitializer { channel in
                channel.eventLoop.makeCompletedFuture {
                    if let context {
                        try channel.pipeline.syncOperations.addHandler(NIOSSLClientHandler(context: context, serverHostname: serverHostname ?? host))
                    }
                    try channel.pipeline.syncOperations.addHandler(MessageToByteHandler(MLLPFrameEncoder()))
                    try channel.pipeline.syncOperations.addHandler(ByteToMessageHandler(MLLPFrameDecoder(maximumFrameBytes: maximum)))
                    try channel.pipeline.syncOperations.addHandler(MLLPReplyHandler())
                }
            }
        channel = try await bootstrap.connect(host: host, port: port).get()
        if _Concurrency.Task.isCancelled {
            try await close()
            throw CancellationError()
        }
    }

    public func send(_ message: ER7Message, encoding: String.Encoding = .utf8) async throws -> ER7Message {
        guard let channel, channel.isActive else { throw MLLPConnectionError.notConnected }
        guard !requestInProgress else { throw MLLPConnectionError.requestInProgress }
        guard let controlID = message.segment("MSH")?[10], !controlID.isEmpty else { throw MLLPConnectionError.missingControlID }
        guard let data = message.serialized(lineEnding: "\r").data(using: encoding) else { throw ER7Error.invalidEncoding }
        guard data.count <= maximumFrameBytes else { throw MLLPError.frameTooLarge }
        requestInProgress = true
        defer { requestInProgress = false }
        let timeout = responseTimeout
        do {
            try _Concurrency.Task.checkCancellation()
            let future = channel.eventLoop.flatSubmit {
                do {
                    return try channel.pipeline.syncOperations.handler(type: MLLPReplyHandler.self)
                        .request(ByteBuffer(bytes: data), channel: channel, timeout: timeout)
                } catch { return channel.eventLoop.makeFailedFuture(error) }
            }
            let bytes = try await withTaskCancellationHandler(operation: { try await future.get() }, onCancel: {
                channel.close(promise: nil)
            })
            try _Concurrency.Task.checkCancellation()
            let ack = try ER7Message(data: Data(bytes.readableBytesView), encoding: encoding, policy: policy)
            guard ack.rawValue(segment: "MSH", field: 9, component: 1) == "ACK",
                  ["AA", "AE", "AR", "CA", "CE", "CR"].contains(ack.segment("MSA")?[1] ?? "") else {
                throw MLLPConnectionError.invalidAcknowledgment
            }
            guard ack.segment("MSA")?[2] == controlID else { throw MLLPConnectionError.mismatchedAcknowledgment }
            return ack
        } catch {
            try? await channel.close().get()
            self.channel = nil
            throw error
        }
    }

    public func close() async throws {
        let socket = channel
        channel = nil
        if let socket { try await socket.close().get() }
    }
}

private final class MLLPReplyHandler: ChannelInboundHandler {
    typealias InboundIn = ByteBuffer
    private var pending: EventLoopPromise<ByteBuffer>?
    private var timeoutTask: Scheduled<Void>?

    func request(_ payload: ByteBuffer, channel: Channel, timeout: TimeAmount) -> EventLoopFuture<ByteBuffer> {
        precondition(channel.eventLoop.inEventLoop)
        guard pending == nil else { return channel.eventLoop.makeFailedFuture(MLLPConnectionError.requestInProgress) }
        let promise = channel.eventLoop.makePromise(of: ByteBuffer.self)
        pending = promise
        timeoutTask = channel.eventLoop.scheduleTask(in: timeout) {
            self.finish(.failure(MLLPConnectionError.timeout))
            channel.close(promise: nil)
        }
        channel.writeAndFlush(payload).whenFailure { self.finish(.failure($0)) }
        return promise.futureResult
    }

    private func finish(_ result: Result<ByteBuffer, Error>) {
        let promise = pending
        pending = nil
        timeoutTask?.cancel(); timeoutTask = nil
        promise?.completeWith(result)
    }
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        guard pending != nil else { context.close(promise: nil); return }
        finish(.success(unwrapInboundIn(data)))
    }
    func channelInactive(context: ChannelHandlerContext) {
        finish(.failure(MLLPConnectionError.closed))
        context.fireChannelInactive()
    }
    func errorCaught(context: ChannelHandlerContext, error: Error) {
        finish(.failure(error))
        context.close(promise: nil)
    }
}
