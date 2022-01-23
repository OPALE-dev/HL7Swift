//
//  File.swift
//  
//
//  Created by Rafael Warnault on 23/12/2021.
//

import Foundation
import NIO

public struct MLLPDecoder: ByteToMessageDecoder {
    public typealias InboundOut = Message
    
    var messageString = String()
    var startFound = false
    var endFound = false
    
    var hl7:HL7!
    var responder:HL7Responder!
    
    init(withHL7 hl7: HL7, responder: HL7Responder) {
        self.hl7        = hl7
        self.responder  = responder
    }
    
    public mutating func decode(context: ChannelHandlerContext, buffer: inout ByteBuffer) -> DecodingState {
        var byte = buffer.readString(length: 1)
        
        // read SB (0x0B)
        if byte == "\u{0B}" {
            startFound = true
        }
        
        if startFound {
            // read message until EB (0x1C) + CR (0x0D)
            while buffer.readableBytes > 0 && !endFound {
                byte = buffer.readString(length: 1)
                                
                if byte != "\u{1C}" {
                    messageString.append(byte!)
                    
                } else {
                    // read last CR
                    byte = buffer.readString(length: 1)
                    
                    if byte == "\r" {
                        endFound = true
                    }
                }
            }
        }
        
        if !startFound && !endFound {
            return .needMoreData
        }
        
        if endFound {
            do {
                let message = try Message(messageString, hl7: hl7)
                context.fireChannelRead(wrapInboundOut(message))
                
            } catch let e {
                context.fireErrorCaught(e)
                
                // reply NAK
                // try? responder.replyNAK(withMessage: e.localizedDescription, inContext: context)
            }

            // reset states
            messageString   = String()
            startFound      = false
            endFound        = false
        }
        
        return .continue
    }
}
