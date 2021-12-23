//
//  File.swift
//  
//
//  Created by Rafael Warnault on 23/12/2021.
//

import Foundation
import NIO

public class HL7CLient: ChannelInboundHandler {
    public typealias InboundIn = Message
    public typealias OutboundOut = Message
    
    var host:String!
    var port:Int!
    
    var channel:Channel?
    var promise: EventLoopPromise<Message>?

    
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
            
            // make promise to receive ACK/NAK
            self.promise = self.channel?.eventLoop.makePromise(of: Message.self)
                        
            return channel.eventLoop.makeSucceededVoidFuture()
        }
    }
    
    
    
    public func disconnect() {
        self.channel?.closeFuture.whenComplete { _ in

        }
        
        self.channel?.close(promise: nil)
    }
    
    
    
    // MARK: -
    
    public func send(fileAt path:String) throws -> Message?  {
        let message = try Message(withFileAt: path)
        
        return try self.send(message)
    }
    
    
    public func send(messageAs string:String) throws -> Message?  {
        let message = Message(string)
        
        return try self.send(message)
    }
    
    
    public func send(_ message: Message?) throws -> Message? {
        guard let message = message else {
            return nil
        }
         
        try channel?.writeAndFlush(message).wait()
        
        return try promise?.futureResult.wait()
    }
    
    
    
    
    // MARK: -
    
    public func channelActive(context: ChannelHandlerContext) {
        Logger.debug("channelActive")
    }
    
    
    public func channelInactive(context: ChannelHandlerContext) {
        Logger.debug("channelInactive")
    }
    
    
    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let response = self.unwrapInboundIn(data)
                
        if response.getType() == "ACK" || response.getType() == "NAK" {
            promise?.succeed(response)

        } else {
            promise?.fail(HL7Error.unexpectedMessage(message: response.getType()))
        }
    }
    
    
    public func errorCaught(context: ChannelHandlerContext, error: Error) {
        promise?.fail(error)
    }
    
    
    
    // MARK: -

}
