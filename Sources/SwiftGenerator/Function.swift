//
//  File.swift
//  
//
//  Created by Rafael Warnault on 07/01/2022.
//

import Foundation

public extension Generator {
    struct Function: Node {
        public var name: String = ""
        
        public var visibility: Visibility = .Unspecified
        public var protocols: [String] = []
        public var nodes: [Node] = []
        
        public var override:Bool = false
        public var parameters: [String] = []
        public var returnType: String
        
        public init(name: String, parameters: [String], returnType: String, override: Bool, visibility: Generator.Visibility = .Unspecified) {
            self.name = name
            self.visibility = visibility
            self.parameters = parameters
            self.returnType = returnType
            self.protocols = []
            self.override = override
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
                        
            // start func
            code += "\(prefix)\(override ? "override " : "")func \(name)(\(parameters.joined())) -> \(returnType) {\n"
            
            // recurscively append child nodes
            for node in nodes {
                code += "\(prefix)\(node.generate(level+1))"
            }
            
            // close func bracket
            code += "\n\(prefix)}\n\n"
            
            return code
        }
    }
}
