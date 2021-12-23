//
//  File.swift
//  
//
//  Created by Rafael Warnault on 23/12/2021.
//

import Foundation
import NIO

extension Data {
    public func toHex() -> String {
        return self.reduce("") { $0 + String(format: "%02x", $1) }
    }
}
    

public struct MLLPEncoder: MessageToByteEncoder {
    public typealias OutboundIn = Message
   
    public init() {

    }
    
    
    public func encode(data: Message, out: inout ByteBuffer) throws {
        guard let messageData = data.description.data(using: .ascii) else {
            throw HL7Error.encondingFailed(message: "Cannot encode message as ASCII")
        }
        
        var outData = Data()
        
        withUnsafeBytes(of: UInt8(0x0B)) { outData.append(contentsOf: $0) }
        
        outData.append(messageData)
        
        withUnsafeBytes(of: UInt8(0x1C)) { outData.append(contentsOf: $0) }
        withUnsafeBytes(of: UInt8(0x0D)) { outData.append(contentsOf: $0) }
                
        out = ByteBuffer(bytes: outData)
    }
}

