//
//  TerserSuggestion.swift
//  
//
//  Created by Paul on 15/04/2022.
//

import Foundation

/**
 Level of autocompleteness of the terser suggestions:
 - Groups: show only groups
 - Segments: show only goups AND segments
 - Fields: show only groups AND segments AND fields
 - Cells: All
 */
public enum AutocompleteLevel {
    case Groups
    case Segments
    case Fields
    case Cells
}

/**
 Used for autocompletion of a terser path.
 */
public class TerserSuggestion {
    
    /// The HL7 message to parse.
    let message: HL7Swift.Message
    
    /// The user's input.
    public var input: String = ""
    
    /// How deep the suggestions must be.
    var autocompleteLevel: AutocompleteLevel = .Segments
    
    /// Dictionnary of suggestions of nodes.
    var nodes: [String:Node] {
        if input.isEmpty {
            return allTerserPaths
        } else {
            if input == "/" {
                return allTerserPaths
            } else {
                return allTerserPaths.filter { $0.key.starts(with: input) }
            }
        }
    }
    
    /// The suggestions array.
    var suggestions: [String] {
        Array(nodes.keys)
    }
    
    /// The node currently visited by the user.
    var currentNodeWithParent: Node? {
        print("User input :", input)
        
        if input.isEmpty { return message.rootGroup }
        
        // The user's input match a terse path
        if let n = nodes[input] {
            return n
        } else {
            
            // If there's only one /, that means there's no parent, it's the root
            if input.filter({ $0 == "/" }).count == 1 {
                return message.rootGroup
            } else {
                // Remove the unwanted part, ie "/goodpart/goodpart/uncompleted_par_"
                let lastSlash = input.lastIndex(of: "/")
                let parentString = String(input[..<lastSlash!])
//                print("Checking parent...")
//                print("Parent string is :", parentString)
//                print("Result :", nodes[parentString])
//                print(nodes.keys)
                self.input = parentString
                
//                print("Result after change :", nodes[parentString])
//                print(nodes.keys)
//                print("All", allTerserPaths)
//                print("Result with all paths :", allTerserPaths[parentString])
                // print(suggestions)
                //print(input[...lastSlash!], "|", input[..<lastSlash!])
                return nodes[parentString]
                //return allTerserPaths()[parentString]
            }
        }
    }
    
    /// The node currently visited by the user.
    var currentNodeWithoutParent: Node? {
        if input.isEmpty { return nil }
        
        // The user's input match a terse path
        if let n = nodes[input] {
            return n
        } else {
            
            // If there's only one /, that means there's no parent,
            // it's the root
            if input.filter({ $0 == "/" }).count == 1 {
                return nil
            } else {
                // Return the root in case the input doesn't match anything
                return message.rootGroup
            }
        }
    }
    
    // MARK: - Inits
    
    public init(_ m: HL7Swift.Message) {
        message = m
    }
    
    public init(_ m: HL7Swift.Message, withCompleteLevel level: AutocompleteLevel) {
        message = m
        autocompleteLevel = level
    }
    
    // MARK: -
    
    /**
     Returns all terser paths of the message, accordingly to the complete level.
     */
    lazy var allTerserPaths: [String:Node] = {
        guard let allItems = message.rootGroup?.items else { return [:] }
        
        var suggestionsNodes: [String:Node] = [:]
        
        for i in allItems {
            switch i {
                
            case .group(let g):
                suggestionsNodes[g.tersePath(nil)] = g
                let nestedSuggestions = terserPaths(for: g)
                suggestionsNodes.merge(nestedSuggestions) { (current,_) in current }
                
            case .segment(let s):
                if autocompleteLevel != .Groups {
                    suggestionsNodes[s.tersePath()] = s
                }
            }
        }
        
        return suggestionsNodes
    }()
    
    func terserPaths(for n: Group) -> [String:Node] {
        var suggestionsNodes: [String:Node] = [:]
        
        for i in n.items {
            switch i {
                
            case .group(let g):
                suggestionsNodes[g.tersePath(nil)] = g
                let nestedSuggestions = terserPaths(for: g)
                suggestionsNodes.merge(nestedSuggestions) { (current,_) in current }
                
            case .segment(let s):
                if autocompleteLevel != .Groups {
                    suggestionsNodes[s.tersePath()] = s
                }
            }
        }
        
        return suggestionsNodes
    }
    
    // MARK: - Getters
    
    /**
     Returns the suggestions for the current user's input.
     */
    public func get() -> [String] {
        return suggestions
    }
    
    /**
     Returns the current node given the user's input. If the input is not a perfect terser path, but we can still get the
     parent group, we return parent group if `perfectMatch` is `false`.
     */
    public func node(_ perfectMatch: Bool = false) -> Node? {
        if perfectMatch {
            return currentNodeWithoutParent
        } else {
            return currentNodeWithParent
        }
    }
}
