//
//  File.swift
//
//
//  Created by Rafael Warnault on 24/12/2021.
//

import Foundation



public class HL7: NSObject {
    public struct MessageType: RawRepresentable {
        public init(rawValue: String) {
            self.rawValue = rawValue
        }
        
        public var rawValue: String
        public typealias RawValue = String
    }
    
    
        
    var version:Version = .all

    var messages:[Version:[SpecMessage]] = [:]
    
    var loadMessagesFlag = false
    var loadSegmentsFlag = false
    
    var currentVersion:Version? = nil
    var currentSequence:String? = nil
    var currentMessage:SpecMessage? = nil
    
    
    public override init() {
        super.init()
        
        do {
            try loadVersions()
        } catch let e {
            Logger.error(e.localizedDescription)
        }
    }
    
    
    init(_ version:Version? = .all) throws {
        self.version = version ?? .all
        
        super.init()
        
        try loadVersions()
    }
    
    
    
    // MARK: -
    subscript(type: HL7.MessageType, version: Version) -> SpecMessage? {
        if let messages = messages[version] {
            for message in messages {
                if message.type == type {
                    return message
                }
            }
        }
        return nil
    }

    subscript(name: String, version: Version) -> SpecMessage? {
        if let messages = messages[version] {
            for message in messages {
                if message.type.rawValue == name {
                    return message
                }
            }
        }
        return nil
    }
    
    
    // MARK: -
    private func loadVersions() throws {
        if self.version == .all {
            for v in Version.allCases {
                currentVersion = v
                try loadMessages(forVersion: v)
            }
        } else {
            currentVersion = version
            try loadMessages(forVersion: self.version)
        }
    }
    
    
    private func loadMessages(forVersion version: Version) throws {
        let xmlURL = Bundle.module.url(forResource: "messages", withExtension: "xsd", subdirectory: "v\(version.description)")!
        
        let xmlParser = XMLParser(contentsOf: xmlURL)!
        
        xmlParser.delegate = self
        
        loadMessagesFlag = true
        currentVersion = version
        
        if !xmlParser.parse() {
            throw HL7Error.parserError(message: "Cannot parse")
        }
                
        for (version, messages) in messages {
            for message in messages {
                try loadSegments(forMessage: message, version: version)
            }
        }
    }
    
    
    
    private func loadSegments(forMessage message: SpecMessage, version: Version) throws {
        if let xmlURL = Bundle.module.url(forResource: message.type.rawValue, withExtension: "xsd", subdirectory: "v\(version.description)/messages") {
            let xmlParser = XMLParser(contentsOf: xmlURL)!
            
            xmlParser.delegate = self
            
            loadSegmentsFlag = true
            currentMessage = message
                        
            if !xmlParser.parse() {
                throw HL7Error.parserError(message: "Cannot parse")
            }
        }
    }
    
    
}


//MARK: XMLParserDelegate methods
extension HL7:XMLParserDelegate {
    public func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        if loadMessagesFlag {
            if elementName == "xsd:element" {
                if let ref = attributeDict["ref"] {
                    let type = HL7.MessageType.init(rawValue: ref)
                        
                    if messages[currentVersion!] == nil {
                        messages[currentVersion!] = []
                    }
                    
                    messages[currentVersion!]?.append(SpecMessage(type: type))
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
                            _ = currentMessage?.rootGroup?.appendSegment(segment: Segment(ref), underGroupName: currentSequence)
                        // it is a group
                        } else {
                            _ = currentMessage?.rootGroup?.appendGroup(group: Group(name: ref + ".CONTENT", items: []), underGroupName: currentSequence)
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
     
        currentMessage = nil
    }
    
}
