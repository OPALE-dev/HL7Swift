//
//  File.swift
//  
//
//  Created by Rafael Warnault on 23/12/2021.
//

import Foundation
import NIO

public class HL7CLient {
    var host:String!
    var port:Int!
    
    var hl7:HL7!
    var channel:Channel?
    var promise: EventLoopPromise<Message>?

    
    public init(host: String, port: Int) throws {
        self.host = host
        self.port = port
        
        self.hl7 = try HL7()
    }

    
    
    // MARK: -
    
    public func connect() -> EventLoopFuture<Void> {
        let responder = HL7Responder(hl7: hl7, spec: hl7.spec(ofVersion: .v282)!, facility: "HL7SWIFT", app: "HL7CLIENT")

        let group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        
        let bootstrap = ClientBootstrap(group: group)
            .channelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .channelOption(ChannelOptions.maxMessagesPerRead, value: 10)
            .channelInitializer { channel in
                channel.pipeline.addHandlers([
                    MessageToByteHandler(MLLPEncoder()),
                    ByteToMessageHandler(MLLPDecoder(withHL7: self.hl7, responder: responder)),
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
            Logger.info("Disconnected form \(self.host!):\(self.port!)")
        }
        
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



    // MARK: -
extension HL7CLient: ChannelInboundHandler {
    public typealias InboundIn = Message
    public typealias OutboundOut = Message
    
    
    public func channelActive(context: ChannelHandlerContext) {
        Logger.debug("channelActive")
    }
    
    
    public func channelInactive(context: ChannelHandlerContext) {
        Logger.debug("channelInactive")
    }
    
    
    public func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let response = self.unwrapInboundIn(data)
        
        guard let type = response.type else {
            promise?.fail(HL7Error.unsupportedMessage(message: "Cannot read message type"))
            return
        }
        
        if type.name == "ACK" || type.name == "NAK" {
            promise?.succeed(response)

        } else {
            promise?.fail(HL7Error.unexpectedMessage(message: type.name))
        }
    }
    
    
    public func errorCaught(context: ChannelHandlerContext, error: Error) {
        promise?.fail(error)
    }
}
