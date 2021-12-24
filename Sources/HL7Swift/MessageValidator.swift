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
    print(parser.rootGroup ?? "")
    
    return parser.rootGroup
}

class MessageSpecParser: NSObject, XMLParserDelegate {

    //list type variables to hold XML values (update list base on XML structure):
    

    //reusable method type veriales (do not touch)
    var strXMLData: String = ""
    
    public var sequence: [String: [[String: String]]] = [:]
    var currentSequence: String = ""
    public var message: Message?
    
    var currentGroup: Group? = nil
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
            print("parse success!")
        } else {
            print("parse failure!")
        }
    }
    
    //MARK: XMLParserDelegate methods

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        
        if elementName == "xsd:complexType" {
            currentSequence = (attributeDict["name"])!
            sequence[currentSequence] = []
            print("current complexType " + currentSequence)
            
        } else if elementName == "xsd:element" {
            sequence[currentSequence]?.append(attributeDict)
            
            if let ref = attributeDict["ref"] {
                if ref.count == 3 {
                    print("append segment \(ref) under \(currentSequence)")
                    if let segment = (message?.getSegment(code: ref)) {
                        print(rootGroup!.appendSegment(segment: segment, underGroupName: currentSequence))
                        print(rootGroup!.pretty())
                    }
                } else {
                    print("append group \(ref) under \(currentSequence)")
                    print(rootGroup!.appendGroup(group: Group(name: ref + ".CONTENT", items: []), underGroupName: currentSequence))
                    print(rootGroup!.pretty())
                }
            }
            
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        print("")
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
    }

    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        print("failure error: ", parseError)
    }
}
