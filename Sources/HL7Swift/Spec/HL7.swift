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
}


public class Versioned: NSObject, Versionable {
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
        self.version = .last
        
        super.init()
        
        try loadXML()
    }
    
    
    internal func loadXML() throws {
        try loadFields(forVersion: self.version)
        try loadMessages(forVersion: self.version)
    }
    
    
    private func loadMessages(forVersion version: Version) throws {
        let xmlURL = Bundle.module.url(forResource: "messages", withExtension: "xsd", subdirectory: "v\(version.rawValue)")!
        
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
    
    
    internal func spec(ofVersion version: Version) -> Versioned {
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
            return v282
        }
    }
    
    struct MessageType: Typable {
        var name: String
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
    
    
    
    
    
    
    class Unknow: Versioned {
        override init(_ version: Version) throws {
            try super.init(.v21)
        }
    }
    
    
    class V21: Versioned {
        override init(_ version: Version) throws {
            try super.init(.v21)
        }
    }
    
    class V23: Versioned {
        override init(_ version: Version) throws {
            try super.init(.v23)
        }
    }

    class V231: Versioned {
        override init(_ version: Version) throws {
            try super.init(.v231)
        }
    }
    
    class V24: Versioned {
        override init(_ version: Version) throws {
            try super.init(.v24)
        }
    }
    
    class V25: Versioned {
        override init(_ version: Version) throws {
            try super.init(.v25)
        }
    }
    
    class V251: Versioned {
        override init(_ version: Version) throws {
            try super.init(.v251)
        }
    }
    
    class V26: Versioned {
        override init(_ version: Version) throws {
            try super.init(.v26)
        }
    }
    
    class V27: Versioned {
        override init(_ version: Version) throws {
            try super.init(.v27)
        }
    }
    
    class V271: Versioned {
        override init(_ version: Version) throws {
            try super.init(.v271)
        }
    }
    
    class V28: Versioned {
        override init(_ version: Version) throws {
            try super.init(.v28)
        }
    }
    
    class V281: Versioned {
        override init(_ version: Version) throws {
            try super.init(.v281)
        }
    }
    
    class V282: Versioned {
        override init(_ version: Version) throws {
            try super.init(.v282)
        }
    }
}


//MARK: XMLParserDelegate methods
extension Versioned:XMLParserDelegate {
    public func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        if loadMessagesFlag {
            if elementName == "xsd:element" {
                if let ref = attributeDict["ref"] {                        
                    messages[ref] = SpecMessage(type: HL7.MessageType(name: ref), version: version)
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
