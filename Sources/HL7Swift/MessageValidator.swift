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
    print(parser.sequence)
    
    /*
    let path = forMessage.getType()
    let version = forMessage.getVersion()
    
    let resourcesPath = "Resources/Messages/HL7-xml v" + version + "/"
    let filePath = Bundle.module.url(forResource: resourcesPath + path, withExtension: "xsd")

    print(resourcesPath + path)
    if let f = filePath {
        
        do {
            let xsdFile = try Message(String(contentsOf: f))
        } catch {
            print("x")
        }
        
        
        
        let parser = MessageSpecParser()
        parser.runParser(forMessage: forMessage)
            
      
    } else {
        print("x")
    }
 */
    
    //return Group(name: "", item: Item(`for`) )
    return nil
}

class MessageSpecParser: NSObject, XMLParserDelegate {

    //list type variables to hold XML values (update list base on XML structure):
    

    //reusable method type veriales (do not touch)
    var strXMLData: String = ""
    
    public var sequence: [String: [[String: String]]] = [:]
    var currentSequence: String = ""

    //parser methods
    func runParser() {
        let xmlURL = Bundle.main.url(forResource: "station", withExtension: "xml")!
        let xmlParser = XMLParser(contentsOf: xmlURL)!
        xmlParser.delegate = self
        let success = xmlParser.parse()
        if success {
            print("parse success!")
            print(sequence)
        } else {
            print("parse failure!")
        }
    }

    //parser methods
    func runParser(forMessage: Message) {
        let path = forMessage.getType()
        let version = forMessage.getVersion()
        
        let resourcesPath = "Resources/HL7-xml v" + version + "/"
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
            print(sequence)
            
        } else {
            print("parse failure!")
        }
    }
    
    //MARK: XMLParserDelegate methods

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        
        if elementName == "xsd:complexType" {
            currentSequence = (attributeDict["name"])!
            sequence[currentSequence] = []
        } else if elementName == "xsd:element" {
            sequence[currentSequence]?.append(attributeDict)
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "xsd:schema"
        || elementName == "xsd:include"
        || elementName == "xsd:complexType"
        || elementName == "xsd:sequence"
        || elementName == "xsd:element"
        {
        
           
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
    }

    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        print("failure error: ", parseError)
    }
}
