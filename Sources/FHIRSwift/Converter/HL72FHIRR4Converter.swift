//
//  File.swift
//  
//
//  Created by Rafael Warnault on 13/02/2022.
//

import Foundation
import ModelsR4
import SwiftCSV
import HL7Swift



public enum HL72FHIRR4Error: LocalizedError, Equatable {
    case unsupportedMessage(message: String)

    public var errorDescription: String? {
        switch self {
  
        case .unsupportedMessage(message: let message):
            return "Unsupported HL7 Message: \(message)"
        }
    }
}


/**
 This class imlements HL7 (v2) to FHIR (Models R4) routines to help translate
 HL7 messages to FHIRE resources.
 */
public class HL72FHIRR4Converter: Converter, CustomStringConvertible {
    var csvMessages:[String:CSV] = [:]
    
    public var description: String {
        "HL7v2.x To FHIR ModelsR4 Converter"
    }
    
    public init() throws {
        try load()
    }
    
    
    /**
     Converts HL7Swift.Message to FHIR JSON string
     */
    public func convert(message:Message, formatting: JSONEncoder.OutputFormatting = []) throws -> String? {
        let encoder = JSONEncoder()
        let bundle = try convert(message)
        
        encoder.outputFormatting = formatting

        let data = try encoder.encode(bundle)
        
        return String(data: data, encoding: .utf8)
    }
    
    
    /**
     Converts HL7Swift.Message to FHIR ModelsR4.Bundle
     */
    public func convert(_ message:Message) throws -> ModelsR4.Bundle? {
        guard csvMessages[message.type.name] != nil else {
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
            
            // PV1
            if let pv1 = message[HL7.PV1] {
                if let encounter = try convert(PV1Segment: pv1) {
                    encounter.subject = Reference(
                        display: patient.id, id: patient.id,
                        identifier: patient.identifier?.first,
                        reference: "patient", type: "Patient")
                    
                    bundle.entry?.append(BundleEntry(resource: ResourceProxy(with: encounter)))
                }
            }
            
            bundle.entry?.append(BundleEntry(resource: ResourceProxy(with: patient)))
        }
        
        return bundle
    }
    
    /**
     Converts HL7 MSH segment to FHIR MessageHeader resource
     */
    func header(MSHSegment msh:Segment) throws -> MessageHeader? {
        let source = MessageHeaderSource(endpoint: "hl7:undef".asFHIRURIPrimitive()!)
        let destination = MessageHeaderDestination(endpoint: "hl7:undef".asFHIRURIPrimitive()!)
        
        // Sending Application
        if let field = msh[3] {
            if let cell = field.cells.first {
                source.software = HD(cell).universalID?.asFHIRStringPrimitive()
            }
        }
        
        // Sending Facility
        if let field = msh[4] {
            if let cell = field.cells.first {
                source.name = HD(cell).universalID?.asFHIRStringPrimitive()
            }
        }
        
        // Receiving Application
        if let field = msh[5] {
            if let cell = field.cells.first {
                destination.name = HD(cell).universalID?.asFHIRStringPrimitive()
            }
        }
        
        // no equivalent of HL7 `Receiving Facility` in FHIR ?
        if let field = msh[6] {
            if let cell = field.cells.first {
                destination.name = HD(cell).universalID?.asFHIRStringPrimitive()
            }
        }
        
        let header = MessageHeader(destination: [destination], event: MessageHeader.EventX.coding(Coding.init(code: msh[HL7.Message_Type]?.asFHIRStringPrimitive())), source: source)
        
        return header
    }
    
