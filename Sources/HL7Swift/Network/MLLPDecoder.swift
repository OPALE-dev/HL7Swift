//
//  File.swift
//  
//
//  Created by Rafael Warnault on 23/12/2021.
//

import Foundation
import NIO

public struct MLLPDecoder: ByteToMessageDecoder {
    public typealias InboundOut = ByteBuffer
    public typealias OutboundOut = Message
    
   
    public init() {

    }
    

    public mutating func decode(context: ChannelHandlerContext, buffer: inout ByteBuffer) -> DecodingState {
        
        // return .continue
        
        return .continue
    }
}
