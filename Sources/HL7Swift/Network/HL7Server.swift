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

public protocol HL7ServerDelegate {
    func server(serverStarted server:HL7Server)
    func server(serverStopped server:HL7Server)
    func server(_ server:HL7Server, receive message:Message, from:String?, channel:Channel)
    func server(_ server:HL7Server, send message:Message, to:String?, channel:Channel)
    func server(_ server:HL7Server, ACKStatusFor message:Message, channel:Channel) -> AcknowledgeStatus
    func server(_ server:HL7Server, channelDidBecomeActive channel:Channel)
    func server(_ server:HL7Server, channelDidBecomeInactive channel:Channel)
}


public extension HL7ServerDelegate {
    func server(serverStarted server:HL7Server) {
        
    }
    
    func server(serverStopped server:HL7Server) {
        
    }
}


public struct ServerConfiguration {
    public var hl7:HL7!

    public var host:String              = "0.0.0.0"
    public var port:Int                 = 2575
    
    public var name:String              = "HL7SERVER"
    public var facility:String          = "HL7SERVER"

    public var TLSEnabled:Bool          = false
    public var certificatePath:String?  = nil
    public var privateKeyPath:String?   = nil
    public var passphrase:String?       = nil
    
    public init(_ hl7: HL7) {
        self.hl7 = hl7
    }
}


public class HL7Server {
    var hl7:HL7
    
    public var config:ServerConfiguration
    public var delegate:HL7ServerDelegate?
    var responder:HL7Responder!
    
    var channel: Channel!
    var group:MultiThreadedEventLoopGroup!
    var bootstrap:ServerBootstrap!
    
    var tlsConfiguration:TLSConfiguration? = nil
    var sslContext:NIOSSLContext? = nil
    
    public init(_ config:ServerConfiguration, delegate: HL7ServerDelegate? = nil) throws {
        self.config     = config
        self.hl7        = config.hl7
        self.delegate   = delegate
        
        self.responder = HL7Responder(hl7: hl7, spec: hl7.spec(ofVersion: .v282)!, facility: config.facility, app: config.name)
        
        if config.TLSEnabled {
            try initTLS()
        }
         
        self.group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        self.bootstrap = ServerBootstrap(group: group)
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .childChannelInitializer { channel in
                if self.config.TLSEnabled {
                    if let context = self.sslContext {
                        let TLShandler = NIOSSLServerHandler(context: context) { certs, promise in
                            Logger.debug("NIOSSLServerHandler")
                            promise.succeed(.certificateVerified)
                        }
                        return channel.pipeline.addHandler(TLShandler).flatMap {
                            channel.pipeline.addHandlers([
                                MessageToByteHandler(MLLPEncoder()),
                                ByteToMessageHandler(MLLPDecoder(withHL7: self.hl7, responder: self.responder)),
                                self
                            ])
                        }
                    }
                }
                
                return channel.pipeline.addHandlers([
                    MessageToByteHandler(MLLPEncoder()),
                    ByteToMessageHandler(MLLPDecoder(withHL7: self.hl7, responder: self.responder)),
                    self
                ])
            }
            .childChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 16)
            .childChannelOption(ChannelOptions.recvAllocator, value: AdaptiveRecvByteBufferAllocator())
    }
    
    
    
    deinit {
        if channel != nil {
            channel.close(mode: .all, promise: nil)
        }
        
        try? group.syncShutdownGracefully()
    }
    
    
    
    public func start() throws {
        channel = try bootstrap.bind(host: config.host, port: config.port).wait()
        
        Logger.info("Server listening on port \(config.port)...")
        
        if let delegate = self.delegate {
            delegate.server(serverStarted: self)
        }
        
        try channel.closeFuture.wait()
    }
    
    
    
    public func stop() throws {
        if channel != nil {
            channel.close(mode: .all, promise: nil)
            
            if let delegate = self.delegate {
                delegate.server(serverStopped: self)
            }
            
            Logger.info("Server stopped.")
        }
    }
}
    


private extension HL7Server {
    func initTLS() throws {
        Logger.info("TLS enabled")
        
        if let certificatePath = config.certificatePath,
           let privateKeyPath = config.privateKeyPath,
           let passphrase = config.passphrase
        {
            let key = try NIOSSLPrivateKey(file: privateKeyPath, format: .pem) { completion in
                completion(passphrase.utf8)
            }
            
            self.tlsConfiguration = TLSConfiguration.makeServerConfiguration(
                certificateChain: try NIOSSLCertificate.fromPEMFile(certificatePath).map { .certificate($0) },
                privateKey: .privateKey(key)
            )
            
            if var conf = self.tlsConfiguration {
                conf.certificateVerification = .none
                self.sslContext = try NIOSSLContext(configuration: conf)
                                
                Logger.debug("TLS init done")
                Logger.debug("\(self.tlsConfiguration!)")
            }
        }
    }
}
    

