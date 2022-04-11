//
//  File.swift
//  
//
//  Created by Rafaël Warnault on 11/03/2022.
//

import Foundation

public protocol Node: CustomStringConvertible {
    var name:String { get set }
    var parent:Node? { get set }
    func path() -> String
}

extension Node {
    public func path() -> String {
        if parent != nil {
            return "\(parent!.path())/\(name)"
        }
        
        return "/\(name)"
    }
    
    /**
     For a given terser path, returns suggestions to complete the path. Returns a dictionnary with the suggested paths as keys
     and the nodes as values. The nodes may be used later for further autocompletion.
     
     Example : `/PATIENT/OB` gives `["/PATIENT/OBX": <OBX node>]`
     - parameters:
        - input: the terser path to complete
        - deepInput: used internally
     */
    public func autocomplete(_ input: String, deepInput: String = "/") -> [String:Node] {
        var suggestions: [String:Node] = [:]
        let i = input.lastIndex(of: "/")!
        let j = input.index(after: i)
        let otherNodes = String(input[..<i])
        let lastNode = String(input[j...])
        
        if let group = self as? Group {
            for item in group.items {
                switch item {
                case .group(let g):
                    if lastNode.isEmpty || g.name.hasPrefix(lastNode) {
                        suggestions[deepInput + g.name] = g as Node
                        suggestions.merge(g.autocomplete(otherNodes + "/" + g.name + "/", deepInput: deepInput + g.name + "/")) {(current,_) in current}
                    }
                case .segment(let s):
                    if lastNode.isEmpty || s.code.hasPrefix(lastNode) {
                        suggestions[deepInput + s.code] = s as Node
                        suggestions.merge(s.autocomplete(otherNodes + "/" + s.code + "/", deepInput: deepInput + s.code + "/")) {(current,_) in current}
                    }
                }
            }
        } else if let segment = self as? Segment {
            
        } else if let field = self as? Field {
            
        } else if let cell = self as? Cell {
            
        }
        
        return suggestions
    }
}
