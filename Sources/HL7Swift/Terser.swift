//
//  Terser.swift
//  
//
//  Created by Paul on 24/12/2021.
//

import Foundation

/**
 Example of path : `/PATIENT_RESULT/ORDER_OBSERVATION/OBSERVATION(0)/OBX-14-1`
 */
public struct Terser {
    public let message: Message
    
    public init(_ message: Message) {
        self.message = message
    }
    
    public func get(_ path: String) throws -> String? {
        guard let group = try message.group() else {
            return nil
        }
        var pathClone = path
        
        // TODO regex check /
        //let comps = path.split(separator: "/")
        if pathClone.first == "/" { pathClone.removeFirst() }
        guard let slashIndex = pathClone.firstIndex(where: { $0 == "/" }) else {
            return nil
        }
        let name = pathClone.prefix(upTo: slashIndex)
        print(name)
        let remainingComponents = pathClone.suffix(from: slashIndex)
        print(remainingComponents)
        
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
                    return try self.get(pathClone)
                }
            case .segment(let segment):
                print("segment \(segment.code)")
                if segment.code == name {
                    if remainingComponents.isEmpty {
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

    public var errorDescription: String? {
        switch self {
  
        case .tersePathTooLong(message: let message):
            return "Terse path is too long: \(message)"
            
        }
    }
}
