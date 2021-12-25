//
//  File.swift
//
//
//  Created by Rafael Warnault on 24/12/2021.
//

import Foundation



public class SpecMessage: CustomStringConvertible {
    public var description: String {
        "\(type.rawValue) \(rootGroup.debugDescription)"
    }
    
    var type:HL7.MessageType!
    var rootGroup: Group?
    
    init(type: HL7.MessageType) {
        self.type = type
    }

}




public class HL7: NSObject, XMLParserDelegate {
    public struct MessageType: RawRepresentable {
        public init?(rawValue: String) {
            self.rawValue = rawValue
        }
        
        public var rawValue: String
        public typealias RawValue = String
    }
    
    
        
    var version:Version = .v251

    var messages:[SpecMessage] = []
    
    var loadMessagesFlag = false
    var loadSegmentsFlag = false
    
    var currentSequence:String? = nil
    var loadingMessage:SpecMessage? = nil
    
    init(_ version:Version) throws {
        self.version = version
        
        super.init()
        
        try loadMessages()
    }
    
    
    // MARK: -
    
    subscript(type: HL7.MessageType) -> SpecMessage? {
        for message in messages {
            if message.type == type {
                return message
            }
        }
        return nil
    }
    
    subscript(name: String) -> SpecMessage? {
        for message in messages {
            if message.type.rawValue == name {
                return message
            }
        }
        return nil
    }
    
    
    // MARK: -
    
    func loadMessages() throws {
        let xmlURL = Bundle.module.url(forResource: "messages", withExtension: "xsd", subdirectory: "v\(version.rawValue)")!
        
        let xmlParser = XMLParser(contentsOf: xmlURL)!
        
        xmlParser.delegate = self
        
        loadMessagesFlag = true
        
        if !xmlParser.parse() {
            throw HL7Error.parserError(message: "Cannot parse")
        }
                
        for m in messages {
            try loadSegments(forMessage: m)
        }
    }
    
    
    
    func loadSegments(forMessage message: SpecMessage) throws {
        if let xmlURL = Bundle.module.url(forResource: message.type.rawValue, withExtension: "xsd", subdirectory: "v\(version.rawValue)/messages") {
            let xmlParser = XMLParser(contentsOf: xmlURL)!
            
            xmlParser.delegate = self
            
            loadSegmentsFlag = true
            loadingMessage = message
            
            loadingMessage?.rootGroup = Group(name: message.type.rawValue + ".CONTENT", items: [])
            
            if !xmlParser.parse() {
                throw HL7Error.parserError(message: "Cannot parse")
            }
        }
    }
    
    
    
    //MARK: XMLParserDelegate methods

    public func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        if loadMessagesFlag {
            if elementName == "xsd:element" {
                if let ref = attributeDict["ref"] {
                   if let type = Version.klass(forVersion: version).MessageType.init(rawValue: ref) {
                        messages.append(SpecMessage(type: type))
                   }
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
                            _ = loadingMessage?.rootGroup?.appendSegment(segment: Segment(ref), underGroupName: currentSequence)
                        // it is a group
                        } else {
                            _ = loadingMessage?.rootGroup?.appendGroup(group: Group(name: ref + ".CONTENT", items: []), underGroupName: currentSequence)
                        }
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
     
        loadingMessage = nil
    }
    
}
