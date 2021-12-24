//
//  Field.swift
//  
//
//  Created by Paul on 22/12/2021.
//

import Foundation

/**
 A field is a set of cells, it contains the data of the HL7 messages.
 
 Usage :
 ```
 let field = Field("LOI_Common_Component^LOI Base Profile^2.16.840.1.113883.9.66^ISO~LOI_NG_Component^LOI NG Profile^2.16.840.1.113883.9.79^ISO")
 
 print(field)
 # same as print(field.description)
 # "LOI_Common_Component^LOI Base Profile^2.16.840.1.113883.9.66^ISO~LOI_NG_Component^LOI NG Profile^2.16.840.1.113883.9.79^ISO"
 ```
 */
public struct Field {
    var cells: [Cell] = []
    
    init(_ str: String) {
        if str.contains("~") {
            // 20 is a random number, could be anything; we want to take empty subsequences but we oughta specify a maximum number
            // of splits too, that's where the 20 is coming from
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
