//
//  File.swift
//  
//
//  Created by Rafael Warnault on 15/02/2022.
//

import Foundation
import ModelsR4
import SwiftCSV
import HL7Swift




public class HL72FHIRR4Client: HL72FHIRR4Converter {
    var client:FHIRClient!

    public override var description: String {
        "HL7v2.x To FHIR ModelsR4 Client"
    }
    
    public init(_ client: FHIRClient) throws {
        try super.init()
        
        self.client = client
    }
    
    public func translate(_ message:Message) throws {
        guard supportedMessages.contains(message.type.name) else {
            throw HL72FHIRR4Error.unsupportedMessage(
                message: "HL7 Message of type \(message.type.name) is not supported by \(description)")
        }
                
        let bundle = ModelsR4.Bundle(entry: [], type: BundleType.message.asPrimitive())
                
        // MSH
        if let msh = message[HL7.MSH] {
            let header = try header(MSHSegment: msh)
            
            if let header = header {
                bundle.entry?.append(BundleEntry(resource: ResourceProxy(with: header)))
            }
        }
        
        // PID
        if let pid = message[HL7.PID] {
            let patient = try convert(PIDSegment: pid)
            let patientID = patient.identifier?.first?.value?.value?.string
            
            // search for existing patient
            if patientID != nil {
                let result = try self.client.read("Patient", params: ["identifier": patientID!])
                
                switch result {
                case .error(let e):
                    switch e {
                    case FHIRClientError.readNotFound(message: _):
                        // create patient
                        break
                    default:
                        break
                    }
                case .success(_, _):
                    // nothing to do
                    break
                }
            }
            
            
//            // PV1
//            if let pv1 = message[HL7.PV1] {
//                if let encounter = try convert(PV1Segment: pv1) {
//                    encounter.subject = Reference(
//                        display: patient.id, id: patient.id,
//                        identifier: patient.identifier?.first,
//                        reference: "patient", type: "Patient")
//
//                    bundle.entry?.append(BundleEntry(resource: ResourceProxy(with: encounter)))
//                }
//            }
//
//            bundle.entry?.append(BundleEntry(resource: ResourceProxy(with: patient)))
        }
    }
}
