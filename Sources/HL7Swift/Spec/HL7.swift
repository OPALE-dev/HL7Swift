//
//  File.swift
//
//
//  Created by Rafael Warnault on 24/12/2021.
//

import Foundation


public protocol Typable {
    var name:String { get }
}


protocol Versionable {
    var version:Version { get }

    func loadXML() throws
    func type(forName name:String) -> Typable?
}


public class Versioned: NSObject, Versionable {    
    func type(forName name:String) -> Typable? {
        return nil
    }
    
    var version: Version
    
    var messages:[String:SpecMessage] = [:]
    var fields:[String:[Field]] = [:] // fields by segment
    
    var loadMessagesFlag = false
    var loadSegmentsFlag = false
    var loadFieldsFlag = false
    
    var currentVersion:Version? = nil
    var currentSequence:String? = nil
    var currentField:Field? = nil
    var currentMessage:SpecMessage? = nil
    
    init(_ version: Version) throws {
        self.version = version
        
        super.init()
        
        try loadXML()
    }
    
    
    internal func loadXML() throws {
        try loadFields(forVersion: self.version)
        try loadMessages(forVersion: self.version)
    }
    
    
    private func loadMessages(forVersion version: Version) throws {
        if let xmlURL = Bundle.module.url(forResource: "messages", withExtension: "xsd", subdirectory: "v\(version.rawValue)") {
            let xmlParser = XMLParser(contentsOf: xmlURL)!
            
            xmlParser.delegate = self
            
            loadMessagesFlag = true
            currentVersion = version
            
            if !xmlParser.parse() {
                throw HL7Error.parserError(message: "Cannot parse")
            }
                    
            for (_, message) in messages {
                try loadSegments(forMessage: message, version: version)
            }
        }
    }
    
    
    
    private func loadSegments(forMessage message: SpecMessage, version: Version) throws {
        if let xmlURL = Bundle.module.url(forResource: message.type.name, withExtension: "xsd", subdirectory: "v\(version.rawValue)/messages") {
            let xmlParser = XMLParser(contentsOf: xmlURL)!
            
            xmlParser.delegate = self
            
            loadSegmentsFlag = true
            currentMessage = message
                        
            if !xmlParser.parse() {
                throw HL7Error.parserError(message: "Cannot parse")
            }
        }
    }
    
    private func loadFields(forVersion version: Version) throws {
        if let xmlURL = Bundle.module.url(forResource: "fields", withExtension: "xsd", subdirectory: "v\(version.rawValue)") {
            let xmlParser = XMLParser(contentsOf: xmlURL)!
            
            xmlParser.delegate = self
            
            loadFieldsFlag = true
            currentVersion = version
            
            if !xmlParser.parse() {
                throw HL7Error.parserError(message: "Cannot parse")
            }
        }
    }
    
}




public struct HL7 {    
    private var v21     :V21!
    private var v23     :V23!
    private var v231    :V231!
    private var v24     :V24!
    private var v25     :V25!
    private var v251    :V251!
    private var v26     :V26!
    private var v27     :V27!
    private var v271    :V271!
    private var v28     :V28!
    private var v281    :V281!
    private var v282    :V282!
    
    
    public init() throws {
        self.v21  = try V21(.v21)
        self.v23  = try V23(.v23)
        self.v231 = try V231(.v231)
        self.v24  = try V24(.v24)
        self.v25  = try V25(.v25)
        self.v251 = try V251(.v251)
        self.v26  = try V26(.v26)
        self.v27  = try V27(.v27)
        self.v271 = try V271(.v271)
        self.v28  = try V28(.v28)
        self.v281 = try V281(.v281)
        self.v282 = try V282(.v282)
    }
    
    
    internal func spec(ofVersion version: Version) -> Versioned? {
        switch version {
        case .v21:  return v21
        case .v23:  return v23
        case .v231: return v231
        case .v24:  return v24
        case .v25:  return v25
        case .v251: return v251
        case .v26:  return v26
        case .v27:  return v27
        case .v271: return v271
        case .v28:  return v28
        case .v281: return v281
        case .v282: return v282
        default:
            return nil
        }
    }
    
    struct MessageType: Typable {
        var name: String
    }

