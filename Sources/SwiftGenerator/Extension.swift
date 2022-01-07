//
//  File.swift
//  
//
//  Created by Rafael Warnault on 07/01/2022.
//

import Foundation

public extension Generator {
    struct Extension: Node {
        public var name: String
        
        public var visibility: Visibility = .Unspecified
        public var protocols: [String] = []
        public var nodes: [Node] = []
        
        public init(name: String, visibility: Generator.Visibility = .Unspecified) {
            self.name = name
            self.visibility = visibility
        }
        
        public func generate(_ level: Int = 0) -> String {
            var code = ""
            var prefix = ""
            
            // compute indentation prefix
            for _ in 0..<level {
                prefix += "  "
            }

            // deal with visibility
            if visibility != .Unspecified {
                code += "\(visibility.rawValue) "
            }
            
            // start struct
            code += "\(prefix)extension \(name) {\n"
            
            // recurscively append child nodes
            for node in nodes {
                code += "\(prefix)\(node.generate(level+1))"
            }
            
            // close struct bracket
            code += "\n\(prefix)}\n\n"
            
            return code
        }
    }
}
