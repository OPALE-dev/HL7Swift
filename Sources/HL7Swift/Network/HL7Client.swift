//
//  File.swift
//  
//
//  Created by Rafael Warnault on 23/12/2021.
//

import Foundation
import NIO

public class HL7CLient: ChannelInboundHandler {
    public typealias InboundIn = ByteBuffer
    public typealias OutboundOut = ByteBuffer
    
    var host:String!
    var port:Int!
    
    var channel:Channel?
    
    public init(host: String, port: Int) {
        self.host = host
        self.port = port
    }

    
    
    // MARK: -
    
    public func connect() -> EventLoopFuture<Void> {
        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        
        let bootstrap = ClientBootstrap(group: group)
            .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .channelOption(ChannelOptions.maxMessagesPerRead, value: 10)
            .channelInitializer { channel in
                channel.pipeline.addHandlers([
                    MessageToByteHandler(MLLPEncoder()),
                    ByteToMessageHandler(MLLPDecoder()),
                    self
                ])
        }
        
        return bootstrap
            .connect(host: self.host, port: self.port)
            .flatMap { channel in
                
            self.channel = channel
                        
            return channel.eventLoop.makeSucceededVoidFuture()
        }
    }
    
    
    
    public func disconnect() {
        self.channel?.closeFuture.whenComplete { _ in

        }
        
        self.channel?.close(promise: nil)
    }
    
    
    
    // MARK: -
    
    public func send(fileAt path:String) throws {
        let message = try Message(withFileAt: path)
        
        try self.send(message)
    }
    
    
    public func send(messageAs string:String) throws {
        let message = Message(string)
        
        try self.send(message)
    }
    
    
    public func send(_ message: Message?) throws {
        guard let message = message else {
            return
        }
        
        //let buffer = channel?.allocator.buffer(string: message.description)
        
        try channel!.writeAndFlush(message).wait()
    }
    
    
    
    
    // MARK: -
    
    public func channelActive(context: ChannelHandlerContext) {
        
    }
    
    
    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        print("channelRead")
    }
    

    
    
    // MARK: -

}
