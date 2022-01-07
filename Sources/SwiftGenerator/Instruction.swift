//
//  File.swift
//  
//
//  Created by Rafael Warnault on 07/01/2022.
//

import Foundation

public extension Generator {
    struct Instruction: Node {
        public var name: String
        
        public var visibility: Visibility = .Unspecified
        public var protocols: [String] = []
        public var nodes: [Node] = []
        
        public init(name: String, visibility: Generator.Visibility = .Unspecified) {
            self.name = name
            self.visibility = visibility
        }
        
        public func generate(_ level: Int = 0) -> String {
            var prefix = ""
            
            // compute indentation prefix
            for _ in 0..<level {
                prefix += "  "
            }
            
            return "\(prefix)\(name)\n"
        }
    }

}
