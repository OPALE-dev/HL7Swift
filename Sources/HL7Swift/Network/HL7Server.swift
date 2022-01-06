//
//  File.swift
//  
//
//  Created by Rafael Warnault on 23/12/2021.
//

import Foundation
import NIO


public protocol HL7ServerDelegate {
    func server(_ server:HL7Server, receive message:Message)
    func server(_ server:HL7Server, ACKStatusFor message:Message) -> AcknowledgeStatus
}


public class HL7Server {
    var hl7:HL7!
    
    var host:String     = "0.0.0.0"
    var port:Int        = 2575
    
    var name:String     = "HL7SERVER"
    var facility:String = "HL7SERVER"

    var delegate:HL7ServerDelegate?
    
    var channel: Channel!
    var group:MultiThreadedEventLoopGroup!
    var bootstrap:ServerBootstrap!
    
    
    public init(host: String, port: Int, delegate: HL7ServerDelegate? = nil) throws {
        self.hl7        = try HL7()
        self.host       = host
        self.port       = port
        self.delegate   = delegate
         
        self.group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        self.bootstrap = ServerBootstrap(group: group)
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .childChannelInitializer { channel in
                return channel.pipeline.addHandlers([
                    MessageToByteHandler(MLLPEncoder()),
                    ByteToMessageHandler(MLLPDecoder(withHL7: self.hl7)),
                    self
                ])
            }
            .childChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 16)
            .childChannelOption(ChannelOptions.recvAllocator, value: AdaptiveRecvByteBufferAllocator())
    }
    
    
    
    deinit {
        channel.close(mode: .all, promise: nil)

        try? group.syncShutdownGracefully()
    }
    
    
    
    public func start() throws {
        channel = try bootstrap.bind(host: host, port: port).wait()
        
        Logger.info("Server listening on port \(port)...")
        
        try channel.closeFuture.wait()
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
            return
        }
        
        if let delegate = self.delegate {
            delegate.server(self, receive: message)
        }
        
        // get remote name and facility
        let remoteName = message.segments[0].fields[1].description
        let remoteFacility = message.segments[0].fields[1].description
        
        var status = AcknowledgeStatus.AA
        
        if let delegate = self.delegate {
            status = delegate.server(self, ACKStatusFor: message)
        }
        
        // build reply message against spec
        print("build reply message against spec")
        if let type = spec.type(forName: "ACK") {
            let ack = try? Message(type, spec: spec, preloadSegments: ["MSH", "MSA"])
            
            print(ack!)
        }
        
        // reply ACK/NAK
        let ack = """
        MSH|^~\\&|\(self.name)|\(self.facility)|\(remoteName)|\(remoteFacility)|||ACK|1|D|\(spec.version.rawValue)||||||
        MSA|\(status)|OK|
        """
        
        print(ack)

        do {
            _ = context.writeAndFlush(NIOAny(try Message(ack, hl7: self.hl7)))
        } catch let e {
            context.fireErrorCaught(e)
        }
    }
    
    public func errorCaught(context: ChannelHandlerContext, error: Error) {
        Logger.error(error.localizedDescription)
    }
}

