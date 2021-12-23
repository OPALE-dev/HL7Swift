//
//  File.swift
//  
//
//  Created by Rafael Warnault on 23/12/2021.
//

import Foundation
import NIO

public struct MLLPEncoder: MessageToByteEncoder {
    public typealias OutboundIn = Message
   
    public init() {

    }
    
    
    public func encode(data: Message, out: inout ByteBuffer) throws {
        
    }
}

