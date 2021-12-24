//
//  File.swift
//  
//
//  Created by Rafael Warnault on 24/12/2021.
//

import Foundation


public enum VersionType:String {
    case v251   = "2.5.1"
    case v26    = "2.6"
    case v282   = "2.8.2"
    
    public static func klass(forVersion type: VersionType) -> Version.Type {
        switch type {
        case .v251: return V251.self
        case .v26:  return V26.self
        case .v282:  return V282.self

        }
    }
}


public struct HL7SpecMessage {
    var type:Version.MessageType!
}


public class HL7Spec: NSObject, XMLParserDelegate {
    var version:VersionType = .v251

    var messages:[HL7SpecMessage] = []
    
    init(_ version:VersionType) throws {
        self.version = version
        
        super.init()
        
        try loadMessages()
    }
    
    
    
    func loadMessages() throws {
        print(version.rawValue)
        
        let xmlURL = Bundle.module.url(forResource: "messages", withExtension: "xsd", subdirectory: "v\(version.rawValue)")!
        
        let xmlParser = XMLParser(contentsOf: xmlURL)!
        
        xmlParser.delegate = self
        
        if !xmlParser.parse() {
            throw HL7Error.parserError(message: "Cannot parse")
        }
    }
    
    
    
    //MARK: XMLParserDelegate methods

    public func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        if elementName == "xsd:element" {
            if let ref = attributeDict["ref"] {
               if let type = VersionType.klass(forVersion: version).MessageType.init(rawValue: ref) {
                    messages.append(HL7SpecMessage(type: type))
               }
            }
        }
    }

    public func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
    }

    public func parser(_ parser: XMLParser, foundCharacters string: String) {
    }

    public func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        print("failure error: ", parseError)
    }
    
}
