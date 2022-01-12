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
            // Extracting the number of repetitions
            let a = group.firstIndex(of: "(")!
            let a1 = group.index(after: a)
            let b = group.firstIndex(of: ")")!
            
            // Extracting the group name
            let groupName = String(group[..<a])
            
            return (UInt(group[a1..<b])!, groupName)
        }
    }
    
    /**
     Scans a segment path, eg `PID-1(2)-3-12`, which represents `code-field(repetition)-component-subcomponent`.
     The repetition is optional, default's 1
     */
    private func scanSegmentPath(_ segment: String, repetitions: UInt = 1) -> String? {
        var path = segment
        var field: Int = 0
        var repetition: Int = 0
        var component: Int = 0
        var subcomponent: Int = 0
        
        // CODE
        let code = String(path.prefix(3))
        path.removeFirst(3)
        
        let scanner = Scanner(string: path)
        
        if path.isEmpty {
            return message.getSegment(code, repetition: repetitions)?.description
        }
        
        // FIELD
        scanner.charactersToBeSkipped = CharacterSet(charactersIn: "-")
        scanner.scanInt(&field)
        //field -= 1 // index offset is now managed by segment subscript itself
        
        if scanner.isAtEnd {
            return message.getSegment(code, repetition: repetitions)?[field]?.description
        }
        
        // REPETITION, optional
        if scanner.scanString("(", into: nil) {
            if scanner.scanInt(&repetition) {
                scanner.scanString(")", into: nil)
                repetition -= 1
            } 
            
            if scanner.isAtEnd {
                return message.getSegment(code, repetition: repetitions)?[field]?.cells[repetition].description
            }
        }        
        
        // COMPONENT
        scanner.scanInt(&component)
        component -= 1
        
        if scanner.isAtEnd {
            return message.getSegment(code, repetition: repetitions)?[field]?.cells[repetition].components[component].description
        }
        
        // SUBCOMPONENT
        scanner.scanInt(&subcomponent)
        subcomponent -= 1
        
        if scanner.isAtEnd {
            return message.getSegment(code, repetition: repetitions)?[field]?.cells[repetition].components[component].components[subcomponent].description
        }
        
        // TODO throw error, path too long
        return nil
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
