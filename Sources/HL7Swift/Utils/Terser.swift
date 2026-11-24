//
//  Terser.swift
//  
//
//  Created by Paul on 24/12/2021.
//

import Foundation

let REGEX_RULE = #"(\/[A-Za-z]+[0-9_\-\(\)]*)+"#
let FIELD_REPETITION_REGEX_RULE = #"[1-9]\([1-9]\)"#
// OBSERVATION(0)
let GROUP_WITH_REPETITION_REGEX_RULE = #"[A-Z]+\([0-9]+\)"#

/**
 The terser can get a segment description, or a field in particular in the message, given a string.
 Example of path : `/PATIENT_RESULT/ORDER_OBSERVATION/OBSERVATION(2)/OBX-14-1`
 Regex rule for path : `(\/[A-za-z]+[0-9_\-\(\)]*)+`
 
 A path must look like this : `/group1/group2/.../group3(repetition)/segment_code-field(repetition)-component-subcomponent`.
 The last token is the segment. The repetitions are optionals.
 
 
 - TODO: setter & better regexes, filters, documentation
 
 Example :
 ```
 let terser = Terser(message)
 
 let pv1 = try terser.get("/PATIENT_RESULT/PATIENT/VISIT/PV1")
 ```
 */
public struct Terser {
    public let message: Message
    
    public init(_ message: Message) {
        self.message = message
    }
    
    public func get(_ path: String) throws -> String? {
        // Check path is correct
        let result = path.range(
            of: REGEX_RULE,
            options: .regularExpression
        )

        if result == nil {
            throw TerserError.incorrectTersePath(message: "Terse path doesn't respect regular expression (\\/[A-za-z0-9_\\-\\(\\)]*)+")
        }
        
        let comps = path.split(separator: "/")
        
        guard let current = message.specMessage?.rootGroup else {
            return nil
        }
        
        return try self.getAux(comps, currentGroup: current)
    }
    
    public func val(_ path: String, value: String) throws -> Bool {
        // Check path is correct
        let result = path.range(
            of: REGEX_RULE,
            options: .regularExpression
        )

        if result == nil {
            throw TerserError.incorrectTersePath(message: "Terse path doesn't respect regular expression (\\/[A-za-z0-9_\\-\\(\\)]*)+")
        }
        
        let comps = path.split(separator: "/")
        
        guard let current = message.specMessage?.rootGroup else {
            return false
        }
        
        let node = try self.__get(comps, currentGroup: current)

        if let cell = node as? Cell {
            cell.text = value
            
            return true
        } else if let field = node as? Field {
            field.cells.first?.text = value
            
            return true
        } else {
            return false
        }
    }
    
    func getAux(_ comps: [String.SubSequence], currentGroup: Group, repetitions: UInt = 1) throws -> String? {
        var components = comps
        var reps: UInt = repetitions
        var groupName = ""
        
        // If there's only one component, there's just a segment's code
        if comps.count == 1 {
            return scanSegmentPath(String(comps[0]), repetitions: reps)
 
        } else {
            // handle segment repetition
            let result = getRepetitionFromGroup(String(comps[0]))
            reps = result.0
            groupName = result.1
            
            for item in currentGroup.items {
                switch item {
                case .group(let subGroup):

                    if subGroup.name == groupName {
                        components.removeFirst()
                        return try self.getAux(components, currentGroup: subGroup, repetitions: reps)
                    }
                case .segment(_):
                    break
                }
            }
        }
        
        return nil
    }
    
    /**
     Gets the number of repetition from a group path, eg `OBSERVATION(2)`, and the group name
     
     If there's no repetition, eg `OBSERVATION`, the function returns (**1**, the group name)
     
     Usage :
     ```
     getRepetitionFromGroup("OBSERVATION(2)")
     // (2, "OBSERVATION")
     ```
     */
    private func getRepetitionFromGroup(_ group: String) -> (UInt, String) {
        // Check if there's a repetition according to a regex
        let result = group.range(
            of: GROUP_WITH_REPETITION_REGEX_RULE,
            options: .regularExpression
        )
        
        // No repetitions were found
        if result == nil {
            return (1, group)
        } else {
            // Extracting the number of repetitions; a count that does not
            // fit leaves the name unmatched rather than stopping.
            guard let a = group.firstIndex(of: "("), let b = group[a...].firstIndex(of: ")"),
                  let count = UInt(group[group.index(after: a)..<b]) else {
                return (1, group)
            }
            
            // Extracting the group name
            let groupName = String(group[..<a])
            
            return (count, groupName)
        }
    }

