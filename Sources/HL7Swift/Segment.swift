//
//  Segment.swift
//  
//
//  Created by Paul on 22/12/2021.
//

import Foundation

public struct Segment {
    var code: String = ""
    var fields: [Field] = []
    
    init(_ str: String) {
        
        // see ORU 1 txt file, contains a ^ at the last line
        if !str.contains("|") {
            code = str
            return
        }
        
        var strCloneSplit = str.split(separator: "|", maxSplits: 50, omittingEmptySubsequences: false)
        
        code = String(strCloneSplit.remove(at: 0))
                    
        if strCloneSplit[0].contains("^") && strCloneSplit[0].contains("~") {
            fields.append(Field([Cell(String(strCloneSplit.remove(at: 0)), isEncoding: true)]))
        }
        
        for field in strCloneSplit {
            fields.append(Field(String(field)))
        }
    }
}

extension Segment: CustomStringConvertible {
    public var description: String {
        var str = code + "|"

        for field in fields {
            str += field.description + "|"
        }
        
        // remove last |
        str.removeLast()

        return str
    }
}
