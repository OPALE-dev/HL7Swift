//
//  File.swift
//  
//
//  Created by Rafael Warnault on 23/12/2021.
//

import Foundation
import NIO


public protocol HL7ServerDelegate {
    func server(_ server:HL7Server, receive message:Message, from:String?)
    func server(_ server:HL7Server, send message:Message, to:String?)
    func server(_ server:HL7Server, ACKStatusFor message:Message) -> AcknowledgeStatus
}


public class HL7Server {
    var hl7:HL7!
    
    public var host:String  = "0.0.0.0"
    public var port:Int     = 2575
    
    var name:String         = "HL7SERVER"
    var facility:String     = "HL7SERVER"

    public var delegate:HL7ServerDelegate?
    var responder:HL7Responder!
    
    var channel: Channel!
    var group:MultiThreadedEventLoopGroup!
    var bootstrap:ServerBootstrap!
    
    
    public init(host: String, port: Int, hl7:HL7, delegate: HL7ServerDelegate? = nil) throws {
        self.hl7        = hl7
        self.host       = host
        self.port       = port
        self.delegate   = delegate
        
        self.responder = HL7Responder(hl7: hl7, spec: hl7.spec(ofVersion: .v282)!, facility: facility, app: name)
         
        self.group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        self.bootstrap = ServerBootstrap(group: group)
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .childChannelInitializer { channel in
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
        channel = try bootstrap.bind(host: host, port: port).wait()
        
        Logger.info("Server listening on port \(port)...")
        
        try channel.closeFuture.wait()
    }
    
    
    
    public func stop() throws {
        if channel != nil {
            channel.close(mode: .all, promise: nil)
            
            Logger.info("Server stopped.")
        }
    }
}
    
    

// MARK: -
extension HL7Server : ChannelInboundHandler, ChannelOutboundHandler {
    public typealias OutboundIn = Message
    public typealias InboundIn = Message
    public typealias OutboundOut = Message
    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let message = self.unwrapInboundIn(data)
        
        guard let spec = hl7.spec(ofVersion: message.version) else {
            Logger.error(HL7Error.unsupportedVersion(message: "Cannor read version").localizedDescription)
            
            //try? responder.replyNAK(withMessage: "Cannor read version", inContext: context)
            
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
            DispatchQueue.main.async {
                delegate.server(self, receive: message, from: fromTo)
            }
        }
        
        Logger.info("### Receive HL7 (\(spec.version.rawValue)) message:\n\n\(message)\n")
        
        // get remote name and facility (TODO: handle optionals below)
        let remoteName = message[HL7.MSH]![HL7.Sending_Application]
        let remoteFacility = message[HL7.MSH]![HL7.Sending_Facility]
        var status = AcknowledgeStatus.AA
        
        if let delegate = self.delegate {
            status = delegate.server(self, ACKStatusFor: message)
        }
        
        // reply ACK/NAK
        if let type = spec.type(forName: "ACK") {
            if let ack = try? Message(type, spec: spec, preloadSegments: ["MSH", "MSA"]) {
                // fill MSH
                ack[HL7.MSH]![HL7.Version_ID] = message.version.rawValue
                
                if let r = remoteFacility {
                    ack[HL7.MSH]![HL7.Receiving_Facility] = r
                }
                
                if let r = remoteName {
                    ack[HL7.MSH]![HL7.Receiving_Application] = r
                }
                
                ack[HL7.MSH]![HL7.Sending_Facility] = facility
                ack[HL7.MSH]![HL7.Sending_Application] = name
                
                ack[HL7.MSH]![HL7.Message_Type] = "ACK"
                // fill MSA
                ack[HL7.MSA]![HL7.Acknowledgment_Code] = status.rawValue
                ack[HL7.MSA]![HL7.Message_Control_ID] = "OK"
                
                Logger.info("### Reply ACK (\(ack.version.rawValue)):\n\n\(ack)\n")
                
                
                if let delegate = self.delegate {
                    DispatchQueue.main.async {
                        delegate.server(self, send: ack, to: fromTo)
                    }
                }
                
                _ = context.writeAndFlush(NIOAny(ack))
            }
        }
    }
    
    public func errorCaught(context: ChannelHandlerContext, error: Error) {
        Logger.error(error.localizedDescription)
        
        // TODO: test test test
        try? responder.replyNAK(withMessage: error.localizedDescription, inContext: context)
    }
}