    func __get(_ comps: [String.SubSequence], currentGroup: Group, repetitions: UInt = 1) throws -> Node? {
        var components = comps
        var reps: UInt = repetitions
        var groupName = ""
        
        // If there's only one component, there's just a segment's code
        if comps.count == 1 {
            return scanSegPath(String(comps[0]), repetitions: reps)
 
        } else {
            // handle segment repetition
            let result = getRepetitionFromGroup(String(comps[0]))
            reps = result.0
            groupName = result.1
            
            for item in currentGroup.items {
                switch item {
                case .group(let subGroup):

                    if subGroup.name == groupName {
                        components.removeFirst()
                        return try self.__get(components, currentGroup: subGroup, repetitions: reps)
                    }
                case .segment(_):
                    break
                }
            }
        }
        
        return nil
    }
    
    /**
     Scans a segment path, eg `PID-1(2)-3-12`, which represents `code-field(repetition)-component-subcomponent`,
     and returns the node it designates, or nil when the message has no such node.
     The repetition is optional, default's 1
     */
    private func scanSegPath(_ segment: String, repetitions: UInt = 1) -> Node? {
        // CODE
        guard segment.count >= 3 else {
            return nil
        }
        var path = segment
        var field: Int = 0
        var repetition: Int = 0
        var component: Int = 0
        var subcomponent: Int = 0
        
        let code = String(path.prefix(3))
        path.removeFirst(3)
        
        guard let messageSegment = message.getSegment(code, repetition: repetitions) else {
            return nil
        }
        
        if path.isEmpty {
            return messageSegment
        }
        
        let scanner = Scanner(string: path)
        
        // FIELD
        scanner.charactersToBeSkipped = CharacterSet(charactersIn: "-")
        scanner.scanInt(&field)
        //field -= 1 // index offset is now managed by segment subscript itself
        
        guard let messageField = messageSegment[field] else {
            return nil
        }
        
        if scanner.isAtEnd {
            return messageField
        }
        
        // REPETITION, optional
        if scanner.scanString("(", into: nil) {
            if scanner.scanInt(&repetition) {
                scanner.scanString(")", into: nil)
                repetition -= 1
            }
        }
        
        guard messageField.cells.indices.contains(repetition) else {
            return nil
        }
        let cell = messageField.cells[repetition]
        
        if scanner.isAtEnd {
            return cell
        }
        
        // COMPONENT
        scanner.scanInt(&component)
        component -= 1
        
        guard cell.components.indices.contains(component) else {
            return nil
        }
        let messageComponent = cell.components[component]
        
        if scanner.isAtEnd {
            return messageComponent
        }
        
        // SUBCOMPONENT
        scanner.scanInt(&subcomponent)
        subcomponent -= 1
        
        if scanner.isAtEnd, messageComponent.components.indices.contains(subcomponent) {
            return messageComponent.components[subcomponent]
        }
        
        // path too long, or no such subcomponent
        return nil
    }
    
    /**
     Scans a segment path, eg `PID-1(2)-3-12`, which represents `code-field(repetition)-component-subcomponent`,
     and returns the text of the node it designates.
     The repetition is optional, default's 1
     */
    private func scanSegmentPath(_ segment: String, repetitions: UInt = 1) -> String? {
        switch scanSegPath(segment, repetitions: repetitions) {
        case let segment as Segment:
            return segment.description
        case let field as Field:
            return field.description
        case let cell as Cell:
            return cell.description
        default:
            return nil
        }
    }
    
}


public enum TerserError: LocalizedError {
    /// Terse path goes far too long in the group tree
    case tersePathTooLong(message: String)
    
    /// If terse path doesn't respect regex rules
    case incorrectTersePath(message: String)

    public var errorDescription: String? {
        switch self {
  
        case .tersePathTooLong(message: let message):
            return "Terse path is too long: \(message)"
        
        case .incorrectTersePath(message: let message):
            return "Terse path is incorrect: \(message)"
          
        }
    }
}
