//
//  MessageValidator.swift
//  
//
//  Created by Paul on 23/12/2021.
//

import Foundation

public func getGroup(forMessage: Message) -> Group? {
    let parser = MessageSpecParser()
    parser.runParser(forMessage: forMessage)    
    return parser.rootGroup
}

class MessageSpecParser: NSObject, XMLParserDelegate {

    // (do not touch)
    var strXMLData: String = ""
    
    var currentSequence: String = ""
    public var message: Message?
    
    var rootGroup: Group?

    //parser methods
    func runParser(forMessage: Message) {
        message = forMessage
        
        let path = forMessage.getType()
        let version = forMessage.getVersion()
        rootGroup = Group(name: path + ".CONTENT", items: [])
        
        // let resourcesPath = "Resources/HL7-xml v" + version + "/"
        //let filePath = Bundle.module.url(forResource: resourcesPath + path, withExtension: "xsd")

        // print(resourcesPath + path)
        //print(Bundle.module.paths(forResourcesOfType: "", inDirectory: nil))
        //print(Bundle.module.paths(forResourcesOfType: "", inDirectory: "HL7-xml v2.5.1"))
        
        let xmlURL = Bundle.module.url(forResource: path, withExtension: "xsd", subdirectory: "HL7-xml v" + version)!//url(forResource: resourcesPath + path, withExtension: "xsd")!
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
