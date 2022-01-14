//
//  File.swift
//  
//
//  Created by Rafael Warnault on 26/12/2021.
//

import Foundation

public class SpecMessage: CustomStringConvertible {
    public var description: String {
        "\(type.name) \(rootGroup.pretty())"
    }
    
    var type:Typable!
    public var rootGroup: Group!
    var version: Version!
    
    init(type: Typable, version: Version) {
        self.type = type
        self.version = version
        self.rootGroup = Group(parent: nil, name: type.name, items: [])
    }
}
