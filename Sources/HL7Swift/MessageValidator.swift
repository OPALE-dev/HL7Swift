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
    let filePath = Bundle.module.path(forResource: resourcesPath + path, ofType: "xsd")

    if let f = filePath {
        let xml = XMLParser(contentsOf: URL(fileURLWithPath: f))
        let xmlDelegate = MessageSpecParser()
        xml?.delegate = xmlDelegate
        if let result = xml?.parse() {
            if result {
                print("oui")
            } else {
                print("x")
            }
        } else {
            print("x")
        }
        
            
      
    } else {
        print("x")
    }
    
    //return Group(name: "", item: Item(`for`) )
    return nil
}
