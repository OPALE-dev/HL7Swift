//
//  Terser.swift
//  
//
//  Created by Paul on 24/12/2021.
//

import Foundation

let REGEX_RULE = #"(\/[A-za-z]+[0-9_\-\(\)]*)+"#
let FIELD_REPETITION_REGEX_RULE = #"[1-9]\([1-9]\)"#

/**
 The terser can get a segment description, or a field in particular in the message, given a string.
 Example of path : `/PATIENT_RESULT/ORDER_OBSERVATION/OBSERVATION(0)/OBX-14-1`
 Regex rule for path : `(\/[A-za-z]+[0-9_\-\(\)]*)+`
 
 A path must look like this : `/group1/group2/.../group3(repetition)/segment_code-field(repetition)-component-subcomponent`.
 The last token is the segment. The repetitions are optionals.
 
 
 - TODO: set a field/cell/segment, parse components, subcomponents, repetitions (segments and fields), better regex
 - TODO: better handling of 0-indexes
 */
public struct Terser {
    public let message: Message
    
    public init(_ message: Message) {
        self.message = message
    }
    
    public func geet(_ path: String) throws -> String? {
        let result = path.range(
            of: REGEX_RULE,
            options: .regularExpression
        )

        if result == nil {
            throw TerserError.incorrectTersePath(message: "Terse path doesn't respect regular expression (\\/[A-za-z0-9_\\-\\(\\)]*)+")
        }
        
        var comps = path.split(separator: "/")
        
        // last component is a segment
        if comps.count == 1 {
            return message[String(comps[0])]?.description
        } else {
            
            guard let current = message.specMessage?.rootGroup else {
                return nil
            }
            
            for item in current.items {
                switch item {
                case .group(let subGroup):
                    
                    if subGroup.name == comps[0] {
                        comps.removeFirst()
                        return try self.geetAux(comps, currentGroup: subGroup)
                    }
                case .segment(_):
                    print("")
                }
            }
        }
        
        return nil
    }
    
    func geetAux(_ comps: [String.SubSequence], currentGroup: Group) throws -> String? {
        var components = comps
        //print("comps \(comps)")
        
        // last component is a segment
        if comps.count == 1 {
            return scanSegmentPath(String(comps[0]))
            /*
            let segmentString = String(comps[0])
            print("Final step \(comps)")
            
            let subpathComponents = segmentString.split(separator: "-")
            
            // PV1
            if subpathComponents.count == 1 {
                return message[segmentString]?.description
                
            // PV1-1
            } else if subpathComponents.count == 2 {
                let segmentCode = String(subpathComponents[0])
                // TODO handle 0 index
                let segmentField = String(subpathComponents[1])
                
                let result = segmentField.range(
                    of: FIELD_REPETITION_REGEX_RULE,
                    options: .regularExpression
                )

                // no repetition
                if result == nil {
                    print(segmentCode, segmentField)
                    return message[segmentCode]![Int(segmentField)! - 1]!.description
                }
                
                
                let scanner = Scanner(string: segmentField)
                if #available(macOS 10.15, *) {
                    let field = (scanner.scanInt())!
                    let _ = scanner.scanCharacter()
                    let repetition = (scanner.scanInt())!
                    return message[segmentCode]![field - 1]!.cells[repetition - 1].description
                } else {
                    // Fallback on earlier versions
                    var field: Int = 0
                    scanner.scanInt(&field)
                    scanner.scanUpTo("(", into: nil)
                    var repetition: Int = 0
                    scanner.scanInt(&repetition)
                    return message[segmentCode]![field - 1]!.cells[repetition - 1].description
                }
                              
            
            // PV1-3-2
            } else if subpathComponents.count == 3 {
                let segmentCode = String(subpathComponents[0])
                // TODO handle 0 index
                let segmentField = Int(subpathComponents[1])! - 1
                let segmentComponent = Int(subpathComponents[2])! - 1
                
                return message[segmentCode]![segmentField]!.cells[0].components[segmentComponent].description
            
            // SFT-1-6-3
            } else if subpathComponents.count == 4 {
                let segmentCode = String(subpathComponents[0])
                // TODO handle 0 index
                let segmentField = Int(subpathComponents[1])! - 1
                let segmentComponent = Int(subpathComponents[2])! - 1
                let segmentSubcomponent = Int(subpathComponents[3])! - 1
                
                return message[segmentCode]![segmentField]!.cells[0].components[segmentComponent].components[segmentSubcomponent].description
    
            }
            */
        } else {
            
            for item in currentGroup.items {
                switch item {
                case .group(let subGroup):

                    if subGroup.name == comps[0] {
                        components.removeFirst()
                        return try self.geetAux(components, currentGroup: subGroup)
                    }
                case .segment(_):
                    print("")
                }
            }
        }
        
        return nil
    }
    
    
    
    
    
    
    
    
    
    
    /**
     Scans a segment path, eg `PID-1(2)-3-12`, which represents `code-field(repetition)-component-subcomponent`.
     The repetition is optional
     */
    private func scanSegmentPath(_ segment: String) -> String? {
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
            return message[code]?.description
        }
        
        // FIELD
        scanner.charactersToBeSkipped = CharacterSet(charactersIn: "-()") //scanUpTo("-", into: nil)
        scanner.scanInt(&field)
        field -= 1
        
        if scanner.isAtEnd {
            return message[code]?[field]?.description
        }
        
        // REPETITION, optional
        
        if scanner.string.first == "(" {
            if scanner.scanInt(&repetition) {
                //scanner.scanUpTo(")", into: nil)
                repetition -= 1
            } 
            
            if scanner.isAtEnd {
                return message[code]?[field]?.cells[repetition].description
            }
        } else {
            
            repetition = 0
        }
        
        
        
        // COMPONENT
        //scanner.scanUpTo("-", into: nil)
        scanner.scanInt(&component)
        component -= 1
        
        if scanner.isAtEnd {
            return message[code]?[field]?.cells[repetition].components[component].description
        }
        
        // SUBCOMPONENT
        //scanner.scanUpTo("-", into: nil)
        scanner.scanInt(&subcomponent)
        subcomponent -= 1
        
        if scanner.isAtEnd {
            return message[code]?[field]?.cells[repetition].components[component].components[subcomponent].description
        }
        
        // TODO throw error, path too long
        return nil
    }
    
}


public enum TerserError: LocalizedError {
    // TODO errrr rethink error name
    case tersePathTooLong(message: String)
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
