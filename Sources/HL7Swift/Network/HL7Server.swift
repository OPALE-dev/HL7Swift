//
//  File.swift
//  
//
//  Created by Rafael Warnault on 23/12/2021.
//

import Foundation
import NIO

public class HL7Server : ChannelInboundHandler {
    public typealias InboundIn = Message
    
    var host:String = "0.0.0.0"
    var port:Int = 2575
    var dir:String = "~/hl7"
    
    var channel: Channel!
    var group:MultiThreadedEventLoopGroup!
    var bootstrap:ServerBootstrap!
    
    
    public init(host: String, port: Int, dir: String) throws {
        self.host = host
        self.port = port
        self.dir  = NSString(string: dir).expandingTildeInPath
        
        // make sure dir exist, else try to create it
        if !FileManager.default.fileExists(atPath: self.dir) {
            try FileManager.default.createDirectory(at: URL(fileURLWithPath: self.dir), withIntermediateDirectories: true, attributes: nil)
        }
                
        self.group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        self.bootstrap = ServerBootstrap(group: group)
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .childChannelInitializer { channel in
                return channel.pipeline.addHandlers([
                    MessageToByteHandler(MLLPEncoder()),
                    ByteToMessageHandler(MLLPDecoder()),
                    self
                ])
            }
            .childChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 16)
            .childChannelOption(ChannelOptions.recvAllocator, value: AdaptiveRecvByteBufferAllocator())
    }
    
    
    public func start() throws {
        defer {
            try? group.syncShutdownGracefully()
        }
        
        channel = try bootstrap.bind(host: host, port: port).wait()
        
        Logger.info("Server listening on port \(port)...")
        
        try channel.closeFuture.wait()
    }
    
    
    
    // MARK: -
    
    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let message = self.unwrapInboundIn(data)
        let timeInterval = NSDate().timeIntervalSince1970
        let filePath = "\(dir)/\(message.getType())-\(timeInterval).hl7"
        
        print(message.getType())
        
        do {
            try message.description.write(toFile: filePath, atomically: true, encoding: .utf8)
            
        } catch let e {
            Logger.error("FS write error: \(e.localizedDescription)")
        }
    }
}