    /**
     Converts HL7 PV1 segment to FHIR Encounter resource
     */
    func convert(PV1Segment pv1:Segment) throws -> Encounter? {
        guard let patientClass = pv1[2]?.description else { return nil }
        
        let coding = Coding.init(code: patientClass.asFHIRStringPrimitive(), system: "HL7")
        let encounter = Encounter(class: coding, location: [], status: EncounterStatus.unknown.asPrimitive())
        
        encounter.text = Narrative(div: "<div xmlns=\"http://www.w3.org/1999/xhtml\">Patient imported from HL7 with FHIRSwift:PV1</div>".asFHIRStringPrimitive(), status: NarrativeStatus.generated.asPrimitive())
        
        // Patient Location
        if let field = pv1[3] {
            for cell in field.cells {
                let pl = PL(cell)

                if let v = pl.pointOfCare {
                    let encounterLocation = EncounterLocation(location: Reference())
                    
                    encounterLocation.physicalType = CodeableConcept(coding: [Coding.init(code: "Point Of Care", system: "HL7")], text: v.asFHIRStringPrimitive())

                    encounter.location?.append(encounterLocation)
                }
                
                if let v = pl.room {
                    let encounterLocation = EncounterLocation(location: Reference())
                    encounterLocation.physicalType = CodeableConcept(coding: [Coding.init(code: "Room", system: "HL7")], text: v.asFHIRStringPrimitive())

                    encounter.location?.append(encounterLocation)
                }
                
                if let v = pl.bed {
                    let encounterLocation = EncounterLocation(location: Reference())
                    encounterLocation.physicalType = CodeableConcept(coding: [Coding.init(code: "Bed", system: "HL7")], text: v.asFHIRStringPrimitive())

                    encounter.location?.append(encounterLocation)
                }
                
                if let v = pl.facility {
                    let encounterLocation = EncounterLocation(location: Reference())
                    encounterLocation.physicalType = CodeableConcept(coding: [Coding.init(code: "Facility", system: "HL7")], text: v.asFHIRStringPrimitive())

                    encounter.location?.append(encounterLocation)
                }
                
                if let v = pl.floor {
                    let encounterLocation = EncounterLocation(location: Reference())
                    encounterLocation.physicalType = CodeableConcept(coding: [Coding.init(code: "Floor", system: "HL7")], text: v.asFHIRStringPrimitive())

                    encounter.location?.append(encounterLocation)
                }

            }
        }
        
        // Admission Type
        if let field = pv1[4] {
            encounter.type = [CodeableConcept(coding: [Coding.init(code: "Admission Type", system: "HL7")], text: field.description.asFHIRStringPrimitive())]
        }
        
        // Preadmit Number
        if let field = pv1[5] {
            if encounter.hospitalization == nil {
                encounter.hospitalization = EncounterHospitalization()
            }
            
            encounter.hospitalization?.preAdmissionIdentifier = Identifier(value: field.description.asFHIRStringPrimitive())
        }
        
        return encounter
    }
    
