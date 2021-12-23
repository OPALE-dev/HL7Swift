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
    
    public func encode(data: Message, out: inout ByteBuffer) throws {
        guard let messageData = data.description.data(using: .utf8) else {
            throw HL7Error.encondingFailed(message: "Cannot encode message as UTF-8")
        }
        
        var outData = Data()
        
        // append SB 0x0B
        withUnsafeBytes(of: UInt8(0x0B)) { outData.append(contentsOf: $0) }
        
        // append HL7 data
        outData.append(messageData)
        
        // append EB + CR (0x1C + 0x0D)
        withUnsafeBytes(of: UInt8(0x1C)) { outData.append(contentsOf: $0) }
        withUnsafeBytes(of: UInt8(0x0D)) { outData.append(contentsOf: $0) }
                
        out = ByteBuffer(bytes: outData)
    }
}