    struct UnknowMessageType: Typable {
        var name: String = "Unknow"
    }
    
    class UnknowVersion: Versioned {
        override init(_ version: Version) throws {
            try super.init(.v21)
        }
    }
    
    func parse(_ str:String) throws -> Message {
        return try Message(str, hl7: self)
    }
    
    
    func validate(_ message:Message) -> Bool {
        return message.validate()
    }
    
    
    func create(version: Version, type: String) throws -> Message? {
        // TODO: TBD
        // let spec = spec(ofVersion: version)
        
        return nil
    }
}


//MARK: XMLParserDelegate methods
extension Versioned:XMLParserDelegate {
    public func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        if loadMessagesFlag {
            if elementName == "xsd:element" {
                if let ref = attributeDict["ref"] {                        
                    if let type = type(forName: ref) {
                        messages[ref] = SpecMessage(type: type, version: version)
                    }
                    //messages[ref] = SpecMessage(type: HL7.MessageType(name: ref), version: version)
                }
            }
        }
        else if loadSegmentsFlag {
            if elementName == "xsd:complexType" {
                currentSequence = (attributeDict["name"])!
                
                currentSequence = shortname(currentSequence!)
                
            } else if elementName == "xsd:element" {
                if let ref = attributeDict["ref"] {
                    if let currentSequence = currentSequence {
                        // is it a segment ?
                        if ref.count == 3 {
                            let segment = Segment(ref, specMessage: currentMessage)
                            
                            if let fields = fields[ref] {
                                segment.fields.append(contentsOf: fields)
                            }
                            
                            _ = currentMessage?.rootGroup?.appendSegment(segment: segment, underGroupName: currentSequence)
                        // it is a group
                        } else {
                            let groupName = shortname(ref)                            
                            
                            _ = currentMessage?.rootGroup?.appendGroup(group: Group(name: groupName, items: []), underGroupName: currentSequence)
                        }
                    }
                }
            }
        }
        else if loadFieldsFlag {
            if elementName == "xsd:attributeGroup" {
                if let attributeGroup = attributeDict["name"] {
                    let split = attributeGroup.split(separator: ".")
                    
                    if let first = split.first {
                        let segmentCode = String(first)
                        
                        currentField = Field(name: "\(split[0]).\(split[1])")
                        currentField?.segmentCode = segmentCode
                        
                        if let index = Int(split[1]) {
                            currentField?.index = index
                        }
                    }
                }
            } else if elementName == "xsd:attribute" {
                if let name = attributeDict["name"] {
                    if name == "Item" {
                        currentField?.item = attributeDict["fixed"]!
                    }
                    else if name == "Type" {
                        currentField?.type = attributeDict["fixed"]!
                    }
                    else if name == "LongName" {
                        currentField?.longName = attributeDict["fixed"]!
                    }
                    else if name == "maxLength" {
                        currentField?.maxLength = Int(attributeDict["fixed"]!)!
                    }
                }
            }
        }
    }

    public func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if loadSegmentsFlag {
            if elementName == "xsd:complexType" {
                currentSequence = nil
            }
        }
        else if loadFieldsFlag {
            if elementName == "xsd:attributeGroup" {
                if let currentField = currentField {
                    if fields[currentField.segmentCode] == nil {
                        fields[currentField.segmentCode] = []
                    }
                
                    fields[currentField.segmentCode]?.append(currentField)
                }
                
                currentField = nil
            }
        }
    }

    public func parser(_ parser: XMLParser, foundCharacters string: String) {
    }

    public func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        print("failure error: ", parseError)
    }
    
    public func parserDidEndDocument(_ parser: XMLParser) {
        if loadMessagesFlag == true {
            loadMessagesFlag = false
        }
        
        if loadSegmentsFlag == true {
            loadSegmentsFlag = false
        }
     
        currentMessage = nil
    }
    
}



