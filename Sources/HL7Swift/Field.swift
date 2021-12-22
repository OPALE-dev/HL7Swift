//
//  Field.swift
//  
//
//  Created by Paul on 22/12/2021.
//

import Foundation

public struct Field {
    var cells: [Cell] = []
    
    init(_ str: String) {
        if str.contains("~") {
            for cell in str.split(separator: "~", maxSplits: 20, omittingEmptySubsequences: false) {
                cells.append(Cell(String(cell)))
            }
        } else {
            cells.append(Cell(str))
        }
    }
    
    init(_ cellsToCopy: [Cell]) {
        cells = cellsToCopy
    }
}

extension Field: CustomStringConvertible {
    public var description: String {
        var str = ""
        
        for cell in cells {
            str += cell.description + "~"
        }
        
        // remove last ~
        str.removeLast()
        
        return str
    }
}
