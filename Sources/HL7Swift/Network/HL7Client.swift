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

public class HL7CLient {
    public var host:String!
    public var port:Int!
    public var localPort:Int? = nil
    public var TLSEnabled:Bool = false
    public var certificateKeyPath:String? = nil
    public var privateKeyPath:String? = nil
    public var passphrase:String? = nil
    
    var hl7:HL7!
    var channel:Channel?
    var promise: EventLoopPromise<Message>?

    var tlsConfiguration:TLSConfiguration? = nil
    var sslContext:NIOSSLContext? = nil
    
    
    public init(host: String, port: Int, hl7: HL7, TLSEnabled:Bool = false) throws {
        self.host       = host
        self.port       = port
        self.hl7        = hl7
        self.TLSEnabled = TLSEnabled
    }

    
    
    // MARK: -
    
    public func connect() throws -> EventLoopFuture<Void> {
        let responder = HL7Responder(hl7: hl7, spec: hl7.spec(ofVersion: .v282)!, facility: "HL7SWIFT", app: "HL7CLIENT")

        if self.TLSEnabled {
            try initTLS()
        }
        
        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        let bootstrap = ClientBootstrap(group: group)
            .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .channelOption(ChannelOptions.maxMessagesPerRead, value: 16)
            .channelInitializer { channel in
                if let sslContext = self.sslContext, self.TLSEnabled {
                    print("SSL context OK")
                    do {
                        let TLShandler = try NIOSSLClientHandler(context: sslContext, serverHostname: self.host, customVerificationCallback: { certs, promise in
                            print("customVerificationCallback success")
                            return promise.succeed(.certificateVerified)
                        })
                        
                        print("TLShandler OK")
                        
                        return channel.pipeline.addHandler(TLShandler).flatMap {
                            channel.pipeline.addHandlers([
                                MessageToByteHandler(MLLPEncoder()),
                                ByteToMessageHandler(MLLPDecoder(withHL7: self.hl7, responder: responder)),
                                self
                            ])
                        }
                    } catch let e {
                        print(e)
                    }
                }
                
                return channel.pipeline.addHandlers([
                    MessageToByteHandler(MLLPEncoder()),
                    ByteToMessageHandler(MLLPDecoder(withHL7: self.hl7, responder: responder)),
                    self
                ])
            }
        
        
        
        return bootstrap
            .connect(host: self.host, port: self.port)
            .flatMap { channel in
                
            self.channel    = channel
            self.localPort  = self.channel?.localAddress?.port
            
            // make promise to receive ACK/NAK
            self.promise    = self.channel?.eventLoop.makePromise(of: Message.self)
                        
            return channel.eventLoop.makeSucceededVoidFuture()
        }
    }
    
    
    
    public func disconnect() {
        self.channel?.closeFuture.whenComplete { _ in
            Logger.info("Disconnected form \(self.host!):\(self.port!)")
        }
        
        self.promise?.fail(HL7Error.initError(message: ""))
        self.channel?.close(promise: nil)
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
                 
        try channel?.writeAndFlush(message).wait()
                
        return try promise?.futureResult.wait()
    }

}



private extension HL7CLient {
    func initTLS() throws {
        Logger.debug("TLS enabled")
        
        if let certificateKeyPath = self.certificateKeyPath,
           let privateKeyPath = self.privateKeyPath,
           let passphrase = self.passphrase
        {
            Logger.debug("TLS config OK")
            
            let cert = try NIOSSLCertificate(file: certificateKeyPath, format: .pem)
            let key = try NIOSSLPrivateKey(file: privateKeyPath, format: .pem) { completion in
                completion(passphrase.utf8)
            }
                    
            var conf = TLSConfiguration.makeClientConfiguration()
            conf.certificateVerification = .fullVerification
//            conf.renegotiationSupport = .none
//            conf.privateKey = .privateKey(key)
//            conf.trustRoots = .certificates([cert])

            self.tlsConfiguration = conf
            self.sslContext = try NIOSSLContext(configuration: conf)
            
            Logger.debug("TLS init done")
        }
    }
}



// MARK: -

extension HL7CLient: ChannelInboundHandler {
    public typealias InboundIn = Message
    public typealias OutboundOut = Message
    
    
    public func channelActive(context: ChannelHandlerContext) {
        Logger.debug("[HL7CLient] channelActive")
    }
    
    
    public func channelInactive(context: ChannelHandlerContext) {
        Logger.debug("[HL7CLient] channelInactive")
    }
    
    
    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let response = self.unwrapInboundIn(data)
        
        Logger.debug("[HL7CLient] channelRead \(response)")
        
        guard let type = response.type else {
            let message = "Cannot read message type"
            Logger.error(message)
            promise?.fail(HL7Error.unsupportedMessage(message: message))
            return
        }
        
        if type.name == "ACK" || type.name == "NAK" {
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
