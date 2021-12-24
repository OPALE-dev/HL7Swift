//
//  MessageValidator.swift
//  
//
//  Created by Paul on 23/12/2021.
//

import Foundation

/**
 Parser for the messages specifications (XSD files)
 
 Usage :
 ```
 let parser = MessageSpecParser()
 
 parser.runParser(forMessage: Message("MSH|whatever|..........|"))
 print(parser.rootGroup.pretty())
 ```
 */
class MessageSpecParser: NSObject, XMLParserDelegate {

    // (do not touch)
    var strXMLData: String = ""
    
    var currentSequence: String = ""
    var message: Message?
    var rootGroup: Group?

    /**
     Get the specification file for the message : if the message is of type ORU_R01, the parser will fetch
     the ORU_R01.xsd file and parse it. It will generate a group accordingly to the message
     
     Beware: the message must have a version and a type, else it won't work
    */
    func runParser(forMessage: Message) throws {
        message = forMessage
        
        guard let version = forMessage.getVersion()?.rawValue else {
            throw HL7Error.parserError(message: "Tu n'a rien à dire")
        }
        
        let path = try forMessage.getType().rawValue
        
        rootGroup = Group(name: path + ".CONTENT", items: [])
        
        let xmlURL = Bundle.module.url(forResource: path, withExtension: "xsd", subdirectory: "HL7-xml v" + version)!
        let xmlParser = XMLParser(contentsOf: xmlURL)!
        xmlParser.delegate = self
        let success = xmlParser.parse()
        
        if success {

        } else {
            print("parse failure!")
        }
    }
    
    //MARK: XMLParserDelegate methods

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        
        if elementName == "xsd:complexType" {
            currentSequence = (attributeDict["name"])!
            
        } else if elementName == "xsd:element" {
            if let ref = attributeDict["ref"] {
                // is it a segment ?
                if ref.count == 3 {
                    if let segment = (message?.getSegment(code: ref)) {
                        _ = rootGroup!.appendSegment(segment: segment, underGroupName: currentSequence)
                    }
                // it is a group
                } else {
                    _ = rootGroup!.appendGroup(group: Group(name: ref + ".CONTENT", items: []), underGroupName: currentSequence)
                }
            }
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
    }

    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        print("failure error: ", parseError)
    }
}
