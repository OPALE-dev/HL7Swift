//
//  File.swift
//  
//
//  Created by Rafael Warnault on 26/12/2021.
//

import Foundation

public class SpecMessage: CustomStringConvertible {
    public var description: String {
        "\(type.rawValue) \(rootGroup.pretty())"
    }
    
    var type:HL7.MessageType!
    var rootGroup: Group!
    
    init(type: HL7.MessageType) {
        self.type = type
        self.rootGroup = Group(name: type.rawValue + ".CONTENT", items: [])
    }

}
