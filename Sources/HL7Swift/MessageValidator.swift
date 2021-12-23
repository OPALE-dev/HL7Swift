//
//  MessageValidator.swift
//  
//
//  Created by Paul on 23/12/2021.
//

import Foundation

public func getGroup(forMessage: Message) -> Group? {
    
    let path = forMessage.getType()
    let version = forMessage.getVersion()
    
    let resourcesPath = "Resources/Messages/HL7-xml v" + version + "/"
    let filePath = Bundle.module.url(forResource: resourcesPath + path, withExtension: "xsd")

    if let f = filePath {
        
            
      
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

    //MARK: XMLParserDelegate methods

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        currentElement = elementName
        if elementName == "StationDesc"
        || elementName == "StationLatitude"
        || elementName == "StationLongitude"
        || elementName == "StationCode"
        || elementName == "StationId"
        {
            if elementName == "StationDesc" {
                passName = true
            }
            passData = true
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        currentElement = ""
        if elementName == "StationDesc"
        || elementName == "StationLatitude"
        || elementName == "StationLongitude"
        || elementName == "StationCode"
        || elementName == "StationId"
        {
            if elementName == "StationDesc" {
                passName = false
            }
            passData = false
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if passName {
            strXMLData = strXMLData+"\n\n"+string
        }

        if passData {
            //ready content for codable struct
            switch currentElement {
            case "StationDesc":
                station = string
            case "StationLatitude":
                latitude = string
            case "StationLongitude":
                longitude = string
            case "StationCode":
                code = string
            case "StationId":
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
