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
    
    
    func loadXML() throws {
       // fatalError("Must be overritten locally")
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
    public static func load(version: Version) throws -> Versioned {
        switch version {
        case .v23:  return try V23(version)
        case .v231: return try V231(version)
        case .v24:  return try V24(version)
        case .v25:  return try V25(version)
        case .v251: return try V251(version)
        case .v26:  return try V26(version)
        case .v27:  return try V27(version)
        case .v271: return try V271(version)
        case .v28:  return try V28(version)
        case .v281: return try V281(version)
        case .v282: return try V282(version)
        default:
            return try V282(version)
        }
    }
    
    struct MessageType: Typable {
        var name: String
    }
    
    
    class V23: Versioned {
        override init(_ version: Version) throws {
            try super.init(.v23)
        }

        struct Message {
            var type: MessageType
        }
    }

    class V231: Versioned {
        override init(_ version: Version) throws {
            try super.init(.v231)
        }

        struct Message {
            var type: MessageType
        }
    }
    
    class V24: Versioned {
        override init(_ version: Version) throws {
            try super.init(.v24)
        }

        struct Message {
            var type: MessageType
        }
    }
    
    class V25: Versioned {
        override init(_ version: Version) throws {
            try super.init(.v25)
        }

        struct Message {
            var type: MessageType
        }
    }
    
    class V251: Versioned {
        override init(_ version: Version) throws {
            try super.init(.v251)
        }

        struct Message {
            var type: MessageType
        }
    }
    
    class V26: Versioned {
        override init(_ version: Version) throws {
            try super.init(.v26)
        }

        struct Message {
            var type: MessageType
        }
    }
    
    class V27: Versioned {
        override init(_ version: Version) throws {
            try super.init(.v27)
        }

        struct Message {
            var type: MessageType
        }
    }
    
    class V271: Versioned {
        override init(_ version: Version) throws {
            try super.init(.v271)
        }
                            
        struct Message {
            var type: MessageType
        }
    }
    
    class V28: Versioned {
        override init(_ version: Version) throws {
            try super.init(.v28)
        }
                                
        struct Message {
            var type: MessageType
        }
    }
    
    class V281: Versioned {
        override init(_ version: Version) throws {
            try super.init(.v281)
        }
             
        struct Message {
            var type: MessageType
        }
    }
    
    class V282: Versioned {
        override init(_ version: Version) throws {
            try super.init(.v282)
        }
             
        struct Message {
            var type: MessageType
        }
    }
    
    // MARK: -
//    subscript(type: HL7.MessageType, version: Version) -> SpecMessage? {
//        if let messages = messages[version] {
//            for message in messages {
//                if message.type == type {
//                    return message
//                }
//            }
//        }
//        return nil
//    }
//
//    subscript(name: String, version: Version) -> SpecMessage? {
//        if let messages = messages[version] {
//            for message in messages {
//                if message.type.rawValue == name {
//                    return message
//                }
//            }
//        }
//        return nil
//    }
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
                currentSequence = attributeDict["name"]
                
            } else if elementName == "xsd:element" {
                if let ref = attributeDict["ref"] {
                    if let currentSequence = currentSequence {
                        // is it a segment ?
                        if ref.count == 3 {
                            var segment = Segment(ref)
                            
                            if let fields = fields[ref] {
                                segment.fields.append(contentsOf: fields)
                            }
                            
                            _ = currentMessage?.rootGroup?.appendSegment(segment: segment, underGroupName: currentSequence)
                        // it is a group
                        } else {
                            _ = currentMessage?.rootGroup?.appendGroup(group: Group(name: ref + ".CONTENT", items: []), underGroupName: currentSequence)
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
