//
//  File.swift
//  
//
//  Created by Rafael Warnault on 07/01/2022.
//

import Foundation

public protocol Node {
    var name:String { get set }
    var visibility:Generator.Visibility { get set }
    var protocols: [String] { get set }
    var nodes:[Node] { get set }
    
    mutating func append(_ child: Node)
    
    func generate(_ level:Int) -> String
}


public extension Node {
    mutating func append(_ child: Node) {
        if !nodes.contains(where: { node in node.name == child.name }) {
            self.nodes.append(child)
        }
    }
}
