//
//  File.swift
//  
//
//  Created by Rafael Warnault on 23/12/2021.
//

import Foundation
import NIO
import NIOTLS
import NIOSSL


public struct ClientConfiguration {
    public var hl7:HL7!

    public var host:String      = "127.0.0.1"
    public var port:Int         = 2575
    public var localPort:Int? = nil
    
    public var connectTimeout: Int = 5
    public var readTimeout: Int    = 5
    
    public var name:String      = "HL7CLIENT"
    public var facility:String  = "HL7CLIENT"

    public var TLSEnabled:Bool  = false
    /// Optional caller-owned trust roots, client identity and verification
    /// policy. The default verifies the server chain and hostname.
    public var tlsConfiguration: TLSConfiguration? = nil
    
    public init(_ hl7: HL7) {
        self.hl7 = hl7
    }
}


public class HL7CLient {
        
    public var config: ClientConfiguration
    
    var hl7: HL7!
    public var channel:Channel? // would be better private
    var promise: EventLoopPromise<Message>?
    private var group: MultiThreadedEventLoopGroup?

    var tlsConfiguration:TLSConfiguration? = nil
    var sslContext:NIOSSLContext? = nil
    
    
    public init(_ config: ClientConfiguration) throws {
        self.config = config
        self.hl7    = config.hl7
    }

    deinit {
        disconnect()
    }

    
    
    // MARK: -
    
    public func connect() throws -> EventLoopFuture<Void> {
        let responder = HL7Responder(hl7: hl7, spec: hl7.spec(ofVersion: .v282)!, facility: "HL7SWIFT", app: "HL7CLIENT")

        if self.config.TLSEnabled {
            try initTLS()
        }
        
        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        self.group = group
        let bootstrap = ClientBootstrap(group: group)
            .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .channelOption(ChannelOptions.maxMessagesPerRead, value: 16)
            .channelOption(ChannelOptions.connectTimeout, value: .seconds(Int64(config.connectTimeout)))
            .channelInitializer { channel in
                if let sslContext = self.sslContext, self.config.TLSEnabled {
                    do {
                        let TLShandler = try NIOSSLClientHandler(context: sslContext, serverHostname: self.config.host)
                                                
                        return channel.pipeline.addHandler(TLShandler).flatMap {
                            channel.pipeline.addHandlers([
                                MessageToByteHandler(MLLPEncoder()),
                                ByteToMessageHandler(MLLPDecoder(withHL7: self.hl7, responder: responder)),
                                self
                            ])
                        }
                    } catch let e {
                        return channel.eventLoop.makeFailedFuture(e)
                    }
                }
                
                return channel.pipeline.addHandlers([
                    MessageToByteHandler(MLLPEncoder()),
                    ByteToMessageHandler(MLLPDecoder(withHL7: self.hl7, responder: responder)),
                    self
                ])
            }
        
        
        
        return bootstrap
            .connect(host: self.config.host, port: self.config.port)
            .flatMap { channel in
                
            self.channel    = channel
            self.config.localPort  = self.channel?.localAddress?.port
            
            return channel.eventLoop.makeSucceededVoidFuture()
        }
    }
    
    
    
    public func disconnect() {
        if let channel {
            try? channel.close().wait()
            Logger.info("Disconnected from \(self.config.host):\(self.config.port)")
        }

        self.promise?.fail(HL7Error.initError(message: ""))
        self.promise = nil
        self.channel = nil

        try? group?.syncShutdownGracefully()
        group = nil
    }
    
    
    
    // MARK: -
    
    public func send(fileAt path:String) throws -> Message?  {
        let message = try Message(withFileAt: path, hl7: self.hl7)
        
        return try self.send(message)
    }
    
    
    public func send(messageAs string:String) throws -> Message?  {
        let message = try Message(string, hl7: self.hl7)
        
        return try self.send(message)
    }
    
    
    public func send(_ message: Message?) throws -> Message? {
        guard let message = message else {
            return nil
        }

        guard let channel else {
            throw HL7Error.initError(message: "Client is not connected")
        }

        let responsePromise = channel.eventLoop.makePromise(of: Message.self)
        promise = responsePromise

        try channel.writeAndFlush(message).wait()
        
        Logger.info("### Sent Message \(message.type.name) (\(message.version.rawValue))")
        Logger.debug("\n\n\(message)\n")
        let timeout = channel.eventLoop.scheduleTask(in: .seconds(Int64(self.config.readTimeout))) {
            responsePromise.fail(HL7Error.timeoutError(message: "Timeout while sending message"))
        }

        defer {
            timeout.cancel()
            promise = nil
        }

        return try responsePromise.futureResult.wait()
    }

}



private extension HL7CLient {
    func initTLS() throws {
        Logger.info("TLS enabled")
                
        let conf = config.tlsConfiguration ?? TLSConfiguration.makeClientConfiguration()

        // Test with hl7rcv (dcm4chee)
//         conf.minimumTLSVersion = .tlsv12
//         conf.cipherSuiteValues = [.TLS_RSA_WITH_AES_128_CBC_SHA]
        
        self.tlsConfiguration = conf
        self.sslContext = try NIOSSLContext(configuration: conf)
        
        Logger.debug("TLS init done")
        Logger.debug("\(self.tlsConfiguration!)")
    }
}



// MARK: -

extension HL7CLient: ChannelInboundHandler {
    public typealias InboundIn = Message
    public typealias OutboundOut = Message
    
    
    public func channelActive(context: ChannelHandlerContext) {
        Logger.debug("[HL7CLient] channelActive \(context.channel)")
    }
    
    
    public func channelInactive(context: ChannelHandlerContext) {
        Logger.debug("[HL7CLient] channelInactive")
    }
    
    
    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let response = self.unwrapInboundIn(data)
                
        guard let type = response.type else {
            let message = "Cannot read message type"
            Logger.error(message)
            promise?.fail(HL7Error.unsupportedMessage(message: message))
            return
        }
            
        if type.name.starts(with: "ACK") || type.name.starts(with: "NAK") {
            promise?.succeed(response)

        } else {
            Logger.error("Unexpected Message: \(type.name)")
            promise?.fail(HL7Error.unexpectedMessage(message: type.name))
        }
    }
    
    
    public func errorCaught(context: ChannelHandlerContext, error: Error) {
        print("errorCaught \(error)")
        promise?.fail(error)
    }
}