// MARK: -
extension HL7Server : ChannelInboundHandler, ChannelOutboundHandler {
    public typealias OutboundIn = Message
    public typealias InboundIn = Message
    public typealias OutboundOut = Message
    
    public func channelRegistered(context: ChannelHandlerContext) {
        Logger.debug("Channel registered \(context.channel)")
    }
    
    public func channelUnregistered(context: ChannelHandlerContext) {
        Logger.debug("Channel unregistered \(context.channel)")
    }
    
    public func channelActive(context: ChannelHandlerContext) {
        Logger.debug("Channel active \(context.channel)")
        
        if let delegate = self.delegate {
            //DispatchQueue.main.async {
                delegate.server(self, channelDidBecomeActive: context.channel)
            //}
        }
    }
    
    public func channelInactive(context: ChannelHandlerContext) {
        Logger.debug("Channel inactive \(context.channel)")
        if let delegate = self.delegate {
            //DispatchQueue.main.async {
                delegate.server(self, channelDidBecomeInactive: self.channel)
            //}
        }
    }
    
    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let message = self.unwrapInboundIn(data)
        
        guard let spec = hl7.spec(ofVersion: message.version) else {
            Logger.error(HL7Error.unsupportedVersion(message: "Cannor read version").localizedDescription)
            
            //try? responder.replyNAK(withMessage: "Cannot read version", inContext: context)
            
            return
        }
        
        var fromTo:String? = nil
        
        if let addr = context.remoteAddress,
           let ip = addr.ipAddress,
           let port = addr.port
        {
            fromTo = "\(ip):\(port)"
        }
        
        if let delegate = self.delegate {
            delegate.server(self, receive: message, from: fromTo, channel: context.channel)
        }
        
        Logger.info("### Received HL7 (\(spec.version.rawValue)) message \(message.type.name)")
        Logger.debug("\n\n\(message)\n")
        
        // get remote name and facility (TODO: handle optionals below)
        let remoteName = message[HL7.MSH]![HL7.Sending_Application]
        let remoteFacility = message[HL7.MSH]![HL7.Sending_Facility]
        var status = AcknowledgeStatus.AA
        
        if let delegate = self.delegate {
            status = delegate.server(self, ACKStatusFor: message, channel: context.channel)
        }
        
        // reply ACK/NAK
        if let type = try? HL7.V251(.v251).type(forName: "ACK") {
            if let ack = try? Message(type, spec: HL7.V251(.v251), preloadSegments: ["MSH", "MSA"]) {
                // fill MSH
                ack[HL7.MSH]![HL7.Version_ID] = message.version.rawValue
                
                if let r = remoteFacility {
                    ack[HL7.MSH]![HL7.Receiving_Facility] = r
                }
                
                if let r = remoteName {
                    ack[HL7.MSH]![HL7.Receiving_Application] = r
                }
                
                let messageControlID = message[HL7.MSH]?[HL7.Message_Control_ID]
                
                ack[HL7.MSH]![2] = message[HL7.MSH]?[2]
                ack[HL7.MSH]![HL7.Sending_Facility] = config.facility
                ack[HL7.MSH]![HL7.Sending_Application] = config.name
                
                ack[HL7.MSH]![HL7.Message_Control_ID] = messageControlID
                ack[HL7.MSH]![HL7.Message_Type] = "ACK"
                
                // fill MSA
                ack[HL7.MSA]![HL7.Acknowledgment_Code] = status.rawValue
                ack[HL7.MSA]![HL7.Message_Control_ID] = messageControlID
                
                Logger.info("### Reply ACK (\(ack.version.rawValue))")
                Logger.debug("\n\n\(ack)\n")
                
                if let delegate = self.delegate {
                    delegate.server(self, send: ack, to: fromTo, channel: context.channel)
                }
                
                _ = context.writeAndFlush(NIOAny(ack))
            }
        }
    }
    
    public func errorCaught(context: ChannelHandlerContext, error: Error) {
        // Ignore unclean shutdown from TLS
        // TODO: check if it's OK in this particular case
        // hint: https://github.com/apple/swift-nio-ssl/issues/18
        if let nioError = error as? NIOSSLError {
            if self.config.TLSEnabled {
                if nioError == .uncleanShutdown {
                    return
                }
            }
        }
        
        Logger.error(error.localizedDescription)
        
        // Reply NAK in case of error
        // TODO: test test test
        try? responder.replyNAK(withMessage: error.localizedDescription, inContext: context)
    }
}

