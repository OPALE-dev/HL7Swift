//
//  File.swift
//  
//
//  Created by Rafael Warnault on 07/01/2022.
//

import Foundation


public extension Generator {
    struct Class: Node {
        public var name: String = ""
        
        public var nodes: [Node] = []
        public var protocols: [String] = []
        public var properties: [String] = []
        public var visibility:Visibility = .Unspecified
        
        public init(name: String, protocols: [String] = [], properties: [String] = [], visibility: Generator.Visibility = .Unspecified) {
            self.name = name
            self.visibility = visibility
            self.properties = properties
            self.protocols = protocols
        }
        
        public func generate(_ level:Int = 0) -> String {
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
            code += "\(prefix)class \(name)"
            
            // add protocols before opening bracket
            if !protocols.isEmpty {
                code += ": "
                for p in protocols {
                    code += p
                    
                    if p != protocols.last {
                        code += ", "
                    }
                }
            }
            
            // open struct bracket
            code += " {\n"
            
            // append propoerties
            for p in properties {
                code += "\(prefix)\(prefix)\(p)\n"
            }
            
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
