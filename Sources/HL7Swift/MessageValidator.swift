//
//  MessageValidator.swift
//  
//
//  Created by Paul on 23/12/2021.
//

import Foundation

public func getGroup(forMessage: Message) -> Group? {
    guard let path = try? forMessage.getType().rawValue else {
        return nil
    }
    guard let version = forMessage.getVersion()?.rawValue else {
        return nil
    }
    
    let resourcesPath = "Resources/Messages/HL7-xml v" + version + "/"
    let filePath = Bundle.module.url(forResource: resourcesPath + path, withExtension: "xsd")

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
    
    //return Group(name: "", item: Item(`for`) )
    return nil
}

class MessageSpecParser: NSObject, XMLParserDelegate {

    //list type variables to hold XML values (update list base on XML structure):
    var station: String = ""
    var latitude: String = ""
    var longitude: String = ""
    private var code: String = ""
    private var id: String = ""

    //reusable method type veriales (do not touch)
    var strXMLData: String = ""
    var currentElement: String = ""
    var passData: Bool = false
    var passName: Bool = false

    //parser methods
    func runParser() {
        let xmlURL = Bundle.main.url(forResource: "station", withExtension: "xml")!
        let xmlParser = XMLParser(contentsOf: xmlURL)!
        xmlParser.delegate = self
        let success = xmlParser.parse()
        if success {
            print("parse success!")
            print(currentElement)
        } else {
            print("parse failure!")
        }
    }

    //parser methods
    func runParser(forMessage: Message) {
        guard let path = try? forMessage.getType().rawValue else {
            return
        }
        guard let version = forMessage.getVersion()?.rawValue else {
            return
        }
        
        let resourcesPath = "Resources/Messages/HL7-xml v" + version + "/"
        //let filePath = Bundle.module.url(forResource: resourcesPath + path, withExtension: "xsd")

        
        let xmlURL = Bundle.main.url(forResource: resourcesPath + path, withExtension: "xsd")!
        let xmlParser = XMLParser(contentsOf: xmlURL)!
        xmlParser.delegate = self
        let success = xmlParser.parse()
        if success {
            print("parse success!")
            print(currentElement)
        } else {
            print("parse failure!")
        }
    }
    
    //MARK: XMLParserDelegate methods

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        currentElement = elementName
        if elementName == "xsd:schema"
        || elementName == "xsd:include"
        || elementName == "xsd:complexType"
        || elementName == "xsd:sequence"
        || elementName == "xsd:element"
        {
        
            passData = true
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        currentElement = ""
        if elementName == "xsd:schema"
        || elementName == "xsd:include"
        || elementName == "xsd:complexType"
        || elementName == "xsd:sequence"
        || elementName == "xsd:element"
        {
        
            passData = true
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if passName {
            strXMLData = strXMLData+"\n\n"+string
        }

        if passData {
            //ready content for codable struct
            switch currentElement {
            case "xsd:schema":
                station = string
            case "xsd:include":
                latitude = string
            case "xsd:complexType":
                longitude = string
            case "xsd:sequence":
                code = string
            case "xsd:element":
                id = string
                print(string)

            default:
                id = string
            }
        }
    }

    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        print("failure error: ", parseError)
    }
}
