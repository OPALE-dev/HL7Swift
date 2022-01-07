//
//  File.swift
//  
//
//  Created by Rafael Warnault on 07/01/2022.
//

import Foundation
import NIO

class HL7Responder {
    var spec: Versioned!
    var hl7: HL7!
    var facility:String!
    var app:String!
    
    init(hl7: HL7, spec: Versioned, facility: String, app: String) {
        self.hl7        = hl7
        self.spec       = spec
        self.app        = app
        self.facility   = facility
    }
    
    func replyNAK(withMessage text:String, inContext context: ChannelHandlerContext) throws {
        let version = spec.version

        if let spec = hl7.spec(ofVersion: version) {
            let nak = try Message(HL7.V282.ACK(), spec: spec, preloadSegments: [HL7.MSH, HL7.MSA])
            
            print(nak[HL7.MSH]![HL7.Receiving_Application]!)
            
            // MSH
//            nak[HL7.MSH]![HL7.Receiving_Facility]! = Field("UNKNOW")
//            //nak[HL7.MSH]![HL7.Receiving_Application]! = Field("UNKNOW")
//            nak[HL7.MSH]![HL7.Sending_Facility]! = Field(facility)
//            nak[HL7.MSH]![HL7.Sending_Application]! = Field(app)
            nak[HL7.MSH]![HL7.Message_Type]! = Field("NAK")
            
            // MSA
            nak[HL7.MSA]![HL7.Acknowledgment_Code]! = Field(AcknowledgeStatus.AR.rawValue)
//            nak[HL7.MSA]![HL7.Message_Control_ID]! = Field("KO")
            
            Logger.info("### Reply NAK (\(nak.version.rawValue)):\n\n\(nak)\n")
            
            _ = context.writeAndFlush(NIOAny(nak))
        }
    }
}
