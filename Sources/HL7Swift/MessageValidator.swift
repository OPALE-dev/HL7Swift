//
//  MessageValidator.swift
//  
//
//  Created by Paul on 23/12/2021.
//

import Foundation

/*
func dictToGroup(dict: [String : [[String : String]]], forMessage: Message) -> Group? {
    let group: Group? = nil
    
    for (complexType, elements) in dict {
        //var ct = complexType.split(separator: ".")
        //ct.removeFirst()
        //ct = ct.joined(separator: ".")
        let ct = complexType
        let groupName = String(ct.dropFirst(forMessage.getType().count + 1))
        
        var group = Group(name: groupName, items: [])
        for element in elements {
            
            // is it a segment ?
            if element["ref"]!.count == 3 {
                if let segment = forMessage.getSegment(code: element["ref"]!) {
                    group.items.append(Item.segment(segment))
                }
            // is it a group ?
            } else {
                group.items.append(Item.group(dictToGroup(dict: dict[element["ref"]!], forMessage: forMessage)))
            }
        }
    }
    
    return group
}
*/

public func getGroup(forMessage: Message) -> Group? {
    let parser = MessageSpecParser()
    parser.runParser(forMessage: forMessage)
    print(parser.rootGroup)
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
    public var message: Message?
    
    var currentGroup: Group? = nil
    var rootGroup: Group?

    //parser methods
    /*
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
    */
    /*
    public func runParser(message: Message) {
        self.message = message
        
        let path = message.getType()
        let version = message.getVersion()
        
        // let resourcesPath = "Resources/HL7-xml v" + version + "/"
        
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
    */

    //parser methods
    func runParser(forMessage: Message) {
        message = forMessage
        
        let path = forMessage.getType()
        let version = forMessage.getVersion()
        rootGroup = Group(name: path + ".CONTENT", items: [])
        
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
            print(rootGroup)
            
        } else {
            print("parse failure!")
        }
    }
    
    //MARK: XMLParserDelegate methods

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String : String]) {
        
        if elementName == "xsd:complexType" {
            currentSequence = (attributeDict["name"])!
            sequence[currentSequence] = []
            currentGroup = Group(name: currentSequence, items: [])
            
        } else if elementName == "xsd:element" {
            sequence[currentSequence]?.append(attributeDict)
            
            if let ref = attributeDict["ref"] {
                if ref.count == 3 {
                    if let segment = (message?.getSegment(code: ref)) {
                        _ = rootGroup?.appendSegment(segment: segment, underGroupName: currentSequence)
                    }
                } else {
                    _ = rootGroup?.appendGroup(group: Group(name: ref, items: []), underGroupName: currentSequence)
                }
            }
            
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "xsd:complexType" {
            currentGroup = nil
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
    }

    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        print("failure error: ", parseError)
    }
}
