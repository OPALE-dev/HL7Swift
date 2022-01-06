//
//  Terser.swift
//  
//
//  Created by Paul on 24/12/2021.
//

import Foundation

let REGEX_RULE = #"(\/[A-za-z]+[0-9_\-\(\)]*)+"#

/**
 The terser can get a segment description, or a field in particular in the message, given a string.
 Example of path : `/PATIENT_RESULT/ORDER_OBSERVATION/OBSERVATION(0)/OBX-14-1`
 Regex rule : `(\/[A-za-z]+[0-9_\-\(\)]*)+`
 
 
 - TODO: set a field/cell/segment, parse components, subcomponents, repetitions
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
                    print("subGroup \(subGroup.name)")
                    if subGroup.name == comps[0] {
                        comps.removeFirst()
                        return self.geetAux(comps, currentGroup: subGroup)
                    }
                case .segment(let segment):
                    print("segment \(segment)")
                }
            }
        }
        
        return nil
    }
    
    func geetAux(_ comps: [String.SubSequence], currentGroup: Group) -> String? {
        var components = comps
        print("comps \(comps)")
        
        // last component is a segment
        if comps.count == 1 {
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
                let segmentField = Int(subpathComponents[1])! - 1
                
                return message[segmentCode]![segmentField]!.description
            
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
        } else {
            
            for item in currentGroup.items {
                switch item {
                case .group(let subGroup):
                    print("subGroup \(subGroup.name)")
                    if subGroup.name == comps[0] {
                        components.removeFirst()
                        return self.geetAux(components, currentGroup: subGroup)
                    }
                case .segment(let segment):
                    print("segment \(segment)")
                }
            }
        }
        
        return nil
    }
    
    public func get(_ path: String, currentGroup: Group? = nil) throws -> String? {
        let group: Group
        let name: String
        let remainingComponents: String
        
        if currentGroup != nil {
            group = currentGroup!
        } else {
            guard let rgroup = message.specMessage?.rootGroup else {
                return nil
            }
            group = rgroup
        }
        
        var pathClone = path
        
        // TODO regex check /
        //let comps = path.split(separator: "/")
        if pathClone.first == "/" { pathClone.removeFirst() }
        if let slashIndex = pathClone.firstIndex(where: { $0 == "/" }) {
            name = String(pathClone.prefix(upTo: slashIndex))
            print("node \(name)")
            remainingComponents = String(pathClone.suffix(from: slashIndex))
            print("remains \(remainingComponents)")
            
        } else {
            name = pathClone
            remainingComponents = ""
        }
        
        /*
        let comps = path.components(separatedBy: "/")
        let name = comps[0]
        let remainingComponents = path.dropFirst()
        // remainingComponents
        print("")
         */
        
        
        
        for item in group.items {
            switch item {
            case .group(let subGroup):
                print("subGroup \(subGroup.name)")
                if subGroup.name == name {
                    print("FOUND subGroup \(subGroup.name)")
                    return try self.get(remainingComponents, currentGroup: subGroup)
                }
            case .segment(let segment):
                print("segment \(segment.code) \(segment.description)")
                if segment.code == name {
                    print("FOUND \(name)")
                    if false {
                        print("is empty")
                        throw TerserError.tersePathTooLong(message: "there are no remaining components")
                    } else {
                        return segment.description
                    }
                }
            }
        }
        
        return ""
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