    /**
     Converts HL7 PID segment to FHIR Patient resource
     */
    func convert(PIDSegment pid:Segment) throws -> Patient {
        let patient = Patient(address: [], identifier: [], name: [], telecom: [])
        
        // Patient ID
        if let field = pid[3] {
            for cell in field.cells {
                let cx = CX(cell)
                let identifier = Identifier()
                    
                identifier.assigner = Reference(display: cx.assigningAuthority?.asFHIRStringPrimitive())
                identifier.value = cx.id?.asFHIRStringPrimitive()
                    
                patient.identifier?.append(identifier)
            }
            
        }
        
        // Patient Name
        if let field = pid[5] {
            for cell in field.cells {
                let xpn = XPN(cell)
                let hn = HumanName(given: [], prefix: [], suffix: [])
                
                hn.family = xpn.familyName?.asFHIRStringPrimitive()
                hn.use = xpn.nameUse?.asPrimitive()
                
                if let prefix = xpn.prefix?.asFHIRStringPrimitive() {
                    hn.prefix?.append(prefix)
                }
                
                if let suffix = xpn.suffix?.asFHIRStringPrimitive() {
                    hn.suffix?.append(suffix)
                }
                
                if let givenName = xpn.givenName {
                    hn.given?.append(givenName.asFHIRStringPrimitive())
                }
                
                if let secondName = xpn.secondAndFurtherGivenNamesOrInitialsThereof {
                    hn.given?.append(secondName.asFHIRStringPrimitive())
                }
                
                // set resource narrative
                patient.text = Narrative(div: "<div xmlns=\"http://www.w3.org/1999/xhtml\">\(xpn.description)</div>".asFHIRStringPrimitive(), status: NarrativeStatus.generated.asPrimitive())
                
                patient.name?.append(hn)
            }
        }
        
        // Patient BirthDate
        if let field = pid[7] {
            let ts = TS(field)
            
            if let t = ts.time {
                try patient.birthDate?.value = FHIRDate(t)
            }
        }
        
        // Patient Sex
        if let field = pid[8]?.description {
            if field == "F" {
                patient.gender = AdministrativeGender.female.asPrimitive()
            }
            else if field == "M" {
                patient.gender = AdministrativeGender.male.asPrimitive()
            }
            else if field == "O" {
                patient.gender = AdministrativeGender.other.asPrimitive()
            }
        }
        
        // Patient Address
        if let field = pid[11] {
            for cell in field.cells {
                let cx = XAD(cell)
                let addr = Address()
                
                addr.line = []
                
                if let sa = cx.streetAddress?.asFHIRStringPrimitive() {
                    addr.line?.append(sa)
                }
                
                if let od = cx.otherDesignation?.asFHIRStringPrimitive() {
                    addr.line?.append(od)
                }
                
                addr.city = cx.city?.asFHIRStringPrimitive()
                addr.postalCode = cx.zipOrPostalCode?.asFHIRStringPrimitive()
                addr.state = cx.stateOrProvince?.asFHIRStringPrimitive()
                addr.use = cx.addressUse?.asPrimitive()
                addr.country = cx.country?.asFHIRStringPrimitive()
                
                patient.address?.append(addr)
            }
        }
        
        // Patient Phone Numbers
        if let field = pid[13] {
            for cell in field.cells {
                let xtn = XTN(cell)
                
                if xtn.telephoneNumber != nil && !xtn.telephoneNumber!.isEmpty {
                    let contact = ContactPoint()
                    
                    contact.system = ContactPointSystem.phone.asPrimitive()
                    contact.value = xtn.telephoneNumber?.asFHIRStringPrimitive()
                    contact.use = ContactPointUse.home.asPrimitive()
                    
                    patient.telecom?.append(contact)
                }
                else if xtn.emailAddress != nil && !xtn.emailAddress!.isEmpty {
                    let contact = ContactPoint()
                    
                    contact.system = ContactPointSystem.email.asPrimitive()
                    contact.value = xtn.emailAddress?.asFHIRStringPrimitive()
                    contact.use = ContactPointUse.home.asPrimitive()
                    
                    patient.telecom?.append(contact)
                }
            }
        }
        
        if let field = pid[14] {
            for cell in field.cells {
                let xtn = XTN(cell)
                if xtn.telephoneNumber != nil && xtn.telephoneNumber!.isEmpty {
                    let contact = ContactPoint()
                    
                    contact.system = ContactPointSystem.phone.asPrimitive()
                    contact.value = xtn.telephoneNumber?.asFHIRStringPrimitive()
                    contact.use = ContactPointUse.work.asPrimitive()
                    
                    patient.telecom?.append(contact)
                }
                else if xtn.emailAddress != nil && xtn.emailAddress!.isEmpty {
                    let contact = ContactPoint()
                    
                    contact.system = ContactPointSystem.email.asPrimitive()
                    contact.value = xtn.emailAddress?.asFHIRStringPrimitive()
                    contact.use = ContactPointUse.work.asPrimitive()
                    
                    patient.telecom?.append(contact)
                }
            }
        }
        
        return patient
    }
}


// MARK: - Load CSV
private extension HL72FHIRR4Converter {
    func load() throws {
        if let csvURLs = Bundle.module.urls(forResourcesWithExtension: "csv", subdirectory: nil) {
            for url in csvURLs {
                if url.lastPathComponent.starts(with: "HL7Message-FHIRR4_") {
                    let comps = url.lastPathComponent.split(separator: "_")
                    let messageType = comps[1] + "_" + comps[2].split(separator: "-")[0]
                    csvMessages[String(messageType)] = try CSV(url: url)
                }
                else if url.lastPathComponent.starts(with: "HL7Segment-FHIRR4_") {
//                    let comps = url.lastPathComponent.split(separator: "_")
//                    let messageType = comps[1] + "_" + comps[2].split(separator: "-")[0]
//                    csvMessages[String(messageType)] = try CSV(url: url)
                }
            }
        }
    }
}