extension HL7 {
    static let ABS = "ABS"
    static let ACC = "ACC"
    static let AFF = "AFF"
    static let AIG = "AIG"
    static let AIL = "AIL"
    static let AIP = "AIP"
    static let AIS = "AIS"
    static let AL1 = "AL1"
    static let APR = "APR"
    static let ARQ = "ARQ"
    static let AUT = "AUT"
    static let BLC = "BLC"
    static let BLG = "BLG"
    static let BPO = "BPO"
    static let BPX = "BPX"
    static let BTX = "BTX"
    static let CDM = "CDM"
    static let CER = "CER"
    static let CM0 = "CM0"
    static let CM1 = "CM1"
    static let CM2 = "CM2"
    static let CNS = "CNS"
    static let CSP = "CSP"
    static let CSR = "CSR"
    static let CSS = "CSS"
    static let CTD = "CTD"
    static let CTI = "CTI"
    static let DB1 = "DB1"
    static let DG1 = "DG1"
    static let DRG = "DRG"
    static let DSC = "DSC"
    static let DSP = "DSP"
    static let ECD = "ECD"
    static let ECR = "ECR"
    static let EDU = "EDU"
    static let EQP = "EQP"
    static let EQU = "EQU"
    static let ERR = "ERR"
    static let EVN = "EVN"
    static let FT1 = "FT1"
    static let GOL = "GOL"
    static let GP1 = "GP1"
    static let GP2 = "GP2"
    static let GT1 = "GT1"
    static let IAM = "IAM"
    static let IIM = "IIM"
    static let IN1 = "IN1"
    static let IN2 = "IN2"
    static let IN3 = "IN3"
    static let INV = "INV"
    static let IPC = "IPC"
    static let ISD = "ISD"
    static let LAN = "LAN"
    static let LCC = "LCC"
    static let LCH = "LCH"
    static let LDP = "LDP"
    static let LOC = "LOC"
    static let LRL = "LRL"
    static let MFA = "MFA"
    static let MFE = "MFE"
    static let MFI = "MFI"
    static let MRG = "MRG"
    static let MSA = "MSA"
    static let MSH = "MSH"
    static let NCK = "NCK"
    static let NDS = "NDS"
    static let NK1 = "NK1"
    static let NPU = "NPU"
    static let NSC = "NSC"
    static let NST = "NST"
    static let NTE = "NTE"
    static let OBR = "OBR"
    static let OBX = "OBX"
    static let ODS = "ODS"
    static let ODT = "ODT"
    static let OM1 = "OM1"
    static let OM2 = "OM2"
    static let OM3 = "OM3"
    static let OM4 = "OM4"
    static let OM5 = "OM5"
    static let OM6 = "OM6"
    static let OM7 = "OM7"
    static let ORC = "ORC"
    static let ORG = "ORG"
    static let PCR = "PCR"
    static let PD1 = "PD1"
    static let PDA = "PDA"
    static let PEO = "PEO"
    static let PES = "PES"
    static let PID = "PID"
    static let PR1 = "PR1"
    static let PRA = "PRA"
    static let PRB = "PRB"
    static let PRC = "PRC"
    static let PRD = "PRD"
    static let PTH = "PTH"
    static let PV1 = "PV1"
    static let PV2 = "PV2"
    static let QAK = "QAK"
    static let QID = "QID"
    static let QPD = "QPD"
    static let QRD = "QRD"
    static let QRF = "QRF"
    static let QRI = "QRI"
    static let RCP = "RCP"
    static let RDF = "RDF"
    static let RDT = "RDT"
    static let RF1 = "RF1"
    static let RGS = "RGS"
    static let RMI = "RMI"
    static let ROL = "ROL"
    static let RQ1 = "RQ1"
    static let RQD = "RQD"
    static let RXA = "RXA"
    static let RXC = "RXC"
    static let RXD = "RXD"
    static let RXE = "RXE"
    static let RXG = "RXG"
    static let RXO = "RXO"
    static let RXR = "RXR"
    static let SAC = "SAC"
    static let SCH = "SCH"
    static let SFT = "SFT"
    static let SID = "SID"
    static let SPM = "SPM"
    static let STF = "STF"
    static let TCC = "TCC"
    static let TCD = "TCD"
    static let TQ1 = "TQ1"
    static let TQ2 = "TQ2"
    static let TXA = "TXA"
    static let UB1 = "UB1"
    static let UB2 = "UB2"
    static let VAR = "VAR"
}
