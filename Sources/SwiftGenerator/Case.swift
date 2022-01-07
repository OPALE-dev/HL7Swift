//
//  File.swift
//  
//
//  Created by Rafael Warnault on 07/01/2022.
//

import Foundation

public extension Generator {
    struct Case: Node {
        public var name: String
        public var value: String
        public var separator:String = "="
        
        public var visibility: Visibility = .Unspecified
        public var protocols: [String] = []
        public var nodes: [Node] = []

        public init(name: String, value: String, separator: String, visibility: Generator.Visibility = .Unspecified) {
            self.name = name
            self.visibility = visibility
            self.value = value
            self.separator = separator
        }
        
        public func generate(_ level: Int = 0) -> String {
            var prefix = ""
            
            // compute indentation prefix
            for _ in 0..<level {
                prefix += "  "
            }
            
            return "\(prefix)case \(name) \(separator) \(value)\n"
        }
    }
}
