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
