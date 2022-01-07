//
//  File.swift
//  
//
//  Created by Rafael Warnault on 07/01/2022.
//

import Foundation

public extension Generator {
    struct Switch: Node {
        public var name: String
        public var defaultCase:String = "default: break"
        
        public var visibility: Visibility = .Unspecified
        public var protocols: [String] = []
        public var nodes: [Node] = []
        
        
        public init(name: String, defaultCase: String, visibility: Generator.Visibility = .Unspecified) {
            self.name = name
            self.visibility = visibility
            self.defaultCase = defaultCase
        }
        
        
        public func generate(_ level: Int = 0) -> String {
            var code = ""
            var prefix = ""
            
            // compute indentation prefix
            for _ in 0..<level {
                prefix += "  "
            }
            
            // start struct
            code += "\(prefix)switch \(name) {\n"
            
            // recurscively append child nodes
            for node in nodes {
                code += "\(prefix)\(node.generate(level+1))"
            }
            
            code += "\(prefix)\(defaultCase)"
        
            // close struct bracket
            code += "\n\(prefix)}\n\n"
            
            return code
        }
    }
}
